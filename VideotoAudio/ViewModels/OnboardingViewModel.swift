//
//  OnboardingViewModel.swift
//  HEIC to JPG
//
//  Created on 2025-11-07.
//

import Foundation
import SwiftUI
import Combine
import StoreKit

enum OnboardingStep: Int, CaseIterable, Hashable {
    case videotoAudio = 0
    case multipleFormats
    case conversionHistory
    case review
    case paywall

    var progress: Double {
        let progressSteps = 5.0
        return Double(self.rawValue + 1) / progressSteps
    }
}

class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .videotoAudio
    @Published var showOnboarding: Bool
    @Published var hasRequestedReview = false
    @Published var canProceedFromReview = false
    @Published var canProceedFromPaywall = false
    @Published var hasShownPaywall = false

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let shouldShowConverterIntroKey = "shouldShowConverterIntro"

    init() {
        self.showOnboarding = !UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)
    }

    func nextStep() {
        // Reset review button state when leaving review step
        if currentStep == .review {
            canProceedFromReview = false
        }

        // Reset paywall button state when leaving paywall step
        if currentStep == .paywall {
            canProceedFromPaywall = false
        }

        guard let nextStepRaw = OnboardingStep(rawValue: currentStep.rawValue + 1) else {
            completeOnboarding()
            return
        }

        currentStep = nextStepRaw
    }

    func previousStep() {
        // Reset review button state when leaving review step
        if currentStep == .review {
            canProceedFromReview = false
        }

        // Reset paywall button state when leaving paywall step
        if currentStep == .paywall {
            canProceedFromPaywall = false
        }

        guard currentStep.rawValue > 0,
              let previousStepRaw = OnboardingStep(rawValue: currentStep.rawValue - 1) else {
            return
        }

        currentStep = previousStepRaw
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.set(true, forKey: shouldShowConverterIntroKey)

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showOnboarding = false
        }
    }

    func canProceed(from step: OnboardingStep) -> Bool {
        // All slides can be proceeded from
        return true
    }

    func requestReview() {
        guard !hasRequestedReview else { return }

        hasRequestedReview = true

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }

    // Reset for testing purposes
    func resetOnboarding() {
        UserDefaults.standard.set(false, forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.set(false, forKey: shouldShowConverterIntroKey)
        currentStep = .videotoAudio
        showOnboarding = true
        hasRequestedReview = false
        canProceedFromReview = false
        canProceedFromPaywall = false
        hasShownPaywall = false
    }
}
