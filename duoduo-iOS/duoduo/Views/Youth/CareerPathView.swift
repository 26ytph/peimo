//
//  CareerPathView.swift
//  duoduo
//
//  民眾首頁：AI 生成的職涯階段（垂直時間軸），點擊每個階段可看詳細描述。
//

import SwiftUI

struct CareerPathView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedStage: CareerStage?
    @State private var showProfile = false

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                            .padding(.horizontal, 4)
                        if let path = appState.youthProfile.path {
                            pathHero(path)
                            stageList(path.stages)
                        } else {
                            emptyState
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedStage) { s in
                StageDetailView(stage: s)
            }
            .sheet(isPresented: $showProfile) {
                YouthProfileSheet()
            }
        }
    }

    // MARK: 上方招呼
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi，\(appState.youthProfile.name)")
                    .font(.title2.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                Text("一起繼續往夢想前進")
                    .font(.footnote)
                    .foregroundStyle(CloudTheme.textSecondary)
            }
            Spacer()
            Button { showProfile = true } label: {
                AvatarView(name: appState.youthProfile.name,
                           imageName: appState.youthProfile.avatarImage,
                           size: 46)
            }
        }
    }

    // MARK: 路徑摘要卡
    private func pathHero(_ p: CareerPath) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("我的職涯雲徑")
                    .font(.caption.bold())
                    .foregroundStyle(CloudTheme.pinkInk)
                Spacer()
                Text("\(doneCount(p))/\(p.stages.count) 階段")
                    .font(.caption)
                    .foregroundStyle(CloudTheme.textSecondary)
            }
            Text(p.headline)
                .font(.title3.bold())
                .foregroundStyle(CloudTheme.textPrimary)
            Text(p.summary)
                .font(.footnote)
                .foregroundStyle(CloudTheme.textSecondary)
                .lineSpacing(2)

            // 進度條
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(CloudTheme.pinkSoft).frame(height: 8)
                    Capsule().fill(CloudTheme.pinkGradientSoft)
                        .frame(width: geo.size.width * progress(p), height: 8)
                }
            }
            .frame(height: 8)
        }
        .cloudCard()
    }

    private func doneCount(_ p: CareerPath) -> Int {
        p.stages.filter { $0.status == .done }.count
    }
    private func progress(_ p: CareerPath) -> Double {
        guard !p.stages.isEmpty else { return 0 }
        return Double(doneCount(p)) / Double(p.stages.count)
    }

    // MARK: 階段時間軸
    private func stageList(_ stages: [CareerStage]) -> some View {
        VStack(spacing: 14) {
            ForEach(stages) { s in
                Button { selectedStage = s } label: { stageRow(s, isLast: s.id == stages.last?.id) }
                    .buttonStyle(.plain)
            }
        }
    }

    private func stageRow(_ s: CareerStage, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(s.status == .done
                              ? AnyShapeStyle(CloudTheme.pinkGradientSoft)
                              : AnyShapeStyle(Color.white))
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle()
                                .stroke(s.status == .current ? CloudTheme.pinkDeep : CloudTheme.divider,
                                        lineWidth: s.status == .current ? 2 : 1)
                        )
                        .shadow(color: CloudTheme.softShadow, radius: 4, y: 2)
                    Image(systemName: s.icon)
                        .foregroundStyle(s.status == .done ? .white : CloudTheme.pinkInk)
                }
                if !isLast {
                    Rectangle()
                        .fill(CloudTheme.divider)
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }
            .frame(width: 42)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Stage \(s.index + 1)・\(s.title)")
                        .font(.headline)
                        .foregroundStyle(CloudTheme.textPrimary)
                    Spacer()
                    statusBadge(s.status)
                }
                Text(s.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CloudTheme.textSecondary)
                Text(s.ageRange)
                    .font(.caption2)
                    .foregroundStyle(CloudTheme.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
            .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
        }
    }

    private func statusBadge(_ s: CareerStageStatus) -> some View {
        let (label, color): (String, Color) = {
            switch s {
            case .done:     return ("已完成", CloudTheme.pinkInk)
            case .current:  return ("進行中", CloudTheme.pinkDeep)
            case .upcoming: return ("待開始", CloudTheme.textMuted)
            }
        }()
        return Text(label)
            .font(.caption2.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(color.opacity(0.12)))
            .foregroundStyle(color)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            CloudGlyph(size: 80)
            Text("還沒生成職涯路徑").font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)
            Text("和朵朵聊聊，我們幫你規劃專屬的成長階段。")
                .font(.footnote)
                .foregroundStyle(CloudTheme.textSecondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "開始 AI 訪談", systemImage: "sparkles") {
                appState.screen = .youthInterview
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 24).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 10, y: 4)
    }
}

