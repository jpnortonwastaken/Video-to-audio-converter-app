//
//  BouncyButton.swift
//  AppFast
//
//  Created on 2025-11-07.
//

import SwiftUI

/// A reusable button component that combines BounceButtonStyle with haptic feedback.
/// Automatically triggers soft impact haptic on tap, matching the Sign in with Apple button experience.
struct BouncyButton<Content: View>: View {
    let scaleAmount: Double
    let action: () -> Void
    let content: Content

    /// Creates a bouncy button with custom content
    /// - Parameters:
    ///   - scaleAmount: Scale factor when pressed (default: 0.95, use 0.9 for more pronounced bounce)
    ///   - content: Custom button content
    ///   - action: Action to perform on tap (haptic fires automatically before this)
    init(
        scaleAmount: Double = 0.95,
        @ViewBuilder content: () -> Content,
        action: @escaping () -> Void
    ) {
        self.scaleAmount = scaleAmount
        self.content = content()
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap() // Soft impact - matches login screen
            action()
        }) {
            content
        }
        .buttonStyle(BounceButtonStyle(scaleAmount: scaleAmount))
    }
}

// MARK: - Convenience Initializers

extension BouncyButton where Content == Text {
    /// Creates a bouncy button with a text label
    /// - Parameters:
    ///   - title: Button text
    ///   - scaleAmount: Scale factor when pressed (default: 0.95)
    ///   - action: Action to perform on tap
    init(
        _ title: String,
        scaleAmount: Double = 0.95,
        action: @escaping () -> Void
    ) {
        self.scaleAmount = scaleAmount
        self.content = Text(title)
        self.action = action
    }
}

extension BouncyButton where Content == Label<Text, Image> {
    /// Creates a bouncy button with an SF Symbol icon and text label
    /// - Parameters:
    ///   - title: Button text
    ///   - systemImage: SF Symbol name
    ///   - scaleAmount: Scale factor when pressed (default: 0.95)
    ///   - action: Action to perform on tap
    init(
        _ title: String,
        systemImage: String,
        scaleAmount: Double = 0.95,
        action: @escaping () -> Void
    ) {
        self.scaleAmount = scaleAmount
        self.content = Label(title, systemImage: systemImage)
        self.action = action
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        // Simple text button
        BouncyButton("Tap Me") {
            print("Tapped!")
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(.blue))
        .foregroundColor(.white)

        // More pronounced bounce (like login button)
        BouncyButton("Sign in with Apple", scaleAmount: 0.9) {
            print("Sign in tapped!")
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(.black))
        .foregroundColor(.white)

        // Custom content
        BouncyButton(scaleAmount: 0.9) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                Text("Custom Button")
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(Capsule().fill(.green))
            .foregroundColor(.white)
        } action: {
            print("Custom tapped!")
        }

        // Using SF Symbol convenience initializer
        BouncyButton("Favorites", systemImage: "star.fill") {
            print("Favorites tapped!")
        }
        .frame(height: 56)
        .frame(maxWidth: .infinity)
        .background(Capsule().fill(.orange))
        .foregroundColor(.white)
    }
    .padding()
}
