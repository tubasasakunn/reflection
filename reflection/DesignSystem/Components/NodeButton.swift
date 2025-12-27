/**
 * NodeButton.swift
 * マインドマップのノードを表示するボタンコンポーネント
 *
 * 責務:
 * - マインドマップのノードUI表示
 * - 選択状態の視覚的フィードバック
 * - タップアクションのハンドリング
 *
 * 使用箇所:
 * - MindMapView
 */

import SwiftUI

// MARK: - NodeType

/// ノードの種類を表す列挙型
enum NodeType {
    /// ルートノード（中央の反省点）
    case root
    /// ブランチノード（原因）
    case branch
    /// アクションノード（対策）
    case action

    /// ノードの背景色を取得
    var backgroundColor: Color {
        switch self {
        case .root:
            return .nodeRoot
        case .branch:
            return .nodeBranch
        case .action:
            return .nodeAction
        }
    }

    /// ノードのサイズを取得
    var size: CGFloat {
        switch self {
        case .root:
            return DesignTokens.MindMap.rootNodeSize
        case .branch:
            return DesignTokens.MindMap.branchNodeSize
        case .action:
            return DesignTokens.MindMap.actionNodeSize
        }
    }

    /// フォントサイズを取得
    var fontSize: Font {
        switch self {
        case .root:
            return .system(size: DesignTokens.FontSize.body, weight: .bold)
        case .branch:
            return .system(size: DesignTokens.FontSize.subheadline, weight: .semibold)
        case .action:
            return .system(size: DesignTokens.FontSize.caption, weight: .medium)
        }
    }
}

// MARK: - NodeButton

/// マインドマップのノードを表示するボタン
struct NodeButton: View {

    // MARK: - Properties

    /// ノードに表示するラベル
    let label: String

    /// ノードの種類
    let nodeType: NodeType

    /// 選択状態
    let isSelected: Bool

    /// タップ時のアクション
    let action: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(nodeType.fontSize)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .padding(DesignTokens.Spacing.sm)
                .frame(
                    width: nodeType.size,
                    height: nodeType.size
                )
                .background(
                    Circle()
                        .fill(isSelected ? Color.nodeSelected : nodeType.backgroundColor)
                        .shadow(
                            color: isSelected ? Color.nodeSelected.opacity(0.5) : .black.opacity(0.1),
                            radius: isSelected ? DesignTokens.Shadow.medium : DesignTokens.Shadow.small,
                            x: 0,
                            y: 2
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Preview

#Preview("NodeButton - Root") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        NodeButton(
            label: "反省点の要約",
            nodeType: .root,
            isSelected: false,
            action: {}
        )

        NodeButton(
            label: "反省点の要約",
            nodeType: .root,
            isSelected: true,
            action: {}
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("NodeButton - Branch") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        NodeButton(
            label: "原因1",
            nodeType: .branch,
            isSelected: false,
            action: {}
        )

        NodeButton(
            label: "原因2",
            nodeType: .branch,
            isSelected: true,
            action: {}
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}

#Preview("NodeButton - Action") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        NodeButton(
            label: "対策を実行",
            nodeType: .action,
            isSelected: false,
            action: {}
        )

        NodeButton(
            label: "対策を実行",
            nodeType: .action,
            isSelected: true,
            action: {}
        )
    }
    .padding()
    .background(Color.backgroundPrimary)
}
