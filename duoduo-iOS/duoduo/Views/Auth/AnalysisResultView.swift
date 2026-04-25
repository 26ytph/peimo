//
//  AnalysisResultView.swift
//  duoduo
//
//  AI 分析結果頁：顯示訪談分析後的使用者建模，
//  使用者可修改後確認，送出 PATCH /users 再打 POST /path/generate。
//

import SwiftUI

struct AnalysisResultView: View {
    @Environment(AppState.self) private var appState
    @State private var isEditing = false

    // 可編輯的本地副本
    @State private var editName = ""
    @State private var editAge = 22
    @State private var editSchool = ""
    @State private var editMajor = ""
    @State private var editLocation = ""
    @State private var editBio = ""
    @State private var editGoal = ""
    @State private var editInterests: [String] = []

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        profileCard
                        analysisCard
                        interestsSection
                        Spacer(minLength: 20)
                    }
                    .padding(22)
                }
                bottomButtons
            }
        }
        .onAppear { loadFromProfile() }
    }

    // MARK: - 進度條（第 3 步）
    private var progressBar: some View {
        HStack(spacing: 6) {
            stepDot(active: true)
            stepDot(active: true)
            stepDot(active: true)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
    }

    private func stepDot(active: Bool) -> some View {
        Capsule()
            .fill(active ? CloudTheme.pinkDeep : CloudTheme.divider)
            .frame(height: 4)
    }

    // MARK: - 標題
    private var headerSection: some View {
        SectionTitle(
            title: "朵朵幫你整理好了",
            subtitle: "以下是根據你的回答分析出的個人輪廓，你可以修改後再確認"
        )
    }

    // MARK: - 個人資料卡
    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("個人資料")
                    .font(.headline)
                    .foregroundStyle(CloudTheme.textPrimary)
                Spacer()
                Button {
                    if isEditing { saveToProfile() }
                    withAnimation { isEditing.toggle() }
                } label: {
                    Text(isEditing ? "完成" : "編輯")
                        .font(.subheadline.bold())
                        .foregroundStyle(CloudTheme.pinkInk)
                }
            }

            if isEditing {
                editableFields
            } else {
                readOnlyFields
            }
        }
        .cloudCard()
    }

    private var readOnlyFields: some View {
        VStack(alignment: .leading, spacing: 10) {
            profileRow(icon: "person.fill", label: "姓名", value: appState.youthProfile.name)
            profileRow(icon: "number", label: "年齡", value: "\(appState.youthProfile.age) 歲")
            profileRow(icon: "graduationcap.fill", label: "學校", value: appState.youthProfile.school)
            profileRow(icon: "book.closed.fill", label: "科系", value: appState.youthProfile.major)
            profileRow(icon: "mappin", label: "居住地", value: appState.youthProfile.location)
            if !appState.youthProfile.bio.isEmpty {
                profileRow(icon: "text.quote", label: "自我描述", value: appState.youthProfile.bio)
            }
            if let goal = appState.youthProfile.goal, !goal.isEmpty {
                profileRow(icon: "target", label: "職涯目標", value: goal)
            }
        }
    }

    @ViewBuilder
    private var editableFields: some View {
        SoftTextField(title: "姓名", placeholder: "你的名字", text: $editName, icon: "person.fill")
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("年齡").font(.caption).foregroundStyle(CloudTheme.textSecondary)
                Stepper(value: $editAge, in: 16...45) {
                    Text("\(editAge) 歲").foregroundStyle(CloudTheme.textPrimary)
                }
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(CloudTheme.pinkSoft.opacity(0.6)))
            }
            SoftTextField(title: "居住地", placeholder: "臺北市", text: $editLocation, icon: "mappin")
        }
        SoftTextField(title: "學校", placeholder: "學校名稱", text: $editSchool, icon: "graduationcap.fill")
        SoftTextField(title: "科系", placeholder: "科系 / 領域", text: $editMajor, icon: "book.closed.fill")
        SoftTextField(title: "職涯目標", placeholder: "你最想成為的樣子", text: $editGoal, icon: "target")
        VStack(alignment: .leading, spacing: 6) {
            Text("自我描述").font(.caption).foregroundStyle(CloudTheme.textSecondary)
            TextEditor(text: $editBio)
                .frame(minHeight: 60)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(CloudTheme.pinkSoft.opacity(0.6)))
                .foregroundStyle(CloudTheme.textPrimary)
                .scrollContentBackground(.hidden)
        }
    }

    private func profileRow(icon: String, label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(CloudTheme.pinkDeep)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(CloudTheme.textMuted)
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(CloudTheme.textPrimary)
            }
        }
    }

    // MARK: - AI 分析卡（Holland、成就、困境、技能）
    private var analysisCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI 分析結果")
                .font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)

            if let primary = appState.youthProfile.hollandPrimary {
                HStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(CloudTheme.pinkDeep)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Holland 人格類型")
                            .font(.caption).foregroundStyle(CloudTheme.textMuted)
                        HStack(spacing: 6) {
                            hollandBadge(primary)
                            if let secondary = appState.youthProfile.hollandSecondary {
                                hollandBadge(secondary)
                            }
                        }
                    }
                }
            }

            if let achievement = appState.youthProfile.achievement, !achievement.isEmpty {
                profileRow(icon: "star.fill", label: "亮點 / 成就", value: achievement)
            }

            if let setback = appState.youthProfile.setback, !setback.isEmpty {
                profileRow(icon: "exclamationmark.triangle", label: "目前的困境", value: setback)
            }

            if !appState.youthProfile.skills.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "wrench.and.screwdriver")
                        .foregroundStyle(CloudTheme.pinkDeep)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("技能")
                            .font(.caption).foregroundStyle(CloudTheme.textMuted)
                        FlowLayout(spacing: 6) {
                            ForEach(appState.youthProfile.skills, id: \.self) { skill in
                                Text(skill)
                                    .font(.caption2)
                                    .padding(.horizontal, 10).padding(.vertical, 4)
                                    .background(Capsule().fill(Color(red: 0.86, green: 0.91, blue: 1.00)))
                                    .foregroundStyle(Color(red: 0.42, green: 0.56, blue: 0.82))
                            }
                        }
                    }
                }
            }
        }
        .cloudCard()
    }

    private func hollandBadge(_ type: String) -> some View {
        Text(type)
            .font(.caption.bold())
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background(Capsule().fill(CloudTheme.pinkSoft))
            .foregroundStyle(CloudTheme.pinkInk)
    }

    // MARK: - 興趣標籤
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("分析出的興趣標籤")
                .font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)

            FlowLayout(spacing: 8) {
                ForEach(appState.youthProfile.interests, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.caption)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(CloudTheme.pinkSoft))
                        .foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
        .cloudCard()
    }

    // MARK: - 底部按鈕
    private var bottomButtons: some View {
        VStack(spacing: 10) {
            PrimaryButton(
                title: appState.isSubmittingProfile ? "儲存中…" : "沒問題，生成我的職涯路徑",
                systemImage: "sparkles",
                enabled: !appState.isSubmittingProfile
            ) {
                appState.confirmAnalysisResult()
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
    }

    // MARK: - 資料搬運
    private func loadFromProfile() {
        let p = appState.youthProfile
        editName = p.name
        editAge = p.age
        editSchool = p.school
        editMajor = p.major
        editLocation = p.location
        editBio = p.bio
        editGoal = p.goal ?? ""
        editInterests = p.interests
    }

    private func saveToProfile() {
        appState.youthProfile.name = editName
        appState.youthProfile.age = editAge
        appState.youthProfile.school = editSchool
        appState.youthProfile.major = editMajor
        appState.youthProfile.location = editLocation
        appState.youthProfile.bio = editBio
        appState.youthProfile.goal = editGoal.isEmpty ? nil : editGoal
        appState.youthProfile.interests = editInterests
    }
}

#Preview { AnalysisResultView().environment(AppState()) }
