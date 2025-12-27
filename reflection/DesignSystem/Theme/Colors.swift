/**
 * Colors.swift
 * アプリ全体で使用するセマンティックカラーを定義
 *
 * 責務:
 * - 色の一元管理
 * - セマンティックな色名による可読性向上
 * - ダークモード完全対応
 *
 * 設計原則:
 * - 60-30-10の法則: ベース60%、セカンダリ30%、アクセント10%
 * - コントラスト比: 通常テキスト4.5:1以上、大型テキスト3.0:1以上
 * - ダークモード: 純黒(#000000)は避け、ダークグレーを使用
 */

import SwiftUI

// MARK: - AppColors

/// アプリケーションカラーの名前空間
enum AppColors {

    // MARK: - Primary Colors

    /// プライマリカラー
    /// メインのブランドカラー、強調要素に使用
    static let themePrimary = Color(light: "0F172A", dark: "F1F5F9")

    /// セカンダリカラー
    /// サブ要素、補助テキストに使用
    static let themeSecondary = Color(light: "475569", dark: "94A3B8")

    /// CTAカラー
    /// ボタン、リンク、アクション要素に使用
    static let cta = Color(light: "0284C7", dark: "0EA5E9")

    /// CTA無効状態カラー
    static let ctaDisabled = Color(light: "B7C5D3", dark: "3A4451")

    // MARK: - Background Colors

    /// 背景カラー
    /// メイン背景に使用
    static let backgroundPrimary = Color(light: "FFFFFF", dark: "121212")

    /// セカンダリ背景
    /// カード、セクション背景に使用
    static let backgroundSecondary = Color(light: "F1F5F9", dark: "1E1E1E")

    /// 三次背景
    /// 入力フィールド、深い階層の背景
    static let backgroundTertiary = Color(light: "E2E8F0", dark: "2C2C2C")

    // MARK: - Text Colors

    /// プライマリテキスト
    /// 本文、見出しに使用
    static let textPrimary = Color(light: "1E293B", dark: "F1F5F9")

    /// セカンダリテキスト
    /// 補助テキスト、説明文に使用
    static let textSecondary = Color(light: "64748B", dark: "94A3B8")

    /// 三次テキスト
    /// プレースホルダー、無効テキスト
    static let textTertiary = Color(light: "94A3B8", dark: "64748B")

    // MARK: - Border Colors

    /// ボーダーカラー
    /// 区切り線、枠線に使用
    static let border = Color(light: "CBD5E1", dark: "3A4451")

    /// フォーカス時のボーダーカラー
    static let borderFocused = Color(light: "0284C7", dark: "0EA5E9")

    // MARK: - MindMap Colors

    /// マインドマップ: ルートノードカラー
    static let nodeRoot = Color(light: "0F172A", dark: "F1F5F9")

    /// マインドマップ: ブランチノードカラー
    static let nodeBranch = Color(light: "475588", dark: "9CA3C5")

    /// マインドマップ: アクションノードカラー
    static let nodeAction = Color(light: "0284C7", dark: "0EA5E9")

    /// マインドマップ: 選択時のカラー
    static let nodeSelected = Color(light: "0EA5E9", dark: "38BDF8")

    /// マインドマップ: 接続線カラー
    static let nodeConnection = Color(light: "94A3B8", dark: "64748B")

    // MARK: - State Colors

    /// 成功カラー（彩度を抑えた緑）
    static let stateSuccess = Color(light: "22916A", dark: "43B989")

    /// エラーカラー
    static let stateError = Color(light: "DC2626", dark: "EF5656")

    /// 警告カラー
    static let stateWarning = Color(light: "F59E0B", dark: "FBB929")

    // MARK: - Semantic Colors

    /// インタラクティブ要素のホバー/プレス状態
    static let pressHighlight = Color(light: "0F172A", dark: "FFFFFF", lightOpacity: 0.08, darkOpacity: 0.12)

    /// 選択状態の背景
    static let selectedBackground = Color(light: "0284C7", dark: "0EA5E9", lightOpacity: 0.10, darkOpacity: 0.20)
}

// MARK: - Color Extension (Convenience)

extension Color {
    // 既存コードとの互換性のためのエイリアス
    static var backgroundPrimary: Color { AppColors.backgroundPrimary }
    static var backgroundSecondary: Color { AppColors.backgroundSecondary }
    static var backgroundTertiary: Color { AppColors.backgroundTertiary }
    static var textPrimary: Color { AppColors.textPrimary }
    static var textSecondary: Color { AppColors.textSecondary }
    static var textTertiary: Color { AppColors.textTertiary }
    static var border: Color { AppColors.border }
    static var borderFocused: Color { AppColors.borderFocused }
    static var cta: Color { AppColors.cta }
    static var ctaDisabled: Color { AppColors.ctaDisabled }
    static var nodeRoot: Color { AppColors.nodeRoot }
    static var nodeBranch: Color { AppColors.nodeBranch }
    static var nodeAction: Color { AppColors.nodeAction }
    static var nodeSelected: Color { AppColors.nodeSelected }
    static var nodeConnection: Color { AppColors.nodeConnection }
    static var stateSuccess: Color { AppColors.stateSuccess }
    static var stateError: Color { AppColors.stateError }
    static var stateWarning: Color { AppColors.stateWarning }
    static var pressHighlight: Color { AppColors.pressHighlight }
    static var selectedBackground: Color { AppColors.selectedBackground }
}

// MARK: - Color Initializers

extension Color {
    /// ライト/ダークモード対応カラーを生成
    /// - Parameters:
    ///   - light: ライトモードの16進数カラーコード
    ///   - dark: ダークモードの16進数カラーコード
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark)
                : UIColor(hex: light)
        })
    }

    /// ライト/ダークモード対応カラーを生成（不透明度付き）
    /// - Parameters:
    ///   - light: ライトモードの16進数カラーコード
    ///   - dark: ダークモードの16進数カラーコード
    ///   - lightOpacity: ライトモードの不透明度
    ///   - darkOpacity: ダークモードの不透明度
    init(light: String, dark: String, lightOpacity: CGFloat, darkOpacity: CGFloat) {
        self.init(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: dark).withAlphaComponent(darkOpacity)
                : UIColor(hex: light).withAlphaComponent(lightOpacity)
        })
    }

    /// 16進数文字列からColorを生成
    /// - Parameter hex: 16進数カラーコード（#なし）
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - UIColor Extension

extension UIColor {
    /// 16進数文字列からUIColorを生成
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}
