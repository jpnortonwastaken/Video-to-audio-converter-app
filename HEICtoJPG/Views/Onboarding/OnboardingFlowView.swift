//
//  OnboardingFlowView.swift
//  AppFast
//
//  Created on 2025-11-07.
//

import SwiftUI
import SuperwallKit

struct OnboardingFlowView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showOnboardingFlow = false

    var body: some View {
        NavigationStack {
            WelcomeScreenView(showOnboardingFlow: $showOnboardingFlow)
                .navigationDestination(isPresented: $showOnboardingFlow) {
                    OnboardingHostView()
                        .navigationBarBackButtonHidden(true)
                }
                .navigationBarHidden(true)
        }
    }
}

// Standalone welcome screen
struct WelcomeScreenView: View {
    @Binding var showOnboardingFlow: Bool
    @EnvironmentObject var viewModel: OnboardingViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var showIcon = false
    @State private var showTitle = false
    @State private var showMessage = false
    @State private var showButton = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(alignment: .center, spacing: 0) {
                // App Icon
                Image("WelcomeScreenAppIcon")
                    .resizable()
                    .frame(width: 160, height: 160)
                    .cornerRadius(32)
                    .padding(.bottom, 32)
                    .opacity(showIcon ? 1 : 0)
                    .offset(y: showIcon ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showIcon)

                // Title
                Text(AppConstants.appName)
                    .font(.roundedSystem(size: 28, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showTitle)

                // Welcome message
                Text("Convert your photos instantly.")
                    .font(.roundedSystem(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .opacity(showMessage ? 1 : 0)
                    .offset(y: showMessage ? 0 : 20)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showMessage)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 20)
            .padding(.top, 60)
            .padding(.bottom, 40)

            // Get Started Button
            Button(action: {
                HapticManager.shared.softImpact()
                showOnboardingFlow = true
            }) {
                Text("Get Started")
                    .font(.roundedSystem(size: 17, weight: .semibold))
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                    )
            }
            .buttonStyle(BounceButtonStyle(scaleAmount: 0.9))
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 34)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showButton)
        }
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea())
        .onAppear {
            playAnimations()
        }
    }

    private func playAnimations() {
        // Staggered fade-in animations with tighter timing for faster flow
        // Using direct state changes - .animation() modifiers on views handle the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            showIcon = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showTitle = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            showButton = true
        }
    }
}

#Preview {
    OnboardingFlowView()
}
