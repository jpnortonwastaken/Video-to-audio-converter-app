//
//  SettingsView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI
import Auth

struct SettingsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var onboardingViewModel: OnboardingViewModel
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    @State private var showingNameEditor = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingFeedback = false
    @State private var showingDeleteAccountError = false
    @State private var deleteAccountErrorMessage = ""
    @AppStorage("appearance_preference") private var appearancePreference: AppearancePreference = .system
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Settings Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Settings")
                            .font(.largeTitle)
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
                        // User Profile Section
                        SettingsSection(title: "Profile") {
                            SettingsCard(
                                icon: "person.fill",
                                title: userProfileViewModel.displayNameOrPlaceholder,
                                subtitle: {
                                    if let user = SupabaseService.shared.currentUser {
                                        return "Member since \(memberSinceText(user.createdAt))"
                                    } else {
                                        return "Not signed in"
                                    }
                                }(),
                                iconColor: .primary,
                                showChevron: true
                            ) {
                                HapticManager.shared.buttonTap()
                                showingNameEditor = true
                            }
                        }

                        // Preferences Section
                        SettingsSection(title: "Preferences") {
                            VStack(spacing: 0) {
                                AppearanceSettingsCard()
                            }
                        }

                        // Support Section
                        SettingsSection(title: "Support") {
                            VStack(spacing: 0) {
                                SettingsCard(
                                    icon: "envelope.fill",
                                    title: "Send Feedback",
                                    subtitle: "Share your thoughts and suggestions",
                                    iconColor: .primary,
                                    showChevron: true
                                ) {
                                    HapticManager.shared.buttonTap()
                                    showingFeedback = true
                                }
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

                                Divider()
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

                        // Account Section
                        SettingsSection(title: "Account") {
                            VStack(spacing: 0) {
                                SettingsCard(
                                    icon: "rectangle.portrait.and.arrow.right.fill",
                                    title: "Logout",
                                    subtitle: "",
                                    iconColor: .red,
                                    showChevron: false
                                ) {
                                    HapticManager.shared.buttonTap()
                                    showingSignOutAlert = true
                                }

                                Divider()
                                    .padding(.horizontal, 16)

                                SettingsCard(
                                    icon: "trash.fill",
                                    title: "Delete Account",
                                    subtitle: "Permanently delete your account and all data",
                                    iconColor: .red,
                                    showChevron: false
                                ) {
                                    HapticManager.shared.buttonTap()
                                    showingDeleteAccountAlert = true
                                }
                            }
                        }

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
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .contentTransition(.numericText())

                                Text("Version \(AppConstants.appVersion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .contentTransition(.numericText())

                                HStack(spacing: 4) {
                                    Image(systemName: "heart.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)

                                    Text("Built with Love")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .contentTransition(.numericText())
                                }

                                // APP BY JP with sheen animation
                                Text("APP BY JP")
                                    .font(.caption)
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
            .sheet(isPresented: $showingNameEditor) {
                NameEditorView(currentName: userProfileViewModel.displayName) { newName in
                    Task {
                        await userProfileViewModel.updateDisplayName(newName)
                    }
                }
                .presentationCornerRadius(32)
            }
            .sheet(isPresented: $showingFeedback) {
                FeedbackView(isPresented: $showingFeedback)
                    .presentationCornerRadius(32)
            }
            .alert("Are you sure?", isPresented: $showingSignOutAlert) {
                Button("Logout", role: .destructive) {
                    Task {
                        await authViewModel.signOut()
                        await MainActor.run {
                            onboardingViewModel.resetOnboardingCompletion()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("You will be logged out of your account.")
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        do {
                            try await authViewModel.deleteAccount()
                            await MainActor.run {
                                onboardingViewModel.resetOnboardingCompletion()
                            }
                        } catch {
                            deleteAccountErrorMessage = error.localizedDescription
                            showingDeleteAccountError = true
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This action is permanent and cannot be undone. All your data and account information will be permanently deleted.")
            }
            .alert("Delete Account Failed", isPresented: $showingDeleteAccountError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(deleteAccountErrorMessage)
            }
        }
    }

    private func memberSinceText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
                .font(.headline)
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
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                    .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
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
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .contentTransition(.numericText())
                    }
                }

                Spacer()

                if let trailingIcon = trailingIcon {
                    Image(systemName: trailingIcon)
                        .font(.body)
                        .foregroundColor(.secondary)
                } else if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.body)
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
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
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
                    .font(.body)
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
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.callout)
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
