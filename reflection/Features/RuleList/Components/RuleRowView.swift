/**
 * RuleRowView.swift
 * 規則の行表示コンポーネント
 *
 * 責務:
 * - 規則の一覧表示用の行UI
 * - 展開/折りたたみ表示
 * - アクティブ状態の切り替え
 *
 * 使用箇所:
 * - RuleListView
 */

import SwiftUI

// MARK: - RuleRowView

/// 規則の行表示
struct RuleRowView: View {

    // MARK: - Properties

    let rule: Rule
    let onToggle: () -> Void
    let onEdit: () -> Void

    // MARK: - State

    @State private var isExpanded = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // メイン行
            mainRow

            // 展開時の詳細表示
            if isExpanded {
                expandedContent
            }
        }
        .padding(.vertical, DesignTokens.Spacing.sm)
        .contentShape(Rectangle())
        .onTapGesture {
            if rule.context != nil {
                withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
                    isExpanded.toggle()
                }
            }
        }
    }

    // MARK: - Subviews

    /// メイン行
    private var mainRow: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // アクティブ状態インジケータ
            Circle()
                .fill(rule.isActive ? Color.stateSuccess : Color.textTertiary.opacity(0.5))
                .frame(width: 12, height: 12)

            // コンテンツ
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(rule.title)
                    .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                    .foregroundStyle(rule.isActive ? Color.textPrimary : Color.textSecondary)
                    .lineSpacing(DesignTokens.FontSize.body * (DesignTokens.LineHeight.normal - 1))

                if let description = rule.ruleDescription, !isExpanded {
                    Text(description)
                        .font(.system(size: DesignTokens.FontSize.subheadline))
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                        .lineSpacing(DesignTokens.FontSize.subheadline * (DesignTokens.LineHeight.normal - 1))
                }
            }

            Spacer()

            // アクションボタン
            actionButtons
        }
    }

    /// アクションボタン
    private var actionButtons: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 経緯がある場合は展開ボタン
            if rule.context != nil {
                Button {
                    withAnimation(.easeInOut(duration: DesignTokens.Animation.standard)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: DesignTokens.IconSize.small))
                        .foregroundStyle(Color.textSecondary)
                        .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button {
                onToggle()
            } label: {
                Image(systemName: rule.isActive ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: DesignTokens.IconSize.large))
                    .foregroundStyle(rule.isActive ? Color.stateSuccess : Color.textTertiary)
                    .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: DesignTokens.IconSize.medium))
                    .foregroundStyle(Color.cta)
                    .frame(width: DesignTokens.TouchTarget.minimum, height: DesignTokens.TouchTarget.minimum)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    /// 展開時の詳細コンテンツ
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            // 説明
            if let description = rule.ruleDescription {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("説明")
                        .font(.system(size: DesignTokens.FontSize.caption, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    Text(description)
                        .font(.system(size: DesignTokens.FontSize.subheadline))
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(DesignTokens.FontSize.subheadline * (DesignTokens.LineHeight.relaxed - 1))
                }
            }

            // 経緯
            if let context = rule.context {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("経緯")
                        .font(.system(size: DesignTokens.FontSize.caption, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    Text(context)
                        .font(.system(size: DesignTokens.FontSize.caption))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(DesignTokens.FontSize.caption * (DesignTokens.LineHeight.relaxed - 1))
                }
            }

            // 作成日
            Text("作成: \(rule.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.system(size: DesignTokens.FontSize.caption2))
                .foregroundStyle(Color.textTertiary)
        }
        .padding(.leading, DesignTokens.Spacing.lg + 12) // インジケータ分のオフセット
        .padding(.top, DesignTokens.Spacing.xs)
    }
}

// MARK: - Preview

#Preview {
    let sampleRule = Rule(
        title: "朝の時間を大切にする",
        description: "7時までに起床し、1日の計画を立てる時間を確保する",
        context: "ミーティング準備不足 → 時間管理の問題 → 朝の習慣がない"
    )

    return List {
        RuleRowView(
            rule: sampleRule,
            onToggle: {},
            onEdit: {}
        )
    }
    .listStyle(.insetGrouped)
}
