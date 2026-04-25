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

struct APIPathStep: Decodable {
    let step: String
    let resource_type: String
}

struct APIPathContent: Decodable {
    let short_term: [APIPathStep]
    let mid_term: [APIPathStep]
    let long_term: [APIPathStep]
}

struct APIPathResponse: Decodable {
    let id: UUID
    let user_id: UUID
    let content: APIPathContent
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
