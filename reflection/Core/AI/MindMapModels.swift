/**
 * MindMapModels.swift
 * マインドマップのデータモデル
 *
 * 責務:
 * - マインドマップのノード構造を定義
 * - Foundation Models (@Generable) 対応の構造体
 * - 動的な深さに対応（原因→原因→...→対策）
 *
 * 使用箇所:
 * - ReflectionAnalyzer: AI分析結果の型
 * - MindMapView: 表示用データ
 * - ReflectionViewModel: 状態管理
 *
 * ノードタイプ:
 * - cause: さらに深堀可能（子ノードを持てる）
 * - action: 終端ノード（規則として保存可能）
 */

import Foundation

// MARK: - MindMapNodeType

/// マインドマップノードの種類
enum MindMapNodeType: String, Codable, Sendable {
    /// 原因ノード - さらに深堀可能
    case cause
    /// 対策ノード - 終端、規則として保存可能
    case action
}

// MARK: - LearningStage

/// コルブの経験学習モデルに基づく学習段階
enum LearningStage: String, Codable, Sendable {
    /// 内省的観察 (Reflective Observation)
    /// 多角的な視点で経験を再構成する
    case reflectiveObservation = "RO"

    /// 抽象的概念化 (Abstract Conceptualization)
    /// パターン・法則を発見し構造化する
    case abstractConceptualization = "AC"

    /// ルール形成 (Rule Formation)
    /// 具体的な行動指針を作成する
    case ruleFormation = "RF"

    /// アイコン名
    var iconName: String {
        switch self {
        case .reflectiveObservation:
            return "eye.circle.fill"           // 観察・視点
        case .abstractConceptualization:
            return "lightbulb.circle.fill"     // 洞察・発見
        case .ruleFormation:
            return "checkmark.circle.fill"     // 行動・ルール
        }
    }

    /// 表示ラベル
    var label: String {
        switch self {
        case .reflectiveObservation:
            return "観察"
        case .abstractConceptualization:
            return "概念化"
        case .ruleFormation:
            return "ルール"
        }
    }
}

// MARK: - MindMapNode

/// マインドマップのノード
/// 動的な深さに対応した再帰的構造
struct MindMapNode: Codable, Identifiable, Equatable, Sendable {
    /// 一意の識別子
    var id: UUID = UUID()

    /// ノードのラベル（表示テキスト）
    let label: String

    /// ノードの種類（cause: 深堀可能, action: 終端）
    let type: MindMapNodeType

    /// 規則テキスト（actionタイプの場合のみ）
    let rule: String?

    /// 学習段階（コルブモデル）
    let learningStage: LearningStage

    /// 子ノード（遅延読み込み、AIで生成）
    var children: [MindMapNode]?

    /// 子ノードが読み込み済みか
    var isLoaded: Bool = false

    /// 関連する既存ルールのID（ルール更新モード用）
    /// このIDが設定されている場合、新規作成ではなく更新を行う
    var existingRuleId: UUID?

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case label, type, rule, children, existingRuleId, learningStage
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.label = try container.decode(String.self, forKey: .label)
        self.type = try container.decode(MindMapNodeType.self, forKey: .type)
        self.rule = try container.decodeIfPresent(String.self, forKey: .rule)
        self.learningStage = try container.decodeIfPresent(LearningStage.self, forKey: .learningStage) ?? .reflectiveObservation
        self.children = try container.decodeIfPresent([MindMapNode].self, forKey: .children)
        self.isLoaded = self.children != nil
        self.existingRuleId = try container.decodeIfPresent(UUID.self, forKey: .existingRuleId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(rule, forKey: .rule)
        try container.encode(learningStage, forKey: .learningStage)
        try container.encodeIfPresent(children, forKey: .children)
        try container.encodeIfPresent(existingRuleId, forKey: .existingRuleId)
    }

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        label: String,
        type: MindMapNodeType,
        rule: String? = nil,
        learningStage: LearningStage = .reflectiveObservation,
        children: [MindMapNode]? = nil,
        existingRuleId: UUID? = nil
    ) {
        self.id = id
        self.label = label
        self.type = type
        self.rule = rule
        self.learningStage = learningStage
        self.children = children
        self.isLoaded = children != nil
        self.existingRuleId = existingRuleId
    }

    // MARK: - Computed Properties

    /// 既存ルール更新モードかどうか
    var isRuleUpdateMode: Bool {
        existingRuleId != nil
    }

    // MARK: - Equatable

    static func == (lhs: MindMapNode, rhs: MindMapNode) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Mutating Methods

    /// 子ノードを設定
    mutating func setChildren(_ children: [MindMapNode]) {
        self.children = children
        self.isLoaded = true
    }
}

// MARK: - AIGeneratedChildren

/// AI生成された子ノードのレスポンス
/// Foundation Models用の構造体
struct AIGeneratedChildren: Codable, Sendable {
    /// 生成された子ノード
    let children: [MindMapNode]
}

// MARK: - Sample Data

extension MindMapNode {
    /// サンプルのルートノード（初期表示用）
    static var sampleRoot: MindMapNode {
        MindMapNode(
            label: "今日のミーティングで準備不足だった",
            type: .cause,
            learningStage: .reflectiveObservation,
            children: [
                MindMapNode(label: "計画不足", type: .cause, learningStage: .reflectiveObservation),
                MindMapNode(label: "時間管理の問題", type: .cause, learningStage: .reflectiveObservation),
                MindMapNode(label: "振り返りの不足", type: .cause, learningStage: .reflectiveObservation)
            ]
        )
    }

    /// サンプルの子ノード（計画不足の深堀）
    static var sampleChildrenForPlanning: [MindMapNode] {
        [
            MindMapNode(label: "優先順位が不明確", type: .cause, learningStage: .abstractConceptualization),
            MindMapNode(
                label: "事前に計画を立てる",
                type: .action,
                rule: "作業開始前に5分間の計画時間を設ける",
                learningStage: .ruleFormation
            ),
            MindMapNode(
                label: "タスクを細分化する",
                type: .action,
                rule: "30分以内で完了できる単位に分割する",
                learningStage: .ruleFormation
            )
        ]
    }

    /// サンプルの子ノード（優先順位の深堀 - 5次目の例）
    static var sampleChildrenForPriority: [MindMapNode] {
        [
            MindMapNode(
                label: "毎朝3つの重要タスクを選ぶ",
                type: .action,
                rule: "朝一番に今日やるべき3つを決める",
                learningStage: .ruleFormation
            ),
            MindMapNode(
                label: "緊急/重要マトリクスを使う",
                type: .action,
                rule: "タスクを4象限で分類してから着手する",
                learningStage: .ruleFormation
            )
        ]
    }
}

// MARK: - JSON Utilities

extension MindMapNode {
    /// JSONデータからデコード
    static func from(data: Data) throws -> MindMapNode {
        let decoder = JSONDecoder()
        return try decoder.decode(MindMapNode.self, from: data)
    }

    /// JSON文字列からデコード
    static func from(jsonString: String) throws -> MindMapNode {
        guard let data = jsonString.data(using: .utf8) else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: [],
                    debugDescription: "Invalid UTF-8 string"
                )
            )
        }
        return try from(data: data)
    }
}

