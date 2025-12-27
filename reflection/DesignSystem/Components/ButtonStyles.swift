/**
 * ButtonStyles.swift
 * 共通ボタンスタイル
 *
 * 責務:
 * - 再利用可能なボタンスタイルの定義
 * - タッチフィードバックの一元管理
 *
 * 使用箇所:
 * - MindMapView
 * - その他のボタンを使用するView
 */

import SwiftUI

// MARK: - ChildNodeButtonStyle

/// 子ノード用のボタンスタイル（タップフィードバック付き）
struct ChildNodeButtonStyle: ButtonStyle {

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed
                    ? Color.pressHighlight
                    : Color.clear
            )
            .animation(.easeInOut(duration: DesignTokens.Animation.instant), value: configuration.isPressed)
    }
}

// MARK: - PrimaryButtonStyle

/// プライマリボタンスタイル（CTAボタン用）
struct PrimaryButtonStyle: ButtonStyle {

    // MARK: - Properties

    let isEnabled: Bool

    // MARK: - Initializer

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.large)
            .background(isEnabled ? Color.cta : Color.ctaDisabled)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.Animation.instant), value: configuration.isPressed)
    }
}

// MARK: - SecondaryButtonStyle

/// セカンダリボタンスタイル（サブアクション用）
struct SecondaryButtonStyle: ButtonStyle {

    // MARK: - Body

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.cta)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.TouchTarget.recommended)
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.inputField)
                    .stroke(Color.cta, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: DesignTokens.Animation.instant), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: DesignTokens.Spacing.lg) {
        Button("Primary Button") {}
            .buttonStyle(PrimaryButtonStyle())

        Button("Primary Disabled") {}
            .buttonStyle(PrimaryButtonStyle(isEnabled: false))

        Button("Secondary Button") {}
            .buttonStyle(SecondaryButtonStyle())

        Button {
        } label: {
            HStack {
                Image(systemName: "star")
                Text("Child Node Style")
            }
            .padding()
        }
        .buttonStyle(ChildNodeButtonStyle())
    }
    .padding()
    .background(Color.backgroundPrimary)
}
