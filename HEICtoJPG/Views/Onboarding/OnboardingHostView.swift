//
//  OnboardingHostView.swift
//  AppFast
//
//  Created by AppFast on 2025-11-08.
//

import SwiftUI
import SuperwallKit

/// Unified onboarding container that manages all persistent UI elements
/// Content changes dynamically based on current step while UI chrome remains consistent
struct OnboardingHostView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header: Back button + Progress bar
            if stepConfig.showHeader {
                headerView
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
            }

            // Title and subtitle (hidden for welcome screen)
            if stepConfig.showTitleSection {
                VStack(alignment: .leading, spacing: 8) {
                    Text(stepConfig.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    if let subtitle = stepConfig.subtitle {
                        Text(subtitle)
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText())
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 32)
                .padding(.bottom, 16)
            }

            // Main content area - changes based on step
            VStack(spacing: 0) {
                stepContent
                    .padding(.horizontal, 20)
                    .padding(.top, stepConfig.showTitleSection ? 16 : 0)
            }

            Spacer(minLength: 0)

            // Bottom action buttons
            bottomButtons
        }
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea())
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.currentStep)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(spacing: 12) {
            // Back button
            if stepConfig.showBackButton {
                Button(action: {
                    HapticManager.shared.softImpact()

                    // If on first onboarding screen, dismiss back to welcome
                    if viewModel.currentStep == .heicToJpg {
                        dismiss()
                    } else {
                        viewModel.previousStep()
                    }
                }) {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .buttonStyle(BounceButtonStyle())
            } else {
                Spacer()
                    .frame(width: 32, height: 32)
            }

            // Progress bar
            if stepConfig.showProgress {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(.systemGray5))
                            .frame(height: 4)

                        // Fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                            .frame(width: geometry.size.width * stepConfig.progress, height: 4)
                            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: stepConfig.progress)
                    }
                }
                .frame(height: 4)
            }
        }
        .frame(height: 32)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .heicToJpg:
            HEICtoJPGContent()
        case .multipleFormats:
            MultipleFormatsContent()
        case .conversionHistory:
            ConversionHistoryContent()
        case .review:
            ReviewContent()
        case .paywall:
            PaywallContent()
        }
    }

    // MARK: - Bottom Buttons

    @ViewBuilder
    private var bottomButtons: some View {
        if stepConfig.showContinueButton {
            VStack(spacing: 0) {
                OnboardingContinueButton(
                    title: stepConfig.continueButtonTitle,
                    isEnabled: stepConfig.canProceed,
                    action: {
                        HapticManager.shared.softImpact()

                        if let customAction = stepConfig.customAction {
                            customAction()
                        } else {
                            viewModel.nextStep()
                        }
                    }
                )
                .padding(.top, 16)
            }
            .padding(.bottom, 8)
        }
    }

    // MARK: - Step Configuration

    private var stepConfig: StepConfiguration {
        StepConfiguration(for: viewModel.currentStep, viewModel: viewModel)
    }
}

// MARK: - Step Configuration

/// Configuration for each onboarding step's UI chrome
private struct StepConfiguration {
    let title: String
    let subtitle: String?
    let showHeader: Bool
    let showTitleSection: Bool
    let showBackButton: Bool
    let showProgress: Bool
    let progress: Double
    let showContinueButton: Bool
    let continueButtonTitle: String
    let canProceed: Bool
    let customAction: (() -> Void)?
    let showSkipButton: Bool

    init(for step: OnboardingStep, viewModel: OnboardingViewModel) {
        switch step {
        case .heicToJpg:
            self.title = "Convert HEIC to JPG"
            self.subtitle = "Transform your iPhone photos to universal format"
            self.showHeader = true
            self.showTitleSection = true
            self.showBackButton = true
            self.showProgress = true
            self.progress = step.progress
            self.showContinueButton = true
            self.continueButtonTitle = "Continue"
            self.canProceed = true
            self.customAction = nil
            self.showSkipButton = false

        case .multipleFormats:
            self.title = "Multiple Formats"
            self.subtitle = "Convert to JPG, PNG, and more"
            self.showHeader = true
            self.showTitleSection = true
            self.showBackButton = true
            self.showProgress = true
            self.progress = step.progress
            self.showContinueButton = true
            self.continueButtonTitle = "Continue"
            self.canProceed = true
            self.customAction = nil
            self.showSkipButton = false

        case .conversionHistory:
            self.title = "Conversion History"
            self.subtitle = "Track all your conversions in one place"
            self.showHeader = true
            self.showTitleSection = true
            self.showBackButton = true
            self.showProgress = true
            self.progress = step.progress
            self.showContinueButton = true
            self.continueButtonTitle = "Continue"
            self.canProceed = true
            self.customAction = nil
            self.showSkipButton = false

        case .review:
            self.title = "Enjoying \(AppConstants.appName)?"
            self.subtitle = "Rate us on the App Store"
            self.showHeader = true
            self.showTitleSection = true
            self.showBackButton = true
            self.showProgress = true
            self.progress = step.progress
            self.showContinueButton = true
            self.continueButtonTitle = "Continue"
            self.canProceed = viewModel.canProceedFromReview
            self.customAction = nil
            self.showSkipButton = false

        case .paywall:
            self.title = "Get Started Converting"
            self.subtitle = "Choose your plan"
            self.showHeader = true
            self.showTitleSection = true
            self.showBackButton = true
            self.showProgress = true
            self.progress = 1.0
            self.showContinueButton = false
            self.continueButtonTitle = ""
            self.canProceed = false
            self.customAction = nil
            self.showSkipButton = false
        }
    }
}

#Preview {
    OnboardingHostView()
        .environmentObject(OnboardingViewModel())
}
