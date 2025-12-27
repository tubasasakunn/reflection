/**
 * MindMapView.swift
 * マインドマップをツリー形式で表示するView
 *
 * 責務:
 * - 親ノードと子ノードをツリー形式で表示
 * - 深堀りノードタップで子ノード生成・画面遷移
 * - ルールノードタップでルール追加ダイアログ
 * - 親ノードタップで前の画面に戻る
 *
 * 使用箇所:
 * - ReflectionView
 */

import SwiftUI

// MARK: - MindMapView

/// マインドマップのツリー表示
struct MindMapView: View {

    // MARK: - Properties

    /// 現在の親ノード
    let currentNode: MindMapNode

    /// 戻れるかどうか（ルートでない場合true）
    let canGoBack: Bool

    /// 展開中かどうか
    let isExpanding: Bool

    /// 親ノードタップ時（戻る）
    let onParentTap: () -> Void

    /// 深堀りノードタップ時
    let onDrillDownTap: (MindMapNode) async -> Void

    /// ルールノードタップ時
    let onRuleTap: (MindMapNode) -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 展開中インジケーター
            if isExpanding {
                expandingIndicator
            }

            ScrollView {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    // 親ノード
                    parentNodeView

                    // 子ノード一覧
                    if let children = currentNode.children, !children.isEmpty {
                        childNodesView(children: children)
                    } else if !isExpanding {
                        emptyChildrenView
                    }
                }
                .padding(DesignTokens.Spacing.lg)
            }
        }
        .background(Color.backgroundPrimary)
        .animation(.easeInOut(duration: DesignTokens.Animation.standard), value: isExpanding)
    }

    // MARK: - Subviews

    /// 展開中インジケーター
    private var expandingIndicator: some View {
        HStack(spacing: DesignTokens.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.9)
            Text("分析中...")
                .font(.system(size: DesignTokens.FontSize.caption))
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, DesignTokens.Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.backgroundSecondary)
    }

    /// 親ノード表示
    private var parentNodeView: some View {
        Button {
            onParentTap()
        } label: {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.md) {
                // 戻るアイコン（戻れる場合のみ）
                if canGoBack {
                    Image(systemName: "chevron.left")
                        .font(.system(size: DesignTokens.FontSize.body, weight: .medium))
                        .foregroundStyle(Color.cta)
                }

                // ノードアイコン
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: DesignTokens.IconSize.large))
                    .foregroundStyle(Color.nodeRoot)

                // ノードテキスト
                Text(currentNode.label)
                    .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(DesignTokens.FontSize.body * (DesignTokens.LineHeight.relaxed - 1))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(DesignTokens.Spacing.md)
            .frame(minHeight: DesignTokens.TouchTarget.minimum)
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
        }
        .buttonStyle(.plain)
        .disabled(!canGoBack)
    }

    /// 子ノード一覧
    private func childNodesView(children: [MindMapNode]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
                childNodeRow(child: child, isLast: index == children.count - 1)
            }
        }
    }

    /// 子ノード行
    private func childNodeRow(child: MindMapNode, isLast: Bool) -> some View {
        Button {
            if child.type == .action {
                onRuleTap(child)
            } else {
                Task {
                    await onDrillDownTap(child)
                }
            }
        } label: {
            HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                // ツリー記号
                Text(isLast ? "└" : "├")
                    .font(.system(size: DesignTokens.FontSize.body, design: .monospaced))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 24, alignment: .leading)

                // ノードタイプアイコン
                nodeTypeIcon(for: child)

                // ノードテキスト
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text(child.label)
                        .font(.system(size: DesignTokens.FontSize.body))
                        .foregroundStyle(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(DesignTokens.FontSize.body * (DesignTokens.LineHeight.relaxed - 1))
                        .fixedSize(horizontal: false, vertical: true)

                    // サブテキスト
                    if child.type == .action {
                        if let rule = child.rule {
                            Text(rule)
                                .font(.system(size: DesignTokens.FontSize.caption))
                                .foregroundStyle(Color.textSecondary)
                                .multilineTextAlignment(.leading)
                                .lineSpacing(DesignTokens.FontSize.caption * (DesignTokens.LineHeight.normal - 1))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Text("タップでルールに追加")
                            .font(.system(size: DesignTokens.FontSize.caption2, weight: .medium))
                            .foregroundStyle(Color.cta)
                    } else {
                        Text("タップで深堀り")
                            .font(.system(size: DesignTokens.FontSize.caption2))
                            .foregroundStyle(Color.textTertiary)
                    }
                }

                Spacer()

                // 矢印
                Image(systemName: child.type == .action ? "plus.circle" : "chevron.right")
                    .font(.system(size: DesignTokens.IconSize.small))
                    .foregroundStyle(child.type == .action ? Color.cta : Color.textTertiary)
            }
            .padding(.vertical, DesignTokens.Spacing.md)
            .padding(.horizontal, DesignTokens.Spacing.sm)
            .frame(minHeight: DesignTokens.TouchTarget.minimum)
            .background(Color.pressHighlight.opacity(0))
            .contentShape(Rectangle())
        }
        .buttonStyle(ChildNodeButtonStyle())
    }
}

