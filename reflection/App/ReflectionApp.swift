/**
 * ReflectionApp.swift
 * アプリのエントリーポイント
 *
 * 責務:
 * - アプリの起動設定
 * - SwiftDataの設定
 * - メイン画面の構成
 *
 * 構成:
 * - TabView: 「反省」タブと「マイルール」タブ
 * - SwiftData: Rule, ReflectionEntryの永続化
 */

import SwiftUI
import SwiftData

// MARK: - ReflectionApp

/// メインアプリケーション
@main
struct ReflectionApp: App {

    // MARK: - Properties

    /// SwiftDataのモデルコンテナ
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Rule.self,
            ReflectionEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("[ReflectionApp] Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - ContentView

/// メインコンテンツView（タブバー）
struct ContentView: View {

    // MARK: - State

    /// 選択されているタブ（デフォルトはマイルール）
    @State private var selectedTab: Tab = .rules

    /// 反省画面のViewModel
    @State private var reflectionViewModel = ReflectionViewModel()

    /// 規則一覧画面のViewModel
    @State private var ruleListViewModel = RuleListViewModel()

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            // マイルールタブ（デフォルト）
            RuleListView(viewModel: ruleListViewModel)
                .tabItem {
                    Label("マイルール", systemImage: "list.clipboard")
                }
                .tag(Tab.rules)

            // 反省タブ
            ReflectionView(viewModel: reflectionViewModel)
                .tabItem {
                    Label("内省", systemImage: "brain.head.profile")
                }
                .tag(Tab.reflection)
        }
        .tint(Color.cta)
        .onAppear {
            // ルール作成完了時にタブを切り替えてリセット
            reflectionViewModel.onRuleCreated = {
                selectedTab = .rules
                reflectionViewModel.reset()
            }
        }
    }
}

// MARK: - Tab

/// タブの種類
enum Tab: Hashable {
    /// 反省タブ
    case reflection
    /// マイルールタブ
    case rules
}

// MARK: - Preview

#Preview {
    ContentView()
        .modelContainer(for: [Rule.self, ReflectionEntry.self], inMemory: true)
}
