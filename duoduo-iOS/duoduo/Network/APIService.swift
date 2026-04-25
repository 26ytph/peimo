//
//  APIService.swift
//  duoduo
//
//  網路層：串接 PEIMO-Backend（https://duoduo-backend.zudo.cc）。
//

import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "無效的 URL"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .decodingError(let err): return "解析失敗: \(err.localizedDescription)"
        case .networkError(let err): return "網路錯誤: \(err.localizedDescription)"
        }
    }
}

actor APIService {
    static let shared = APIService()

    /// Demo 用動態 user_id，每次 onboarding 自動建立新 user
    static var demoUserId: UUID = UUID(uuidString: "38a7d586-3317-4a8a-ba01-595476ad9595")!

    private let baseURL = "https://duoduo-backend.zudo.cc"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        encoder = JSONEncoder()
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        method: String,
        path: String,
        body: (any Encodable)? = nil,
        query: [(String, String)] = []
    ) async throws -> T {
        guard var components = URLComponents(string: baseURL + path) else {
            throw APIError.invalidURL
        }
        if !query.isEmpty {
            components.queryItems = query.map { URLQueryItem(name: $0.0, value: $0.1) }
        }
        guard let url = components.url else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        guard (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(http.statusCode, msg)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    /// Fire-and-forget for DELETE (204 no content)
    private func requestVoid(method: String, path: String, body: (any Encodable)? = nil) async throws {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try encoder.encode(AnyEncodable(body))
        }
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? ""
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw APIError.httpError(code, msg)
        }
    }

    // MARK: - Health

    func healthCheck() async throws -> Bool {
        struct H: Decodable { let status: String }
        let h: H = try await request(method: "GET", path: "/health")
        return h.status == "ok"
    }

    // MARK: - Users

    func createUser(_ body: APIUserCreate) async throws -> APIUserResponse {
        try await request(method: "POST", path: "/users", body: body)
    }

    func getUser(id: UUID) async throws -> APIUserResponse {
        try await request(method: "GET", path: "/users/\(id)")
    }

    func listUsers() async throws -> [APIUserResponse] {
        try await request(method: "GET", path: "/users")
    }

    func updateUser(id: UUID, body: APIUserUpdate) async throws -> APIUserResponse {
        try await request(method: "PATCH", path: "/users/\(id)", body: body)
    }

    // MARK: - Youth Profile

    func getYouthProfile(userId: UUID) async throws -> APIYouthProfileResponse {
        try await request(method: "GET", path: "/youth/me",
                          query: [("user_id", userId.uuidString)])
    }

    func updateYouthProfile(userId: UUID, body: APIYouthProfileUpdate) async throws -> APIYouthProfileResponse {
        try await request(method: "PATCH", path: "/youth/me",
                          body: body, query: [("user_id", userId.uuidString)])
    }

    // MARK: - Landing Chat

    func landingChat(userId: UUID, message: String? = nil) async throws -> APILandingChatResponse {
        let body = APILandingChatRequest(user_id: userId, message: message)
        return try await request(method: "POST", path: "/landing/chat", body: body)
    }

    // MARK: - Resources (Admin CRUD — full list)

    func listAdminResources() async throws -> [APIResourceResponse] {
        try await request(method: "GET", path: "/admin/resources")
    }

    func getAdminResource(id: UUID) async throws -> APIResourceResponse {
        try await request(method: "GET", path: "/admin/resources/\(id)")
    }

    // MARK: - Resources (RAG semantic search)

    func searchResources(query: String, n: Int = 5) async throws -> [APIResourceItem] {
        try await request(method: "GET", path: "/resources",
                          query: [("query", query), ("n", "\(n)")])
    }

    // MARK: - Chat (AI with RAG)

    func sendChatMessage(userId: UUID, message: String, history: [APIChatMessage]) async throws -> APIChatResponse {
        let body = APIChatRequest(user_id: userId, message: message, history: history)
        return try await request(method: "POST", path: "/chat/message", body: body)
    }

    // MARK: - Path Generation

    func generatePath(userId: UUID, dream: String, background: [String: String]) async throws -> APIPathResponse {
        let body = APIPathRequest(user_id: userId, dream: dream, background: background)
        return try await request(method: "POST", path: "/path/generate", body: body)
    }

    // MARK: - Case Records

    func listCaseRecords() async throws -> [APICaseRecordResponse] {
        try await request(method: "GET", path: "/case-records")
    }

    func createCaseRecord(_ body: APICaseRecordCreate) async throws -> APICaseRecordResponse {
        try await request(method: "POST", path: "/case-records", body: body)
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void
    init(_ wrapped: any Encodable) {
        _encode = { try wrapped.encode(to: $0) }
    }
    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
