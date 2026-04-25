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
    case youthAnalysisResult  // AI 分析結果，使用者可確認/修改
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
    var isLoadingResources = false
    var resourceLoadError: String?

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
    /// 民眾登入：自動建立新 user，進入 onboarding
    var isCreatingUser = false

    func loginAsYouth() {
        role = .youth
        isCreatingUser = true

        Task {
            do {
                let suffix = String(UUID().uuidString.prefix(6))
                let body = APIUserCreate(
                    account: "duoduo_\(suffix)",
                    password: "demo123",
                    role: "citizen",
                    name: "朵朵用戶"
                )
                let user = try await APIService.shared.createUser(body)
                APIService.demoUserId = user.id
                print("[AppState] Created new user: \(user.id)")
            } catch {
                print("[AppState] createUser failed: \(error), using existing demoUserId")
            }

            await MainActor.run {
                isCreatingUser = false
                screen = youthProfile.path == nil ? .youthLanding : .youthMain
                // 加載資源
                Task { await self.loadResources() }
            }
        }
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

        // 非同步調用後端 API
        Task {
            do {
                let result = try await APIService.shared.applyResource(
                    resourceId: resourceId,
                    userId: APIService.demoUserId
                )

                await MainActor.run {
                    // 根據後端回傳的 status 更新
                    switch result.status.lowercased() {
                    case "accepted":
                        self.applicationStatuses[resourceId] = .accepted
                    case "applying":
                        self.applicationStatuses[resourceId] = .applying
                    default:
                        self.applicationStatuses[resourceId] = .applying
                    }
                }
            } catch {
                print("[AppState] applyResource failed: \(error)")
                await MainActor.run {
                    self.applicationStatuses[resourceId] = .applying
                }
            }
        }
    }

    func startRegistration() { screen = .youthRegister }

    /// 註冊完成 → 同步到後端 → 進到 AI 訪談
    var isSyncingRegistration = false

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

        isSyncingRegistration = true
        let userId = APIService.demoUserId

        Task {
            // 1. PATCH /users — 更新 name
            do {
                var userBody = APIUserUpdate()
                userBody.name = youthProfile.name
                let _ = try await APIService.shared.updateUser(id: userId, body: userBody)
            } catch {
                print("[AppState] updateUser failed: \(error)")
            }

            // 2. PATCH /youth/me — 同步基本資料，讓 /landing/chat 知道已填欄位
            do {
                let youthBody = APIYouthProfileUpdate(
                    name: youthProfile.name,
                    age: youthProfile.age,
                    school: youthProfile.school,
                    location: youthProfile.location,
                    interests: youthProfile.interests.isEmpty ? nil : youthProfile.interests,
                    department: youthProfile.major
                )
                let _ = try await APIService.shared.updateYouthProfile(userId: userId, body: youthBody)
            } catch {
                print("[AppState] updateYouthProfile failed: \(error)")
            }

            await MainActor.run {
                isSyncingRegistration = false
                screen = .youthInterview
            }
        }
    }

    /// 訪談完成 → 由 AIInterviewView 在 /landing/chat completed 時直接跳轉
    /// 此方法保留作為 fallback（如果從其他地方呼叫）
    func finishInterview() {
        screen = .youthAnalysisResult
    }

    /// 使用者確認分析結果 → PATCH /youth/me → 分析動畫 → POST /path/generate → 主畫面
    var isSubmittingProfile = false

    func confirmAnalysisResult() {
        guard !isSubmittingProfile else { return }
        isSubmittingProfile = true

        Task {
            let userId = APIService.demoUserId

            // 1. PATCH /youth/me 更新使用者資料
            do {
                let body = APIYouthProfileUpdate(
                    name: youthProfile.name,
                    age: youthProfile.age,
                    school: youthProfile.school,
                    location: youthProfile.location,
                    bio: youthProfile.bio,
                    interests: youthProfile.interests,
                    skills: youthProfile.skills,
                    education_level: youthProfile.educationLevel,
                    department: youthProfile.department ?? youthProfile.major,
                    goal: youthProfile.goal,
                    achievement: youthProfile.achievement,
                    setback: youthProfile.setback,
                    holland_primary: youthProfile.hollandPrimary,
                    holland_secondary: youthProfile.hollandSecondary
                )
                let _ = try await APIService.shared.updateYouthProfile(userId: userId, body: body)
            } catch {
                print("[APIService] updateYouthProfile failed: \(error)")
            }

            // 2. 進到分析動畫
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.4)) {
                    screen = .youthAnalyzing
                }
            }

            // 3. POST /path/generate 生成職涯路徑
            do {
                let dream = youthProfile.goal ?? interviewAnswers.first?.answer ?? ""
                var background: [String: String] = [
                    "name": youthProfile.name,
                    "school": youthProfile.school,
                    "major": youthProfile.major,
                    "location": youthProfile.location,
                ]
                if !youthProfile.bio.isEmpty { background["bio"] = youthProfile.bio }
                if let hl = youthProfile.hollandPrimary { background["holland_primary"] = hl }
                if let hl = youthProfile.hollandSecondary { background["holland_secondary"] = hl }
                if let achievement = youthProfile.achievement { background["achievement"] = achievement }
                if let setback = youthProfile.setback { background["setback"] = setback }
                for (i, ans) in interviewAnswers.enumerated() {
                    background["interview_q\(i)"] = ans.questionPrompt
                    background["interview_a\(i)"] = ans.answer
                }

                let response = try await APIService.shared.generatePath(
                    userId: userId, dream: dream, background: background
                )
                // 將 APIPathResponse 轉換為本地 CareerPath
                await MainActor.run {
                    youthProfile.path = CareerPath.from(api: response, registration: registration, answers: interviewAnswers)
                }
            } catch {
                print("[APIService] generatePath failed: \(error)")
                // fallback: 用本地 mock 生成
                await MainActor.run {
                    let path = MockData.generatePath(for: registration, answers: interviewAnswers)
                    youthProfile.path = path
                }
            }

            await MainActor.run {
                isSubmittingProfile = false
                withAnimation(.easeInOut(duration: 0.4)) {
                    screen = .youthMain
                }
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

    /// 從後端加載資源（用於 browse）
    func loadResources() async {
        await MainActor.run {
            isLoadingResources = true
            resourceLoadError = nil
        }

        do {
            let cardResponses = try await APIService.shared.browseResources()
            let cards = cardResponses.map { resp -> ResourceCard in
                // 將 APIResourceCardResponse 轉換為 ResourceCard
                let category = ResourceCategory.jobIntern  // 預設分類，後端若有 category 欄位則改用
                return ResourceCard(
                    id: resp.id,
                    title: resp.title,
                    organization: resp.source ?? "朵朵",
                    category: category,
                    summary: String(resp.content.prefix(50)) + "...",
                    description: resp.content,
                    tags: resp.tags ?? [],
                    url: resp.url
                )
            }

            await MainActor.run {
                self.allResources = cards
                self.isLoadingResources = false
            }
        } catch {
            await MainActor.run {
                self.resourceLoadError = error.localizedDescription
                self.isLoadingResources = false
                print("[AppState] loadResources failed: \(error)")
            }
        }
    }

    /// 從後端加載已收藏的資源
    func loadLikedResources() async {
        do {
            let cardResponses = try await APIService.shared.likedResources(userId: APIService.demoUserId)
            let likedIds = Set(cardResponses.map { $0.id })

            await MainActor.run {
                self.likedResourceIds = likedIds
            }
        } catch {
            print("[AppState] loadLikedResources failed: \(error)")
        }
    }

    func swipe(card: ResourceCard, direction: SwipeDirection) {
        switch direction {
        case .right:
            likedResourceIds.insert(card.id)
        case .left:
            passedResourceIds.insert(card.id)
        }

        // 同步到後端
        Task {
            do {
                let directionStr = direction == .right ? "right" : "left"
                try await APIService.shared.swipeResource(
                    resourceId: card.id,
                    userId: APIService.demoUserId,
                    direction: directionStr
                )
            } catch {
                print("[AppState] swipeResource failed: \(error)")
            }
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
            // 調用後端 AI chat API
            Task {
                do {
                    _ = try await APIService.shared.sendAIChat(
                        userId: APIService.demoUserId,
                        message: trimmed
                    )

                    // 這裡的 reply 應該來自後端，但 APIChatMessage 結構不同
                    // 暫時使用 mock reply
                    await MainActor.run {
                        self.aiMessages.append(
                            ChatMessage(sender: .ai, content: Self.fakeAIReply(for: trimmed))
                        )
                    }
                } catch {
                    print("[AppState] sendAIChat failed: \(error)")
                    // 失敗時也使用 mock reply
                    await MainActor.run {
                        self.aiMessages.append(
                            ChatMessage(sender: .ai, content: "抱歉，我現在無法回應。請稍後再試。")
                        )
                    }
                }
            }

        case .counselor:
            counselorMessages.append(msg)
            // 調用後端諮商師 chat API
            Task {
                do {
                    _ = try await APIService.shared.sendCounselorChat(
                        userId: APIService.demoUserId,
                        message: trimmed
                    )

                    await MainActor.run {
                        self.counselorMessages.append(
                            ChatMessage(sender: .counselor,
                                        content: "收到～我等等回覆你詳細的，先給你一個方向")
                        )
                    }
                } catch {
                    print("[AppState] sendCounselorChat failed: \(error)")
                }
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
