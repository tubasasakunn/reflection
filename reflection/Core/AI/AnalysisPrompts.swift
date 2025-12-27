/**
 * AnalysisPrompts.swift
 * AI分析用のプロンプト定数
 *
 * 責務:
 * - システムプロンプトの定義
 * - ユーザープロンプトテンプレートの定義
 * - ステップ別のプロンプト管理
 *
 * 使用箇所:
 * - ReflectionAnalyzer
 *
 * 設計原則（Foundation Models向け最適化）:
 * - XMLタグによる明確な構造化
 * - サンドイッチ構造（重要指示を冒頭と末尾に配置）
 * - Few-Shot事例（良い例・悪い例の両方）
 * - リテラリズム対応（曖昧さを排除）
 */

import Foundation

// MARK: - AnalysisPrompts

/// AI分析用プロンプト定数
enum AnalysisPrompts {

    // MARK: - System Instructions

    /// 共通のシステムプロンプト（コルブの経験学習モデルに基づく）
    /// 高速化のため圧縮版
    static let systemInstruction = """
        <role>経験学習コーチ</role>

        <stages>
        RO: 具体的状況（「〜だった」形式）
        AC: 普遍的法則（「〜が重要」形式）
        RF: 行動指針（「〜する」形式）
        </stages>

        <examples>
        RO: 「スライドの文字が多く聞き手が読むのに必死だった」
        AC: 「情報量と理解度は反比例する」
        RF: 「スライド作成前に聞き手の関心を3つ書き出す」
        </examples>

        <rules>
        - RO: 3〜4つ、AC: 許可時3〜4つ、RF: 許可時0〜1つ
        - 質問形式禁止、単語のみ禁止、重複禁止
        - 日本語で出力
        </rules>
        """

    // MARK: - Initial Analysis (初期分析)

    /// 初期分析：Step1 - 自由文で思考
    /// 高速化のため簡略化版
    static func initialAnalysisThinking(content: String) -> String {
        """
        【経験】\(content)

        【分析】
        反省者本人が「何をしたか／しなかったか」を推測。
        結果の言い換えではなく原因を推測する。

        3〜4つの原因仮説を箇条書きで簡潔に（各1文）。
        """
    }

    /// 初期分析：Step2 - 構造化
    static func initialAnalysisStructuring(thinkingResult: String) -> String {
        """
        以下の分析結果を構造化してください。

        【分析結果】
        \(thinkingResult)

        【構造化ルール】
        - 各仮説を20文字程度のlabelに要約
        - stageは全て「RO」
        - ruleはnull
        - 3〜4つに絞る（重複は除く）
        """
    }

    // MARK: - Node Expansion (ノード展開)

    /// ノード展開：Step1 - 自由文で思考
    /// 高速化のため簡略化版
    static func nodeExpansionThinking(
        originalContent: String,
        currentCause: String,
        path: [String],
        depth: Int,
        allowedStages: [String]
    ) -> String {
        let pathDescription = path.joined(separator: " → ")

        let stageGuidance: String
        if depth <= 4 {
            stageGuidance = "深い原因を推測（なぜ？具体的に何が？）"
        } else if depth == 5 {
            stageGuidance = "深い原因 + パターン・法則を抽出"
        } else {
            stageGuidance = "深い原因 + パターン・法則 + 具体的ルール（あれば1つ）"
        }

        return """
        【経験】\(originalContent)
        【経緯】\(pathDescription)
        【焦点】\(currentCause)

        【分析】\(stageGuidance)

        箇条書きで簡潔に。
        """
    }

    /// ノード展開：Step2 - 構造化
    static func nodeExpansionStructuring(
        thinkingResult: String,
        allowedStages: [String]
    ) -> String {
        let stagesDescription = allowedStages.joined(separator: "、")

        return """
        以下の分析結果を構造化してください。

        【分析結果】
        \(thinkingResult)

        【構造化ルール】
        - 各仮説を20文字程度のlabelに要約
        - stageは \(stagesDescription) のいずれか
        - RFの場合のみruleに「〜する」形式で30文字以内の行動指針
        - 各ステージ3〜4つ（重複は除く）
        - RFは0〜1つ（無理に出さない）
        """
    }

    // MARK: - Rule Conflict Check (既存ルール競合チェック)

    /// 既存ルール競合チェックのプロンプトテンプレート
    static func ruleConflictCheck(cause: String, existingRules: [(index: Int, title: String, description: String?)]) -> String {
        let rulesDescription = existingRules.map { rule in
            if let desc = rule.description {
                return "[\(rule.index)] \(rule.title): \(desc)"
            } else {
                return "[\(rule.index)] \(rule.title)"
            }
        }.joined(separator: "\n")

        return """
        <task>
        以下の原因が、既存ルールを守れなかったことに関連しているか判定せよ。
        </task>

        <cause>\(cause)</cause>

        <existing_rules>
        \(rulesDescription)
        </existing_rules>

        <criteria>
        - ルールの内容と原因が明確に直接関係している場合のみ
        - 曖昧な関連は含めない
        - 無理に関連づけなくてよい
        </criteria>

        <output>
        - 明確に関連するルールがあれば、そのインデックス番号を1つだけ返す
        - 関連がなければ空リスト（空リストで問題ない）
        </output>
        """
    }

    /// 既存ルール違反ノードのラベル生成
    static func ruleViolationLabel(ruleTitle: String) -> String {
        "「\(ruleTitle)」が守れなかった"
    }
}
