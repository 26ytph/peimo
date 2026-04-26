//
//  CloudModels.swift
//  duoduo
//
//  共用 Domain Model（朵朵 Cloud Hub）。
//

import Foundation
import SwiftUI

// MARK: - 角色
enum UserRole: String, Codable, CaseIterable, Identifiable {
    case youth = "民眾"
    case counselor = "諮商師"
    var id: String { rawValue }
}

// MARK: - 資源卡片分類（依 frontend_spec.md）
enum ResourceCategory: String, Codable, CaseIterable, Identifiable {
    case jobIntern  = "職缺/實習"
    case course     = "課程/活動"
    case competition = "競賽/計劃"
    case startup    = "創業資源"
    case overseas   = "國外資源"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .jobIntern:   return "briefcase.fill"
        case .course:      return "book.fill"
        case .competition: return "trophy.fill"
        case .startup:     return "lightbulb.fill"
        case .overseas:    return "airplane"
        }
    }

    /// 卡片角落小色塊（淡淡的）
    var tintColor: Color {
        switch self {
        case .jobIntern:   return Color(red: 0.86, green: 0.91, blue: 1.00)
        case .course:      return Color(red: 1.00, green: 0.93, blue: 0.83)
        case .competition: return Color(red: 1.00, green: 0.88, blue: 0.93)
        case .startup:     return Color(red: 0.92, green: 0.95, blue: 0.86)
        case .overseas:    return Color(red: 0.90, green: 0.88, blue: 1.00)
        }
    }

    /// 中飽和色（用於文字重點、圖標、按鈕）
    var solidColor: Color {
        switch self {
        case .jobIntern:   return Color(red: 0.42, green: 0.56, blue: 0.82)
        case .course:      return Color(red: 0.82, green: 0.60, blue: 0.32)
        case .competition: return Color(red: 0.80, green: 0.46, blue: 0.58)
        case .startup:     return Color(red: 0.42, green: 0.66, blue: 0.44)
        case .overseas:    return Color(red: 0.56, green: 0.48, blue: 0.78)
        }
    }

    /// 從後端 category 字串對應到本地 enum
    static func from(apiCategory: String?) -> ResourceCategory {
        guard let cat = apiCategory else { return .course }
        switch cat {
        case "職缺", "實習", "就業":          return .jobIntern
        case "課程", "活動", "培訓課程":       return .course
        case "競賽", "計劃", "補助":           return .competition
        case "創業", "貸款":                   return .startup
        case "國際交流":                       return .overseas
        default:                               return .course
        }
    }
}

// MARK: - 資源卡片
struct ResourceCard: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var organization: String
    var category: ResourceCategory
    var summary: String
    var description: String
    var deadline: String?
    var amount: String?
    var location: String?
    var tags: [String]
    var importantInfo: [String]
    var url: String?

    init(id: UUID = UUID(), title: String, organization: String,
         category: ResourceCategory, summary: String, description: String,
         deadline: String? = nil, amount: String? = nil, location: String? = nil,
         tags: [String] = [], importantInfo: [String] = [], url: String? = nil) {
        self.id = id; self.title = title; self.organization = organization
        self.category = category; self.summary = summary; self.description = description
        self.deadline = deadline; self.amount = amount; self.location = location
        self.tags = tags; self.importantInfo = importantInfo; self.url = url
    }
}

enum SwipeDirection { case left, right }

// MARK: - 資源申請狀態
enum ApplicationStatus: String, Codable {
    case none       = "未申請"
    case applying   = "申請中"
    case accepted   = "報名成功"
}

// MARK: - 諮商師配對狀態
enum CounselorMatchStatus: String, Codable {
    case none       = "未申請"
    case applied    = "已申請"
    case scheduled  = "已安排"
    case inProgress = "諮商中"
}

// MARK: - 註冊 / 個人輪廓
struct RegistrationDraft {
    var name: String = ""
    var age: Int = 22
    var school: String = ""
    var major: String = ""
    var location: String = "臺北市"
    var cvFileName: String? = nil
    /// 上傳 CV 後 LLM 自動萃取的關鍵字（mock）
    var cvHighlights: [String] = []
}

// MARK: - AI 訪談題目 / 回答
struct InterviewQuestion: Identifiable {
    let id = UUID()
    var prompt: String
    var hint: String
    var quickReplies: [String] = []   // 快速回覆按鈕
}

struct InterviewAnswer: Codable {
    var questionPrompt: String
    var answer: String
}

// MARK: - 職涯階段（取代舊的 milestone）
enum CareerStageStatus: String, Codable {
    case done       // 已完成
    case current    // 進行中
    case upcoming   // 未開始
}

struct CareerTask: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var done: Bool
    init(id: UUID = UUID(), title: String, done: Bool = false) {
        self.id = id; self.title = title; self.done = done
    }
}

