//
//  VideotoAudioApp.swift
//  HEIC to JPG
//
//  Created by JP Norton on 11/7/25.
//

import SwiftUI
import SuperwallKit

@main
struct VideotoAudioApp: App {
    @StateObject private var onboardingManager = OnboardingViewModel()

    init() {
        // Warm up haptics early to eliminate first-use delay
        _ = HapticManager.shared

        // Configure Superwall for paywall monetization
        Superwall.configure(apiKey: AppConstants.superwallAPIKey)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !onboardingManager.showOnboarding {
                    MainTabView()
                        .environmentObject(onboardingManager)
                } else {
                    OnboardingFlowView()
                        .environmentObject(onboardingManager)
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}
