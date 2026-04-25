//
//  CounselorTabView.swift
//  duoduo
//

import SwiftUI

struct CounselorTabView: View {
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
            AppointmentsView()
                .tabItem { Image(systemName: "calendar.badge.clock"); Text("查看預約") }
                .tag(0)
            CaseTrackingView()
                .tabItem { Image(systemName: "person.crop.rectangle.stack.fill"); Text("個案追蹤") }
                .tag(1)
            CounselorProfileView()
                .tabItem { Image(systemName: "person.fill"); Text("個人頁面") }
                .tag(2)
        }
        .tint(CloudTheme.pinkInk)
    }
}

#Preview { CounselorTabView().environment(AppState()) }
