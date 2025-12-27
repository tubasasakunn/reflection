/**
 * AnalysisPrompts.swift
 * AI分析用のプロンプト定数
 *
 * 責務:
 * - システムプロンプトの定義
 * - ユーザープロンプトテンプレートの定義
 * - ステップ別のプロンプト管理
 *
 * 使用箇所:
 * - ReflectionAnalyzer
 *
 * 設計原則（Foundation Models向け最適化）:
 * - XMLタグによる明確な構造化
 * - サンドイッチ構造（重要指示を冒頭と末尾に配置）
 * - Few-Shot事例（良い例・悪い例の両方）
 * - リテラリズム対応（曖昧さを排除）
 */

import Foundation

// MARK: - AnalysisPrompts

/// AI分析用プロンプト定数
enum AnalysisPrompts {

    // MARK: - System Instructions

    /// 共通のシステムプロンプト（コルブの経験学習モデルに基づく）
    static let systemInstruction = """
        <role>経験学習コーチ</role>

        <task>
        ユーザーの振り返りを分析し、具体的な仮説・洞察・行動指針を出力する。
        質問文ではなく、断定的な文で回答すること。
        </task>

        <output_stages>
        ■ RO（内省的観察）
        - 「〜だった」「〜していた」という断定形で具体的状況を推測
        - 行動・心理・状況を具体的に描写

        ■ AC（抽象的概念化）
        - 「〜が重要」「〜は〜である」という法則・原理の形式
        - 他の場面にも応用可能な普遍的パターン

        ■ RF（ルール形成）
        - 「〜する」という行動指針の形式
        - 測定可能で実行可能な具体的行動
        </output_stages>

        <good_examples>
        RO: 「スライドの文字が多く聞き手が読むのに必死だった」
        RO: 「専門用語を説明なしに使っていた」
        AC: 「情報量と理解度は反比例する」
        AC: 「相手の知識レベルに合わせることが重要」
        RF: 「スライド作成前に聞き手の関心を3つ書き出す」
        </good_examples>

        <bad_examples>
        NG: 「具体的に何が起きたか？」（質問形式は禁止）
        NG: 「準備不足」（抽象的すぎる）
        NG: 「コミュニケーション」（単語のみは禁止）
        </bad_examples>

        <constraints>
        - RO: 3〜4つ（重複禁止）
        - AC: 許可時は3〜4つ（重複禁止）
        - RF: 許可時は0〜1つ（無理に出さなくてよい）
        - 質問形式（〜か？）は禁止
        - 単語のみの出力は禁止
        - 同じ意味の内容を複数出さない
        - 日本語で出力
        </constraints>
        """

    // MARK: - Initial Analysis (初期分析)

    /// 初期分析：Step1 - 自由文で思考
    static func initialAnalysisThinking(content: String) -> String {
        """
        以下の経験について、反省者本人の視点で「なぜこうなったのか」を分析してください。

        【経験】
        \(content)

        【分析の観点】
        - 反省者本人が「何をしたか／しなかったか」に焦点を当てる
        - 「結果の言い換え」ではなく「原因の推測」を行う
        - 具体的な行動・状況・心理を推測する

        【悪い例】
        ✗「提出物が不十分だった」→ これは結果の言い換え
        ✗「確認が不十分だった」→ 抽象的すぎる

        【良い例】
        ✓「依頼時に完成イメージを具体的に伝えなかった」→ 具体的な行動
        ✓「途中で進捗確認をしなかった」→ 具体的な行動
        ✓「相手の理解度を確認せずに任せた」→ 具体的な行動

        3〜4つの原因仮説を、文章で説明してください。
        """
    }

    /// 初期分析：Step2 - 構造化
    static func initialAnalysisStructuring(thinkingResult: String) -> String {
        """
        以下の分析結果を構造化してください。

        【分析結果】
        \(thinkingResult)

        【構造化ルール】
        - 各仮説を20文字程度のlabelに要約
        - stageは全て「RO」
        - ruleはnull
        - 3〜4つに絞る（重複は除く）
        """
    }

    // MARK: - Node Expansion (ノード展開)

    /// ノード展開：Step1 - 自由文で思考
    static func nodeExpansionThinking(
        originalContent: String,
        currentCause: String,
        path: [String],
        depth: Int,
        allowedStages: [String]
    ) -> String {
        let pathDescription = path.joined(separator: " → ")
        // Note: stagesDescriptionは将来的にプロンプトに使用予定
        _ = allowedStages.joined(separator: "、")

        let stageGuidance: String
        if depth <= 4 {
            stageGuidance = """
            【求める分析】
            「\(currentCause)」について、さらに深い原因を推測してください。
            - なぜそうなったのか？
            - 具体的に何が起きていたのか？
            - 本人はどういう心理・状況だったのか？
            """
        } else if depth == 5 {
            stageGuidance = """
            【求める分析】
            「\(currentCause)」について：
            1. さらに深い原因の推測（具体的な行動・状況）
            2. この経験から見えるパターン・法則（他の場面にも当てはまる原理）
            """
        } else {
            stageGuidance = """
            【求める分析】
            「\(currentCause)」について：
            1. さらに深い原因の推測（具体的な行動・状況）
            2. パターン・法則（他の場面にも当てはまる原理）
            3. 次に実践できる具体的なルール（あれば1つだけ）
            """
        }

        return """
        【元の経験】
        \(originalContent)

        【これまでの経緯】
        \(pathDescription)

        【今の焦点】
        \(currentCause)

        \(stageGuidance)

        【注意】
        - 「結果の言い換え」ではなく「原因の推測」を行う
        - 反省者本人が改善できることに焦点を当てる
        - 具体的な行動・状況・心理を推測する

        文章で分析してください。
        """
    }

    /// ノード展開：Step2 - 構造化
    static func nodeExpansionStructuring(
        thinkingResult: String,
        allowedStages: [String]
    ) -> String {
        let stagesDescription = allowedStages.joined(separator: "、")

        return """
        以下の分析結果を構造化してください。

        【分析結果】
        \(thinkingResult)

        【構造化ルール】
        - 各仮説を20文字程度のlabelに要約
        - stageは \(stagesDescription) のいずれか
        - RFの場合のみruleに「〜する」形式で30文字以内の行動指針
        - 各ステージ3〜4つ（重複は除く）
        - RFは0〜1つ（無理に出さない）
        """
    }

    // MARK: - Rule Conflict Check (既存ルール競合チェック)

    /// 既存ルール競合チェックのプロンプトテンプレート
    static func ruleConflictCheck(cause: String, existingRules: [(index: Int, title: String, description: String?)]) -> String {
        let rulesDescription = existingRules.map { rule in
            if let desc = rule.description {
                return "[\(rule.index)] \(rule.title): \(desc)"
            } else {
                return "[\(rule.index)] \(rule.title)"
            }
        }.joined(separator: "\n")

        return """
        <task>
        以下の原因が、既存ルールを守れなかったことに関連しているか判定せよ。
        </task>

        <cause>\(cause)</cause>

        <existing_rules>
        \(rulesDescription)
        </existing_rules>

        <criteria>
        - ルールの内容と原因が明確に直接関係している場合のみ
        - 曖昧な関連は含めない
        - 無理に関連づけなくてよい
        </criteria>

        <output>
        - 明確に関連するルールがあれば、そのインデックス番号を1つだけ返す
        - 関連がなければ空リスト（空リストで問題ない）
        </output>
        """
    }

    /// 既存ルール違反ノードのラベル生成
    static func ruleViolationLabel(ruleTitle: String) -> String {
        "「\(ruleTitle)」が守れなかった"
    }
}
