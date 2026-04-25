//
//  AIInterviewView.swift
//  duoduo
//
//  AI 訪談：用聊天介面一題一題問，了解使用者性向 / 夢想。
//

import SwiftUI

struct AIInterviewView: View {
    @Environment(AppState.self) private var appState
    @State private var step: Int = 0
    @State private var input: String = ""
    @State private var typedMessages: [ChatMessage] = []
    @FocusState private var inputFocused: Bool

    private var questions: [InterviewQuestion] { MockData.interviewQuestions }
    private var currentQ: InterviewQuestion? {
        step < questions.count ? questions[step] : nil
    }

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
                            if let q = currentQ {
                                quickRepliesView(q)
                                    .padding(.top, 4)
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
                }

                inputBar
            }
        }
        .onAppear { askNextQuestion() }
    }

    // MARK: 進度條
    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<questions.count, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? CloudTheme.pinkDeep : CloudTheme.divider)
                    .frame(height: 4)
            }
        }
    }

    // MARK: 快速回覆
    private func quickRepliesView(_ q: InterviewQuestion) -> some View {
        HStack(spacing: 8) {
            ForEach(q.quickReplies, id: \.self) { r in
                Button {
                    submit(r)
                } label: {
                    Text(r)
                        .font(.caption)
                        .padding(.horizontal, 12).padding(.vertical, 7)
                        .background(Capsule().fill(CloudTheme.pinkSoft))
                        .foregroundStyle(CloudTheme.pinkInk)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
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
                submit(input)
            } label: {
                Image(systemName: "arrow.up")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(CloudTheme.pinkGradient))
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: 行為
    private func askNextQuestion() {
        guard let q = currentQ else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                typedMessages.append(ChatMessage(sender: .ai, content: q.prompt))
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation {
                    typedMessages.append(ChatMessage(sender: .ai, content: q.hint))
                }
            }
        }
    }

    private func submit(_ raw: String) {
        let text = raw.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, let q = currentQ else { return }
        appState.interviewAnswers.append(
            InterviewAnswer(questionPrompt: q.prompt, answer: text)
        )
        withAnimation {
            typedMessages.append(ChatMessage(sender: .user, content: text))
        }
        input = ""
        step += 1
        if step < questions.count {
            askNextQuestion()
        } else {
            // 結尾訊息 → 進到分析動畫
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation {
                    typedMessages.append(
                        ChatMessage(sender: .ai,
                                    content: "謝謝你～朵朵正在幫你整理專屬的職涯雲徑")
                    )
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                    appState.finishInterview()
                }
            }
        }
    }
}

#Preview { AIInterviewView().environment(AppState()) }
