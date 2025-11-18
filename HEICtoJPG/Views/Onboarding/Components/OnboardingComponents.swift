//
//  OnboardingComponents.swift
//  AppFast
//
//  Created on 2025-11-07.
//

import SwiftUI

// MARK: - Reusable Components

// Reusable selection card component
struct SelectionCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let icon: String?
    let iconColor: Color?
    let isSystemIcon: Bool
    let needsWhiteBackground: Bool
    let isSelected: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        isSystemIcon: Bool = false,
        needsWhiteBackground: Bool = false,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.isSystemIcon = isSystemIcon
        self.needsWhiteBackground = needsWhiteBackground
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.softImpact()
            action()
        }) {
            HStack(spacing: 12) {
                if let icon = icon {
                    if isSystemIcon {
                        // SF Symbol - adapts to light/dark mode
                        Image(systemName: icon)
                            .font(.roundedSystem(size: 20))
                            .foregroundColor(iconColor ?? .primary)
                            .frame(width: 28)
                    } else {
                        // Asset image - rendered as-is
                        ZStack {
                            if needsWhiteBackground {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 28, height: 28)
                            }

                            Image(icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: needsWhiteBackground ? 22 : 28, height: needsWhiteBackground ? 22 : 28)
                        }
                        .frame(width: 28, height: 28)
                    }
                }

                Text(title)
                    .font(.roundedSystem(size: 17))
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                isSelected ? Color.primary : (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)),
                                lineWidth: isSelected ? 2 : 0.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
            )
        }
        .buttonStyle(BounceButtonStyle(scaleAmount: 0.98))
    }
}

// Reusable continue button
struct OnboardingContinueButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    init(title: String = "Continue", isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticManager.shared.softImpact()
            action()
        }) {
            Text(title)
                .font(.roundedSystem(size: 17, weight: .semibold))
                .foregroundColor(isEnabled ? Color(.systemBackground) : Color(.systemBackground).opacity(0.5))
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(isEnabled ? Color.primary : Color.primary.opacity(0.3))
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEnabled)
                )
        }
        .disabled(!isEnabled)
        .buttonStyle(BounceButtonStyle())
        .padding(.horizontal, 20)
    }
}
