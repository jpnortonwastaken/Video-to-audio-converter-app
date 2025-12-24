//
//  HomeView.swift
//  Video to Audio
//
//  History view showing past audio extractions.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var historyService = ConversionHistoryService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @State private var itemToDelete: ConversionHistoryItem?
    @State private var showDeleteConfirmation = false
    @State private var showDeleteAllConfirmation = false
    @State private var thumbnailCache: [UUID: UIImage] = [:]
    @State private var animateItems = false
    @State private var selectedItemForNavigation: ConversionHistoryItem?

    var body: some View {
        NavigationView {
            ZStack {
                // Hidden NavigationLink controlled by state
                NavigationLink(
                    destination: selectedItemForNavigation.map { item in
                        HistoryDetailView(item: item)
                    },
                    isActive: Binding(
                        get: { selectedItemForNavigation != nil },
                        set: { if !$0 { selectedItemForNavigation = nil } }
                    )
                ) {
                    EmptyView()
                }
                .hidden()

                VStack(spacing: 0) {
                    // History Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("History")
                                .font(.roundedLargeTitle())
                                .fontWeight(.bold)
                        }

                        Spacer()

                        // Delete All Button (only show when there are items)
                        if !historyService.items.isEmpty {
                            Button(action: {
                                HapticManager.shared.softImpact()
                                showDeleteAllConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.roundedTitle3())
                                    .foregroundColor(.red)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(ScaleDownButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 0)
                    .background(Color.appSecondaryBackground(for: colorScheme))

                    // History Content
                    if historyService.isLoading {
                        loadingView
                    } else if historyService.items.isEmpty {
                        emptyStateView
                    } else {
                        historyListView
                    }
                }
            }
            .background((Color.appSecondaryBackground(for: colorScheme)).ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Load history asynchronously when view appears
                await historyService.loadHistoryIfNeeded()

                // Trigger animations after loading completes
                if !historyService.items.isEmpty {
                    // Small delay to ensure view is ready
                    try? await Task.sleep(for: .milliseconds(50))
                    animateItems = true
                }
            }
            .onChange(of: historyService.items.count) { _, _ in
                // Reset and re-trigger animations when items change
                animateItems = false
                Task {
                    try? await Task.sleep(for: .milliseconds(50))
                    animateItems = true
                }
            }
        }
        .alert("Delete Conversion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    HapticManager.shared.softImpact()
                    historyService.deleteItem(item)
                    itemToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this conversion from your history?")
        }
        .alert("Delete All History", isPresented: $showDeleteAllConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                HapticManager.shared.softImpact()
                historyService.clearAll()
            }
        } message: {
            Text("Are you sure you want to delete all conversions from your history? This action cannot be undone.")
        }
    }

    // MARK: - Loading State
    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()

            LoadingSpinner()

            Text("Loading history...")
                .font(.roundedBody())
                .foregroundColor(.gray)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((Color.appSecondaryBackground(for: colorScheme)).ignoresSafeArea(.all))
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 100)

                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.roundedSystem(size: 60))
                        .foregroundColor(.gray)

                    Text("No Conversions Yet")
                        .font(.roundedTitle2())
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Text("Extract audio from a video to see it here")
                        .font(.roundedBody())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .gradientFadeMask()
        .scrollIndicators(.hidden)
        .background((Color.appSecondaryBackground(for: colorScheme)).ignoresSafeArea(.all))
    }

    // MARK: - History List
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(historyService.items.enumerated()), id: \.element.id) { index, item in
                    historyCard(for: item)
                        .opacity(animateItems ? 1 : 0)
                        .scaleEffect(animateItems ? 1 : 0.9)
                        .offset(y: animateItems ? 0 : -10)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05),
                            value: animateItems
                        )

                    // Add dashed separator between cards (but not after the last one)
                    if index < historyService.items.count - 1 {
                        GeometryReader { geometry in
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: 0))
                                path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                            }
                            .stroke(
                                (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                            )
                        }
                        .frame(height: 2.5)
                        .padding(.vertical, 16)
                        .opacity(animateItems ? 1 : 0)
                        .scaleEffect(animateItems ? 1 : 0.9)
                        .offset(y: animateItems ? 0 : -10)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                                .delay(Double(index) * 0.05 + 0.025),
                            value: animateItems
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 100)
        }
        .gradientFadeMask()
        .scrollIndicators(.hidden)
        .background((Color.appSecondaryBackground(for: colorScheme)).ignoresSafeArea(.all))
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

    // Load thumbnail asynchronously and cache it
    private func loadThumbnail(for item: ConversionHistoryItem) async -> UIImage? {
        // Check cache first
        if let cachedImage = thumbnailCache[item.id] {
            return cachedImage
        }

        // Load thumbnail from disk
        let thumbnail = await Task.detached {
            return item.loadThumbnail()
        }.value

        // Cache the thumbnail
        if let thumbnail = thumbnail {
            await MainActor.run {
                thumbnailCache[item.id] = thumbnail
            }
        }

        return thumbnail
    }

    // MARK: - History Card
    private func historyCard(for item: ConversionHistoryItem) -> some View {
        Button(action: {
            HapticManager.shared.softImpact()

            // Check subscription before allowing access to history detail
            guard subscriptionService.requireSubscription() else {
                return
            }

            // User is subscribed, navigate to detail view
            selectedItemForNavigation = item
        }) {
            HStack(spacing: 16) {
                // Async Thumbnail
                AsyncThumbnailView(item: item, cache: $thumbnailCache, loadThumbnail: loadThumbnail)

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.fromFormat)
                            .font(.roundedCaption())
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForFormat(item.fromFormat).opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        colorForFormat(item.fromFormat).opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 3])
                                    )
                            )

                        Image(systemName: "arrow.right")
                            .font(.roundedCaption())
                            .foregroundColor(.gray)

                        Text(item.toFormat.displayName)
                            .font(.roundedCaption())
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForFormat(item.toFormat.displayName).opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(
                                        colorForFormat(item.toFormat.displayName).opacity(0.4),
                                        style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 3])
                                    )
                            )
                    }

                    HStack(spacing: 8) {
                        Text(item.formattedDate)
                            .font(.roundedSubheadline())
                            .foregroundColor(.gray)

                        if let duration = item.formattedDuration {
                            Text("•")
                                .foregroundColor(.gray)
                            Text(duration)
                                .font(.roundedSubheadline())
                                .foregroundColor(.gray)
                        }
                    }

                    Text(item.formattedFileSize)
                        .font(.roundedSubheadline())
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.roundedBody())
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.001))
        }
        .buttonStyle(ScaleDownButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                HapticManager.shared.softImpact()
                itemToDelete = item
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Async Thumbnail View
struct AsyncThumbnailView: View {
    let item: ConversionHistoryItem
    @Binding var cache: [UUID: UIImage]
    let loadThumbnail: (ConversionHistoryItem) async -> UIImage?

    @State private var thumbnail: UIImage?
    @State private var isLoading = true
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if isLoading {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appTertiaryBackground(for: colorScheme))
                    .frame(width: 80, height: 80)
                    .overlay(
                        LoadingSpinner(size: 24)
                    )
            } else {
                // Error/default placeholder - audio icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appTertiaryBackground(for: colorScheme))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.roundedTitle2())
                            .foregroundColor(.gray)
                    )
            }
        }
        .task {
            // Check cache first (synchronously)
            if let cachedImage = cache[item.id] {
                thumbnail = cachedImage
                isLoading = false
                return
            }

            // Load thumbnail asynchronously
            thumbnail = await loadThumbnail(item)
            isLoading = false
        }
    }
}

