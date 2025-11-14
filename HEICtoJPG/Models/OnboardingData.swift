//
//  OnboardingData.swift
//  AppFast
//
//  Created on 2025-11-07.
//

import Foundation

enum Gender: String, CaseIterable, Codable {
    case male = "Male"
    case female = "Female"
    case other = "Other"
}

enum ReferralSource: String, CaseIterable, Codable {
    case instagram = "Instagram"
    case facebook = "Facebook"
    case tiktok = "TikTok"
    case youtube = "Youtube"
    case x = "X"
    case google = "Google"
    case tv = "TV"
    case friendsFamily = "Friends & family"
    case appStore = "App Store"
    case other = "Other"

    var iconName: String {
        switch self {
        case .instagram: return "instagram-logo"
        case .facebook: return "facebook-logo"
        case .tiktok: return "tiktok-logo"
        case .youtube: return "youtube-logo"
        case .x: return "x-logo"
        case .google: return "google-logo"
        case .tv: return "tv.fill"
        case .friendsFamily: return "person.2.fill"
        case .appStore: return "appstore-logo"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var isSystemIcon: Bool {
        switch self {
        case .tv, .friendsFamily, .other:
            return true
        default:
            return false
        }
    }

    var needsWhiteBackground: Bool {
        switch self {
        case .tiktok:
            return true
        default:
            return false
        }
    }

    var iconColor: String {
        switch self {
        case .instagram: return "#E1306C"
        case .facebook: return "#1877F2"
        case .tiktok: return "#000000"
        case .youtube: return "#FF0000"
        case .x: return "#000000"
        case .google: return "#4285F4"
        case .tv: return "#000000"
        case .friendsFamily: return "#34C759"
        case .appStore: return "#007AFF"
        case .other: return "#8E8E93"
        }
    }
}

enum Goal: String, CaseIterable, Codable {
    case loseWeight = "Option 1"
    case maintain = "Option 2"
    case gainWeight = "Option 3"
}

struct OnboardingData: Codable {
    var gender: Gender?
    var name: String = ""
    var age: String = ""
    var referralSource: ReferralSource?
    var goal: Goal?
    var hasCompletedOnboarding: Bool = false
}
