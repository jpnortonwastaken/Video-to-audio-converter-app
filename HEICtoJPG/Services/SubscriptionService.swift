//
//  SubscriptionService.swift
//  HEIC to JPG
//
//  Manages subscription status and paywall presentation using Superwall
//

import Foundation
import SuperwallKit
import Combine

@MainActor
class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    // MARK: - Published Properties
    @Published private(set) var isSubscribed = false

    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Check initial subscription status
        checkSubscriptionStatus()
    }

    // MARK: - Public Methods

    /// Shows the paywall if user is not subscribed
    /// - Returns: True if user is subscribed (allow action), false if not subscribed (prevent action)
    func requireSubscription() -> Bool {
        // First check current subscription status
        checkSubscriptionStatus()

        // If user is already subscribed, allow the action
        if isSubscribed {
            return true
        }

        // User is not subscribed, show the paywall
        showPaywall()

        // Return false to prevent the action
        return false
    }

    /// Shows the paywall using Superwall
    /// Superwall automatically checks if user is subscribed and skips if they are
    func showPaywall() {
        // Create a handler to monitor paywall events
        let handler = PaywallPresentationHandler()
        handler.onPresent { [weak self] paywallInfo in
            print("✅ Paywall presented: \(paywallInfo.name)")
        }
        handler.onDismiss { [weak self] paywallInfo, result in
            print("✅ Paywall dismissed")
            // Update subscription status after paywall is dismissed
            self?.checkSubscriptionStatus()
        }
        handler.onSkip { [weak self] skipReason in
            print("✅ Paywall skipped: \(skipReason)")
            // Update subscription status
            self?.checkSubscriptionStatus()
        }
        handler.onError { error in
            print("❌ Paywall error: \(error.localizedDescription)")
        }

        // Register with Superwall using the same placement as onboarding
        // This will show the paywall if user is not subscribed
        Superwall.shared.register(placement: "campaign_trigger", handler: handler)
    }

    // MARK: - Private Methods

    /// Check subscription status by examining Superwall's subscription status
    private func checkSubscriptionStatus() {
        // Check the subscription status property
        let status = Superwall.shared.subscriptionStatus

        // Update our published property based on the status
        switch status {
        case .active:
            isSubscribed = true
        case .inactive:
            isSubscribed = false
        default:
            isSubscribed = false
        }

        print("💳 Subscription status: \(isSubscribed ? "ACTIVE" : "INACTIVE")")
    }
}