// MARK: - Loading Spinner
struct LoadingSpinner: View {
    var size: CGFloat = 40
    @State private var isAnimating = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                colorScheme == .dark ? Color.white : Color.black,
                style: StrokeStyle(lineWidth: size / 10, lineCap: .round)
            )
            .frame(width: size, height: size)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            .animation(
                Animation.linear(duration: 1)
                    .repeatForever(autoreverses: false),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - History Detail View
/// Wrapper view that loads audio data from disk before showing ConversionResultView
struct HistoryDetailView: View {
    let item: ConversionHistoryItem
    @State private var convertedAudioData: Data?
    @State private var isLoading = true
    @State private var loadError = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if isLoading {
                VStack(spacing: 16) {
                    LoadingSpinner(size: 40)
                    Text("Loading audio...")
                        .font(.roundedBody())
                        .foregroundColor(.gray)
                }
            } else if let convertedAudioData = convertedAudioData {
                ConversionResultView(
                    convertedAudioData: convertedAudioData,
                    format: item.toFormat,
                    displayMode: .fullImage
                )
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text("Failed to load audio")
                        .font(.roundedHeadline())
                    Text("The audio file may have been deleted")
                        .font(.roundedBody())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .task {
            do {
                convertedAudioData = try item.loadConvertedAudioData()
                isLoading = false
            } catch {
                print("❌ Failed to load audio data: \(error)")
                loadError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    HomeView()
}
