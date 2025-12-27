/**
 * EditRuleView.swift
 * 規則編集シート
 *
 * 責務:
 * - 規則の編集フォーム表示
 * - 保存/キャンセルアクション
 *
 * 使用箇所:
 * - RuleListView
 */

import SwiftUI

// MARK: - EditRuleView

/// 規則編集View
struct EditRuleView: View {

    // MARK: - Properties

    let rule: Rule
    let onSave: (Rule) -> Void
    let onCancel: () -> Void

    // MARK: - State

    @State private var title: String = ""
    @State private var description: String = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("タイトル", text: $title)
                }

                Section("説明（任意）") {
                    TextField("詳細な説明を入力", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("有効", isOn: .constant(rule.isActive))
                }
            }
            .navigationTitle("ルールを編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        rule.update(
                            title: title,
                            description: description.isEmpty ? nil : description
                        )
                        onSave(rule)
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                title = rule.title
                description = rule.ruleDescription ?? ""
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview {
    EditRuleView(
        rule: Rule(title: "サンプルルール", description: "説明文"),
        onSave: { _ in },
        onCancel: {}
    )
}
