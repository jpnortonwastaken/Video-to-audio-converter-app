//
//  OnboardingContentViews.swift
//  AppFast
//
//  Created by AppFast on 2025-11-08.
//

import SwiftUI
import AuthenticationServices
import SuperwallKit
import StoreKit

// MARK: - Welcome Content

struct WelcomeContent: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .leading, spacing: 0) {
                // App Icon
                Image("WelcomeScreenAppIcon")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)
                    .padding(.bottom, 16)

                // Title
                Text(AppConstants.appName)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                // Welcome message
                Text("Welcome. Let's build your apps fast.")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 50)
        }
        .frame(maxHeight: .infinity)
    }
}

// MARK: - Gender Selection Content

struct GenderSelectionContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                ForEach(Array(Gender.allCases.enumerated()), id: \.element) { index, gender in
                    SelectionCard(
                        title: gender.rawValue,
                        isSelected: viewModel.onboardingData.gender == gender
                    ) {
                        viewModel.onboardingData.gender = gender
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .offset(y: isVisible ? 0 : -20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isVisible)
                }
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Name & Age Content

struct NameAgeContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?
    @State private var isVisible = false

    enum Field {
        case name, age
    }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Name field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("Enter your name", text: $viewModel.onboardingData.name)
                        .font(.system(size: 17))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            focusedField == .name ? Color.primary : (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)),
                                            lineWidth: focusedField == .name ? 2 : 0.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
                        )
                        .focused($focusedField, equals: .name)
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .offset(y: isVisible ? 0 : -20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.0), value: isVisible)

                // Age field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)

                    TextField("Enter your age", text: $viewModel.onboardingData.age)
                        .font(.system(size: 17))
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            focusedField == .age ? Color.primary : (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)),
                                            lineWidth: focusedField == .age ? 2 : 0.5
                                        )
                                )
                                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                                .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
                        )
                        .focused($focusedField, equals: .age)
                }
                .opacity(isVisible ? 1 : 0)
                .scaleEffect(isVisible ? 1 : 0.8)
                .offset(y: isVisible ? 0 : -20)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: isVisible)
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
        .onTapGesture {
            focusedField = nil
        }
        .onChange(of: viewModel.currentStep) { oldValue, newValue in
            // Dismiss keyboard when navigating away from this step
            if oldValue == .nameAge && newValue != .nameAge {
                focusedField = nil
            }
        }
    }
}

// MARK: - Referral Source Content

struct ReferralSourceContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var shuffledSources: [ReferralSource] = []
    @State private var isVisible = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(Array(shuffledSources.enumerated()), id: \.element) { index, source in
                    SelectionCard(
                        title: source.rawValue,
                        icon: source.iconName,
                        iconColor: source.isSystemIcon ? .primary : nil,
                        isSystemIcon: source.isSystemIcon,
                        needsWhiteBackground: source.needsWhiteBackground,
                        isSelected: viewModel.onboardingData.referralSource == source
                    ) {
                        viewModel.onboardingData.referralSource = source
                        MixpanelService.shared.track(event: "Referral Source Selected", properties: ["source": source.rawValue])
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .offset(y: isVisible ? 0 : -20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.05), value: isVisible)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 48)
        }
        .padding(.horizontal, -20)
        .scrollIndicators(.hidden)
        .onAppear {
            if shuffledSources.isEmpty {
                // Separate "Other" from the rest
                let sourcesWithoutOther = ReferralSource.allCases.filter { $0 != .other }
                // Shuffle all except "Other"
                shuffledSources = sourcesWithoutOther.shuffled()
                // Always keep "Other" at the bottom
                shuffledSources.append(.other)
            }
            // Small delay to ensure view hierarchy is ready for animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                isVisible = true
            }
        }
    }
}

// MARK: - Cal AI Comparison Content

struct CalAIComparisonContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var isVisible = false

    let features = [
        ("AI Coaching", 0.4, 0.9),
        ("Accuracy", 0.6, 0.95),
        ("Easy to Use", 0.5, 0.92),
        ("Support", 0.3, 0.88)
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 24) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(feature.0)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            // Other Apps bar
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Other Apps")
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 32)

                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray3))
                                            .frame(width: geometry.size.width * feature.1, height: 32)
                                    }
                                }
                                .frame(height: 32)
                            }

                            // AppFast bar
                            VStack(alignment: .leading, spacing: 4) {
                                Text(AppConstants.appName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)

                                GeometryReader { geometry in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(.systemGray5))
                                            .frame(height: 32)

                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.accentColor)
                                            .frame(width: geometry.size.width * feature.2, height: 32)
                                    }
                                }
                                .frame(height: 32)
                            }
                        }
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .offset(y: isVisible ? 0 : -20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isVisible)
                }
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Goal Selection Content

