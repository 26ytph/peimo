//
//  LoginView.swift
//  duoduo
//
//  登入頁：選擇要以民眾還是諮商師身份進入。
//  （Demo 用，沒有真的密碼欄位）
//

import SwiftUI

struct LoginView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 0) {
                Spacer()
                CloudGlyph(size: 110)
                Text("朵朵")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(CloudTheme.textPrimary)
                    .padding(.top, 18)
                Text("Cloud Hub・讓夢想有支撐的雲")
                    .font(.subheadline)
                    .foregroundStyle(CloudTheme.textSecondary)
                Spacer()

                VStack(spacing: 14) {
                    Text("請選擇身份")
                        .font(.footnote)
                        .foregroundStyle(CloudTheme.textMuted)

                    PrimaryButton(title: "我是青年", systemImage: "person.fill") {
                        appState.loginAsYouth()
                    }
                    PrimaryButton(title: "我是諮商師",
                                  systemImage: "person.2.fill",
                                  filled: false) {
                        appState.loginAsCounselor()
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
    }
}

#Preview { LoginView().environment(AppState()) }
