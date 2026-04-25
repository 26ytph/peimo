//
//  AppState.swift
//  duoduo
//
//  全域狀態：登入流程、註冊草稿、AI 訪談、職涯路徑、聊天、諮商師端。
//

import Foundation
import SwiftUI

/// 整個 App 目前停在哪一個流程
enum AppScreen {
    case login
    case youthLanding         // 民眾登入後的歡迎頁（未註冊）
    case youthRegister        // 註冊（姓名 / CV）
    case youthInterview       // AI 多輪提問
    case youthAnalyzing       // 分析動畫
    case youthMain            // 進入主 App
    case counselorMain
}

@Observable
final class AppState {
    // MARK: 流程
    var screen: AppScreen = .login
    var role: UserRole = .youth

    // MARK: 民眾資料
    var youthProfile: YouthProfile = MockData.sampleProfile
    var registration = RegistrationDraft()
    var interviewAnswers: [InterviewAnswer] = []

    // MARK: 資源 / 收藏
    var allResources: [ResourceCard] = MockData.resources
    var likedResourceIds: Set<UUID> = []
    var passedResourceIds: Set<UUID> = []
    var applicationStatuses: [UUID: ApplicationStatus] = [:]  // resourceId → status

    // MARK: 聊天
    var chatMode: ChatMode = .ai
    var aiMessages: [ChatMessage] = [
        ChatMessage(sender: .ai,
                    content: "嗨～我是朵朵，今天想聊什麼呢？\n你可以問我「適合我的補助」「該怎麼準備履歷」，或抱怨一下也 OK！")
    ]
    var counselorMessages: [ChatMessage] = []
    var selectedCounselorId: UUID?       // 民眾端選擇的諮商師
    var counselorMatchStatus: CounselorMatchStatus = .none

    var selectedCounselor: Counselor? {
        guard let id = selectedCounselorId else { return nil }
        return counselors.first { $0.id == id }
    }

    // MARK: 諮商師端
    var counselors: [Counselor] = MockData.counselors
    var appointments: [Appointment] = MockData.appointments()
    var cases: [CounselingCase] = []
    var caseTags: [CaseTag] = MockData.caseTags
    var currentCounselor: Counselor

    init() {
        self.currentCounselor = MockData.counselors[0]
        self.cases = MockData.cases(youthId: youthProfile.id,
                                    youthName: youthProfile.name,
                                    youthAvatar: youthProfile.name)
    }

    // MARK: - 流程動作
    /// 民眾登入：判斷是否已有 path，決定要不要走完整 onboarding
    func loginAsYouth() {
        role = .youth
        screen = youthProfile.path == nil ? .youthLanding : .youthMain
    }

    func loginAsCounselor() {
        role = .counselor
        screen = .counselorMain
    }

    func logout() {
        screen = .login
    }

