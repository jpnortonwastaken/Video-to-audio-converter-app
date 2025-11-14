//
//  OnboardingDataStorage.swift
//  AppFast
//
//  Created by Claude on 11/10/25.
//

import Foundation

/// Manages local persistence of onboarding data before authentication
class OnboardingDataStorage {
    static let shared = OnboardingDataStorage()

    private let userDefaults = UserDefaults.standard
    private let onboardingDataKey = "pendingOnboardingData"

    private init() {}

    /// Saves onboarding data to local storage
    func save(_ data: OnboardingData) {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(data)
            userDefaults.set(encoded, forKey: onboardingDataKey)
            debugPrint("💾 Onboarding data saved locally")
        } catch {
            debugPrint("❌ Failed to save onboarding data: \(error)")
        }
    }

    /// Retrieves onboarding data from local storage
    func retrieve() -> OnboardingData? {
        guard let data = userDefaults.data(forKey: onboardingDataKey) else {
            debugPrint("ℹ️ No pending onboarding data found")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(OnboardingData.self, from: data)
            debugPrint("✅ Retrieved pending onboarding data from local storage")
            return decoded
        } catch {
            debugPrint("❌ Failed to decode onboarding data: \(error)")
            return nil
        }
    }

    /// Clears onboarding data from local storage (call after successful upload)
    func clear() {
        userDefaults.removeObject(forKey: onboardingDataKey)
        debugPrint("🗑️ Cleared pending onboarding data from local storage")
    }

    /// Checks if there's pending onboarding data
    var hasPendingData: Bool {
        return userDefaults.data(forKey: onboardingDataKey) != nil
    }
}