// MARK: - MindMapView Extension

extension MindMapView {
    /// 学習段階アイコン
    func nodeTypeIcon(for node: MindMapNode) -> some View {
        Image(systemName: node.learningStage.iconName)
            .font(.system(size: DesignTokens.IconSize.large))
            .foregroundStyle(learningStageColor(for: node.learningStage))
            .frame(width: 28)
    }

    /// 学習段階に応じた色
    func learningStageColor(for stage: LearningStage) -> Color {
        switch stage {
        case .reflectiveObservation:
            return Color.nodeBranch          // 青系：観察・視点
        case .abstractConceptualization:
            return Color.stateWarning        // オレンジ系：洞察・発見
        case .ruleFormation:
            return Color.cta                 // 緑系：行動・ルール
        }
    }

    /// 子ノードがない場合
    var emptyChildrenView: some View {
        HStack {
            Spacer()
            VStack(spacing: DesignTokens.Spacing.sm) {
                Image(systemName: "tray")
                    .font(.system(size: DesignTokens.IconSize.extraLarge))
                    .foregroundStyle(Color.textTertiary)
                Text("子ノードがありません")
                    .font(.system(size: DesignTokens.FontSize.subheadline))
                    .foregroundStyle(Color.textSecondary)
            }
            Spacer()
        }
        .padding(.vertical, DesignTokens.Spacing.xl)
    }
}

// MARK: - Preview

#Preview("With Children") {
    let root = MindMapNode(
        label: "今日のミーティングで準備不足だったため、質問に答えられなかった",
        type: .cause,
        learningStage: .reflectiveObservation,
        children: [
            MindMapNode(label: "事前に資料を確認していなかった", type: .cause, learningStage: .reflectiveObservation),
            MindMapNode(label: "想定質問を考えていなかった", type: .cause, learningStage: .abstractConceptualization),
            MindMapNode(
                label: "ミーティング前に5分間資料を見直す",
                type: .action,
                rule: "毎回ミーティングの5分前にリマインダーを設定する",
                learningStage: .ruleFormation
            )
        ]
    )

    return MindMapView(
        currentNode: root,
        canGoBack: false,
        isExpanding: false,
        onParentTap: {},
        onDrillDownTap: { _ in },
        onRuleTap: { _ in }
    )
}

#Preview("With Back") {
    let node = MindMapNode(
        label: "事前に資料を確認していなかった",
        type: .cause,
        learningStage: .abstractConceptualization,
        children: [
            MindMapNode(label: "時間がなかった", type: .cause, learningStage: .reflectiveObservation),
            MindMapNode(label: "優先順位付けの習慣がない", type: .cause, learningStage: .abstractConceptualization),
            MindMapNode(
                label: "前日に資料を確認する時間を確保する",
                type: .action,
                rule: "カレンダーに資料確認の予定を入れる",
                learningStage: .ruleFormation
            )
        ]
    )

    return MindMapView(
        currentNode: node,
        canGoBack: true,
        isExpanding: false,
        onParentTap: {},
        onDrillDownTap: { _ in },
        onRuleTap: { _ in }
    )
}

#Preview("Expanding") {
    MindMapView(
        currentNode: MindMapNode(label: "分析中のノード", type: .cause, learningStage: .abstractConceptualization),
        canGoBack: true,
        isExpanding: true,
        onParentTap: {},
        onDrillDownTap: { _ in },
        onRuleTap: { _ in }
    )
}
