/**
 * ReflectionViewModel.swift
 * 反省入力・分析画面のViewModel
 *
 * 責務:
 * - 反省内容の入力管理
 * - AI分析の実行（初期分析 + ノード展開）
 * - ナビゲーションスタックの管理（深堀り・戻る）
 * - ルール追加ダイアログの管理
 *
 * 使用箇所:
 * - ReflectionView
 */

import Foundation
import SwiftData
import SwiftUI

// MARK: - ReflectionViewModel

/// 反省画面のViewModel
@Observable
@MainActor
final class ReflectionViewModel {

    // MARK: - Properties

    /// 反省の入力テキスト
    var inputText = ""

    /// ローディング状態（初期分析中）
    var isLoading = false

    /// ノード展開中の状態
    var isExpanding = false

    /// エラーメッセージ
    var errorMessage: String?

    /// ルートノード（マインドマップ全体の起点）
    var rootNode: MindMapNode?

    /// ナビゲーションスタック（現在のパス）
    /// 最後の要素が現在表示中のノード
    var navigationPath: [MindMapNode] = []

    /// ルール追加ダイアログ用の選択されたノード
    var nodeForRuleDialog: MindMapNode?

    /// 現在の反省エントリー
    var currentEntry: ReflectionEntry?

    /// 成功メッセージ
    var successMessage: String?

    /// ルール作成完了時のコールバック
    var onRuleCreated: (() -> Void)?

    /// 分析サービス
    private let analyzer: ReflectionAnalyzerProtocol

    /// モデルコンテキスト
    private var modelContext: ModelContext?

    // MARK: - Cache & Prefetch

    /// 展開結果のキャッシュ
    private var expansionCache: [UUID: [MindMapNode]] = [:]

    /// 先読みタスク
    private var prefetchTasks: [UUID: Task<[MindMapNode], Error>] = [:]

    /// ストリーミング中の子ノード（段階的に表示）
    var streamingChildren: [MindMapNode] = []

    /// ストリーミングモードを使用するか
    var useStreamingMode = true

    // MARK: - Computed Properties

    /// 現在表示中のノード
    var currentNode: MindMapNode? {
        navigationPath.last
    }

    /// 戻れるかどうか（ルート以外にいる場合）
    var canGoBack: Bool {
        navigationPath.count > 1
    }

    /// 現在のパスのラベル一覧（経緯表示用）
    var pathLabels: [String] {
        navigationPath.map { $0.label }
    }

    // MARK: - Initializer

    /// 初期化
    /// - Parameter analyzer: 分析サービス
    init(analyzer: ReflectionAnalyzerProtocol? = nil) {
        self.analyzer = analyzer ?? ReflectionAnalyzer.shared
    }

    // MARK: - Setup

