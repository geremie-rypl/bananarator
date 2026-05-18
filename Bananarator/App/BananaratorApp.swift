import SwiftUI
import FirebaseCore

@main
struct BananaratorApp: App {
    @StateObject private var appState = AppState()

    init() {
        FirebaseApp.configure()
        Self.applyGlobalAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .tint(BananaTheme.accent)
                .preferredColorScheme(.light)
        }
    }

    /// Style UIKit-backed surfaces (tab bar, nav bar) so they match the SwiftUI theme.
    private static func applyGlobalAppearance() {
        // Tab bar: cream surface with a soft top divider so it reads like a sticker tray.
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(BananaTheme.cream)
        tabAppearance.shadowColor = UIColor(Color.dapperBrown.opacity(0.15))

        let pink = UIColor(BananaTheme.partyPink)
        let brown = UIColor(BananaTheme.dapperBrown.opacity(0.55))

        for item in [tabAppearance.stackedLayoutAppearance,
                     tabAppearance.inlineLayoutAppearance,
                     tabAppearance.compactInlineLayoutAppearance] {
            item.selected.iconColor = pink
            item.selected.titleTextAttributes = [
                .foregroundColor: pink,
                .font: UIFont.systemFont(ofSize: 11, weight: .heavy)
            ]
            item.normal.iconColor = brown
            item.normal.titleTextAttributes = [
                .foregroundColor: brown,
                .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
            ]
        }

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Nav bar: transparent so the party gradient shows through; chunky rounded title.
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .heavy)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 34, weight: .black)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor.white
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CameraView()
                .tabItem {
                    Label("Create", systemImage: "camera.fill")
                }
                .tag(0)

            ShowcaseView()
                .tabItem {
                    Label("Showcase", systemImage: "star.fill")
                }
                .tag(1)

            StoreView()
                .tabItem {
                    Label("Shop", systemImage: "bag.fill")
                }
                .tag(2)
        }
        .tint(BananaTheme.accent)
    }
}