struct CareerStage: Identifiable, Codable, Hashable {
    let id: UUID
    var index: Int
    var title: String           // 例：探索期
    var subtitle: String        // 例：認識自己、累積觸角
    var description: String     // 段落式描述
    var ageRange: String        // 例：22~24 歲
    var icon: String
    var status: CareerStageStatus
    var tasks: [CareerTask]
    var recommendedResourceIds: [UUID]
    init(id: UUID = UUID(), index: Int, title: String, subtitle: String,
         description: String, ageRange: String, icon: String,
         status: CareerStageStatus, tasks: [CareerTask] = [],
         recommendedResourceIds: [UUID] = []) {
        self.id = id; self.index = index; self.title = title; self.subtitle = subtitle
        self.description = description; self.ageRange = ageRange; self.icon = icon
        self.status = status; self.tasks = tasks
        self.recommendedResourceIds = recommendedResourceIds
    }
}

struct CareerPath: Codable {
    var headline: String        // 例：永續品牌行銷家
    var summary: String         // AI 一段式描述
    var stages: [CareerStage]
    var generatedAt: Date

    /// 從 API 回傳的 PathResponse 轉換為本地 CareerPath
    static func from(api: APIPathResponse, registration: RegistrationDraft, answers: [InterviewAnswer]) -> CareerPath {
        let stageIcons = ["sparkles", "list.bullet.clipboard.fill", "graduationcap.fill", "paperplane.fill", "lightbulb.fill"]
        let statusOrder: [CareerStageStatus] = [.done, .current, .upcoming, .upcoming, .upcoming]
        let baseAge = max(registration.age, 18)

        let stages = api.stages.enumerated().map { (i, s) in
            CareerStage(
                index: i,
                title: s.title,
                subtitle: s.content.prefix(30) + (s.content.count > 30 ? "…" : ""),
                description: s.content,
                ageRange: "\(baseAge + i)~\(baseAge + i + 1) 歲",
                icon: i < stageIcons.count ? stageIcons[i] : "circle",
                status: i < statusOrder.count ? statusOrder[i] : .upcoming,
                tasks: [],
                recommendedResourceIds: []
            )
        }

        return CareerPath(
            headline: api.dream,
            summary: stages.map(\.title).joined(separator: " → "),
            stages: stages,
            generatedAt: Date()
        )
    }
}

// MARK: - 個人檔案
struct YouthProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var age: Int
    var school: String
    var major: String
    var location: String
    var avatarImage: String?         // Assets catalog 圖片名（nil 則顯示姓名首字）
    var bio: String                  // 自我敘述
    var interests: [String]
    var skills: [String]
    var cvFileName: String?
    var path: CareerPath?            // AI 生成的職涯路徑
    var assignedCounselorId: UUID?

    // 後端 /youth/me 新增欄位
    var educationLevel: String?      // 學歷等級
    var department: String?          // 科系（對應後端 department，與 major 區分）
    var goal: String?                // 職涯目標
    var achievement: String?         // 成就 / 經歷亮點
    var setback: String?             // 困境 / 卡住的事
    var hollandPrimary: String?      // Holland 主型
    var hollandSecondary: String?    // Holland 副型
}

// MARK: - 對話
enum ChatSender: String, Codable { case user, ai, counselor }

struct ChatMessage: Identifiable, Codable, Hashable {
    let id: UUID
    var sender: ChatSender
    var content: String
    var timestamp: Date
    var attachedResourceId: UUID?

    init(id: UUID = UUID(), sender: ChatSender, content: String,
         timestamp: Date = Date(), attachedResourceId: UUID? = nil) {
        self.id = id; self.sender = sender; self.content = content
        self.timestamp = timestamp; self.attachedResourceId = attachedResourceId
    }
}

enum ChatMode: String, CaseIterable, Identifiable {
    case ai = "朵朵 AI"
    case counselor = "我的諮商師"
    var id: String { rawValue }
}

// MARK: - 諮商師
enum CounselorStatus: String, Codable, CaseIterable {
    case available = "可預約"
    case offline   = "離線"
    case inSession = "諮商中"

    var color: Color {
        switch self {
        case .available: return Color(red: 0.55, green: 0.78, blue: 0.55)
        case .offline:   return Color(red: 0.74, green: 0.74, blue: 0.80)
        case .inSession: return CloudTheme.pinkDeep
        }
    }
}

struct Counselor: Identifiable, Codable {
    let id: UUID
    var name: String
    var title: String
    var avatarImage: String?         // Assets catalog 圖片名
    var specialties: [String]
    var status: CounselorStatus
    var bio: String
}

// MARK: - 預約 / 個案
struct Appointment: Identifiable, Codable {
    let id: UUID
    var youthId: UUID
    var youthName: String
    var youthAvatar: String
    var requestedAt: Date
    var topic: String
    var aiSummary: String
    var keywords: [String]
    var isNew: Bool
}

struct CaseTag: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id; self.name = name; self.colorHex = colorHex
    }
}

struct CounselingCase: Identifiable, Codable {
    let id: UUID
    var youthId: UUID
    var youthName: String
    var youthAvatar: String
    var lastContact: Date
    var tags: [CaseTag]
    var statusNote: String
    var recommendedResourceIds: [UUID]
}
