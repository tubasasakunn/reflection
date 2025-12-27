/**
 * Rule.swift
 * 規則（マイルール）を表すSwiftDataモデル
 *
 * 責務:
 * - 反省から導き出された規則の永続化
 * - 規則の状態管理（アクティブ/非アクティブ）
 *
 * 関連:
 * - ReflectionEntry: 反省エントリーから規則が生成される
 */

import Foundation
import SwiftData

// MARK: - Rule

/// マイルールを表すモデル
@Model
final class Rule {

    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// 規則のタイトル
    var title: String

    /// 規則の詳細説明（オプション）
    var ruleDescription: String?

    /// アクティブ状態
    /// trueの場合、規則が有効
    var isActive: Bool

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    /// 関連する反省エントリーのID（オプション）
    var relatedReflectionId: UUID?

    /// 経緯（反省内容 → 原因1 → 原因2 → ... の形式）
    var context: String?

    // MARK: - Initializer

    /// 新しい規則を作成
    /// - Parameters:
    ///   - title: 規則のタイトル
    ///   - description: 詳細説明（オプション）
    ///   - relatedReflectionId: 関連する反省エントリーのID（オプション）
    ///   - context: 経緯（深堀りのパス）
    init(
        title: String,
        description: String? = nil,
        relatedReflectionId: UUID? = nil,
        context: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.ruleDescription = description
        self.isActive = true
        self.createdAt = Date()
        self.updatedAt = Date()
        self.relatedReflectionId = relatedReflectionId
        self.context = context
    }

    // MARK: - Methods

    /// 規則を更新
    /// - Parameters:
    ///   - title: 新しいタイトル
    ///   - description: 新しい説明
    func update(title: String, description: String?) {
        self.title = title
        self.ruleDescription = description
        self.updatedAt = Date()
    }

    /// アクティブ状態を切り替え
    func toggleActive() {
        self.isActive.toggle()
        self.updatedAt = Date()
    }
}

// MARK: - Rule Extension

extension Rule {
    /// サンプルデータを生成（プレビュー用）
    static var sampleData: [Rule] {
        [
            Rule(
                title: "朝の時間を大切にする",
                description: "7時までに起床し、1日の計画を立てる時間を確保する"
            ),
            Rule(
                title: "タスクは細分化する",
                description: "大きなタスクは30分以内で完了できる単位に分割する"
            ),
            Rule(
                title: "完璧を求めすぎない",
                description: "80%の完成度で一旦リリースし、フィードバックを得る"
            )
        ]
    }
}
