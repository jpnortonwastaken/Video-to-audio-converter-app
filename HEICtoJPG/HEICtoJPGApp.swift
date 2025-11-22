//
//  HEICtoJPGApp.swift
//  HEIC to JPG
//
//  Created by JP Norton on 11/7/25.
//

import SwiftUI
import SuperwallKit

enum AppearancePreference: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

@main
struct HEICtoJPGApp: App {
    @StateObject private var onboardingManager = OnboardingViewModel()
    @AppStorage("appearance_preference") private var appearancePreference: AppearancePreference = .system

    init() {
        // Warm up haptics early to eliminate first-use delay
        _ = HapticManager.shared

        // Configure Superwall for paywall monetization
        Superwall.configure(apiKey: AppConstants.superwallAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            if !onboardingManager.showOnboarding {
                MainTabView()
                    .environmentObject(onboardingManager)
                    .onAppear {
                        applyStoredAppearance()
                    }
            } else {
                OnboardingFlowView()
                    .environmentObject(onboardingManager)
                    .onAppear {
                        applyStoredAppearance()
                    }
            }
        }
    }

    private func applyStoredAppearance() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        switch appearancePreference {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}
