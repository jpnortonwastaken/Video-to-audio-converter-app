//
//  ConverterView.swift
//  HEIC to JPG
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import PhotosUI

struct ConverterView: View {
    @StateObject private var viewModel = ConverterViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showImage = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                VStack(spacing: 32) {
                    // Input Options or Image Preview
                        if let selectedImage = viewModel.selectedImage {
                            // Image Preview
                            imagePreviewView(image: selectedImage)
                                .padding(.horizontal, 24)
                                .scaleEffect(showImage ? 1.0 : 0.3)
                                .opacity(showImage ? 1.0 : 0.0)
                        } else {
                            // Input Options
                            VStack(spacing: 16) {
                                // Title
                                Text("Convert to any format")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                                    .padding(.bottom, 8)

                                // Photos Option
                                inputOptionCard(
                                    title: "Photos",
                                    subtitle: "Choose from Photos",
                                    icon: "photo.on.rectangle",
                                    backgroundColor: Color.pink.opacity(0.1),
                                    iconColor: .pink
                                ) {
                                    viewModel.selectFromPhotos()
                                }

                                // Files and Paste Row
                                HStack(spacing: 16) {
                                    // Files Option
                                    smallInputOptionCard(
                                        title: "Files",
                                        subtitle: "Pick from Files",
                                        icon: "folder.fill",
                                        backgroundColor: Color.blue.opacity(0.1),
                                        iconColor: .blue
                                    ) {
                                        viewModel.selectFromFiles()
                                    }

                                    // Paste Option
                                    smallInputOptionCard(
                                        title: "Paste",
                                        subtitle: "Paste an image",
                                        icon: "doc.on.clipboard.fill",
                                        backgroundColor: Color.orange.opacity(0.1),
                                        iconColor: .orange
                                    ) {
                                        viewModel.pasteImage()
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer()

                        // Format Selector and Convert Button
                        VStack(spacing: 16) {
                            // Format Selector
                            formatSelectorView

                            // Convert Button
                            convertButton
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                }
                .padding(.top, 20)
                .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .navigationBarHidden(true)
        }
        .photosPicker(
            isPresented: $viewModel.showPhotoPicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .images
        )
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadPhotoPickerItem()
            }
        }
        .onChange(of: viewModel.selectedImage) { _, newValue in
            if newValue != nil {
                // Reset animation state
                showImage = false
                // Trigger bouncy animation with spring
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showImage = true
                }
            } else {
                showImage = false
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(AppConstants.appName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
    }

    // MARK: - Input Option Card (Large)
    private func inputOptionCard(
        title: String,
        subtitle: String,
        icon: String,
        backgroundColor: Color,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 50))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Input Option Card (Small)
    private func smallInputOptionCard(
        title: String,
        subtitle: String,
        icon: String,
        backgroundColor: Color,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Format Selector
    private var formatSelectorView: some View {
        HStack {
            Text("Format")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            Spacer()

            // Dropdown button
            Menu {
                ForEach(ImageFormat.allCases) { format in
                    Button(action: {
                        HapticManager.shared.softImpact()
                        viewModel.selectedFormat = format
                    }) {
                        HStack {
                            Text(format.displayName)
                            if viewModel.selectedFormat == format {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(viewModel.selectedFormat.displayName)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.1))
        )
    }

    // MARK: - Convert Button
    private var convertButton: some View {
        Button(action: {
            Task {
                await viewModel.convertImage()
            }
        }) {
            HStack {
                if viewModel.isConverting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Convert")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black)
            )
            .foregroundColor(.white)
            .opacity(viewModel.selectedImage == nil || viewModel.isConverting ? 0.5 : 1.0)
        }
        .disabled(viewModel.selectedImage == nil || viewModel.isConverting)
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Image Preview
    private func imagePreviewView(image: UIImage) -> some View {
        ZStack(alignment: .topTrailing) {
            // Image
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 336) // Same total height as the three buttons
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .clipped()

            // X button
            Button(action: {
                HapticManager.shared.softImpact()
                viewModel.reset()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.6))
                    )
            }
            .padding(12)
        }
    }

    // MARK: - File Selection Handler
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Load image from file URL
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }

                if let data = try? Data(contentsOf: url),
                   let image = UIImage(data: data) {
                    viewModel.selectedImage = image
                }
            }

        case .failure(let error):
            viewModel.errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }
}

#Preview {
    ConverterView()
}