struct GoalSelectionContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var isVisible = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                ForEach(Array(Goal.allCases.enumerated()), id: \.element) { index, goal in
                    SelectionCard(
                        title: goal.rawValue,
                        isSelected: viewModel.onboardingData.goal == goal
                    ) {
                        viewModel.onboardingData.goal = goal
                    }
                    .opacity(isVisible ? 1 : 0)
                    .scaleEffect(isVisible ? 1 : 0.8)
                    .offset(y: isVisible ? 0 : -20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1), value: isVisible)
                }
            }

            Spacer()
        }
        .onAppear {
            isVisible = true
        }
    }
}

// MARK: - Calculating Results Content

struct CalculatingResultsContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var progress: CGFloat = 0
    @State private var currentStep = 0
    @State private var percentage: Int = 0
    @State private var timer: Timer?

    let steps = [
        "Analyzing your profile...",
        "Calculating calorie goals...",
        "Customizing your plan...",
        "Preparing your experience..."
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Loading indicator
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.primary, lineWidth: 8)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: progress)

                // Percentage display
                Text("\(percentage)%")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
            }

            Text("Setting up your plan")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 32)

            Text(steps[currentStep])
                .font(.system(size: 17))
                .foregroundColor(.secondary)
                .padding(.top, 12)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: currentStep)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startCalculating()
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }

    private func startCalculating() {
        // Timing configuration: normal speed until 88%, slow for 88-96%, then fast again for 96-100%
        let normalInterval = 0.055 // 55ms per increment for 0-88% (slightly slower than before)
        let slowInterval = 0.25    // 250ms per increment for 88-96% (slower)
        let fastInterval = 0.05    // 50ms per increment for 96-100%

        var currentPercentage = 0

        // Use Timer for reliable 1-by-1 increments
        timer = Timer.scheduledTimer(withTimeInterval: normalInterval, repeats: true) { t in
            if currentPercentage <= 100 {
                percentage = currentPercentage

                // Update progress ring smoothly
                withAnimation(.linear(duration: normalInterval)) {
                    progress = CGFloat(currentPercentage) / 100.0
                }

                // Switch to slow interval at 88%
                if currentPercentage == 88 {
                    t.invalidate()
                    timer = Timer.scheduledTimer(withTimeInterval: slowInterval, repeats: true) { slowTimer in
                        if currentPercentage <= 100 {
                            percentage = currentPercentage
                            withAnimation(.linear(duration: slowInterval)) {
                                progress = CGFloat(currentPercentage) / 100.0
                            }

                            // Switch to fast interval at 96%
                            if currentPercentage == 96 {
                                slowTimer.invalidate()
                                timer = Timer.scheduledTimer(withTimeInterval: fastInterval, repeats: true) { fastTimer in
                                    if currentPercentage <= 100 {
                                        percentage = currentPercentage
                                        withAnimation(.linear(duration: fastInterval)) {
                                            progress = CGFloat(currentPercentage) / 100.0
                                        }
                                        currentPercentage += 1
                                    } else {
                                        fastTimer.invalidate()
                                    }
                                }
                            }

                            currentPercentage += 1
                        } else {
                            slowTimer.invalidate()
                        }
                    }
                }

                currentPercentage += 1
            } else {
                t.invalidate()
            }
        }

        // Update step text messages
        let stepTimings: [Double] = [0.0, 1.8, 3.6, 5.4]
        for (index, timing) in stepTimings.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + timing) {
                withAnimation {
                    currentStep = index
                }
            }
        }

        // Calculate total duration and move to next step
        let totalDuration = (88.0 * normalInterval) + (8.0 * slowInterval) + (4.0 * fastInterval)
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration + 0.5) {
            timer?.invalidate()
            viewModel.nextStep()
        }
    }
}

// MARK: - Rating Content

