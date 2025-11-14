//
//  ProfileService.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import Foundation
import Supabase

class ProfileService {
    private let supabase = SupabaseService.shared.client

    // MARK: - Profile Management

    func fetchUserProfile() async throws -> Profile? {
        guard let userId = supabase.auth.currentUser?.id else {
            throw ServiceError.userNotAuthenticated
        }

        let response: [Profile] = try await supabase
            .from("profiles")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        return response.first
    }

    func createUserProfile(displayName: String? = nil) async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            throw ServiceError.userNotAuthenticated
        }

        let request = CreateProfileRequest(
            userId: userId,
            displayName: displayName
        )

        let response: Profile = try await supabase
            .from("profiles")
            .insert(request)
            .select()
            .single()
            .execute()
            .value

        return response
    }

    func updateUserProfile(displayName: String) async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            debugPrint("ProfileService - No authenticated user")
            throw ServiceError.userNotAuthenticated
        }

        debugPrint("ProfileService - Updating profile for user: \(userId)")
        let request = UpdateProfileRequest(displayName: displayName)

        let response: Profile = try await supabase
            .from("profiles")
            .update(request)
            .eq("user_id", value: userId)
            .select()
            .single()
            .execute()
            .value

        debugPrint("ProfileService - Updated profile: \(response.displayName ?? "no name")")
        return response
    }

    func getOrCreateUserProfile() async throws -> Profile {
        guard let userId = supabase.auth.currentUser?.id else {
            debugPrint("❌ ProfileService - No authenticated user")
            throw ServiceError.userNotAuthenticated
        }

        debugPrint("✅ ProfileService - Getting or creating profile for user: \(userId)")

        do {
            if let existingProfile = try await fetchUserProfile() {
                debugPrint("✅ ProfileService - Found existing profile: \(existingProfile.displayName ?? "no name")")
                return existingProfile
            } else {
                debugPrint("📝 ProfileService - No existing profile, creating new one")
                do {
                    let newProfile = try await createUserProfile()
                    debugPrint("✅ ProfileService - Created profile: \(newProfile.displayName ?? "no name")")
                    return newProfile
                } catch {
                    debugPrint("❌ ProfileService - Create profile failed: \(error)")
                    debugPrint("📋 Error details: \(error.localizedDescription)")

                    // If creation fails, it might be due to unique constraint (profile already exists)
                    // Try fetching again as a fallback
                    if let retryProfile = try? await fetchUserProfile() {
                        debugPrint("✅ ProfileService - Found profile on retry")
                        return retryProfile
                    }

                    throw error
                }
            }
        } catch {
            debugPrint("❌ ProfileService - Failed to get or create profile: \(error)")
            throw error
        }
    }
}

// MARK: - Request Models

struct CreateProfileRequest: Codable {
    let userId: UUID
    let displayName: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case displayName = "display_name"
    }
}

struct UpdateProfileRequest: Codable {
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case displayName = "display_name"
    }
}

// MARK: - Service Error

enum ServiceError: Error, LocalizedError {
    case userNotAuthenticated

    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User is not authenticated"
        }
    }
}
