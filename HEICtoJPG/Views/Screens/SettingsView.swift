//
//  SettingsView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @AppStorage("appearance_preference") private var appearancePreference: AppearancePreference = .system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.roundedLargeTitle())
                            .fontWeight(.bold)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))

                // Settings Content
                ScrollView {
                    VStack(spacing: 32) {
                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            VStack(spacing: 0) {
                                AppearanceSettingsCard()
                            }
                        }

                        // Legal Section
                        SettingsSection(title: "Legal") {
                            VStack(spacing: 0) {
                                SettingsCard(
                                    icon: "doc.text.fill",
                                    title: "Privacy Policy",
                                    subtitle: "",
                                    iconColor: .primary,
                                    showChevron: false,
                                    trailingIcon: "arrow.up.right"
                                ) {
                                    HapticManager.shared.buttonTap()
                                    if let url = URL(string: AppConstants.privacyPolicyURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }

                                // Dotted divider line
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 1)
                                    .overlay(
                                        GeometryReader { geometry in
                                            Path { path in
                                                path.move(to: CGPoint(x: 0, y: 0))
                                                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                                            }
                                            .stroke(
                                                (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                                            )
                                        }
                                    )
                                    .padding(.horizontal, 16)

                                SettingsCard(
                                    icon: "doc.plaintext.fill",
                                    title: "Terms of Service",
                                    subtitle: "",
                                    iconColor: .primary,
                                    showChevron: false,
                                    trailingIcon: "arrow.up.right"
                                ) {
                                    HapticManager.shared.buttonTap()
                                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }
                        }

                        // Debug Section
                        #if DEBUG
                        SettingsSection(title: "Debug") {
                            VStack(spacing: 0) {
                                SettingsCard(
                                    icon: "arrow.counterclockwise",
                                    title: "Reset Onboarding",
                                    subtitle: "Show onboarding flow again",
                                    iconColor: .orange,
                                    showChevron: false
                                ) {
                                    HapticManager.shared.buttonTap()
                                    onboardingViewModel.resetOnboarding()
                                }
                            }
                        }
                        #endif

                        // App info at bottom
                        VStack(spacing: 12) {
                            // App Icon
                            Image("WelcomeScreenAppIcon")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .shadow(
                                    color: .black.opacity(0.1),
                                    radius: 3,
                                    x: 0,
                                    y: 1
                                )

                            VStack(spacing: 8) {
                                Text(AppConstants.appDisplayName)
                                    .font(.roundedBody())
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .contentTransition(.numericText())

                                Text("Version \(AppConstants.appVersion)")
                                    .font(.roundedCaption())
                                    .foregroundColor(.secondary)
                                    .contentTransition(.numericText())

                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.roundedCaption())
                                        .foregroundColor(.red)

                                    Text("Built with Love")
                                        .font(.roundedCaption())
                                        .foregroundColor(.secondary)
                                        .contentTransition(.numericText())
                                }

                                // APP BY JP with sheen animation
                                Text("APP BY JP")
                                    .font(.roundedCaption())
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .secondary.opacity(0.3) : .secondary)
                                    .contentTransition(.numericText())
                                    .modifier(SheenEffect())
                                    .padding(.top, 4)
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, 32)
                        .padding(.bottom, 16)
                    }
                    .padding(24)
                    .padding(.top, 20)
                    .padding(.bottom, 100)
                }
                .gradientFadeMask()
                .scrollIndicators(.hidden)
                .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.roundedHeadline())
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .contentTransition(.numericText())
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 0) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                    )
            )
        }
    }
}

struct SettingsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let showChevron: Bool
    var trailingIcon: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            action()
        }) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.roundedBody())
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.roundedCaption())
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText())
                    }
                }

                Spacer()

                if let trailingIcon = trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.roundedBody())
                        .foregroundColor(.secondary)
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.roundedBody())
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleDownButtonStyle())
    }
}

struct ToggleSettingsCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    @Binding var isOn: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.roundedBody())
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.roundedCaption())
                        .foregroundColor(.secondary)
                        .contentTransition(.numericText())
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(colorScheme == .dark ? Color(.systemGray) : .primary)
                .onChange(of: isOn) { _, _ in
                    HapticManager.shared.buttonTap()
                }
        }
        .padding()
        .background(Color.clear)
    }
}

struct AppearanceSettingsCard: View {
    @AppStorage("appearance_preference") private var appearancePreference: AppearancePreference = .system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "paintbrush.fill")
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text("Appearance")
                    .font(.roundedBody())
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }

            Spacer()

            Menu {
                ForEach(AppearancePreference.allCases, id: \.self) { mode in
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        appearancePreference = mode
                        updateAppearance(mode)
                    }) {
                        HStack {
                            Text(mode.displayName)
                            if appearancePreference == mode {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(appearancePreference.displayName)
                        .font(.roundedBody())
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.roundedCallout())
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray6))
                )
            }
        }
        .padding()
        .background(Color.clear)
    }

    private func updateAppearance(_ preference: AppearancePreference) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        switch preference {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// Sheen Effect Modifier
struct SheenEffect: ViewModifier {
    @State private var animationOffset: CGFloat = -1
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        sheenColor.opacity(0.6),
                        sheenColor.opacity(0.8),
                        sheenColor.opacity(0.6),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 100)
                .offset(x: animationOffset * 300)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 3)
                        .repeatForever(autoreverses: false)
                ) {
                    animationOffset = 1
                }
            }
    }

    private var sheenColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

#Preview {
    SettingsView()
}
