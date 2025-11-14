//
//  UserProfileViewModel.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class UserProfileViewModel: ObservableObject {
    @Published var userProfile: Profile?
    @Published var displayName: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let profileService = ProfileService()
    private var cancellables = Set<AnyCancellable>()

    init() {
        Task {
            await loadUserProfile()
        }
    }

    // MARK: - Data Loading

    func loadUserProfile() async {
        isLoading = true
        errorMessage = nil

        do {
            let profile = try await profileService.getOrCreateUserProfile()
            withAnimation(.smooth(duration: 0.5)) {
                userProfile = profile
                displayName = profile.displayName ?? ""
            }
            debugPrint("UserProfileViewModel - Loaded profile: \(profile.displayName ?? "no name")")
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            debugPrint("UserProfileViewModel - Load error: \(error)")
        }

        isLoading = false
    }

    // MARK: - Profile Management

    func updateDisplayName(_ newName: String) async {
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        do {
            let updatedProfile = try await profileService.updateUserProfile(displayName: trimmedName)
            withAnimation(.smooth(duration: 0.5)) {
                userProfile = updatedProfile
                displayName = updatedProfile.displayName ?? ""
            }
        } catch {
            errorMessage = "Failed to update name: \(error.localizedDescription)"
            debugPrint("UserProfileViewModel - Update error: \(error)")
        }

        isLoading = false
    }

    var displayNameOrPlaceholder: String {
        if displayName.isEmpty {
            return "Enter your name"
        }
        return displayName
    }
}
