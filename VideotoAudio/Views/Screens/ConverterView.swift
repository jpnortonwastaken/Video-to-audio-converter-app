//
//  ConverterView.swift
//  Video to Audio
//
//  Main converter view for selecting videos and extracting audio.
//  Supports both single and batch conversion with auto-adapting UI.
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

    // Confirmation popup state
    @State private var showClearConfirmation = false

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
                // Title (outside border) - only show when no videos selected or still loading
                if !viewModel.hasSelection || viewModel.isLoadingItems {
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
                    // Show video preview only when items are loaded and ready
                    if viewModel.hasSelection && !viewModel.isLoadingItems {
                        // Unified selected videos container
                        selectedVideosContainer
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
            allowsMultipleSelection: true
        ) { result in
            handleFileSelection(result)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $viewModel.selectedPhotoItems,
            maxSelectionCount: 50,
            matching: .videos,
            photoLibrary: .shared()
        )
        .onChange(of: viewModel.selectedPhotoItems) { _, newValue in
            Task {
                await viewModel.handlePhotoPickerSelection(newValue)
            }
        }
        .onChange(of: viewModel.isLoadingItems) { oldValue, newValue in
            // When loading finishes and we have items, animate to show video
            if oldValue == true && newValue == false && viewModel.hasSelection {
                showButtons = false
                showVideo = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showVideo = true
                }
            }
        }
        .onChange(of: viewModel.items.count) { oldValue, newValue in
            // Only handle removal animations here (loading handles additions)
            if newValue == 0 && oldValue > 0 {
                // All videos removed: hide video, show buttons
                showVideo = false
                showButtons = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    showButtons = true
                }
            } else if newValue != oldValue && !viewModel.isLoadingItems {
                // Count changed but still have videos - animate
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    // Just trigger a re-render
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
        .alert("Clear Selected Videos", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                HapticManager.shared.softImpact()
                viewModel.clearQueue()
            }
        } message: {
            Text("Are you sure you want to remove all selected videos?")
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
            if viewModel.isSingleMode, let convertedData = viewModel.convertedAudioData {
                // Single result view
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
            } else {
                // Batch results view
                BatchResultsView(
                    results: viewModel.results,
                    format: viewModel.selectedFormat,
                    onDismiss: {
                        viewModel.showResultView = false
                        viewModel.reset()
                    },
                    onRetryFailed: {
                        Task {
                            await viewModel.retryFailed()
                        }
                    }
                )
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
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(
                            (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                            lineWidth: 4
                        )
                        .frame(width: 60, height: 60)

                    if viewModel.isBatchMode {
                        // Batch mode: show progress ring with percentage
                        Circle()
                            .trim(from: 0, to: viewModel.overallProgress)
                            .stroke(
                                colorScheme == .dark ? Color.white : Color.black,
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.2), value: viewModel.overallProgress)

                        Text("\(Int(viewModel.overallProgress * 100))%")
                            .font(.roundedSystem(size: 14, weight: .semibold))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    } else {
                        // Single mode: spinning loader
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
                }

                // Status text
                VStack(spacing: 8) {
                    if viewModel.isBatchMode {
                        Text("Converting \(viewModel.completedCount + 1) of \(viewModel.items.count)")
                            .font(.roundedHeadline())
                            .foregroundColor(colorScheme == .dark ? .white : .black)

                        if let currentIndex = viewModel.currentConvertingIndex,
                           viewModel.items.indices.contains(currentIndex) {
                            Text(viewModel.items[currentIndex].title)
                                .font(.roundedSubheadline())
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Extracting audio...")
                            .font(.roundedHeadline())
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
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

    // MARK: - Selected Videos Container (Unified for single and multiple)
    private var selectedVideosContainer: some View {
        VStack(spacing: 0) {
            // Header row with title and actions
            HStack {
                Text("Selected Video\(viewModel.items.count > 1 ? "s" : "")")
                    .font(.roundedHeadline())
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                if viewModel.items.count > 1 {
                    Text("(\(viewModel.items.count))")
                        .font(.roundedHeadline())
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }

                Spacer()

                // Add more button
                Button(action: {
                    HapticManager.shared.softImpact()
                    guard SubscriptionService.shared.requireSubscription() else { return }
                    showPhotoPicker = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.roundedCaption())
                        Text("Add Videos")
                            .font(.roundedCaption())
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.15))
                    )
                }
                .buttonStyle(ScaleDownButtonStyle())

                // Clear button
                Button(action: {
                    HapticManager.shared.softImpact()
                    showClearConfirmation = true
                }) {
                    Image(systemName: "xmark")
                        .font(.roundedCaption())
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.15))
                        )
                }
                .buttonStyle(ScaleDownButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // Scrollable video cards
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.items) { item in
                        BatchQueueItemView(
                            item: item,
                            onRemove: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.removeItem(item)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 330)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appSecondaryBackground(for: colorScheme))
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
                if viewModel.isLoadingItems {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(height: 50)
                } else {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.roundedSystem(size: 50))
                        .foregroundColor(.blue)
                }

                Text("Select Video(s)")
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
                    .foregroundColor(colorScheme == .dark ? Color(red: 0.6, green: 0.8, blue: 1.0) : Color(red: 0.0, green: 0.2, blue: 0.5))
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
                    Text(viewModel.isBatchMode ? "Convert \(viewModel.items.count) Videos" : "Convert")
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
        .disabled(!viewModel.hasSelection || viewModel.isConverting)
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Helper Functions
    private func colorForFormat(_ format: String) -> Color {
        switch format.uppercased() {
        case "MP4", "MOV", "AVI", "MKV":
            return .blue
        case "MP3":
            return .red
        case "M4A", "AAC":
            return .orange
        case "WAV":
            return .green
        case "FLAC":
            return .purple
        case "AIFF":
            return .teal
        default:
            return .gray
        }
    }

    // MARK: - File Selection Handler
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard !urls.isEmpty else { return }

            Task {
                await viewModel.handleFileSelection(urls)
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
