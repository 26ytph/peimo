//
//  APIModels.swift
//  duoduo
//
//  對齊 PEIMO-Backend 的 Pydantic schemas，用於 JSON 解碼/編碼。
//

import Foundation

// MARK: - User

struct APIUserCreate: Encodable {
    let account: String
    let password: String
    let role: String        // citizen / counselor / admin
    let name: String
    var email: String?
    var avatar_url: String?
}

struct APIUserUpdate: Encodable {
    var password: String?
    var role: String?
    var name: String?
    var email: String?
    var avatar_url: String?
}

struct APIUserResponse: Decodable, Identifiable {
    let id: UUID
    let account: String
    let role: String
    let name: String
    let email: String?
    let avatar_url: String?
    let created_at: String
    let updated_at: String
}

// MARK: - Youth Profile

struct APIYouthProfileUpdate: Encodable {
    var name: String?
    var age: Int?
    var school: String?
    var location: String?
    var bio: String?
    var interests: [String]?
    var skills: [String]?
    var education_level: String?
    var department: String?
    var goal: String?
    var achievement: String?
    var setback: String?
    var holland_primary: String?
    var holland_secondary: String?
}

struct APIYouthProfileResponse: Decodable, Identifiable {
    let id: UUID
    let user_id: UUID
    let name: String?
    let age: Int?
    let school: String?
    let major: String?
    let location: String?
    let bio: String?
    let interests: [String]?
    let skills: [String]?
    let education_level: String?
    let department: String?
    let goal: String?
    let achievement: String?
    let setback: String?
    let holland_primary: String?
    let holland_secondary: String?
    let avatar_url: String?
    let career_path: [String]?
    let counselor_list: [String]?
    let created_at: String
    let updated_at: String
}

// MARK: - Landing Chat

struct APILandingChatRequest: Encodable {
    let user_id: UUID
    var message: String?
}

struct APILandingChatResponse: Decodable {
    let completed: Bool
    let missing_fields: [String]
    let next_question: String?
    let extracted_fields: [String: AnyCodableValue]?
    let generated_bio: String?
    let profile_data: [String: AnyCodableValue]?
}

/// 用於解析 JSON 中混合類型的值（string / int / array / null）
enum AnyCodableValue: Decodable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([AnyCodableValue].self) {
            self = .array(v)
        } else {
            self = .null
        }
    }

    var stringValue: String? {
        switch self {
        case .string(let s): return s
        case .int(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return String(b)
        default: return nil
        }
    }

    var intValue: Int? {
        switch self {
        case .int(let i): return i
        case .string(let s): return Int(s)
        default: return nil
        }
    }

    var stringArray: [String] {
        switch self {
        case .array(let arr): return arr.compactMap(\.stringValue)
        case .string(let s): return [s]
        default: return []
        }
    }
}

// MARK: - Resource (Admin CRUD)

struct APIResourceResponse: Decodable, Identifiable {
    let id: UUID
    let title: String
    let category: String
    let description: String
    let provider: String?
    let url: String?
    let location: String?
    let target_goal: String?
    let required_skills: [String]?
    let created_at: String
    let updated_at: String
}

// MARK: - Resource (RAG Search)

struct APIResourceItem: Decodable {
    let content: String
    let source: String
    let url: String
    let tags: String
    let title: String
}

// MARK: - Chat

struct APIChatMessage: Codable {
    let role: String    // "user" or "model"
    let content: String
}

struct APIChatRequest: Encodable {
    let user_id: UUID
    let message: String
    let history: [APIChatMessage]
}

struct APIChatResponse: Decodable {
    let reply: String
    let needs_human_handoff: Bool
}

// MARK: - Path Generation

struct APIPathRequest: Encodable {
    let user_id: UUID
    let dream: String
    let background: [String: String]
}

struct APIPathStage: Decodable {
    let title: String
    let content: String
    let resources: [String]
}

struct APIPathResponse: Decodable {
    let user_id: UUID
    let dream: String
    let stages: [APIPathStage]
}

// MARK: - Case Records

struct APICaseRecordCreate: Encodable {
    let citizen_id: UUID
    let counselor_id: UUID
    var summary: String?
    var current_status: String?
    var counselor_note: String?
}

struct APICaseRecordResponse: Decodable, Identifiable {
    let id: UUID
    let citizen_id: UUID
    let counselor_id: UUID
    let summary: String?
    let current_status: String?
    let counselor_note: String?
    let created_at: String
    let updated_at: String
}
