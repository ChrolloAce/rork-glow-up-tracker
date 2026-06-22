import Foundation

// MARK: - Setup
//
// Run this SQL in your Supabase SQL editor once to enable the live chat:
//
//   create table if not exists public.glow_chat_messages (
//     id uuid primary key default gen_random_uuid(),
//     username text not null,
//     avatar text not null default '',
//     age int not null default 0,
//     message text not null,
//     is_current_user boolean not null default false,
//     created_at timestamptz not null default now()
//   );
//   alter table public.glow_chat_messages enable row level security;
//   create policy "anon read" on public.glow_chat_messages for select using (true);
//   create policy "anon insert" on public.glow_chat_messages for insert with check (true);
//

nonisolated struct SupabaseChatRow: Codable, Sendable {
    let id: String
    let username: String
    let avatar: String
    let age: Int
    let message: String
    let created_at: String
}

nonisolated struct SupabaseChatInsert: Codable, Sendable {
    let username: String
    let avatar: String
    let age: Int
    let message: String
}

nonisolated enum SupabaseError: Error, Sendable {
    case missingConfig
    case invalidURL
    case badResponse(Int, String)
}

nonisolated final class SupabaseService: Sendable {
    static let shared = SupabaseService()

    private let table = "glow_chat_messages"

    private var baseURL: String {
        Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
    }

    private var anonKey: String {
        Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""
    }

    var isConfigured: Bool {
        !baseURL.isEmpty && !anonKey.isEmpty
    }

    private func makeRequest(path: String, query: String? = nil, method: String = "GET") throws -> URLRequest {
        guard !baseURL.isEmpty, !anonKey.isEmpty else { throw SupabaseError.missingConfig }
        var urlString = "\(baseURL)/rest/v1/\(path)"
        if let query { urlString += "?\(query)" }
        guard let url = URL(string: urlString) else { throw SupabaseError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return req
    }

    func fetchMessages(limit: Int = 100) async throws -> [SupabaseChatRow] {
        let query = "select=*&order=created_at.asc&limit=\(limit)"
        let req = try makeRequest(path: table, query: query)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SupabaseError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
        }
        return try JSONDecoder().decode([SupabaseChatRow].self, from: data)
    }

    func sendMessage(username: String, avatar: String, age: Int, message: String) async throws -> SupabaseChatRow {
        var req = try makeRequest(path: table, method: "POST")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        let payload = SupabaseChatInsert(username: username, avatar: avatar, age: age, message: message)
        req.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw SupabaseError.badResponse(code, String(data: data, encoding: .utf8) ?? "")
        }
        let rows = try JSONDecoder().decode([SupabaseChatRow].self, from: data)
        guard let row = rows.first else { throw SupabaseError.badResponse(0, "empty response") }
        return row
    }
}
