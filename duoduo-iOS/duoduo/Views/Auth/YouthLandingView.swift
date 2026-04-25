//
//  YouthLandingView.swift
//  duoduo
//
//  民眾登入後的歡迎頁（未註冊狀態）：說明 App 可以做什麼，引導註冊。
//

import SwiftUI

struct YouthLandingView: View {
    @Environment(AppState.self) private var appState

    private let features: [(String, String, String)] = [
        ("sparkles", "AI 量身訂做職涯路徑", "回答幾個問題，朵朵就能幫你規劃下一步"),
        ("rectangle.stack.fill", "卡片式探索青年資源", "左滑右滑，輕鬆找到適合的補助與機會"),
        ("bubble.left.and.text.bubble.right.fill", "AI 與真人諮商隨時切換", "不知道怎麼決定？讓朵朵或顧問陪你聊")
    ]

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 0) {
                Spacer().frame(height: 60)
                CloudGlyph(size: 90)
                Text("歡迎來到朵朵")
                    .font(.title.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                    .padding(.top, 14)
                Text("讓我們花 1 分鐘認識你")
                    .font(.subheadline)
                    .foregroundStyle(CloudTheme.textSecondary)

                VStack(spacing: 14) {
                    ForEach(features, id: \.0) { f in
                        featureRow(icon: f.0, title: f.1, subtitle: f.2)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 36)

                Spacer()

                VStack(spacing: 10) {
                    PrimaryButton(title: "建立我的個人輪廓", systemImage: "arrow.right") {
                        appState.startRegistration()
                    }
                    Button("我已經註冊過了") {
                        appState.screen = .youthMain
                    }
                    .font(.footnote)
                    .foregroundStyle(CloudTheme.textSecondary)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }

    private func featureRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(CloudTheme.pinkSoft)
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .foregroundStyle(CloudTheme.pinkInk)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                Text(subtitle).font(.caption)
                    .foregroundStyle(CloudTheme.textSecondary)
            }
            Spacer()
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
    }
}

#Preview { YouthLandingView().environment(AppState()) }
