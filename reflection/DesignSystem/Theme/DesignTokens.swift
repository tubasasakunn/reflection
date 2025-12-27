/**
 * DesignTokens.swift
 * アプリ全体で使用するデザイントークンを定義
 *
 * 責務:
 * - スペーシング、角丸、シャドウなどのデザイン定数を一元管理
 * - ハードコードを防ぎ、一貫したデザインを実現
 *
 * 使用方法:
 * - VStack(spacing: DesignTokens.Spacing.md)
 * - .padding(DesignTokens.Spacing.lg)
 */

import SwiftUI

// MARK: - DesignTokens

/// デザイントークンの名前空間
enum DesignTokens {

    // MARK: - Spacing

    /// スペーシングトークン（コーディング規約準拠）
    /// xxs(2), xs(4), sm(8), md(12), lg(16), xl(20), xxl(24)
    enum Spacing {
        /// 2pt - 最小のスペーシング（アイコン内部余白等）
        static let xxs: CGFloat = 2

        /// 4pt - 非常に小さいスペーシング（密接な要素間）
        static let xs: CGFloat = 4

        /// 8pt - 小さいスペーシング（関連要素間）
        static let sm: CGFloat = 8

        /// 12pt - 標準のスペーシング（リスト間、パディング）
        static let md: CGFloat = 12

        /// 16pt - 大きいスペーシング（セクション区切り）
        static let lg: CGFloat = 16

        /// 20pt - 非常に大きいスペーシング（大きな場面転換）
        static let xl: CGFloat = 20

        /// 24pt - 最大のスペーシング（画面セクション間）
        static let xxl: CGFloat = 24
    }

    // MARK: - CornerRadius

    /// 角丸トークン
    enum CornerRadius {
        /// 4pt - 最小の角丸
        static let minimal: CGFloat = 4

        /// 8pt - 小さい角丸
        static let small: CGFloat = 8

        /// 12pt - 入力フィールド用
        static let inputField: CGFloat = 12

        /// 16pt - タイル用
        static let tile: CGFloat = 16

        /// 24pt - カード用
        static let card: CGFloat = 24
    }

    // MARK: - Shadow

    /// シャドウトークン
    enum Shadow {
        /// 小さいシャドウ
        static let small: CGFloat = 2

        /// 中程度のシャドウ
        static let medium: CGFloat = 4

        /// 大きいシャドウ
        static let large: CGFloat = 8
    }

    // MARK: - Font Size

    /// フォントサイズトークン（HIG準拠：本文17pt以上）
    enum FontSize {
        /// 12pt - キャプション2（メタデータ）
        static let caption2: CGFloat = 12

        /// 13pt - キャプション（補足情報）
        static let caption: CGFloat = 13

        /// 15pt - サブヘッドライン
        static let subheadline: CGFloat = 15

        /// 17pt - 本文（HIG推奨の最小読みやすいサイズ）
        static let body: CGFloat = 17

        /// 20pt - タイトル3
        static let title3: CGFloat = 20

        /// 22pt - タイトル2
        static let title2: CGFloat = 22

        /// 28pt - タイトル1
        static let title: CGFloat = 28

        /// 34pt - 大きいタイトル
        static let largeTitle: CGFloat = 34
    }

    // MARK: - Line Height

    /// 行間トークン（和文対応：1.5-1.8倍推奨）
    enum LineHeight {
        /// 1.2倍 - 欧文向け、タイトル等
        static let tight: CGFloat = 1.2

        /// 1.4倍 - 標準（短文）
        static let normal: CGFloat = 1.4

        /// 1.6倍 - 和文本文推奨
        static let relaxed: CGFloat = 1.6

        /// 1.8倍 - 長文、読みやすさ重視
        static let loose: CGFloat = 1.8
    }

    // MARK: - Icon Size

    /// アイコンサイズトークン
    enum IconSize {
        /// 16pt - 小さいアイコン（インライン）
        static let small: CGFloat = 16

        /// 20pt - 中程度のアイコン（リスト）
        static let medium: CGFloat = 20

        /// 24pt - 大きいアイコン（ボタン）
        static let large: CGFloat = 24

        /// 32pt - 非常に大きいアイコン（強調）
        static let extraLarge: CGFloat = 32

        /// 48pt - 特大アイコン（空状態等）
        static let huge: CGFloat = 48
    }

    // MARK: - Touch Target

    /// タッチターゲットサイズ（HIG: 44pt以上推奨）
    enum TouchTarget {
        /// 44pt - 最小タッチターゲット
        static let minimum: CGFloat = 44

        /// 48pt - 推奨タッチターゲット
        static let recommended: CGFloat = 48

        /// 56pt - 大きいタッチターゲット（主要ボタン）
        static let large: CGFloat = 56
    }

    // MARK: - Animation

    /// アニメーション時間トークン
    enum Animation {
        /// 0.15秒 - 即座のフィードバック
        static let instant: Double = 0.15

        /// 0.25秒 - 標準トランジション
        static let standard: Double = 0.25

        /// 0.35秒 - 強調アニメーション
        static let emphasis: Double = 0.35

        /// 0.5秒 - 画面遷移
        static let transition: Double = 0.5
    }

    // MARK: - MindMap

    /// マインドマップ専用トークン
    enum MindMap {
        /// ルートノードのサイズ
        static let rootNodeSize: CGFloat = 100

        /// ブランチノードのサイズ
        static let branchNodeSize: CGFloat = 90

        /// アクションノードのサイズ
        static let actionNodeSize: CGFloat = 70

        /// ノード間の接続線の太さ
        static let connectionLineWidth: CGFloat = 2

        /// ノード間の水平スペーシング
        static let horizontalSpacing: CGFloat = 40

        /// ノード間の垂直スペーシング
        static let verticalSpacing: CGFloat = 35
    }
}
