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
    @State private var showFormatSheet = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.top, geometry.safeAreaInsets.top)

                    // Content area
                    VStack(alignment: .leading, spacing: 16) {
                        // Title (outside red border)
                        if viewModel.selectedImage == nil {
                            Text("Convert to any format")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Fixed-height content container (TESTING: Red border)
                        ZStack {
                            if let selectedImage = viewModel.selectedImage {
                                // Image Preview (inside fixed container)
                                imagePreviewView(image: selectedImage)
                                    .scaleEffect(showImage ? 1.0 : 0.3)
                                    .opacity(showImage ? 1.0 : 0.0)
                            } else {
                                // Input Options (inside fixed container)
                                VStack(spacing: 16) {
                                    // Photos Option
                                    inputOptionCard(
                                        title: "Photos",
                                        subtitle: "Choose from Photos",
                                        icon: "photo.on.rectangle",
                                        backgroundColor: Color.pink.opacity(0.1),
                                        iconColor: .pink,
                                        textColor: Color(red: 0.5, green: 0.1, blue: 0.25)
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
                                            iconColor: .blue,
                                            textColor: Color(red: 0.0, green: 0.2, blue: 0.5)
                                        ) {
                                            viewModel.selectFromFiles()
                                        }

                                        // Paste Option
                                        smallInputOptionCard(
                                            title: "Paste",
                                            subtitle: "Paste an image",
                                            icon: "doc.on.clipboard.fill",
                                            backgroundColor: Color.orange.opacity(0.1),
                                            iconColor: .orange,
                                            textColor: Color(red: 0.6, green: 0.3, blue: 0.0)
                                        ) {
                                            viewModel.pasteImage()
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: 350) // Fixed height to prevent movement
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    Spacer(minLength: 32)

                    // Format Selector and Convert Button (Pinned to Bottom)
                    VStack(spacing: 16) {
                        // Format Selector
                        formatSelectorView

                        // Convert Button
                        convertButton
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
        .sheet(isPresented: $showFormatSheet) {
            FormatSelectionSheet(
                selectedFormat: $viewModel.selectedFormat,
                isPresented: $showFormatSheet
            )
            .presentationDetents([.fraction(0.75)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Header
    private var headerView: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // App Icon
                Image("WelcomeScreenAppIcon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppConstants.appName)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 8)
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
    }

    // MARK: - Input Option Card (Large)
    private func inputOptionCard(
        title: String,
        subtitle: String,
        icon: String,
        backgroundColor: Color,
        iconColor: Color,
        textColor: Color,
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
                    .foregroundColor(textColor)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(textColor.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.2),
                                iconColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(iconColor, lineWidth: 1)
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
        textColor: Color,
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
                    .foregroundColor(textColor)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.2),
                                iconColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(iconColor, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Format Selector
    private var formatSelectorView: some View {
        Button(action: {
            HapticManager.shared.softImpact()
            showFormatSheet = true
        }) {
            HStack {
                Text("Format")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Spacer()

                HStack(spacing: 8) {
                    Text(viewModel.selectedFormat.displayName)
                        .font(.headline)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Image(systemName: "chevron.down")
                        .font(.body)
                        .foregroundColor(.gray)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
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
                        .tint(colorScheme == .dark ? .black : .white)
                } else {
                    Text("Convert")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(colorScheme == .dark ? Color.white : Color.black)
            )
            .foregroundColor(colorScheme == .dark ? .black : .white)
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
                .frame(width: 350, height: 350)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 20))

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
        .frame(width: 350, height: 350)
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

// MARK: - Format Selection Sheet
struct FormatSelectionSheet: View {
    @Binding var selectedFormat: ImageFormat
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Format Options
                ScrollView {
                    VStack(spacing: 0) {
                        // Spacing below drag indicator
                        Spacer()
                            .frame(height: 8)

                        VStack(spacing: 12) {
                            ForEach(ImageFormat.allCases) { format in
                                formatCard(for: format)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                }
            }
            .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
            .navigationBarHidden(true)
        }
    }

    // MARK: - Format Card
    private func formatCard(for format: ImageFormat) -> some View {
        let isSelected = selectedFormat == format
        let backgroundColor = isSelected
            ? (colorScheme == .dark ? Color.white : Color.black)
            : (colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
        let textColor = isSelected
            ? (colorScheme == .dark ? Color.black : Color.white)
            : (colorScheme == .dark ? Color.white : Color.black)

        return Button(action: {
            HapticManager.shared.softImpact()
            selectedFormat = format
            isPresented = false
        }) {
            HStack {
                Text(format.displayName)
                    .font(.headline)
                    .foregroundColor(textColor)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(colorScheme == .dark ? .black : .white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }
}

#Preview {
    ConverterView()
}
