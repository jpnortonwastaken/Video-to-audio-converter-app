//
//  ConverterView.swift
//  Video to Audio
//
//  Main converter view for selecting videos and extracting audio.
//

import SwiftUI
import UniformTypeIdentifiers
import PhotosUI

struct ConverterView: View {
    @StateObject private var viewModel = ConverterViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var showVideo = false
    @State private var showButtons = true
    @State private var showFormatSheet = false
    @State private var showPhotoPicker = false
    @State private var isAnimating = false

    // Intro animation state
    @AppStorage("shouldShowConverterIntro") private var shouldShowIntro = false
    @State private var showHeader = false
    @State private var showTitle = false
    @State private var showFilesCard = false
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
                // Title (outside border)
                if viewModel.selectedVideoURL == nil {
                    Text("Convert to any format")
                        .font(.roundedTitle2())
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(y: showTitle ? 0 : -15)
                        .opacity(showTitle ? 1 : 0)
                }

                // Fixed-height content container
                ZStack(alignment: .top) {
                    if viewModel.selectedVideoURL != nil {
                        // Video Preview
                        videoPreviewView
                            .scaleEffect(showVideo ? 1.0 : 0.3)
                            .opacity(showVideo ? 1.0 : 0.0)
                    } else {
                        // Input Options
                        VStack(spacing: 12) {
                            // Photos Option (large)
                            photosPickerButton
                                .scaleEffect(showFilesCard ? 1.0 : 0.8)
                                .opacity(showFilesCard ? 1 : 0)

                            // Files and Clipboard buttons (side by side)
                            HStack(spacing: 12) {
                                // Files Option
                                smallInputOptionCard(
                                    title: "Files",
                                    icon: "folder.fill",
                                    iconColor: .indigo
                                ) {
                                    viewModel.selectFromFiles()
                                }

                                // Clipboard Option
                                smallInputOptionCard(
                                    title: "Paste",
                                    icon: "doc.on.clipboard.fill",
                                    iconColor: .cyan
                                ) {
                                    viewModel.pasteFromClipboard()
                                }
                            }
                            .scaleEffect(showFilesCard ? 1.0 : 0.8)
                            .opacity(showFilesCard ? 1 : 0)

                            // Supported formats info
                            Text("Supports MP4, MOV, AVI, MKV, and more")
                                .font(.roundedCaption())
                                .foregroundColor(.gray)
                                .opacity(showFilesCard ? 1 : 0)
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
                    .fill(Color.appSecondaryBackground(for: colorScheme))
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
        .background((Color.appSecondaryBackground(for: colorScheme)).ignoresSafeArea(.all))
        .onAppear {
            if shouldShowIntro {
                playIntroAnimation()
                shouldShowIntro = false
            } else {
                // Skip animation, show everything immediately
                showHeader = true
                showTitle = true
                showFilesCard = true
                showFormatContainer = true
            }
        }
        .fileImporter(
            isPresented: $viewModel.showFilePicker,
            allowedContentTypes: ConverterViewModel.supportedVideoTypes,
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .onChange(of: viewModel.selectedVideoURL) { _, newValue in
            if newValue != nil {
                // Video selected: hide buttons, show video
                showButtons = false
                showVideo = false
                // Trigger bouncy animation with spring
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showVideo = true
                }
            } else {
                // Video removed: hide video, show buttons
                showVideo = false
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
            .presentationDetents([.fraction(0.65)])
            .presentationDragIndicator(.visible)
        }
        .fullScreenCover(isPresented: $viewModel.showResultView) {
            if let convertedData = viewModel.convertedAudioData {
                NavigationStack {
                    ConversionResultView(
                        convertedAudioData: convertedData,
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

        // Files card - bouncy
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.65)) {
                showFilesCard = true
            }
        }

        // Format container - slide up from bottom
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showFormatContainer = true
            }
        }
    }

    // MARK: - Converting Overlay
    private var convertingOverlay: some View {
        ZStack {
            (Color.appSecondaryBackground(for: colorScheme))
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

                Text("Extracting audio...")
                    .font(.roundedHeadline())
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appSecondaryBackground(for: colorScheme))
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
        .background(Color.appSecondaryBackground(for: colorScheme))
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
            .frame(height: 220)
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

    // MARK: - Photos Picker Button (Large)
    private var photosPickerButton: some View {
        Button(action: {
            HapticManager.shared.softImpact()

            // Check subscription before showing picker
            guard SubscriptionService.shared.requireSubscription() else {
                return
            }

            showPhotoPicker = true
        }) {
            VStack(spacing: 12) {
                if viewModel.isLoadingFromPhotos {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 50)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.roundedSystem(size: 50))
                        .foregroundColor(.blue)
                }

                Text("Select Video")
                    .font(.roundedTitle2())
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? Color(red: 0.6, green: 0.8, blue: 1.0) : Color(red: 0.0, green: 0.2, blue: 0.5))

                Text("Choose from Photos")
                    .font(.roundedSubheadline())
                    .foregroundColor((colorScheme == .dark ? Color(red: 0.6, green: 0.8, blue: 1.0) : Color(red: 0.0, green: 0.2, blue: 0.5)).opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.blue.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        Color.blue.opacity(inputButtonsOpacity),
                        style: inputButtonsUseDottedLine
                            ? StrokeStyle(lineWidth: inputButtonsLineWidth, lineCap: .round, dash: [inputButtonsDashLength, inputButtonsGapLength])
                            : StrokeStyle(lineWidth: inputButtonsLineWidth)
                    )
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $viewModel.selectedPhotoItem,
            matching: .videos,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.selectedPhotoItem) { _, newValue in
            Task {
                await viewModel.handlePhotoPickerSelection(newValue)
            }
        }
    }

    // MARK: - Small Input Option Card
    private func smallInputOptionCard(
        title: String,
        icon: String,
        iconColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.roundedSystem(size: 28))
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.roundedSubheadline())
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                iconColor.opacity(0.15),
                                iconColor.opacity(0.05)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
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

