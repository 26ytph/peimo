//
//  CounselorProfileView.swift
//  duoduo
//
//  諮商師端 Tab 3：個人頁面 + 狀態切換。
//

import SwiftUI

struct CounselorProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        statusCard
                        infoCard
                        PrimaryButton(title: "登出", filled: false) { appState.logout() }
                    }
                    .padding(18)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            AvatarView(name: appState.currentCounselor.name,
                       imageName: appState.currentCounselor.avatarImage,
                       size: 110)
            Text(appState.currentCounselor.name)
                .font(.title.bold())
                .foregroundStyle(CloudTheme.textPrimary)
            Text(appState.currentCounselor.title)
                .font(.subheadline)
                .foregroundStyle(CloudTheme.textSecondary)
        }
        .padding(.top, 24)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("我的狀態").font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)
            HStack(spacing: 8) {
                Circle().fill(appState.currentCounselor.status.color).frame(width: 12, height: 12)
                Text(appState.currentCounselor.status.rawValue)
                    .font(.subheadline.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                Spacer()
                Button { appState.toggleCounselorStatus() } label: {
                    Label("切換", systemImage: "arrow.triangle.2.circlepath")
                        .font(.caption.bold())
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(CloudTheme.pinkGradientSoft))
                        .foregroundStyle(.white)
                }
            }
            HStack(spacing: 6) {
                ForEach(CounselorStatus.allCases, id: \.self) { s in
                    Text(s.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(s.color.opacity(0.18)))
                        .foregroundStyle(s.color)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cloudCard()
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("專長領域").font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)
            HStack(spacing: 6) {
                ForEach(appState.currentCounselor.specialties, id: \.self) { s in
                    Text("#\(s)").font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Capsule().fill(CloudTheme.pinkSoft))
                        .foregroundStyle(CloudTheme.pinkInk)
                }
            }
            Divider().padding(.vertical, 4)
            Text("自我介紹").font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)
            Text(appState.currentCounselor.bio)
                .font(.subheadline)
                .foregroundStyle(CloudTheme.textPrimary.opacity(0.85))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cloudCard()
    }
}

#Preview { CounselorProfileView().environment(AppState()) }