struct RatingContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var ratingWorkItem: DispatchWorkItem?

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Rating display card
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        // Left laurel
                        Image(systemName: "laurel.leading")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "EB9760"))

                        HStack(spacing: 4) {
                            Text("4.8")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)

                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color(hex: "EB9760"))
                            }
                        }

                        // Right laurel
                        Image(systemName: "laurel.trailing")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "EB9760"))
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
                .padding(.top, 24)

                // Title text
                Text("\(AppConstants.appName) was made for people like you")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                    .padding(.horizontal, 20)

                // Profile images
                HStack(spacing: -20) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: index == 0 ? "FF6B6B" : index == 1 ? "4ECDC4" : "45B7D1"),
                                        Color(hex: index == 0 ? "FF8E8E" : index == 1 ? "7EDDD8" : "6FCFE5")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                            .frame(width: 90, height: 90)
                            .overlay(
                                Circle()
                                    .stroke(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground), lineWidth: 4)
                            )
                    }
                }
                .padding(.top, 32)

                // First Testimonial card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        // Profile image
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                            .frame(width: 50, height: 50)

                        // Name
                        Text("Jake Sullivan")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "EB9760"))
                            }
                        }
                    }

                    // Review text
                    Text("I lost 15 lbs in 2 months! I was about to go on Ozempic but decided to give this app a shot and it worked :)")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
                .padding(.top, 32)

                // Second Testimonial card
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 12) {
                        // Profile image
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "F093FB"), Color(hex: "F5576C")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white.opacity(0.8))
                            )
                            .frame(width: 50, height: 50)

                        // Name
                        Text("Sarah Mitchell")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)

                        Spacer()

                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(0..<5) { _ in
                                Image(systemName: "star.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(hex: "EB9760"))
                            }
                        }
                    }

                    // Review text
                    Text("Best tracking app I've used! The interface is super intuitive and the insights actually help me stay on track with my goals.")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
                .padding(.top, 16)

                Spacer(minLength: 32)
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, -20)
        .scrollIndicators(.hidden)
        .onAppear {
            // Reset the timer when appearing
            viewModel.canProceedFromRating = false

            // Create a work item for the delayed action
            let workItem = DispatchWorkItem {
                // Request app rating from Apple
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }

                // Enable continue button
                withAnimation {
                    viewModel.canProceedFromRating = true
                }
            }

            // Store the work item so we can cancel it if needed
            ratingWorkItem = workItem

            // Wait 4 seconds, then show rating popup and enable continue button
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: workItem)
        }
        .onDisappear {
            // Cancel the delayed action if user navigates away before 4 seconds
            ratingWorkItem?.cancel()
            ratingWorkItem = nil
        }
    }
}

// MARK: - Paywall Content

struct PaywallContent: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme

    let features = [
        "Unlimited AI coaching",
        "Advanced analytics",
        "Custom meal plans",
        "Priority support"
    ]

    var body: some View {
        VStack(spacing: 24) {
            // Star icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
            .padding(.top, 20)

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.accentColor)

                        Text(feature)
                            .font(.system(size: 17))
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
            .padding(.top, 24)

            Spacer()

            // Skip button
            Button(action: {
                HapticManager.shared.softImpact()
                viewModel.nextStep()
            }) {
                Text("Skip for now")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(BounceButtonStyle())
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Create Account Content

struct CreateAccountContent: View {
    @EnvironmentObject var authManager: AuthViewModel
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showErrorAlert = false
    @State private var hasShownPaywallForSession = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                // Error message display
                if let errorMessage = authManager.errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.leading)
                            .contentTransition(.numericText())
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.red.opacity(0.1))
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                // Sign in with Apple Button
                Button(action: {
                    HapticManager.shared.softImpact()
                    Task {
                        do {
                            try await authManager.signInWithApple()
                            // After successful sign in, check authentication and show paywall
                            await MainActor.run {
                                // Only show paywall if user is actually authenticated
                                if authManager.isAuthenticated {
                                    presentPaywall()
                                }
                            }
                        } catch {
                            debugPrint("Apple Sign-In error: \(error.localizedDescription)")
                            showErrorAlert = true
                        }
                    }
                }) {
                    HStack(spacing: 8) {
                        if !authManager.isLoading {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 16, weight: .semibold))
                                .transition(.opacity)
                        }
                        Text(authManager.isLoading ? "Loading..." : "Sign in with Apple")
                            .font(.system(size: 15, weight: .semibold))
                            .contentTransition(.numericText())
                    }
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: authManager.isLoading)
                }
                .buttonStyle(BounceButtonStyle(scaleAmount: 0.9))
                .disabled(authManager.isLoading)
            }

            Spacer()
        }
        .frame(maxHeight: .infinity)
        .alert("Sign In Failed", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                authManager.errorMessage = nil
            }
        } message: {
            Text(authManager.errorMessage ?? "An unknown error occurred. Please try again.")
                .contentTransition(.numericText())
        }
    }

    private func presentPaywall() {
        // Present Superwall paywall after successful authentication
        Superwall.shared.register(placement: "campaign_trigger") {
            // Check if user has an active subscription
            Task { @MainActor in
                // Check subscription status from Superwall using isActive property
                let isSubscribed = Superwall.shared.subscriptionStatus.isActive

                if isSubscribed {
                    // User subscribed, proceed to the app
                    debugPrint("✅ User subscribed, completing onboarding")
                    viewModel.completeOnboarding()
                } else {
                    // User dismissed without subscribing, stay on Create account page
                    debugPrint("ℹ️ User did not subscribe, staying on Create account page")
                    // Don't sign them out - let them stay authenticated and try the paywall again
                }
            }
        }
    }
}

// MARK: - Hex Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
