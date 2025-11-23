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
    private var isCheckingSubscription = false

    private init() {
        // Check subscription status based on Superwall's subscription status
        checkSubscriptionStatus()
    }

    // MARK: - Public Methods

    /// Shows the paywall if user is not subscribed
    /// - Returns: True if user is subscribed (paywall not shown), false if paywall was shown
    func requireSubscription() -> Bool {
        // Use Superwall's register method which automatically checks subscription
        // If user is subscribed, it will skip showing the paywall
        // If not subscribed, it will show the paywall
        showPaywall()

        // Return false to prevent the action (paywall will handle navigation)
        // The actual subscription check happens in Superwall's register method
        return false
    }

    /// Shows the paywall using Superwall
    /// Superwall automatically checks if user is subscribed and skips if they are
    func showPaywall() {
        // Superwall's register method will:
        // 1. Check if user is subscribed
        // 2. If subscribed, skip showing paywall (returns .skipped(.userIsSubscribed))
        // 3. If not subscribed, show the paywall
        Superwall.shared.register(placement: "feature_gated")
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
    }
}
