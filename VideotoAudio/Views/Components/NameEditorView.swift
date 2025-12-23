//
//  NameEditorView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct NameEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name: String
    @FocusState private var isTextFieldFocused: Bool

    let onSave: (String) -> Void

    init(currentName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: currentName)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Header
            ZStack {
                // Title (centered)
                Text("Edit Name")
                    .font(.roundedHeadline())
                    .fontWeight(.semibold)

                // Close button (left)
                HStack {
                    Button(action: {
                        HapticManager.shared.buttonTap()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.roundedSystem(size: 14, weight: .semibold))
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
                Text("Name")
                    .font(.roundedSubheadline())
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                TextField("Enter your name", text: $name)
                    .font(.roundedBody())
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(.systemGray4), lineWidth: 0.5)
                            )
                    )
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        saveName()
                    }

                Spacer()

                // Save Button
                Button(action: {
                    saveName()
                }) {
                    Text("Save")
                        .font(.roundedHeadline())
                        .foregroundColor(Color(.systemBackground))
                        .contentTransition(.numericText())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray.opacity(0.5) : Color.primary)
                        )
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(BounceButtonStyle(scaleAmount: 0.97))
                .padding(.bottom, 24)
            }
            .padding(.horizontal, 24)
        }
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
        .onAppear {
            isTextFieldFocused = true
        }
    }

    private func saveName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            HapticManager.shared.buttonTap()
            onSave(trimmedName)
        }
        dismiss()
    }
}

#Preview {
    NameEditorView(currentName: "John Doe") { newName in
        debugPrint("New name: \(newName)")
    }
}
