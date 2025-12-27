/**
 * GenerableTypes.swift
 * Foundation Models (@Generable) 対応の構造体定義
 *
 * 責務:
 * - AI生成用の構造体定義
 * - Foundation Modelsとの連携型
 *
 * 使用箇所:
 * - ReflectionAnalyzer
 */

import Foundation
import FoundationModels

// MARK: - GeneratedItem

/// AI生成用: 学習段階付きの項目
@Generable(description: "学習段階が付与された分析項目")
struct GeneratedItem {

    // MARK: - Properties

    @Guide(description: "項目のラベル（15文字以内）")
    var label: String

    @Guide(description: "学習段階（RO: 内省的観察, AC: 抽象的概念化, RF: ルール形成）")
    var stage: String

    @Guide(description: "ルールテキスト（RF段階のみ、30文字以内）")
    var rule: String?
}

// MARK: - GeneratedAnalysisResult

/// AI生成用: 統合分析結果
/// 深さに応じて使用可能なステージが変わる
@Generable(description: "コルブモデルに基づく分析結果")
struct GeneratedAnalysisResult {

    // MARK: - Properties

    @Guide(description: "反省内容の要約（20文字以内）")
    var summary: String

    @Guide(description: "分析項目のリスト（3〜4つ、重複なし）")
    var items: [GeneratedItem]
}

// MARK: - GeneratedRuleConflictCheck

/// AI生成用: 既存ルール競合チェック結果
@Generable(description: "既存ルールとの競合チェック結果")
struct GeneratedRuleConflictCheck {

    // MARK: - Properties

    @Guide(description: "競合する既存ルールのインデックス番号（0始まり）のリスト。競合がなければ空配列")
    var conflictingRuleIndices: [Int]
}

// MARK: - ExistingRuleInfo

/// 既存ルールの情報（競合チェック用）
struct ExistingRuleInfo: Sendable {

    // MARK: - Properties

    let id: UUID
    let title: String
    let description: String?
}

// MARK: - ReflectionAnalyzerError

/// 分析エラーの種類
enum ReflectionAnalyzerError: Error, LocalizedError {
    /// Foundation Modelsが利用不可
    case foundationModelsUnavailable
    /// 分析に失敗
    case analysisFailed(String)
    /// デコードに失敗
    case decodingFailed(Error)
    /// 入力が空
    case emptyInput
    /// モデルが拒否
    case refused(String)

    var errorDescription: String? {
        switch self {
        case .foundationModelsUnavailable:
            return "Apple Intelligenceが利用できません"
        case .analysisFailed(let message):
            return "分析に失敗しました: \(message)"
        case .decodingFailed(let error):
            return "結果の解析に失敗しました: \(error.localizedDescription)"
        case .emptyInput:
            return "反省内容を入力してください"
        case .refused(let message):
            return "リクエストが拒否されました: \(message)"
        }
    }
}