    // MARK: - Video Preview
    private var videoPreviewView: some View {
        VStack(spacing: 16) {
            // Title above the container
            Text("Selected Video")
                .font(.roundedTitle2())
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Video card container with dotted border
            VStack(spacing: 0) {
                videoCardItem
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(containerOpacity),
                        style: containerUseDottedLine
                            ? StrokeStyle(lineWidth: containerLineWidth, lineCap: .round, dash: [containerDashLength, containerGapLength])
                            : StrokeStyle(lineWidth: containerLineWidth)
                    )
            )
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Video Card Item
    private var videoCardItem: some View {
        HStack(spacing: 16) {
            // Thumbnail
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let thumbnail = viewModel.videoThumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle()
                            .fill(Color.appTertiaryBackground(for: colorScheme))
                            .overlay(
                                Image(systemName: "film")
                                    .font(.roundedSystem(size: 24))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                .frame(width: 100, height: 80)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Duration badge on thumbnail
                if let duration = viewModel.formattedDuration {
                    Text(duration)
                        .font(.roundedSystem(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.75))
                        )
                        .padding(6)
                }
            }

            // Video info
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(viewModel.videoTitle ?? "Video")
                    .font(.roundedHeadline())
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(2)

                // Format and date row
                HStack(spacing: 8) {
                    // Format badge
                    Text(viewModel.originalVideoFormat)
                        .font(.roundedCaption())
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.8))
                        )

                    // Date
                    if let date = viewModel.formattedDate {
                        Text(date)
                            .font(.roundedCaption())
                            .foregroundColor(.gray)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // X button to remove
            Button(action: {
                HapticManager.shared.softImpact()
                viewModel.reset()
            }) {
                Image(systemName: "xmark")
                    .font(.roundedSystem(size: 12, weight: .bold))
                    .foregroundColor(.gray)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5))
                    )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appTertiaryBackground(for: colorScheme))
        )
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
                    .fill(Color.appTertiaryBackground(for: colorScheme))
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Convert Button
    private var convertButton: some View {
        Button(action: {
            HapticManager.shared.softImpact()
            Task {
                await viewModel.convertVideo()
            }
        }) {
            HStack {
                if viewModel.isConverting {
                    ProgressView()
                        .tint(.white)
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
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.5, blue: 1.0),
                                Color(red: 0.0, green: 0.3, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .foregroundColor(.white)
        }
        .disabled(viewModel.selectedVideoURL == nil || viewModel.isConverting)
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - File Selection Handler
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }

            // Try to get security-scoped access for files from the Files picker
            let hasSecurityAccess = url.startAccessingSecurityScopedResource()
            Task {
                await viewModel.loadVideoFromURL(url, securityScoped: hasSecurityAccess)
            }

        case .failure(let error):
            viewModel.errorMessage = "Failed to load file: \(error.localizedDescription)"
        }
    }
}

// MARK: - Format Selection Sheet
struct FormatSelectionSheet: View {
    @Binding var selectedFormat: AudioFormat
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
                            ForEach(AudioFormat.allCases) { format in
                                formatCard(for: format)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 32)
                    .padding(.bottom, 24)
                }
            }
            .background(Color.appSecondaryBackground(for: colorScheme))
            .navigationBarHidden(true)
        }
    }

    // MARK: - Format Card
    private func formatCard(for format: AudioFormat) -> some View {
        let isSelected = selectedFormat == format
        let textColor = colorScheme == .dark ? Color.white : Color.black

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
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appTertiaryBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : Color.clear,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                    )
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }
}

#Preview {
    ConverterView()
}
