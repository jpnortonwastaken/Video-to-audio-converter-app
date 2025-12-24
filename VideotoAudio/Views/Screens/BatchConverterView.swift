//
//  BatchConverterView.swift
//  Video to Audio
//
//  Batch conversion view for converting multiple videos at once.
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

struct BatchConverterView: View {
    @StateObject private var viewModel = BatchConverterViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss

    @State private var showPhotoPicker = false
    @State private var showFormatSheet = false
    @State private var animateItems = false

    // Border style constants
    private let containerLineWidth: CGFloat = 2.5
    private let containerDashLength: CGFloat = 7
    private let containerGapLength: CGFloat = 8
    private let containerOpacity: Double = 0.3

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                headerView

                // Content
                if viewModel.items.isEmpty {
                    emptyQueueView
                } else {
                    queueListView
                }

                // Bottom action bar
                actionBar
            }
            .background(Color.appSecondaryBackground(for: colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
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
            .fileImporter(
                isPresented: $viewModel.showFilePicker,
                allowedContentTypes: BatchConverterViewModel.supportedVideoTypes,
                allowsMultipleSelection: true
            ) { result in
                handleFileSelection(result)
            }
            .sheet(isPresented: $showFormatSheet) {
                FormatSelectionSheet(
                    selectedFormat: $viewModel.selectedFormat,
                    isPresented: $showFormatSheet
                )
                .presentationDetents([.fraction(0.65)])
                .presentationDragIndicator(.visible)
            }
            .fullScreenCover(isPresented: $viewModel.showResultsView) {
                BatchResultsView(
                    results: viewModel.results,
                    format: viewModel.selectedFormat,
                    onDismiss: {
                        viewModel.showResultsView = false
                        viewModel.reset()
                        dismiss()
                    },
                    onRetryFailed: {
                        Task {
                            await viewModel.retryFailed()
                        }
                    }
                )
            }
            .overlay {
                if viewModel.isProcessing {
                    convertingOverlay
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
    }

    // MARK: - Header View

    private var headerView: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: {
                HapticManager.shared.softImpact()
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.roundedTitle3())
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(ScaleDownButtonStyle())

            VStack(alignment: .leading, spacing: 2) {
                Text("Batch Convert")
                    .font(.roundedTitle2())
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                if !viewModel.items.isEmpty {
                    Text("\(viewModel.items.count) video\(viewModel.items.count == 1 ? "" : "s")")
                        .font(.roundedCaption())
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Clear all button (only show when there are items)
            if !viewModel.items.isEmpty && !viewModel.isProcessing {
                Button(action: {
                    HapticManager.shared.softImpact()
                    viewModel.clearQueue()
                }) {
                    Image(systemName: "trash")
                        .font(.roundedBody())
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(ScaleDownButtonStyle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSecondaryBackground(for: colorScheme))
    }

    // MARK: - Empty Queue View

    private var emptyQueueView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 40)

                // Select Videos Card
                selectVideosCard

                // Files and Paste buttons
                HStack(spacing: 12) {
                    smallInputButton(
                        title: "Files",
                        icon: "folder.fill",
                        iconColor: .indigo
                    ) {
                        HapticManager.shared.softImpact()
                        guard SubscriptionService.shared.requireSubscription() else { return }
                        viewModel.showFilePicker = true
                    }

                    smallInputButton(
                        title: "Paste",
                        icon: "doc.on.clipboard.fill",
                        iconColor: .cyan
                    ) {
                        // Paste functionality for batch would require more complex implementation
                        HapticManager.shared.softImpact()
                    }
                }
                .padding(.horizontal, 24)

                Text("Select up to 50 videos to convert at once")
                    .font(.roundedCaption())
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)

                Spacer()
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Select Videos Card

    private var selectVideosCard: some View {
        Button(action: {
            HapticManager.shared.softImpact()
            guard SubscriptionService.shared.requireSubscription() else { return }
            showPhotoPicker = true
        }) {
            VStack(spacing: 16) {
                if viewModel.isLoadingItems {
                    LoadingSpinner(size: 50)
                } else {
                    Image(systemName: "photo.stack")
                        .font(.roundedSystem(size: 60))
                        .foregroundColor(.blue)
                }

                Text("Select Videos")
                    .font(.roundedTitle2())
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? Color(red: 0.6, green: 0.8, blue: 1.0) : Color(red: 0.0, green: 0.2, blue: 0.5))

                Text("Choose multiple from Photos")
                    .font(.roundedSubheadline())
                    .foregroundColor((colorScheme == .dark ? Color(red: 0.6, green: 0.8, blue: 1.0) : Color(red: 0.0, green: 0.2, blue: 0.5)).opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)
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
                        Color.blue.opacity(0.35),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                    )
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
        .padding(.horizontal, 24)
    }

    // MARK: - Small Input Button

    private func smallInputButton(
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
                        iconColor.opacity(0.35),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                    )
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
    }

    // MARK: - Queue List View

    private var queueListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Add more videos button
                addMoreVideosButton
                    .padding(.top, 16)

                // Queue items
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    BatchQueueItemView(
                        item: item,
                        onRemove: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                viewModel.removeItem(item)
                            }
                        }
                    )
                    .opacity(animateItems ? 1 : 0)
                    .offset(y: animateItems ? 0 : 20)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.7)
                            .delay(Double(index) * 0.05),
                        value: animateItems
                    )
                }

                // Total duration summary
                if let totalDuration = viewModel.totalDuration {
                    HStack {
                        Text("Total duration:")
                            .font(.roundedCaption())
                            .foregroundColor(.gray)

                        Text(totalDuration)
                            .font(.roundedCaption())
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .onAppear {
            animateItems = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateItems = true
            }
        }
        .onChange(of: viewModel.items.count) { _, _ in
            animateItems = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateItems = true
            }
        }
    }

    // MARK: - Add More Videos Button

    private var addMoreVideosButton: some View {
        Button(action: {
            HapticManager.shared.softImpact()
            guard SubscriptionService.shared.requireSubscription() else { return }
            showPhotoPicker = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.roundedBody())
                    .foregroundColor(.blue)

                Text("Add More Videos")
                    .font(.roundedSubheadline())
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        Color.blue.opacity(0.3),
                        style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [5, 5])
                    )
            )
        }
        .buttonStyle(ScaleDownButtonStyle())
        .disabled(viewModel.isProcessing)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 16) {
            // Format Selector
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
            .disabled(viewModel.isProcessing)

            // Convert Button
            Button(action: {
                HapticManager.shared.softImpact()
                Task {
                    await viewModel.startConversion()
                }
            }) {
                HStack(spacing: 8) {
                    if viewModel.isProcessing {
                        LoadingSpinner(size: 20)
                            .tint(.white)

                        Text("Converting...")
                            .font(.roundedHeadline())
                            .fontWeight(.semibold)
                    } else {
                        Text("Convert \(viewModel.items.count) Video\(viewModel.items.count == 1 ? "" : "s")")
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
                                colors: viewModel.canStartConversion ? [
                                    Color(red: 0.0, green: 0.5, blue: 1.0),
                                    Color(red: 0.0, green: 0.3, blue: 0.9)
                                ] : [
                                    Color.gray.opacity(0.5),
                                    Color.gray.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .foregroundColor(.white)
            }
            .disabled(!viewModel.canStartConversion)
            .buttonStyle(ScaleDownButtonStyle())
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
                    style: StrokeStyle(lineWidth: containerLineWidth, lineCap: .round, dash: [containerDashLength, containerGapLength])
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Converting Overlay

    @State private var isAnimating = false

    private var convertingOverlay: some View {
        ZStack {
            Color.appSecondaryBackground(for: colorScheme)
                .opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Overall progress ring
                ZStack {
                    Circle()
                        .stroke(
                            (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                            lineWidth: 6
                        )
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: viewModel.overallProgress)
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: viewModel.overallProgress)

                    Text("\(Int(viewModel.overallProgress * 100))%")
                        .font(.roundedTitle3())
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                }

                VStack(spacing: 8) {
                    Text("Converting \(viewModel.completedCount + 1) of \(viewModel.items.count)")
                        .font(.roundedHeadline())
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    // Current item info
                    if let currentIndex = viewModel.currentConvertingIndex,
                       viewModel.items.indices.contains(currentIndex) {
                        Text(viewModel.items[currentIndex].title)
                            .font(.roundedSubheadline())
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                }

                // Cancel button
                Button(action: {
                    HapticManager.shared.softImpact()
                    viewModel.cancelConversion()
                }) {
                    Text("Cancel")
                        .font(.roundedSubheadline())
                        .foregroundColor(.red)
                }
                .buttonStyle(ScaleDownButtonStyle())
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.appSecondaryBackground(for: colorScheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(
                        (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                    )
            )
        }
    }

    // MARK: - File Selection Handler

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            Task {
                await viewModel.handleFileSelection(urls)
            }
        case .failure(let error):
            viewModel.errorMessage = "Failed to load files: \(error.localizedDescription)"
        }
    }
}

#Preview {
    BatchConverterView()
        .preferredColorScheme(.dark)
}
