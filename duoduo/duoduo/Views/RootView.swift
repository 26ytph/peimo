//
//  RootView.swift
//  duoduo
//
//  根據 AppState.screen 切換到對應頁面。
//

import SwiftUI

struct RootView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Group {
            switch appState.screen {
            case .login:           LoginView()
            case .youthLanding:    YouthLandingView()
            case .youthRegister:   RegisterView()
            case .youthInterview:  AIInterviewView()
            case .youthAnalyzing:  PathGeneratingView()
            case .youthMain:       YouthTabView()
            case .counselorMain:   CounselorTabView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.screen)
    }
}

#Preview { RootView().environment(AppState()) }