    /// ModelContextを設定
    /// - Parameter context: SwiftDataのModelContext
    func setup(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Analysis Methods

    /// 反省を分析（初期分析）
    func analyzeReflection() async {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "反省内容を入力してください"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let existingRules = fetchExistingRules()
            let result = try await analyzer.analyzeInitial(
                content: inputText,
                existingRules: existingRules
            )
            rootNode = result
            navigationPath = [result]

            saveReflectionEntry(result)

            print("[ReflectionViewModel] Initial analysis completed: \(result.label)")
        } catch {
            print("[ReflectionViewModel] Analysis failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Prefetch Methods

    /// 子ノードを先読み展開
    /// - Parameter node: 先読み対象のノード
    func prefetchChildren(for node: MindMapNode) {
        // 既にキャッシュ済み、先読み中、または読み込み済みならスキップ
        guard node.type == .cause,
              expansionCache[node.id] == nil,
              prefetchTasks[node.id] == nil,
              !node.isLoaded else {
            return
        }

        let currentPath = pathLabels + [node.label]
        let existingRules = fetchExistingRules()
        let context = inputText

        prefetchTasks[node.id] = Task { [analyzer] in
            try await analyzer.expandNode(
                node: node,
                context: context,
                path: currentPath,
                existingRules: existingRules
            )
        }

        print("[ReflectionViewModel] Started prefetch for: \(node.label)")
    }

    /// 現在の子ノードすべてを先読み
    func prefetchAllChildren() {
        guard let current = currentNode, let children = current.children else { return }

        for child in children where child.type == .cause {
            prefetchChildren(for: child)
        }
    }

    // MARK: - Navigation Methods

    /// 深堀りノードをタップ（子ノードを展開して移動）
    /// - Parameter node: タップされた深堀りノード
    func drillDown(to node: MindMapNode) async {
        guard node.type == .cause else { return }

        // 既に読み込み済みの場合は移動のみ
        if node.isLoaded, let _ = node.children {
            navigationPath.append(node)
            return
        }

        // キャッシュチェック
        if let cached = expansionCache[node.id] {
            var updatedNode = node
            updatedNode.setChildren(cached)
            updateNodeInTree(updatedNode)
            navigationPath.append(updatedNode)
            print("[ReflectionViewModel] Used cached expansion for: \(node.label)")
            return
        }

        // 先読み結果をチェック
        if let prefetchTask = prefetchTasks[node.id] {
            isExpanding = true
            do {
                let children = try await prefetchTask.value
                prefetchTasks.removeValue(forKey: node.id)
                expansionCache[node.id] = children

                var updatedNode = node
                updatedNode.setChildren(children)
                updateNodeInTree(updatedNode)
                navigationPath.append(updatedNode)
                print("[ReflectionViewModel] Used prefetched expansion for: \(node.label)")
                isExpanding = false
                return
            } catch {
                prefetchTasks.removeValue(forKey: node.id)
                // 先読み失敗時は通常の展開にフォールバック
            }
        }

        // 子ノードを生成
        isExpanding = true

        do {
            // 現在のパス + タップしたノードのラベルを含める
            let currentPath = pathLabels + [node.label]
            let existingRules = fetchExistingRules()
            var children = try await analyzer.expandNode(
                node: node,
                context: inputText,
                path: currentPath,
                existingRules: existingRules
            )

            // キャッシュに保存
            expansionCache[node.id] = children

            // 親ノードがルール更新モードの場合、子ノードにも伝播
            if let ruleId = node.existingRuleId {
                children = children.map { child in
                    var updatedChild = child
                    // 子ノードに既存ルールIDが設定されていない場合のみ伝播
                    if updatedChild.existingRuleId == nil {
                        updatedChild = MindMapNode(
                            id: child.id,
                            label: child.label,
                            type: child.type,
                            rule: child.rule,
                            children: child.children,
                            existingRuleId: ruleId
                        )
                    }
                    return updatedChild
                }
            }

            // ノードを更新
            var updatedNode = node
            updatedNode.setChildren(children)

            // ルートノードのツリーを更新
            updateNodeInTree(updatedNode)

            // ナビゲーションに追加
            navigationPath.append(updatedNode)

            print("[ReflectionViewModel] Drilled down: \(node.label) -> \(children.count) children")
        } catch {
            print("[ReflectionViewModel] Expand failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }

        isExpanding = false
    }

    /// 親ノードタップで戻る
    func goBack() {
        guard canGoBack else { return }
        navigationPath.removeLast()
    }

    /// ルールノードをタップ（ダイアログ表示）
    /// - Parameter node: タップされたルールノード
    func showRuleDialog(for node: MindMapNode) {
        guard node.type == .action else { return }
        nodeForRuleDialog = node
    }

    /// ルールダイアログを閉じる
    func dismissRuleDialog() {
        nodeForRuleDialog = nil
    }

    // MARK: - Rule Creation

    /// 選択されたアクションノードからルールを作成または更新
    func createRuleFromNode(_ node: MindMapNode) {
        guard modelContext != nil else {
            print("[ReflectionViewModel] ModelContext not set")
            return
        }

        guard node.type == .action else {
            errorMessage = "対策ノードを選択してください"
            return
        }

        let ruleText = node.rule ?? node.label
        let pathDescription = pathLabels.joined(separator: " → ")

        // 既存ルール更新モードかチェック
        if let existingRuleId = node.existingRuleId {
            updateExistingRule(
                ruleId: existingRuleId,
                newTitle: ruleText,
                newDescription: "経緯: \(pathDescription)\n対策: \(node.label)",
                context: pathDescription
            )
        } else {
            createNewRule(
                title: ruleText,
                description: "経緯: \(pathDescription)\n対策: \(node.label)",
                context: pathDescription
            )
        }

        nodeForRuleDialog = nil
    }

    /// 新規ルールを作成
    private func createNewRule(title: String, description: String, context pathDescription: String) {
        guard let context = modelContext else { return }

        let newRule = Rule(
            title: title,
            description: description,
            relatedReflectionId: currentEntry?.id,
            context: pathDescription
        )

        context.insert(newRule)

        do {
            try context.save()
            print("[ReflectionViewModel] Rule created: \(newRule.title)")
            // ルール作成完了コールバックを呼び出し
            onRuleCreated?()
        } catch {
            print("[ReflectionViewModel] Failed to create rule: \(error.localizedDescription)")
            errorMessage = "ルールの保存に失敗しました"
        }
    }

    /// 既存ルールを更新
    private func updateExistingRule(ruleId: UUID, newTitle: String, newDescription: String, context pathDescription: String) {
        guard let context = modelContext else { return }

        // 既存ルールを取得
        let descriptor = FetchDescriptor<Rule>(predicate: #Predicate { $0.id == ruleId })
        guard let existingRule = try? context.fetch(descriptor).first else {
            print("[ReflectionViewModel] Existing rule not found: \(ruleId)")
            // フォールバック: 新規作成
            createNewRule(title: newTitle, description: newDescription, context: pathDescription)
            return
        }

        // ルールを更新
        existingRule.update(title: newTitle, description: newDescription)

        do {
            try context.save()
            print("[ReflectionViewModel] Rule updated: \(existingRule.title)")
            // ルール作成完了コールバックを呼び出し
            onRuleCreated?()
        } catch {
            print("[ReflectionViewModel] Failed to update rule: \(error.localizedDescription)")
            errorMessage = "ルールの更新に失敗しました"
        }
    }

    /// 既存ルールのリストを取得
    private func fetchExistingRules() -> [ExistingRuleInfo] {
        guard let context = modelContext else { return [] }

        let descriptor = FetchDescriptor<Rule>(
            predicate: #Predicate { $0.isActive == true },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        guard let rules = try? context.fetch(descriptor) else { return [] }

        return rules.map { rule in
            ExistingRuleInfo(
                id: rule.id,
                title: rule.title,
                description: rule.ruleDescription
            )
        }
    }

    // MARK: - Tree Update

    /// ツリー内のノードを更新
    private func updateNodeInTree(_ updatedNode: MindMapNode) {
        guard var root = rootNode else { return }

        if updateNodeRecursive(node: &root, target: updatedNode) {
            rootNode = root

            // ナビゲーションパスも更新
            navigationPath = navigationPath.map { pathNode in
                if pathNode.id == updatedNode.id {
                    return updatedNode
                }
                return pathNode
            }
        }
    }

    /// 再帰的にノードを更新
    private func updateNodeRecursive(node: inout MindMapNode, target: MindMapNode) -> Bool {
        if node.id == target.id {
            node = target
            return true
        }

        if var children = node.children {
            for i in children.indices {
                if updateNodeRecursive(node: &children[i], target: target) {
                    node.children = children
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Entry Persistence

    /// 反省エントリーを保存
    private func saveReflectionEntry(_ node: MindMapNode) {
        guard let context = modelContext else {
            print("[ReflectionViewModel] ModelContext not set")
            return
        }

        let entry = ReflectionEntry(content: inputText)

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(node)
            if let jsonString = String(data: data, encoding: .utf8) {
                entry.saveAnalysisResult(jsonString)
            }
        } catch {
            print("[ReflectionViewModel] Failed to encode node: \(error.localizedDescription)")
        }

        context.insert(entry)

        do {
            try context.save()
            currentEntry = entry
            print("[ReflectionViewModel] Entry saved: \(entry.id)")
        } catch {
            print("[ReflectionViewModel] Failed to save entry: \(error.localizedDescription)")
        }
    }

    // MARK: - UI Methods

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    /// 成功メッセージをクリア
    func clearSuccess() {
        successMessage = nil
    }

    /// 画面をリセット
    func reset() {
        inputText = ""
        rootNode = nil
        navigationPath = []
        nodeForRuleDialog = nil
        currentEntry = nil
        errorMessage = nil
        successMessage = nil

        // キャッシュをクリア
        expansionCache.removeAll()

        // 先読みタスクをキャンセル
        prefetchTasks.values.forEach { $0.cancel() }
        prefetchTasks.removeAll()
    }
}

// MARK: - Legacy Compatibility

extension ReflectionViewModel {
    /// 後方互換: mindMapプロパティ
    var mindMap: MindMapNode? {
        get { rootNode }
        set { rootNode = newValue }
    }
}
