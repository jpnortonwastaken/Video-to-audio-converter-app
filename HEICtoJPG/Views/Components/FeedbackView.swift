//
//  FeedbackView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Binding var isPresented: Bool
    @State private var feedbackText = ""
    @State private var showingSuccessAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isSending = false
    @State private var showProgress = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            ZStack {
                // Title (centered)
                Text("Send Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)

                // Close button (left)
                HStack {
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                    }
                    .buttonStyle(BounceButtonStyle(scaleAmount: 0.9))

                    Spacer()
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)

            // Content
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Feedback")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                ZStack(alignment: .topLeading) {
                    TextEditor(text: $feedbackText)
                        .focused($isFocused)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color(.systemGray4), lineWidth: 0.5)
                                )
                        )

                    if feedbackText.isEmpty {
                        Text("Share your thoughts, suggestions, or report any issues...")
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 20)
                            .allowsHitTesting(false)
                    }
                }
                .frame(minHeight: 200)

                Spacer()

                // Action Button
                Button(action: {
                    HapticManager.shared.buttonTap()
                    sendFeedback()
                }) {
                    HStack {
                        if showProgress {
                            SwiftUI.ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .tint(Color(.systemBackground))
                        } else {
                            Image(systemName: "paperplane.fill")
                            Text("Send Feedback")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(Color(.systemBackground))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(feedbackText.isEmpty || isSending ? Color.gray.opacity(0.5) : Color.primary)
                    )
                }
                .disabled(feedbackText.isEmpty || isSending)
                .buttonStyle(BounceButtonStyle(scaleAmount: 0.97))
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
        .alert("Thank You!", isPresented: $showingSuccessAlert) {
            Button("Done") {
                isPresented = false
            }
        } message: {
            Text("Your feedback has been sent successfully. We appreciate your input!")
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
                .contentTransition(.numericText())
        }
    }

    private func sendFeedback() {
        isSending = true
        isFocused = false

        // Delay showing progress to let button bounce animation complete
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000) // 0.35 seconds
            await MainActor.run {
                showProgress = true
            }
        }

        Task {
            // Simulate sending feedback (no backend)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

            await MainActor.run {
                isSending = false
                showProgress = false
                showingSuccessAlert = true
                feedbackText = ""
                HapticManager.shared.success()
            }
        }
    }
}

#Preview {
    FeedbackView(isPresented: .constant(true))
}
