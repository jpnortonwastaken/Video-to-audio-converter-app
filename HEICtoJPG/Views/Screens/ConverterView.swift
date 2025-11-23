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
    @State private var showButtons = true
    @State private var showFormatSheet = false
    @State private var isAnimating = false

    // Intro animation state
    @AppStorage("shouldShowConverterIntro") private var shouldShowIntro = false
    @State private var showHeader = false
    @State private var showTitle = false
    @State private var showPhotosCard = false
    @State private var showFilesCard = false
    @State private var showPasteCard = false
    @State private var showFormatContainer = false

    // Border style constants
    private let inputButtonsLineWidth: CGFloat = 2.5
    private let inputButtonsDashLength: CGFloat = 7
    private let inputButtonsGapLength: CGFloat = 8
    private let inputButtonsOpacity: Double = 0.35
    private let inputButtonsUseDottedLine = true
    private let containerLineWidth: CGFloat = 2.5
    private let containerDashLength: CGFloat = 7
    private let containerGapLength: CGFloat = 8
    private let containerOpacity: Double = 0.3
    private let containerUseDottedLine = true

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .offset(y: showHeader ? 0 : -20)
                .opacity(showHeader ? 1 : 0)

            // Content area
            VStack(alignment: .leading, spacing: 16) {
                // Title (outside red border)
                if viewModel.selectedImage == nil {
                    Text("Convert to any format")
                        .font(.roundedTitle2())
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(y: showTitle ? 0 : -15)
                        .opacity(showTitle ? 1 : 0)
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
                                textColor: colorScheme == .dark ? Color(red: 1.0, green: 0.7, blue: 0.85) : Color(red: 0.5, green: 0.1, blue: 0.25),
                                colorScheme: colorScheme
                            ) {
                                viewModel.selectFromPhotos()
                            }
                            .scaleEffect(showPhotosCard ? 1.0 : 0.8)
                            .opacity(showPhotosCard ? 1 : 0)

                            // Files and Paste Row
                            HStack(spacing: 16) {
                                // Files Option
                                smallInputOptionCard(
                                    title: "Files",
                                    subtitle: "Pick from Files",
                                    icon: "folder.fill",
                                    backgroundColor: Color.blue.opacity(0.1),
                                    iconColor: .blue,
                                    textColor: colorScheme == .dark ? Color(red: 0.6, green: 0.8, blue: 1.0) : Color(red: 0.0, green: 0.2, blue: 0.5),
                                    colorScheme: colorScheme
                                ) {
                                    viewModel.selectFromFiles()
                                }
                                .scaleEffect(showFilesCard ? 1.0 : 0.8)
                                .opacity(showFilesCard ? 1 : 0)

                                // Paste Option
                                smallInputOptionCard(
                                    title: "Paste",
                                    subtitle: "Paste an image",
                                    icon: "doc.on.clipboard.fill",
                                    backgroundColor: Color.indigo.opacity(0.1),
                                    iconColor: .indigo,
                                    textColor: colorScheme == .dark ? Color(red: 0.7, green: 0.75, blue: 1.0) : Color(red: 0.3, green: 0.2, blue: 0.7),
                                    colorScheme: colorScheme
                                ) {
                                    viewModel.pasteImage()
                                }
                                .scaleEffect(showPasteCard ? 1.0 : 0.8)
                                .opacity(showPasteCard ? 1 : 0)
                            }
                        }
                        .scaleEffect(showButtons ? 1.0 : 0.7)
                        .opacity(showButtons ? 1.0 : 0.0)
                    }
                }
                .frame(height: 350) // Fixed height to prevent movement
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 32)

            // Format Selector and Convert Button
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
                    .stroke(
                        (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(containerOpacity),
                        style: containerUseDottedLine
                            ? StrokeStyle(lineWidth: containerLineWidth, lineCap: .round, dash: [containerDashLength, containerGapLength])
                            : StrokeStyle(lineWidth: containerLineWidth)
                    )
            )
            .compositingGroup()
            .padding(.horizontal, 24)
            .offset(y: showFormatContainer ? 0 : 20)
            .opacity(showFormatContainer ? 1 : 0)

            Spacer()
        }
        .padding(.bottom, 20)
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
        .onAppear {
            if shouldShowIntro {
                playIntroAnimation()
                shouldShowIntro = false
            } else {
                // Skip animation, show everything immediately
                showHeader = true
                showTitle = true
                showPhotosCard = true
                showFilesCard = true
                showPasteCard = true
                showFormatContainer = true
            }
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
                // Image selected: hide buttons, show image
                showButtons = false
                showImage = false
                // Trigger bouncy animation with spring
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showImage = true
                }
            } else {
                // Image removed: hide image, show buttons
                showImage = false
                showButtons = false
                // Trigger bouncy animation for buttons with spring
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showButtons = true
                }
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
        .fullScreenCover(isPresented: $viewModel.showResultView) {
            if let convertedData = viewModel.convertedImageData {
                NavigationStack {
                    ConversionResultView(
                        convertedImageData: convertedData,
                        format: viewModel.selectedFormat,
                        onDismiss: {
                            viewModel.showResultView = false
                        }
                    )
                    .onDisappear {
                        viewModel.reset()
                    }
                }
            }
        }
        .overlay {
            if viewModel.isConverting {
                convertingOverlay
            }
        }
    }

    // MARK: - Intro Animation
    private func playIntroAnimation() {
        // Header - immediate start
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            showHeader = true
        }

        // Title - slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showTitle = true
            }
        }

        // Photos card - bouncy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                showPhotosCard = true
            }
        }

        // Files card - bouncy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                showFilesCard = true
            }
        }

        // Paste card - bouncy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                showPasteCard = true
            }
        }

        // Format container - slide up from bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showFormatContainer = true
            }
        }
    }

    // MARK: - Converting Overlay
    private var convertingOverlay: some View {
        ZStack {
            (colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Custom loading animation
                ZStack {
                    Circle()
                        .stroke(
                            (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                            lineWidth: 4
                        )
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            colorScheme == .dark ? Color.white : Color.black,
                            lineWidth: 4
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                        }
                        .onDisappear {
                            isAnimating = false
                        }
                }

                Text("Converting...")
                    .font(.roundedHeadline())
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding(40)
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
                        .font(.roundedLargeTitle())
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
        colorScheme: ColorScheme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.roundedSystem(size: 50))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.roundedTitle2())
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)

                Text(subtitle)
                    .font(.roundedSubheadline())
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
                    .stroke(
                        iconColor.opacity(inputButtonsOpacity),
                        style: inputButtonsUseDottedLine
                            ? StrokeStyle(lineWidth: inputButtonsLineWidth, lineCap: .round, dash: [inputButtonsDashLength, inputButtonsGapLength])
                            : StrokeStyle(lineWidth: inputButtonsLineWidth)
                    )
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
        colorScheme: ColorScheme,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.roundedSystem(size: 40))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.roundedHeadline())
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)

                Text(subtitle)
                    .font(.roundedCaption())
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
                    .stroke(
                        iconColor.opacity(inputButtonsOpacity),
                        style: inputButtonsUseDottedLine
                            ? StrokeStyle(lineWidth: inputButtonsLineWidth, lineCap: .round, dash: [inputButtonsDashLength, inputButtonsGapLength])
                            : StrokeStyle(lineWidth: inputButtonsLineWidth)
                    )
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
                    .font(.roundedHeadline())
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Spacer()

                HStack(spacing: 8) {
                    Text(viewModel.selectedFormat.displayName)
                        .font(.roundedHeadline())
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Image(systemName: "chevron.down")
                        .font(.roundedBody())
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
            HapticManager.shared.softImpact()
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
                        .font(.roundedHeadline())
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
                    .font(.roundedSystem(size: 14, weight: .bold))
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

                if let data = try? Data(contentsOf: url) {
                    viewModel.loadImageFromData(data)
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
                    .font(.roundedHeadline())
                    .foregroundColor(textColor)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.roundedTitle3())
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
