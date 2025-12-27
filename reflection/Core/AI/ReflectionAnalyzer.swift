/**
 * ReflectionAnalyzer.swift
 * Foundation Modelsを使用して反省内容を分析するサービス
 *
 * 責務:
 * - 反省テキストの初期分析（ルート + 1次原因）
 * - ノード展開時の深堀分析（原因タップ → 子ノード生成）
 * - Foundation Models (Apple Intelligence) との連携
 *
 * 使用箇所:
 * - ReflectionViewModel: 分析実行時に使用
 *
 * 注意:
 * - Foundation Modelsフレームワークが必要（iOS 26+）
 * - デバイス上でのAI処理のため、対応デバイスが必要
 */

import Foundation
import FoundationModels

// MARK: - ReflectionAnalyzerProtocol

/// 反省分析のプロトコル
protocol ReflectionAnalyzerProtocol: Sendable {
    /// 反省内容を分析してルート + 1次原因を生成（4-6個）
    /// - Parameters:
    ///   - content: 反省内容
    ///   - existingRules: 既存ルールのリスト（競合チェック用）
    func analyzeInitial(content: String, existingRules: [ExistingRuleInfo]) async throws -> MindMapNode

    /// ノードを展開して子ノードを生成
    /// - Parameters:
    ///   - node: 展開するノード
    ///   - context: 元の反省内容
    ///   - path: これまでの経緯（ラベルの配列）
    ///   - existingRules: 既存ルールのリスト（競合チェック用）
    func expandNode(node: MindMapNode, context: String, path: [String], existingRules: [ExistingRuleInfo]) async throws -> [MindMapNode]
}

// MARK: - ReflectionAnalyzer

/// Foundation Modelsを使用した反省分析サービス
@MainActor
final class ReflectionAnalyzer: ReflectionAnalyzerProtocol {

    // MARK: - Singleton

    /// シングルトンインスタンス
    static let shared = ReflectionAnalyzer()

    // MARK: - Properties

    /// Foundation Modelsが利用可能か
    private var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    // MARK: - Initializer

    private init() {}

    // MARK: - Public Methods

    /// 反省内容を分析してルート + 1次原因を生成（4-6個）
    /// コルブモデルに基づき、各項目に学習段階を付与
    /// - Parameters:
    ///   - content: 反省の内容
    ///   - existingRules: 既存ルールのリスト
    /// - Returns: ルートノード（子に1次原因を含む）
    func analyzeInitial(content: String, existingRules: [ExistingRuleInfo]) async throws -> MindMapNode {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ReflectionAnalyzerError.emptyInput
        }

        // Foundation Modelsの利用可能性チェック
        guard SystemLanguageModel.default.isAvailable else {
            throw ReflectionAnalyzerError.foundationModelsUnavailable
        }

