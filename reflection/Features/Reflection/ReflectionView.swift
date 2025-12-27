/**
 * ReflectionView.swift
 * 反省入力・分析結果表示のメインView
 *
 * 責務:
 * - 反省内容の入力UI
 * - AI分析の実行トリガー
 * - マインドマップの表示
 * - 選択されたノードから規則を作成
 *
 * 使用箇所:
 * - メインタブの「反省」タブ
 */

import SwiftUI
import SwiftData

// MARK: - ReflectionView

/// 反省画面
struct ReflectionView: View {

    // MARK: - Properties

    /// ViewModel
    @Bindable var viewModel: ReflectionViewModel

    // MARK: - State

    /// キーボードのフォーカス状態
    @FocusState private var isInputFocused: Bool

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.currentNode != nil {
                    // 分析結果表示モード
                    analysisResultView
                } else {
                    // 入力モード
                    inputView
                }
            }
            .navigationTitle("内省")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    toolbarButton
                }
            }
            .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("保存完了", isPresented: .constant(viewModel.successMessage != nil)) {
                Button("OK") {
                    viewModel.clearSuccess()
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .sheet(item: $viewModel.nodeForRuleDialog) { node in
                ruleAdditionSheet(for: node)
            }
            .onAppear {
                viewModel.setup(with: modelContext)
            }
        }
    }

    // MARK: - Subviews

    /// ツールバーボタン
    @ViewBuilder
    private var toolbarButton: some View {
        if viewModel.currentNode != nil {
            Button("新規") {
                viewModel.reset()
            }
        }
    }

    /// 入力View
    private var inputView: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            // 説明テキスト
            VStack(spacing: DesignTokens.Spacing.sm) {
                Text("今日の反省を入力してください")
                    .font(.system(size: DesignTokens.FontSize.title3, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)

                Text("AIが原因と対策を分析し、マインドマップで可視化します")
                    .font(.system(size: DesignTokens.FontSize.subheadline))
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(DesignTokens.FontSize.subheadline * (DesignTokens.LineHeight.relaxed - 1))
            }
            .padding(.top, DesignTokens.Spacing.xl)

            // 入力エリア
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("反省内容")
                    .font(.system(size: DesignTokens.FontSize.subheadline, weight: .medium))
                    .foregroundStyle(Color.textSecondary)

                TextEditor(text: $viewModel.inputText)
                    .font(.system(size: DesignTokens.FontSize.body))
                    .lineSpacing(DesignTokens.FontSize.body * (DesignTokens.LineHeight.relaxed - 1))
                    .focused($isInputFocused)
                    .frame(minHeight: 180)
                    .padding(DesignTokens.Spacing.md)
                    .scrollContentBackground(.hidden)
                    .background(Color.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField)
                            .stroke(
                                isInputFocused ? Color.borderFocused : Color.border,
                                lineWidth: isInputFocused ? 2 : 1
                            )
                    )
                    .animation(.easeInOut(duration: DesignTokens.Animation.instant), value: isInputFocused)

                Text("例: 今日のミーティングで準備不足だった。事前に資料を確認していなかったため、質問に答えられなかった。")
                    .font(.system(size: DesignTokens.FontSize.caption))
                    .foregroundStyle(Color.textTertiary)
                    .lineSpacing(DesignTokens.FontSize.caption * (DesignTokens.LineHeight.normal - 1))
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)

            Spacer()

            // 分析ボタン
            Button {
                isInputFocused = false
                Task {
                    await viewModel.analyzeReflection()
                }
            } label: {
                HStack(spacing: DesignTokens.Spacing.sm) {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: DesignTokens.IconSize.large))
                    }
                    Text(viewModel.isLoading ? "分析中..." : "AIで分析する")
                        .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.TouchTarget.large)
                .background(
                    viewModel.inputText.isEmpty || viewModel.isLoading
                        ? Color.ctaDisabled
                        : Color.cta
                )
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField))
            }
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.bottom, DesignTokens.Spacing.xl)
        }
        .background(Color.backgroundPrimary)
    }

    /// 分析結果View
    private var analysisResultView: some View {
        VStack(spacing: 0) {
            // 経緯表示（パンくずリスト）
            if viewModel.canGoBack {
                pathBreadcrumb
            }

            // マインドマップ（ツリー形式）
            if let currentNode = viewModel.currentNode {
                MindMapView(
                    currentNode: currentNode,
                    canGoBack: viewModel.canGoBack,
                    isExpanding: viewModel.isExpanding,
                    onParentTap: {
                        viewModel.goBack()
                    },
                    onDrillDownTap: { node in
                        await viewModel.drillDown(to: node)
                    },
                    onRuleTap: { node in
                        viewModel.showRuleDialog(for: node)
                    }
                )
                .frame(maxHeight: .infinity)
            }
        }
    }

    /// 経緯のパンくずリスト
    private var pathBreadcrumb: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                ForEach(Array(viewModel.pathLabels.enumerated()), id: \.offset) { index, label in
                    if index > 0 {
                        Image(systemName: "chevron.right")
                            .font(.system(size: DesignTokens.FontSize.caption2))
                            .foregroundStyle(Color.textTertiary)
                    }

                    Text(label)
                        .font(.system(size: DesignTokens.FontSize.caption))
                        .foregroundStyle(
                            index == viewModel.pathLabels.count - 1
                                ? Color.textPrimary
                                : Color.textSecondary
                        )
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.vertical, DesignTokens.Spacing.md)
        }
        .background(Color.backgroundSecondary)
    }

    /// ルール追加シート
    private func ruleAdditionSheet(for node: MindMapNode) -> some View {
        NavigationStack {
            VStack(spacing: DesignTokens.Spacing.lg) {
                // 対策内容
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("対策")
                        .font(.system(size: DesignTokens.FontSize.subheadline, weight: .medium))
                        .foregroundStyle(Color.textSecondary)

                    Text(node.label)
                        .font(.system(size: DesignTokens.FontSize.body))
                        .foregroundStyle(Color.textPrimary)
                        .lineSpacing(DesignTokens.FontSize.body * (DesignTokens.LineHeight.relaxed - 1))
                        .padding(DesignTokens.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }

                // ルール内容
                if let rule = node.rule {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                        Text("規則として追加される内容")
                            .font(.system(size: DesignTokens.FontSize.subheadline, weight: .medium))
                            .foregroundStyle(Color.textSecondary)

                        HStack(alignment: .top, spacing: DesignTokens.Spacing.sm) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: DesignTokens.IconSize.medium))
                                .foregroundStyle(Color.stateWarning)
                            Text(rule)
                                .font(.system(size: DesignTokens.FontSize.body))
                                .foregroundStyle(Color.textPrimary)
                                .lineSpacing(DesignTokens.FontSize.body * (DesignTokens.LineHeight.relaxed - 1))
                        }
                        .padding(DesignTokens.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                    }
                }

                // 経緯
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                    Text("経緯")
                        .font(.system(size: DesignTokens.FontSize.subheadline, weight: .medium))
                        .foregroundStyle(Color.textSecondary)

                    Text(viewModel.pathLabels.joined(separator: " → "))
                        .font(.system(size: DesignTokens.FontSize.caption))
                        .foregroundStyle(Color.textSecondary)
                        .lineSpacing(DesignTokens.FontSize.caption * (DesignTokens.LineHeight.relaxed - 1))
                        .padding(DesignTokens.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.small))
                }

                Spacer()

                // 追加ボタン
                Button {
                    viewModel.createRuleFromNode(node)
                } label: {
                    HStack(spacing: DesignTokens.Spacing.sm) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: DesignTokens.IconSize.large))
                        Text("マイルールに追加")
                            .font(.system(size: DesignTokens.FontSize.body, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.TouchTarget.large)
                    .background(Color.cta)
                    .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField))
                }
            }
            .padding(DesignTokens.Spacing.lg)
            .background(Color.backgroundPrimary)
            .navigationTitle("ルールに追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        viewModel.dismissRuleDialog()
                    }
                    .font(.system(size: DesignTokens.FontSize.body))
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Preview

#Preview("Input Mode") {
    ReflectionView(viewModel: ReflectionViewModel())
        .modelContainer(for: [Rule.self, ReflectionEntry.self], inMemory: true)
}

#Preview("Analysis Result") {
    let viewModel = ReflectionViewModel()
    let root = MindMapNode.sampleRoot
    viewModel.rootNode = root
    viewModel.navigationPath = [root]

    return ReflectionView(viewModel: viewModel)
        .modelContainer(for: [Rule.self, ReflectionEntry.self], inMemory: true)
}
