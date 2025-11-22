//
//  HomeView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI
import PDFKit

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var historyService = ConversionHistoryService.shared
    @State private var itemToDelete: ConversionHistoryItem?
    @State private var showDeleteConfirmation = false
    @State private var showDeleteAllConfirmation = false
    @State private var isLoadingThumbnails = false
    @State private var thumbnailCache: [UUID: UIImage] = [:]

    var body: some View {
        NavigationView {
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
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))

                // History Content
                if historyService.isLoading {
                    loadingView
                } else if historyService.items.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .task {
                // Load history asynchronously when view appears
                await historyService.loadHistoryIfNeeded()
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
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
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

                    Text("Convert an image to see it here")
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
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
    }

    // MARK: - History List
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(historyService.items.enumerated()), id: \.element.id) { index, item in
                    historyCard(for: item)

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
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 100)
        }
        .gradientFadeMask()
        .scrollIndicators(.hidden)
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
    }

    // MARK: - Helper Functions
    private func colorForFormat(_ format: String) -> Color {
        switch format.uppercased() {
        case "HEIC":
            return .blue
        case "JPG", "JPEG":
            return .red
        case "PNG":
            return .green
        case "PDF":
            return .orange
        case "GIF":
            return .purple
        case "TIFF":
            return .indigo
        case "WEBP":
            return .teal
        case "BMP":
            return .pink
        default:
            return .gray
        }
    }

    // Helper function to render PDF data as a UIImage thumbnail (async, scaled down)
    private func renderPDFAsThumbnail(data: Data, maxDimension: CGFloat = 300) async -> UIImage? {
        // Perform PDF rendering off the main thread
        return await Task.detached(priority: .userInitiated) {
            guard let pdfDocument = PDFDocument(data: data),
                  let pdfPage = pdfDocument.page(at: 0) else {
                return nil
            }

            let pageRect = pdfPage.bounds(for: .mediaBox)

            // Scale down for thumbnail to reduce memory usage
            let scale = min(maxDimension / pageRect.width, maxDimension / pageRect.height, 1.0)
            let thumbnailSize = CGSize(width: pageRect.width * scale, height: pageRect.height * scale)

            let renderer = UIGraphicsImageRenderer(size: thumbnailSize)

            let image = renderer.image { context in
                UIColor.white.set()
                context.fill(CGRect(origin: .zero, size: thumbnailSize))

                context.cgContext.scaleBy(x: scale, y: scale)
                context.cgContext.translateBy(x: 0, y: pageRect.size.height)
                context.cgContext.scaleBy(x: 1.0, y: -1.0)

                pdfPage.draw(with: .mediaBox, to: context.cgContext)
            }

            return image
        }.value
    }

    // Load thumbnail asynchronously and cache it
    private func loadThumbnail(for item: ConversionHistoryItem) async -> UIImage? {
        // Check cache first
        if let cachedImage = thumbnailCache[item.id] {
            return cachedImage
        }

        // Load and cache thumbnail
        let thumbnail: UIImage?
        if item.toFormat == .pdf {
            thumbnail = await renderPDFAsThumbnail(data: item.convertedImageData)
        } else {
            // Load image off main thread for large images
            thumbnail = await Task.detached {
                UIImage(data: item.convertedImageData)
            }.value
        }

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
        NavigationLink(destination: ConversionResultView(
            convertedImageData: item.convertedImageData,
            format: item.toFormat,
            displayMode: .fullImage
        )) {
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

                    Text(item.formattedDate)
                        .font(.roundedSubheadline())
                        .foregroundColor(.gray)

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
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.softImpact()
        })
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
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .overlay(
                        LoadingSpinner(size: 24)
                    )
            } else {
                // Error placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
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

#Preview {
    HomeView()
}