        do {
            // Step 1: 自由文で思考
            let thinkingSession = LanguageModelSession(instructions: AnalysisPrompts.systemInstruction)
            let thinkingPrompt = AnalysisPrompts.initialAnalysisThinking(content: content)

            let thinkingResponse = try await thinkingSession.respond(to: thinkingPrompt)
            let thinkingResult = thinkingResponse.content

            print("[ReflectionAnalyzer] Step1 thinking: \(thinkingResult.prefix(100))...")

            // Step 2: 構造化
            let structuringPrompt = AnalysisPrompts.initialAnalysisStructuring(thinkingResult: thinkingResult)

            let structuredResponse = try await thinkingSession.respond(
                to: structuringPrompt,
                generating: GeneratedAnalysisResult.self
            )

            let analysis = structuredResponse.content

            // MindMapNodeに変換（深さ1なので全てRO）
            let rootLabel = String(content.prefix(20)) + (content.count > 20 ? "..." : "")
            let children = analysis.items.map { item in
                convertToMindMapNode(item, depth: 1)
            }

            // 初期分析（深さ1）ではルール競合チェックは行わない
            // ルール競合は深さ6以降（RF許可時）のみ

            print("[ReflectionAnalyzer] Initial analysis completed: \(children.count) items")

            return MindMapNode(
                label: rootLabel,
                type: .cause,
                learningStage: .reflectiveObservation,
                children: children
            )

        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .refusal(let refusal, _):
                if let explanationResponse = try? await refusal.explanation {
                    throw ReflectionAnalyzerError.refused(explanationResponse.content)
                } else {
                    throw ReflectionAnalyzerError.refused("不明な理由")
                }
            default:
                print("[ReflectionAnalyzer] Generation error: \(error)")
                throw ReflectionAnalyzerError.analysisFailed(error.localizedDescription)
            }
        } catch {
            print("[ReflectionAnalyzer] Error: \(error)")
            throw ReflectionAnalyzerError.analysisFailed(error.localizedDescription)
        }
    }

    /// ノードを展開して子ノードを生成
    /// 深さに応じて使用可能なステージを制御
    /// - 深さ1-2: ROのみ
    /// - 深さ3以降: RO + AC（AI判定）
    /// - 深さ4以降: RO + AC + RF（AI判定）
    /// - Parameters:
    ///   - node: 展開するノード
    ///   - context: 元の反省内容
    ///   - path: これまでの経緯（ラベルの配列）
    ///   - existingRules: 既存ルールのリスト
    /// - Returns: 生成された子ノード
    func expandNode(node: MindMapNode, context: String, path: [String], existingRules: [ExistingRuleInfo]) async throws -> [MindMapNode] {
        guard node.type == MindMapNodeType.cause else {
            return []
        }

        // Foundation Modelsの利用可能性チェック
        guard SystemLanguageModel.default.isAvailable else {
            throw ReflectionAnalyzerError.foundationModelsUnavailable
        }

        // 深さを計算（pathの長さ + 1 = 次のノードの深さ）
        let depth = path.count + 1

        // 深さに応じて使用可能なステージを決定
        let allowedStages = determineAllowedStages(for: depth)

        do {
            // Step 1: 自由文で思考
            let thinkingSession = LanguageModelSession(instructions: AnalysisPrompts.systemInstruction)
            let thinkingPrompt = AnalysisPrompts.nodeExpansionThinking(
                originalContent: context,
                currentCause: node.label,
                path: path,
                depth: depth,
                allowedStages: allowedStages
            )

            let thinkingResponse = try await thinkingSession.respond(to: thinkingPrompt)
            let thinkingResult = thinkingResponse.content

            print("[ReflectionAnalyzer] Step1 thinking (depth=\(depth)): \(thinkingResult.prefix(100))...")

            // Step 2: 構造化
            let structuringPrompt = AnalysisPrompts.nodeExpansionStructuring(
                thinkingResult: thinkingResult,
                allowedStages: allowedStages
            )

            let structuredResponse = try await thinkingSession.respond(
                to: structuringPrompt,
                generating: GeneratedAnalysisResult.self
            )

            let analysis = structuredResponse.content

            // MindMapNodeに変換（学習段階付き）
            // 深さに基づいてステージをフィルタ/強制変換
            var children = analysis.items.map { item in
                convertToMindMapNode(item, depth: depth)
            }

            // 既存ルールとの競合チェック
            // 深さ6以降（RF許可時）のみ、直近ノードのみで判定
            if depth >= 6 && !existingRules.isEmpty && !node.isRuleUpdateMode {
                let conflictNodes = try await checkRuleConflicts(
                    cause: node.label,
                    existingRules: existingRules
                )
                children.append(contentsOf: conflictNodes)
            }

            print("[ReflectionAnalyzer] Node expansion (depth=\(depth)) completed: \(children.count) items")

            return children

        } catch let error as LanguageModelSession.GenerationError {
            switch error {
            case .refusal(let refusal, _):
                if let explanationResponse = try? await refusal.explanation {
                    throw ReflectionAnalyzerError.refused(explanationResponse.content)
                } else {
                    throw ReflectionAnalyzerError.refused("不明な理由")
                }
            default:
                print("[ReflectionAnalyzer] Generation error: \(error)")
                throw ReflectionAnalyzerError.analysisFailed(error.localizedDescription)
            }
        } catch {
            print("[ReflectionAnalyzer] Error: \(error)")
            throw ReflectionAnalyzerError.analysisFailed(error.localizedDescription)
        }
    }

    /// 深さに応じて使用可能なステージを決定
    /// - 深さ1-4: ROのみ
    /// - 深さ5: RO + AC
    /// - 深さ6以降: RO + AC + RF
    private func determineAllowedStages(for depth: Int) -> [String] {
        if depth <= 4 {
            return ["RO"]
        } else if depth == 5 {
            return ["RO", "AC"]
        } else {
            return ["RO", "AC", "RF"]
        }
    }

    // MARK: - Private Methods

    /// GeneratedItemをMindMapNodeに変換
    /// 深さに基づいてステージを強制変換
    private func convertToMindMapNode(_ item: GeneratedItem, depth: Int? = nil) -> MindMapNode {
        var stage = parseLearningStage(item.stage)

        // 深さに基づくステージ制限を強制
        if let depth = depth {
            stage = enforceStageConstraint(stage, depth: depth)
        }

        let nodeType: MindMapNodeType = (stage == .ruleFormation) ? .action : .cause

        return MindMapNode(
            label: item.label,
            type: nodeType,
            rule: item.rule,
            learningStage: stage
        )
    }

    /// 学習段階文字列をLearningStageに変換
    private func parseLearningStage(_ stageString: String) -> LearningStage {
        let normalized = stageString.uppercased().trimmingCharacters(in: .whitespaces)

        if normalized.contains("RF") || normalized.contains("RULE") {
            return .ruleFormation
        } else if normalized.contains("AC") || normalized.contains("ABSTRACT") {
            return .abstractConceptualization
        } else {
            return .reflectiveObservation
        }
    }

    /// 深さに基づいてステージを強制変換
    /// - 深さ1-4: 必ずRO
    /// - 深さ5: RO or AC（RFは不可）
    /// - 深さ6以降: すべて許可
    private func enforceStageConstraint(_ stage: LearningStage, depth: Int) -> LearningStage {
        if depth <= 4 {
            // 深さ1-4は必ずRO
            return .reflectiveObservation
        } else if depth == 5 {
            // 深さ5はRFを許可しない
            if stage == .ruleFormation {
                return .abstractConceptualization
            }
            return stage
        } else {
            // 深さ6以降はすべて許可
            return stage
        }
    }

    /// 既存ルールとの競合をチェック
    /// - Parameters:
    ///   - cause: 現在の原因
    ///   - existingRules: 既存ルールのリスト
    /// - Returns: 競合するルールに対応するノード（existingRuleIdが設定済み）
    private func checkRuleConflicts(
        cause: String,
        existingRules: [ExistingRuleInfo]
    ) async throws -> [MindMapNode] {
        guard !existingRules.isEmpty else { return [] }

        let session = LanguageModelSession(instructions: AnalysisPrompts.systemInstruction)

        // インデックス付きのルール情報を作成
        let rulesWithIndex = existingRules.enumerated().map { index, rule in
            (index: index, title: rule.title, description: rule.description)
        }

        let prompt = AnalysisPrompts.ruleConflictCheck(
            cause: cause,
            existingRules: rulesWithIndex
        )

        let response = try await session.respond(
            to: prompt,
            generating: GeneratedRuleConflictCheck.self
        )

        let conflictCheck = response.content

        // 競合するルールのノードを作成
        var conflictNodes: [MindMapNode] = []
        for index in conflictCheck.conflictingRuleIndices {
            guard index >= 0 && index < existingRules.count else { continue }

            let rule = existingRules[index]
            let label = AnalysisPrompts.ruleViolationLabel(ruleTitle: rule.title)

            let node = MindMapNode(
                label: label,
                type: .cause,
                learningStage: .reflectiveObservation,  // 既存ルール違反は観察段階
                existingRuleId: rule.id
            )

            conflictNodes.append(node)
            print("[ReflectionAnalyzer] Rule conflict detected: '\(rule.title)'")
        }

        if conflictNodes.isEmpty {
            print("[ReflectionAnalyzer] No rule conflicts found")
        }

        return conflictNodes
    }
}
