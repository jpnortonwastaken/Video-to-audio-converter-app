//
//  ConversionResultView.swift
//  HEIC to JPG
//
//  Created by Claude on 11/15/25.
//

import SwiftUI
import Photos

struct ConversionResultView: View {
    let convertedImageData: Data
    let format: ImageFormat
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""

    var convertedImage: UIImage? {
        UIImage(data: convertedImageData)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, geometry.safeAreaInsets.top)

                // Converted Image Preview
                ScrollView {
                    VStack(spacing: 24) {
                        if let image = convertedImage {
                            VStack(spacing: 16) {
                                // Success Message
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.green)

                                    Text("Converted to \(format.displayName)")
                                        .font(.headline)
                                        .foregroundColor(colorScheme == .dark ? .white : .black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color.green.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                )

                                // Image Preview
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4), lineWidth: 0.5)
                                    )

                                // File Info
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Format")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(format.displayName)
                                            .font(.headline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 4) {
                                        Text("Size")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(formatFileSize(convertedImageData.count))
                                            .font(.headline)
                                            .foregroundColor(colorScheme == .dark ? .white : .black)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 160)
                }
                .gradientFadeMask()

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    // Share Button
                    Button(action: shareImage) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.headline)
                            Text("Share")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                        )
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                    }
                    .buttonStyle(ScaleDownButtonStyle())

                    // Save to Photos Button
                    Button(action: saveToPhotos) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.headline)
                            Text("Save to Photos")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                        )
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .buttonStyle(ScaleDownButtonStyle())

                    // Done Button
                    Button(action: {
                        HapticManager.shared.softImpact()
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .buttonStyle(ScaleDownButtonStyle())
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4), lineWidth: 0.5)
                )
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 32, x: 0, y: 16)
                .padding(.horizontal, 24)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .ignoresSafeArea()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            if let image = convertedImage {
                ShareSheet(items: [createShareableFile()])
            }
        }
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK") {
                HapticManager.shared.softImpact()
            }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                HapticManager.shared.softImpact()
            }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack(spacing: 12) {
            Button(action: {
                HapticManager.shared.softImpact()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            Text("Conversion Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
    }

    // MARK: - Actions
    private func shareImage() {
        HapticManager.shared.softImpact()
        showShareSheet = true
    }

    private func saveToPhotos() {
        HapticManager.shared.softImpact()

        guard let image = convertedImage else {
            errorMessage = "Failed to load image"
            showError = true
            return
        }

        // Request photo library permission
        PHPhotoLibrary.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .authorized {
                    // Save image to photo library
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    HapticManager.shared.success()
                    successMessage = "Image saved to Photos"
                    showSuccessMessage = true
                } else {
                    HapticManager.shared.error()
                    errorMessage = "Permission denied. Please enable photo library access in Settings."
                    showError = true
                }
            }
        }
    }

    private func createShareableFile() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "converted_\(Date().timeIntervalSince1970).\(format.fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try convertedImageData.write(to: fileURL)
        } catch {
            print("❌ Failed to write temp file: \(error)")
        }

        return fileURL
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
