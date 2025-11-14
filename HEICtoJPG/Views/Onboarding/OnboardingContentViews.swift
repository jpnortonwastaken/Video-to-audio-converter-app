//
//  OnboardingContentViews.swift
//  HEIC to JPG
//
//  Created by Claude on 11/13/25.
//

import SwiftUI
import SuperwallKit
import StoreKit

// MARK: - HEIC to JPG Content

struct HEICtoJPGContent: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "photo.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)

                // Description
                Text("Convert your iPhone photos from HEIC to JPG format with ease.")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Multiple Formats Content

struct MultipleFormatsContent: View {
    @State private var isVisible = false

    let formats = ["JPG", "PNG", "HEIF", "PDF"]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "rectangle.3.group.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)

                // Format chips
                HStack(spacing: 12) {
                    ForEach(Array(formats.enumerated()), id: \.element) { index, format in
                        Text(format)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemGray5))
                            )
                            .opacity(isVisible ? 1 : 0)
                            .scaleEffect(isVisible ? 1 : 0.8)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2 + Double(index) * 0.05), value: isVisible)
                    }
                }

                // Description
                Text("Convert images between multiple formats to suit your needs.")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.4), value: isVisible)
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Conversion History Content

struct ConversionHistoryContent: View {
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Icon
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 80))
                    .foregroundColor(.orange)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)

                // Description
                Text("Keep track of all your conversions in one convenient place.")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Review Content

struct ReviewContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                // Star rating display
                HStack(spacing: 4) {
                    ForEach(0..<5) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.yellow)
                    }
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)

                // Title
                Text("Enjoying \(AppConstants.appName)?")
                    .font(.system(size: 24, weight: .bold))
                    .multilineTextAlignment(.center)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)

                // Description
                Text("We'd love to hear from you! Rate us on the App Store.")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .opacity(isVisible ? 1 : 0)
                    .offset(y: isVisible ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)
            }

            Spacer()
        }
        .onAppear {
            isVisible = true

            // After 3 seconds, enable the continue button and request review
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                viewModel.canProceedFromReview = true
                viewModel.requestReview()
            }
        }
    }
}

// MARK: - Paywall Content

struct PaywallContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)

                // Main message
                VStack(spacing: 16) {
                    Text("Get Started Converting Now")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2), value: isVisible)

                    Text("Unlock unlimited conversions and premium features")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .opacity(isVisible ? 1 : 0)
                        .offset(y: isVisible ? 0 : 20)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isVisible)
                }
            }

            Spacer()
        }
        .onAppear {
            isVisible = true

            // Show paywall immediately after brief delay for animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                let handler = PaywallPresentationHandler()
                handler.onDismiss { paywallInfo, result in
                    // After paywall is dismissed, complete onboarding
                    viewModel.completeOnboarding()
                }

                Superwall.shared.register(placement: "campaign_trigger", handler: handler)
            }
        }
    }
}

#Preview {
    HEICtoJPGContent()
}
