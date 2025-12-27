/**
 * RuleListViewModel.swift
 * 規則一覧画面のViewModel
 *
 * 責務:
 * - 規則の取得・追加・更新・削除
 * - UI状態の管理
 * - SwiftDataとの連携
 *
 * 使用箇所:
 * - RuleListView
 */

import Foundation
import SwiftData
import SwiftUI

// MARK: - RuleListViewModel

/// 規則一覧のViewModel
@Observable
@MainActor
final class RuleListViewModel {

    // MARK: - Properties

    /// ローディング状態
    var isLoading = false

    /// エラーメッセージ
    var errorMessage: String?

    /// 新規規則作成用のタイトル
    var newRuleTitle = ""

    /// 新規規則作成用の説明
    var newRuleDescription = ""

    /// 新規規則追加シートの表示状態
    var isAddingRule = false

    /// 編集中の規則
    var editingRule: Rule?

    /// モデルコンテキスト
    private var modelContext: ModelContext?

    // MARK: - Initializer

    init() {}

    // MARK: - Setup

    /// ModelContextを設定
    /// - Parameter context: SwiftDataのModelContext
    func setup(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - CRUD Methods

    /// 新しい規則を追加
    func addRule() {
        guard let context = modelContext else {
            print("[RuleListViewModel] ModelContext not set")
            return
        }

        guard !newRuleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "タイトルを入力してください"
            return
        }

        let rule = Rule(
            title: newRuleTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: newRuleDescription.isEmpty ? nil : newRuleDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        context.insert(rule)

        do {
            try context.save()
            print("[RuleListViewModel] Rule added: \(rule.title)")

            // 入力をリセット
            newRuleTitle = ""
            newRuleDescription = ""
            isAddingRule = false
        } catch {
            print("[RuleListViewModel] Failed to save rule: \(error.localizedDescription)")
            errorMessage = "規則の保存に失敗しました"
        }
    }

    /// AI分析結果から規則を追加
    /// - Parameters:
    ///   - title: 規則のタイトル
    ///   - reflectionId: 関連する反省エントリーのID
    func addRuleFromAnalysis(title: String, reflectionId: UUID?) {
        guard let context = modelContext else {
            print("[RuleListViewModel] ModelContext not set")
            return
        }

        let rule = Rule(
            title: title,
            description: nil,
            relatedReflectionId: reflectionId
        )

        context.insert(rule)

        do {
            try context.save()
            print("[RuleListViewModel] Rule added from analysis: \(rule.title)")
        } catch {
            print("[RuleListViewModel] Failed to save rule from analysis: \(error.localizedDescription)")
            errorMessage = "規則の保存に失敗しました"
        }
    }

    /// 規則を更新
    /// - Parameter rule: 更新する規則
    func updateRule(_ rule: Rule) {
        guard let context = modelContext else {
            print("[RuleListViewModel] ModelContext not set")
            return
        }

        do {
            try context.save()
            print("[RuleListViewModel] Rule updated: \(rule.title)")
            editingRule = nil
        } catch {
            print("[RuleListViewModel] Failed to update rule: \(error.localizedDescription)")
            errorMessage = "規則の更新に失敗しました"
        }
    }

    /// 規則を削除
    /// - Parameter rule: 削除する規則
    func deleteRule(_ rule: Rule) {
        guard let context = modelContext else {
            print("[RuleListViewModel] ModelContext not set")
            return
        }

        context.delete(rule)

        do {
            try context.save()
            print("[RuleListViewModel] Rule deleted: \(rule.title)")
        } catch {
            print("[RuleListViewModel] Failed to delete rule: \(error.localizedDescription)")
            errorMessage = "規則の削除に失敗しました"
        }
    }

    /// 規則のアクティブ状態を切り替え
    /// - Parameter rule: 切り替える規則
    func toggleRuleActive(_ rule: Rule) {
        rule.toggleActive()
        updateRule(rule)
    }

    // MARK: - UI Methods

    /// エラーメッセージをクリア
    func clearError() {
        errorMessage = nil
    }

    /// 新規規則追加を開始
    func startAddingRule() {
        newRuleTitle = ""
        newRuleDescription = ""
        isAddingRule = true
    }

    /// 新規規則追加をキャンセル
    func cancelAddingRule() {
        newRuleTitle = ""
        newRuleDescription = ""
        isAddingRule = false
    }

    /// 規則の編集を開始
    /// - Parameter rule: 編集する規則
    func startEditing(_ rule: Rule) {
        editingRule = rule
    }

    /// 規則の編集をキャンセル
    func cancelEditing() {
        editingRule = nil
    }
}
