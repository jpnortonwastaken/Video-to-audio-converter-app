//
//  PaywallPlaceholderView.swift
//  AppFast
//
//  Created on 2025-11-07.
//

import SwiftUI
import SuperwallKit

struct PaywallPlaceholderView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.yellow, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Unlock Premium")
                .font(.system(size: 34, weight: .bold))
                .padding(.top, 24)

            Text("Get access to all features")
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .padding(.top, 8)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "checkmark.circle.fill", text: "Personalized meal plans")
                FeatureRow(icon: "checkmark.circle.fill", text: "AI-powered recommendations")
                FeatureRow(icon: "checkmark.circle.fill", text: "Track your progress")
                FeatureRow(icon: "checkmark.circle.fill", text: "Unlimited access")
            }
            .padding(.top, 32)

            Spacer()

            VStack(spacing: 12) {
                Text("Superwall integration goes here")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .italic()

                OnboardingContinueButton(title: "Continue to Login") {
                    viewModel.nextStep()
                }

                Button(action: {
                    viewModel.nextStep()
                }) {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, 20)
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
        .navigationBarBackButtonHidden(true)
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)

            Text(text)
                .font(.system(size: 17))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    PaywallPlaceholderView()
        .environmentObject(OnboardingViewModel())
}
