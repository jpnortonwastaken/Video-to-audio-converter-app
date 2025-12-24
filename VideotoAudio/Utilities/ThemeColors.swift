//
//  ThemeColors.swift
//  Video to Audio
//
//  Centralized theme colors with blue-tinted dark mode.
//

import SwiftUI

extension Color {
    // MARK: - Blue-Tinted Dark Mode Backgrounds

    /// Primary background - replaces systemBackground in dark mode
    /// Light mode: system background, Dark mode: deep blue-tinted black
    static func appBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.06, green: 0.08, blue: 0.14)
            : Color(.systemBackground)
    }

    /// Secondary background - replaces systemGray6 in dark mode
    /// Light mode: systemGray6, Dark mode: slightly lighter blue-tinted
    static func appSecondaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.08, green: 0.10, blue: 0.18)
            : Color(.systemGray6)
    }

    /// Tertiary background - replaces systemGray5 in dark mode
    /// Light mode: systemGray5, Dark mode: blue-tinted gray
    static func appTertiaryBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.12, green: 0.14, blue: 0.22)
            : Color(.systemGray5)
    }

    /// Card background - for elevated surfaces
    static func appCardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.10, green: 0.12, blue: 0.20)
            : Color(.systemBackground)
    }
}
