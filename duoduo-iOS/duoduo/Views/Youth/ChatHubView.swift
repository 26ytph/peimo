//
//  ChatHubView.swift
//  duoduo
//
//  朵朵樹洞：AI 模式 / 我的諮商師模式 無縫切換。
//

import SwiftUI

struct ChatHubView: View {
    @Environment(AppState.self) private var appState
    @State private var input: String = ""
    @Namespace private var ns

    var body: some View {
        ZStack {
            CloudBackground()
            VStack(spacing: 0) {
                modeSwitcher
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                if appState.chatMode == .counselor, let c = appState.selectedCounselor {
                    counselorHeader(c)
                }

                if appState.chatMode == .counselor && appState.selectedCounselor == nil {
                    counselorPickerList
                } else if appState.chatMode == .counselor && appState.counselorMatchStatus == .applied {
                    counselorWaitingState
                } else if appState.chatMode == .counselor && appState.counselorMessages.isEmpty {
                    counselorEmptyState
                } else {
                    chatList
                }

                if appState.chatMode == .counselor && (appState.selectedCounselor == nil || appState.counselorMatchStatus == .applied) {
                    // 隱藏輸入列
                } else {
                    inputBar
                }
            }
        }
    }

    private var currentMessages: [ChatMessage] {
        appState.chatMode == .ai ? appState.aiMessages : appState.counselorMessages
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            ForEach(ChatMode.allCases) { mode in
                let selected = (appState.chatMode == mode)
                Button {
                    withAnimation(.spring(duration: 0.3)) { appState.chatMode = mode }
                } label: {
                    Text(mode.rawValue)
                        .font(.subheadline.bold())
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selected ? .white : CloudTheme.textSecondary)
                        .background(
                            ZStack {
                                if selected {
                                    Capsule().fill(CloudTheme.pinkGradientSoft)
                                        .matchedGeometryEffect(id: "modePill", in: ns)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 6, y: 3)
    }

    private func counselorHeader(_ c: Counselor) -> some View {
        HStack(spacing: 10) {
            AvatarView(name: c.name, imageName: c.avatarImage, size: 34)
            VStack(alignment: .leading, spacing: 1) {
                Text(c.name).font(.subheadline.bold())
                    .foregroundStyle(CloudTheme.textPrimary)
                Text(appState.counselorMatchStatus.rawValue)
                    .font(.caption2.bold())
                    .foregroundStyle(counselorStatusColor)
            }
            Spacer()
            if appState.counselorMatchStatus != .applied {
                Button {
                    appState.selectedCounselorId = nil
                    appState.counselorMessages = []
                    appState.counselorMatchStatus = .none
                } label: {
                    Text("換諮商師")
                        .font(.caption.bold())
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().stroke(CloudTheme.pinkInk, lineWidth: 1))
                        .foregroundStyle(CloudTheme.pinkInk)
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 8)
    }

    private var counselorStatusColor: Color {
        switch appState.counselorMatchStatus {
        case .none:       return CloudTheme.textMuted
        case .applied:    return Color(red: 0.88, green: 0.68, blue: 0.40)
        case .scheduled:  return Color(red: 0.50, green: 0.64, blue: 0.88)
        case .inProgress: return Color(red: 0.50, green: 0.72, blue: 0.50)
        }
    }

    private var counselorWaitingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
                .tint(CloudTheme.pinkInk)
            Text("已送出申請")
                .font(.headline)
                .foregroundStyle(CloudTheme.textPrimary)
            Text("諮商師正在確認你的申請，稍等一下...")
                .font(.footnote)
                .foregroundStyle(CloudTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(currentMessages) { m in
                        MessageBubble(message: m,
                                      attached: m.attachedResourceId
                                        .flatMap { appState.resource(by: $0) })
                            .id(m.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: currentMessages.count) { _, _ in
                if let last = currentMessages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
        }
    }

    private var counselorEmptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            if let c = appState.selectedCounselor {
                AvatarView(name: c.name, imageName: c.avatarImage, size: 70)
                Text(c.name).font(.headline)
                    .foregroundStyle(CloudTheme.textPrimary)
                Text("開始和你的諮商師聊天吧")
                    .font(.footnote).foregroundStyle(CloudTheme.textSecondary)
            }
            Spacer()
        }
    }

    // MARK: 諮商師選擇清單（內嵌）
    @State private var selectedDetail: Counselor?

    private var counselorPickerList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("選擇你的諮商師")
                    .font(.headline)
                    .foregroundStyle(CloudTheme.textPrimary)
                    .padding(.horizontal, 4)
                    .padding(.top, 12)

                ForEach(appState.counselors) { c in
                    Button { selectedDetail = c } label: {
                        counselorRow(c)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 20)
        }
        .sheet(item: $selectedDetail) { c in
            CounselorDetailSheet(counselor: c)
        }
    }

    private func counselorRow(_ c: Counselor) -> some View {
        HStack(spacing: 14) {
            AvatarView(name: c.name, imageName: c.avatarImage, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(c.name).font(.subheadline.bold())
                        .foregroundStyle(CloudTheme.textPrimary)
                    Circle().fill(c.status.color).frame(width: 8, height: 8)
                    Text(c.status.rawValue)
                        .font(.caption2)
                        .foregroundStyle(CloudTheme.textMuted)
                }
                Text(c.specialties.joined(separator: "・"))
                    .font(.caption)
                    .foregroundStyle(CloudTheme.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(CloudTheme.textMuted)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white))
        .shadow(color: CloudTheme.softShadow, radius: 8, y: 3)
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField(appState.chatMode == .ai ? "想跟朵朵說什麼？" : "傳訊息給諮商師…",
                      text: $input)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .background(Capsule().fill(Color.white))
                .shadow(color: CloudTheme.softShadow, radius: 6, y: 3)
            Button {
                appState.sendChat(input); input = ""
            } label: {
                Image(systemName: "paperplane.fill")
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
}

// MARK: - 訊息泡泡（共用）
struct MessageBubble: View {
    let message: ChatMessage
    var attached: ResourceCard? = nil

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .user { Spacer(minLength: 40) }
            if message.sender != .user { avatar }

            VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 8) {
                Text(message.content)
                    .font(.subheadline)
                    .foregroundStyle(message.sender == .user ? .white : CloudTheme.textPrimary)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(message.sender == .user
                                  ? AnyShapeStyle(CloudTheme.pinkGradientSoft)
                                  : AnyShapeStyle(Color.white))
                    )
                    .shadow(color: CloudTheme.softShadow, radius: 4, y: 2)

                if let card = attached {
                    ResourceCardView(card: card, compact: true)
                        .frame(maxWidth: 280)
                }
            }

            if message.sender != .user { Spacer(minLength: 40) }
        }
    }

    private var avatar: some View {
        Group {
            if message.sender == .ai {
                Image(systemName: "cloud.fill")
                    .foregroundStyle(CloudTheme.pinkInk)
                    .font(.system(size: 14))
            } else {
                Image(systemName: "person.fill")
                    .foregroundStyle(CloudTheme.pinkInk)
                    .font(.system(size: 14))
            }
        }
        .frame(width: 32, height: 32)
        .background(Circle().fill(CloudTheme.pinkSoft))
    }
}

#Preview { ChatHubView().environment(AppState()) }