// MARK: - 階段詳細
struct StageDetailView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    let stage: CareerStage

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Stage \(stage.index + 1)")
                                .font(.caption.bold())
                                .foregroundStyle(CloudTheme.pinkInk)
                            Text(stage.title)
                                .font(.largeTitle.bold())
                                .foregroundStyle(CloudTheme.textPrimary)
                            Text(stage.subtitle)
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textSecondary)
                            Text(stage.ageRange)
                                .font(.caption)
                                .foregroundStyle(CloudTheme.textMuted)
                        }

                        Text(stage.description)
                            .font(.body)
                            .foregroundStyle(CloudTheme.textPrimary.opacity(0.85))
                            .lineSpacing(4)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
                            .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)

                        if !stage.tasks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("這個階段的任務")
                                    .font(.headline)
                                    .foregroundStyle(CloudTheme.textPrimary)
                                ForEach(stage.tasks) { t in
                                    HStack(spacing: 10) {
                                        Image(systemName: t.done ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(t.done ? CloudTheme.pinkInk : CloudTheme.textMuted)
                                        Text(t.title)
                                            .strikethrough(t.done, color: CloudTheme.textMuted)
                                            .foregroundStyle(t.done ? CloudTheme.textMuted : CloudTheme.textPrimary)
                                        Spacer()
                                    }
                                }
                            }
                            .padding(16)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
                            .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
                        }

                        let recs = stage.recommendedResourceIds.compactMap(appState.resource(by:))
                        if !recs.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("推薦資源")
                                    .font(.headline)
                                    .foregroundStyle(CloudTheme.textPrimary)
                                ForEach(recs) { r in
                                    ResourceCardView(card: r, compact: true)
                                }
                            }
                        }
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") { dismiss() }
                        .foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
    }
}

// MARK: - 個人資料 Sheet
struct YouthProfileSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                CloudBackground()
                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 8) {
                            AvatarView(name: appState.youthProfile.name,
                                       imageName: appState.youthProfile.avatarImage,
                                       size: 90)
                            Text(appState.youthProfile.name)
                                .font(.title2.bold())
                                .foregroundStyle(CloudTheme.textPrimary)
                            Text("\(appState.youthProfile.school)・\(appState.youthProfile.major)")
                                .font(.footnote)
                                .foregroundStyle(CloudTheme.textSecondary)
                        }
                        .padding(.top, 24)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("自我描述").font(.headline)
                                .foregroundStyle(CloudTheme.textPrimary)
                            Text(appState.youthProfile.bio)
                                .font(.subheadline)
                                .foregroundStyle(CloudTheme.textPrimary.opacity(0.85))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .cloudCard()

                        if !appState.youthProfile.interests.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("興趣 / 關鍵字").font(.headline)
                                    .foregroundStyle(CloudTheme.textPrimary)
                                HStack(spacing: 6) {
                                    ForEach(appState.youthProfile.interests, id: \.self) { t in
                                        Text("#\(t)")
                                            .font(.caption)
                                            .padding(.horizontal, 8).padding(.vertical, 4)
                                            .background(Capsule().fill(CloudTheme.pinkSoft))
                                            .foregroundStyle(CloudTheme.pinkInk)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .cloudCard()
                        }

                        PrimaryButton(title: "登出", filled: false) {
                            appState.logout()
                            dismiss()
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("我的")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }.foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
    }
}

#Preview {
    let s = AppState()
    s.youthProfile.path = MockData.generatePath(for: .init(), answers: [])
    return CareerPathView().environment(s)
}
