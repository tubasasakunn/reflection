/**
 * ReflectionEntry.swift
 * 反省エントリーを表すSwiftDataモデル
 *
 * 責務:
 * - ユーザーの反省内容の永続化
 * - AI分析結果（マインドマップデータ）の保存
 *
 * 関連:
 * - Rule: 反省エントリーから規則が生成される
 * - ReflectionAnalyzer: AI分析を実行
 */

import Foundation
import SwiftData

// MARK: - ReflectionEntry

/// 反省エントリーを表すモデル
@Model
final class ReflectionEntry {

    // MARK: - Properties

    /// 一意識別子
    var id: UUID

    /// 反省の内容（ユーザー入力）
    var content: String

    /// AI分析結果（マインドマップのJSONデータ）
    /// ReflectionMindMapをJSON文字列として保存
    var analysisResultJSON: String?

    /// 作成日時
    var createdAt: Date

    /// 更新日時
    var updatedAt: Date

    // MARK: - Initializer

    /// 新しい反省エントリーを作成
    /// - Parameter content: 反省の内容
    init(content: String) {
        self.id = UUID()
        self.content = content
        self.analysisResultJSON = nil
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    // MARK: - Methods

    /// 分析結果を保存
    /// - Parameter analysisJSON: マインドマップのJSON文字列
    func saveAnalysisResult(_ analysisJSON: String) {
        self.analysisResultJSON = analysisJSON
        self.updatedAt = Date()
    }

    /// 内容を更新
    /// - Parameter content: 新しい内容
    func updateContent(_ content: String) {
        self.content = content
        self.updatedAt = Date()
    }
}

// MARK: - ReflectionEntry Extension

extension ReflectionEntry {
    /// サンプルデータを生成（プレビュー用）
    static var sampleData: [ReflectionEntry] {
        let entry1 = ReflectionEntry(
            content: "今日のミーティングで準備不足だった。事前に資料を確認していなかったため、質問に答えられなかった。"
        )
        entry1.analysisResultJSON = """
        {
            "rootNode": "ミーティング準備不足",
            "branches": [
                {
                    "label": "時間管理の問題",
                    "children": [
                        {"label": "前日に確認時間を確保", "rule": "会議前日に30分の準備時間を設ける"},
                        {"label": "カレンダーにリマインダー設定", "rule": "会議の24時間前にリマインダーを設定する"}
                    ]
                },
                {
                    "label": "優先順位の誤り",
                    "children": [
                        {"label": "重要度を見直す", "rule": "会議の重要度を事前に評価する"}
                    ]
                }
            ]
        }
        """

        let entry2 = ReflectionEntry(
            content: "締め切りに間に合わなかった。タスクの見積もりが甘かった。"
        )

        return [entry1, entry2]
    }
}
