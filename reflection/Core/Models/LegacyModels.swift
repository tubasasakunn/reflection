/**
 * LegacyModels.swift
 * 後方互換性のためのレガシーモデル定義
 *
 * 責務:
 * - 旧バージョンのデータモデル互換性維持
 * - 移行期間中のサポート
 *
 * 注意:
 * - 新規機能では使用しないこと
 * - 将来的に削除予定
 */

import Foundation

// MARK: - Legacy Compatibility

/// 後方互換性のためのエイリアス
typealias ReflectionMindMap = MindMapNode

// MARK: - MindMapNode Legacy Extension

extension MindMapNode {
    /// 後方互換: sampleプロパティ
    static var sample: MindMapNode { sampleRoot }

    /// 後方互換: rootNodeプロパティ
    var rootNode: String { label }

    /// 後方互換: branchesプロパティ（旧形式への変換）
    var branches: [CauseBranch] {
        children?.compactMap { child -> CauseBranch? in
            guard child.type == MindMapNodeType.cause else { return nil }
            return CauseBranch(
                id: child.id,
                label: child.label,
                children: child.children?.compactMap { action -> ActionNode? in
                    guard action.type == MindMapNodeType.action else { return nil }
                    return ActionNode(
                        id: action.id,
                        label: action.label,
                        rule: action.rule ?? ""
                    )
                } ?? []
            )
        } ?? []
    }
}

// MARK: - CauseBranch

/// 原因の分岐（後方互換用）
struct CauseBranch: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Properties

    var id: UUID = UUID()
    let label: String
    let children: [ActionNode]

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case label, children
    }

    // MARK: - Initializer

    init(id: UUID = UUID(), label: String, children: [ActionNode]) {
        self.id = id
        self.label = label
        self.children = children
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.label = try container.decode(String.self, forKey: .label)
        self.children = try container.decode([ActionNode].self, forKey: .children)
    }
}

// MARK: - ActionNode

/// 対策ノード（後方互換用）
struct ActionNode: Codable, Equatable, Identifiable, Sendable {

    // MARK: - Properties

    var id: UUID = UUID()
    let label: String
    let rule: String

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case label, rule
    }

    // MARK: - Initializer

    init(id: UUID = UUID(), label: String, rule: String) {
        self.id = id
        self.label = label
        self.rule = rule
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.label = try container.decode(String.self, forKey: .label)
        self.rule = try container.decode(String.self, forKey: .rule)
    }
}
