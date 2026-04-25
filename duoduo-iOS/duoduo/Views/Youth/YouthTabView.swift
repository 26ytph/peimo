//
//  YouthTabView.swift
//  duoduo
//
//  民眾端三個 Tab：職涯路徑（首頁）/ 資源探索 / 朵朵樹洞。
//

import SwiftUI

struct YouthTabView: View {
    @State private var tab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.96)
        let pink  = UIColor(red: 0.78, green: 0.45, blue: 0.55, alpha: 1)
        let muted = UIColor(red: 0.72, green: 0.74, blue: 0.80, alpha: 1)
        appearance.stackedLayoutAppearance.normal.iconColor = muted
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: muted]
        appearance.stackedLayoutAppearance.selected.iconColor = pink
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: pink]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $tab) {
            CareerPathView()
                .tabItem { Image(systemName: "cloud.fill"); Text("職涯路徑") }
                .tag(0)
            ResourceSwipeView()
                .tabItem { Image(systemName: "rectangle.stack.fill"); Text("資源探索") }
                .tag(1)
            ChatHubView()
                .tabItem { Image(systemName: "bubble.left.and.text.bubble.right.fill"); Text("朵朵樹洞") }
                .tag(2)
        }
        .tint(CloudTheme.pinkInk)
    }
}

#Preview { YouthTabView().environment(AppState()) }
