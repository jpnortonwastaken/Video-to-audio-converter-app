//
//  HapticManager.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private let impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()

    private init() {
        // Warm up haptics on initialization
        warmUpHaptics()
    }

    /// Warms up the haptic feedback generators to eliminate first-use delay
    func warmUpHaptics() {
        // Prepare all feedback generators
        impactFeedbackGenerator.prepare()
        selectionFeedbackGenerator.prepare()
        notificationFeedbackGenerator.prepare()

        // Fire a silent haptic to initialize the Taptic Engine
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impactFeedbackGenerator.impactOccurred(intensity: 0.1)
        }
    }

    // Soft haptic feedback for general interactions
    func softImpact() {
        impactFeedbackGenerator.impactOccurred()
        impactFeedbackGenerator.prepare() // Prepare for next use
    }

    // Light haptic feedback for subtle interactions
    func lightImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    // Medium haptic feedback for more prominent interactions
    func mediumImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    // Heavy haptic feedback for important actions
    func heavyImpact() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }

    // Selection haptic feedback for picker-like interactions
    func selectionChanged() {
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare() // Prepare for next use
    }

    // Success notification haptic
    func success() {
        notificationFeedbackGenerator.notificationOccurred(.success)
        notificationFeedbackGenerator.prepare() // Prepare for next use
    }

    // Warning notification haptic
    func warning() {
        notificationFeedbackGenerator.notificationOccurred(.warning)
        notificationFeedbackGenerator.prepare() // Prepare for next use
    }

    // Error notification haptic
    func error() {
        notificationFeedbackGenerator.notificationOccurred(.error)
        notificationFeedbackGenerator.prepare() // Prepare for next use
    }
}

// MARK: - Convenience methods for common actions

extension HapticManager {
    /// Haptic for button taps
    func buttonTap() {
        softImpact()
    }

    /// Haptic for tab bar switches
    func tabSelection() {
        softImpact()
    }

    /// Haptic for opening sheets/modals
    func sheetPresentation() {
        lightImpact()
    }
}
