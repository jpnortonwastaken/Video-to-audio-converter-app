//
//  ConversionResultView.swift
//  HEIC to JPG
//
//  Created by Claude on 11/15/25.
//

import SwiftUI
import Photos

enum ConversionResultDisplayMode {
    case thumbnail  // Square thumbnail with rounded corners (for direct conversions)
    case fullImage  // Full aspect ratio image (for history items)
}

struct ConversionResultView: View {
    let convertedImageData: Data
    let format: ImageFormat
    let displayMode: ConversionResultDisplayMode
    let onDismiss: (() -> Void)?
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

    // Default initializer with thumbnail mode
    init(convertedImageData: Data, format: ImageFormat, displayMode: ConversionResultDisplayMode = .thumbnail, onDismiss: (() -> Void)? = nil) {
        self.convertedImageData = convertedImageData
        self.format = format
        self.displayMode = displayMode
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Header
                headerView
                    .padding(.top, geometry.safeAreaInsets.top)

                // Converted Image Preview
                if let image = convertedImage {
                    switch displayMode {
                    case .thumbnail:
                        // Square thumbnail with rounded corners (like ConverterView)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 350, height: 350)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.top, 20)

                    case .fullImage:
                        // Full aspect ratio image (for history items)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 24)
                            .padding(.top, 20)
                    }
                }
                .padding(.bottom, 24)

                Spacer()

                // File Info and Action Buttons
                VStack(spacing: 16) {
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

                    // Share and Save Buttons (side by side)
                    HStack(spacing: 12) {
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
                                Text("Save")
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
                    }

                    // Done Button
                    Button(action: {
                        HapticManager.shared.softImpact()
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
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
            if convertedImage != nil {
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
        ZStack {
            // Back button on left
            HStack {
                Button(action: {
                    HapticManager.shared.softImpact()
                    if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "arrow.backward")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .buttonStyle(ScaleDownButtonStyle())

                Spacer()
            }

            // Centered title
            Text("Conversion Complete")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .allowsHitTesting(false)
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

        // Request photo library permission (using modern API)
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized, .limited:
                    // Save image to photo library using modern API
                    PHPhotoLibrary.shared().performChanges({
                        PHAssetCreationRequest.creationRequestForAsset(from: image)
                    }) { success, error in
                        DispatchQueue.main.async {
                            if success {
                                HapticManager.shared.success()
                                successMessage = "Image saved to Photos"
                                showSuccessMessage = true
                            } else {
                                HapticManager.shared.error()
                                errorMessage = error?.localizedDescription ?? "Failed to save image"
                                showError = true
                            }
                        }
                    }
                case .denied, .restricted:
                    HapticManager.shared.error()
                    errorMessage = "Permission denied. Please enable photo library access in Settings."
                    showError = true
                case .notDetermined:
                    HapticManager.shared.error()
                    errorMessage = "Permission not determined. Please try again."
                    showError = true
                @unknown default:
                    HapticManager.shared.error()
                    errorMessage = "Unknown authorization status"
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
