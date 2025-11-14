//
//  Profile.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import Foundation

struct Profile: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let displayName: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case displayName = "display_name"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Update profile data structure for sending to Supabase
/// Only includes display_name for privacy - onboarding data kept local-only
struct ProfileUpdate: Encodable {
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}
