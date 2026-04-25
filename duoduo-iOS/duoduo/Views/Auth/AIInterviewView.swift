//
//  AIInterviewView.swift
//  duoduo
//
//  AI 訪談：透過 /landing/chat 動態問答，逐步建立使用者輪廓。
//  後端會根據 missing_fields 自動決定下一題，直到 completed = true。
//

import SwiftUI

struct AIInterviewView: View {
    @Environment(AppState.self) private var appState
    @State private var input: String = ""
    @State private var typedMessages: [ChatMessage] = []
    @State private var isWaitingResponse = false
    @State private var isCompleted = false
    @State private var totalFields = 12  // 預設 missing_fields 總數
    @State private var filledFields = 0
    @State private var lastLandingResponse: APILandingChatResponse?
    @FocusState private var inputFocused: Bool

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 22)
                    .padding(.top, 20)

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(typedMessages) { m in
                                MessageBubble(message: m)
                                    .id(m.id)
                            }
                            if isWaitingResponse {
                                HStack {
                                    ProgressView()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                    Spacer()
                                }
                                .id("loading")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .onChange(of: typedMessages.count) { _, _ in
                        if let last = typedMessages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                    .onChange(of: isWaitingResponse) { _, waiting in
                        if waiting {
                            withAnimation { proxy.scrollTo("loading", anchor: .bottom) }
                        }
                    }
                }

                if !isCompleted {
                    inputBar
                }
            }
        }
        .onAppear { startConversation() }
    }

    // MARK: 進度條
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(CloudTheme.divider).frame(height: 4)
                Capsule().fill(CloudTheme.pinkDeep)
                    .frame(width: geo.size.width * progressRatio, height: 4)
                    .animation(.easeInOut, value: filledFields)
            }
        }
        .frame(height: 4)
    }

    private var progressRatio: CGFloat {
        guard totalFields > 0 else { return 0 }
        return CGFloat(filledFields) / CGFloat(totalFields)
    }

    // MARK: 輸入列
    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("輸入你的回答…", text: $input, axis: .vertical)
                .focused($inputFocused)
                .lineLimit(1...3)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Capsule().fill(Color.white))
                .shadow(color: CloudTheme.softShadow, radius: 6, y: 3)

            Button {
                submitAnswer()
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(CloudTheme.pinkGradient))
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isWaitingResponse)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: 行為

    /// 初始呼叫 /landing/chat（不帶 message）取得第一個問題
    private func startConversation() {
        // 先顯示歡迎訊息
        typedMessages.append(
            ChatMessage(sender: .ai,
                        content: "嗨～我是朵朵，讓我花幾分鐘認識你！")
        )

        // 短暫延遲讓歡迎訊息先渲染，再發起 API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isWaitingResponse = true

            Task {
                do {
                    // 不帶 message，讓後端根據 missing_fields 一題一題問
                    let resp = try await APIService.shared.landingChat(
                        userId: APIService.demoUserId
                    )
                    await MainActor.run {
                        self.handleLandingResponse(resp)
                    }
                } catch {
                    print("[AIInterview] initial landingChat failed: \(error)")
                    await MainActor.run {
                        self.isWaitingResponse = false
                        self.typedMessages.append(
                            ChatMessage(sender: .ai,
                                        content: "連線有點問題，不過沒關係，先告訴我你的名字和學校吧！")
                        )
                    }
                }
            }
        }
    }

    private func submitAnswer() {
        let text = input.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        // 記錄到 appState
        let questionPrompt = typedMessages.last(where: { $0.sender == .ai })?.content ?? ""
        appState.interviewAnswers.append(
            InterviewAnswer(questionPrompt: questionPrompt, answer: text)
        )

        withAnimation {
            typedMessages.append(ChatMessage(sender: .user, content: text))
        }
        input = ""
        isWaitingResponse = true

        Task {
            do {
                let resp = try await APIService.shared.landingChat(
                    userId: APIService.demoUserId, message: text
                )
                await MainActor.run {
                    handleLandingResponse(resp)
                }
            } catch {
                print("[AIInterview] landingChat failed: \(error)")
                await MainActor.run {
                    isWaitingResponse = false
                    typedMessages.append(
                        ChatMessage(sender: .ai, content: "抱歉，我卡住了，你可以再說一次嗎？")
                    )
                }
            }
        }
    }

    private func handleLandingResponse(_ resp: APILandingChatResponse) {
        lastLandingResponse = resp
        isWaitingResponse = false

        // 更新進度
        let missing = resp.missing_fields.count
        filledFields = totalFields - missing

        if resp.completed {
            // 訪談完成
            isCompleted = true
            filledFields = totalFields

            withAnimation {
                typedMessages.append(
                    ChatMessage(sender: .ai,
                                content: "謝謝你～朵朵已經了解你了，正在幫你整理專屬的個人輪廓！")
                )
            }

            // 把結果寫入 appState，然後轉場
            applyProfileData(resp)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.4)) {
                    appState.screen = .youthAnalysisResult
                }
            }
        } else {
            // 顯示下一個問題
            if let question = resp.next_question {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        typedMessages.append(
                            ChatMessage(sender: .ai, content: question)
                        )
                    }
                }
            }
        }
    }

    /// 將 /landing/chat 回傳的 profile_data 寫入 appState.youthProfile
    private func applyProfileData(_ resp: APILandingChatResponse) {
        if let bio = resp.generated_bio, !bio.isEmpty {
            appState.youthProfile.bio = bio
        }
        guard let data = resp.profile_data else { return }

        if let v = data["name"]?.stringValue, !v.isEmpty { appState.youthProfile.name = v }
        if let v = data["age"]?.intValue { appState.youthProfile.age = v }
        if let v = data["school"]?.stringValue, !v.isEmpty { appState.youthProfile.school = v }
        if let v = data["department"]?.stringValue, !v.isEmpty {
            appState.youthProfile.major = v
            appState.youthProfile.department = v
        }
        if let v = data["location"]?.stringValue, !v.isEmpty { appState.youthProfile.location = v }
        if let v = data["goal"]?.stringValue, !v.isEmpty { appState.youthProfile.goal = v }
        if let v = data["achievement"]?.stringValue, !v.isEmpty { appState.youthProfile.achievement = v }
        if let v = data["setback"]?.stringValue, !v.isEmpty { appState.youthProfile.setback = v }
        if let v = data["holland_primary"]?.stringValue, !v.isEmpty { appState.youthProfile.hollandPrimary = v }
        if let v = data["holland_secondary"]?.stringValue, !v.isEmpty { appState.youthProfile.hollandSecondary = v }
        if let v = data["education_level"]?.stringValue, !v.isEmpty { appState.youthProfile.educationLevel = v }
        if let v = data["bio"]?.stringValue, !v.isEmpty { appState.youthProfile.bio = v }

        let interests = data["interests"]?.stringArray ?? []
        if !interests.isEmpty { appState.youthProfile.interests = interests }

        let skills = data["skills"]?.stringArray ?? []
        if !skills.isEmpty { appState.youthProfile.skills = skills }
    }
}

#Preview { AIInterviewView().environment(AppState()) }