    func selectCounselor(_ c: Counselor) {
        selectedCounselorId = c.id
        counselorMatchStatus = .applied
        counselorMessages = []
        chatMode = .counselor
        // 模擬 1.5 秒後變成「已安排」
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self, self.selectedCounselorId == c.id else { return }
            self.counselorMatchStatus = .scheduled
            self.counselorMessages = [
                ChatMessage(sender: .counselor,
                            content: "你好，我是\(c.name)。很高興認識你，有什麼我可以幫忙的嗎？")
            ]
        }
    }

    func applyResource(_ resourceId: UUID) {
        applicationStatuses[resourceId] = .applying
        // 模擬 2 秒後報名成功
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.applicationStatuses[resourceId] = .accepted
        }
    }

    func startRegistration() { screen = .youthRegister }

    /// 註冊完成 → 進到 AI 訪談
    func finishRegistration() {
        // 把草稿的姓名等寫進 profile
        youthProfile.name     = registration.name.isEmpty ? youthProfile.name : registration.name
        youthProfile.age      = registration.age
        youthProfile.school   = registration.school.isEmpty ? youthProfile.school : registration.school
        youthProfile.major    = registration.major.isEmpty ? youthProfile.major : registration.major
        youthProfile.location = registration.location
        youthProfile.cvFileName = registration.cvFileName
        if !registration.cvHighlights.isEmpty {
            youthProfile.interests = registration.cvHighlights
        }
        screen = .youthInterview
    }

    /// 訪談完成 → 進到分析動畫，分析完成後進主畫面
    func finishInterview() {
        screen = .youthAnalyzing
        // 模擬 LLM 思考 2.4 秒
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { [weak self] in
            guard let self else { return }
            let path = MockData.generatePath(for: self.registration,
                                             answers: self.interviewAnswers)
            self.youthProfile.path = path
            // 把第一句訪談回答放進 bio
            if let first = self.interviewAnswers.first?.answer, !first.isEmpty {
                self.youthProfile.bio = first
            }
            withAnimation(.easeInOut(duration: 0.4)) {
                self.screen = .youthMain
            }
        }
    }

    // MARK: - 滑卡
    var swipeQueue: [ResourceCard] {
        allResources.filter {
            !likedResourceIds.contains($0.id) && !passedResourceIds.contains($0.id)
        }
    }
    var likedResources: [ResourceCard] {
        allResources.filter { likedResourceIds.contains($0.id) }
    }
    func swipe(card: ResourceCard, direction: SwipeDirection) {
        switch direction {
        case .right: likedResourceIds.insert(card.id)
        case .left:  passedResourceIds.insert(card.id)
        }
    }
    func resetSwipeDeck() {
        likedResourceIds.removeAll()
        passedResourceIds.removeAll()
    }

    // MARK: - 聊天
    func sendChat(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let msg = ChatMessage(sender: .user, content: trimmed)
        switch chatMode {
        case .ai:
            aiMessages.append(msg)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.aiMessages.append(
                    ChatMessage(sender: .ai, content: Self.fakeAIReply(for: trimmed))
                )
            }
        case .counselor:
            counselorMessages.append(msg)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.counselorMessages.append(
                    ChatMessage(sender: .counselor,
                                content: "收到～我等等回覆你詳細的，先給你一個方向")
                )
            }
        }
    }
    private static func fakeAIReply(for t: String) -> String {
        if t.contains("補助") || t.contains("貸款") {
            return "幫你抓了兩個方向：\n• 青年創業及啟動金貸款（最高 400 萬）\n• 青年初次尋職津貼（最高 3 萬）\n想先了解哪一個？"
        }
        if t.contains("履歷") || t.contains("面試") {
            return "可以從三件事著手：\n• 用數字量化成果\n• 對照目標職缺關鍵字\n• 預約 TYS 履歷健診"
        }
        return "嗯嗯，我聽到你說：「\(t)」。\n可以再多告訴我一點嗎？我會幫你整理可用的青年資源 💗"
    }

    // MARK: - 諮商師端
    func toggleCounselorStatus() {
        let order: [CounselorStatus] = [.available, .inSession, .offline]
        let i = order.firstIndex(of: currentCounselor.status) ?? 0
        currentCounselor.status = order[(i + 1) % order.count]
    }
    func addTag(_ tag: CaseTag, to c: CounselingCase) {
        guard let i = cases.firstIndex(where: { $0.id == c.id }) else { return }
        if !cases[i].tags.contains(tag) { cases[i].tags.append(tag) }
    }
    func recommend(resource: ResourceCard, to c: CounselingCase) {
        guard let i = cases.firstIndex(where: { $0.id == c.id }) else { return }
        if !cases[i].recommendedResourceIds.contains(resource.id) {
            cases[i].recommendedResourceIds.append(resource.id)
        }
        counselorMessages.append(
            ChatMessage(sender: .counselor,
                        content: "幫你推薦這份資源，看看適不適合",
                        attachedResourceId: resource.id)
        )
    }
    func resource(by id: UUID) -> ResourceCard? {
        allResources.first { $0.id == id }
    }
}
