//
//  AppConstants.swift
//  AppFast
//
//  Centralized configuration for the app.
//  This is the single source of truth for app-specific values.
//  When duplicating this template, update the values here and in Info.plist.
//

import Foundation

struct AppConstants {
    // MARK: - App Information

    /// The app name used throughout the UI
    /// UPDATE THIS when duplicating the template
    static let appName = "HEIC to JPG"

    /// The display name (can be different from internal app name)
    static var appDisplayName: String {
        Bundle.main.infoDictionary?["AppDisplayName"] as? String ?? appName
    }

    /// Current app version
    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// Current build number
    static var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - API Keys
    // All API keys are read from Info.plist for easy template duplication

    /// Superwall API key
    static var superwallAPIKey: String {
        guard let key = Bundle.main.infoDictionary?["SuperwallAPIKey"] as? String else {
            fatalError("SuperwallAPIKey not found in Info.plist. Add it to configure Superwall.")
        }
        return key
    }

    // MARK: - URLs

    /// Privacy policy URL
    static var privacyPolicyURL: String {
        Bundle.main.infoDictionary?["PrivacyPolicyURL"] as? String ?? "https://www.graey.dev/privacy"
    }

    // MARK: - Feature Flags
    // Add feature flags here as needed

    /// Whether to enable Superwall paywall
    static let paywallEnabled = true
}
