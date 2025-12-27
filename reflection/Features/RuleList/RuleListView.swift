/**
 * RuleListView.swift
 * 規則一覧を表示するView
 *
 * 責務:
 * - 規則の一覧表示
 * - 規則の追加・編集・削除UI
 * - SwiftDataからの規則取得
 *
 * 使用箇所:
 * - メインタブの「マイルール」タブ
 */

import SwiftUI
import SwiftData

// MARK: - RuleListView

/// 規則一覧画面
struct RuleListView: View {

    // MARK: - Properties

    /// ViewModel
    @Bindable var viewModel: RuleListViewModel

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Query

    /// 規則一覧（作成日降順）
    @Query(sort: \Rule.createdAt, order: .reverse)
    private var rules: [Rule]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("マイルール")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        addButton
                    }
                }
                .sheet(isPresented: $viewModel.isAddingRule) {
                    addRuleSheet
                }
                .sheet(item: $viewModel.editingRule) { rule in
                    EditRuleView(
                        rule: rule,
                        onSave: { updatedRule in
                            viewModel.updateRule(updatedRule)
                        },
                        onCancel: {
                            viewModel.cancelEditing()
                        }
                    )
                }
                .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                    Button("OK") {
                        viewModel.clearError()
                    }
                } message: {
                    Text(viewModel.errorMessage ?? "")
                }
                .onAppear {
                    viewModel.setup(with: modelContext)
                }
        }
    }

    // MARK: - Subviews

    /// メインコンテンツ
    @ViewBuilder
    private var content: some View {
        if rules.isEmpty {
            emptyState
        } else {
            ruleList
        }
    }

    /// 空状態の表示
    private var emptyState: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            Image(systemName: "list.clipboard")
                .font(.system(size: DesignTokens.IconSize.huge))
                .foregroundStyle(Color.textTertiary)

            Text("マイルールがありません")
                .font(.system(size: DesignTokens.FontSize.title3, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Text("反省から学んだルールを追加して\n自己改善を始めましょう")
                .font(.system(size: DesignTokens.FontSize.subheadline))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(DesignTokens.FontSize.subheadline * (DesignTokens.LineHeight.relaxed - 1))

            Button {
                viewModel.startAddingRule()
            } label: {
                Label("ルールを追加", systemImage: "plus")
                    .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, DesignTokens.Spacing.xl)
                    .frame(height: DesignTokens.TouchTarget.recommended)
                    .background(Color.cta)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField))
            }
        }
        .padding(DesignTokens.Spacing.lg)
    }

    /// 規則リスト
    private var ruleList: some View {
        List {
            ForEach(rules) { rule in
                RuleRowView(
                    rule: rule,
                    onToggle: {
                        viewModel.toggleRuleActive(rule)
                    },
                    onEdit: {
                        viewModel.startEditing(rule)
                    }
                )
            }
            .onDelete { indexSet in
                for index in indexSet {
                    viewModel.deleteRule(rules[index])
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    /// 追加ボタン
    private var addButton: some View {
        Button {
            viewModel.startAddingRule()
        } label: {
            Image(systemName: "plus")
        }
    }

    /// 新規規則追加シート
    private var addRuleSheet: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("例: 朝の時間を大切にする", text: $viewModel.newRuleTitle)
                }

                Section("説明（任意）") {
                    TextField("詳細な説明を入力", text: $viewModel.newRuleDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新しいルール")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.cancelAddingRule()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        viewModel.addRule()
                    }
                    .disabled(viewModel.newRuleTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    RuleListView(viewModel: RuleListViewModel())
        .modelContainer(for: Rule.self, inMemory: true)
}
