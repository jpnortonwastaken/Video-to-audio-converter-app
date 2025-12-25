//
//  ConverterViewModel.swift
//  Video to Audio
//
//  ViewModel for handling video-to-audio conversion (unified single & batch).
//

import SwiftUI
import Combine
import AVFoundation
import UniformTypeIdentifiers
import PhotosUI

@MainActor
class ConverterViewModel: ObservableObject {
    // MARK: - Published Properties

    // Queue-based properties (replaces single video)
    @Published var items: [BatchConversionItem] = []
    @Published var selectedFormat: AudioFormat = .mp3
    @Published var isConverting = false
    @Published var showFilePicker = false
    @Published var showFormatPicker = false
    @Published var errorMessage: String?
    @Published var showResultView = false
    @Published var selectedPhotoItems: [PhotosPickerItem] = []
    @Published var isLoadingItems = false
    @Published var results: [BatchConversionResult] = []
    @Published var currentConvertingIndex: Int?

    // Single video converted data (for single result view compatibility)
    @Published var convertedAudioData: Data?

    // MARK: - Concurrency Control

    private let maxConcurrentConversions = 2
    private var conversionTask: Task<Void, Never>?

    // MARK: - Supported Video Types
    static let supportedVideoTypes: [UTType] = [
        .movie,
        .video,
        .mpeg4Movie,
        .quickTimeMovie,
        .avi,
        UTType(filenameExtension: "mkv") ?? .movie,
        UTType(filenameExtension: "webm") ?? .movie,
        UTType(filenameExtension: "flv") ?? .movie,
        UTType(filenameExtension: "wmv") ?? .movie
    ]

    // MARK: - Computed Properties

    var isSingleMode: Bool { items.count == 1 }
    var isBatchMode: Bool { items.count > 1 }
    var hasSelection: Bool { !items.isEmpty }

    /// For single mode backward compatibility
    var currentItem: BatchConversionItem? { items.first }

    /// Convenience accessors for single mode UI
    var selectedVideoURL: URL? { currentItem?.sourceURL }
    var videoThumbnail: UIImage? { currentItem?.thumbnail }
    var videoDuration: Double? { currentItem?.duration }
    var videoTitle: String? { currentItem?.title }
    var originalVideoFormat: String { currentItem?.originalFormat ?? "MP4" }

    var formattedDuration: String? {
        currentItem?.formattedDuration
    }

    var formattedDate: String? {
        guard let date = currentItem?.dateAdded else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    var completedCount: Int {
        items.filter { $0.status.isCompleted }.count
    }

    var failedCount: Int {
        items.filter { $0.status.isFailed }.count
    }

    var readyCount: Int {
        items.filter { if case .ready = $0.status { return true } else { return false } }.count
    }

    var overallProgress: Double {
        guard !items.isEmpty else { return 0 }
        let progressSum = items.reduce(0.0) { sum, item in
            sum + item.status.progress
        }
        return progressSum / Double(items.count)
    }

    var canStartConversion: Bool {
        !items.isEmpty && !isConverting && readyCount == items.count
    }

    var totalDuration: String? {
        let total = items.compactMap { $0.duration }.reduce(0, +)
        guard total > 0 else { return nil }
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Methods

    func selectFromFiles() {
        HapticManager.shared.softImpact()

        // Check subscription before allowing access
        guard SubscriptionService.shared.requireSubscription() else {
            return
        }

        showFilePicker = true
    }

    // MARK: - Photo Picker Handling (Multi-select)

    func handlePhotoPickerSelection(_ selectedItems: [PhotosPickerItem]) async {
        guard !selectedItems.isEmpty else { return }

        isLoadingItems = true

        for item in selectedItems {
            do {
                if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                    await addItems(from: [movie.url], securityScoped: false)
                }
            } catch {
                print("Failed to load video: \(error)")
            }
        }

        selectedPhotoItems.removeAll()
        isLoadingItems = false
    }

    // MARK: - File Selection Handling (Multi-select)

    func handleFileSelection(_ urls: [URL]) async {
        var accessibleURLs: [URL] = []

        for url in urls {
            // Start accessing security-scoped resource
            if url.startAccessingSecurityScopedResource() {
                // Copy to temp directory to avoid security scope issues
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString)_\(url.lastPathComponent)")

                do {
                    try FileManager.default.copyItem(at: url, to: tempURL)
                    accessibleURLs.append(tempURL)
                } catch {
                    print("Failed to copy file: \(error)")
                }

                url.stopAccessingSecurityScopedResource()
            }
        }

        await addItems(from: accessibleURLs, securityScoped: false)
    }

    func pasteFromClipboard() {
        HapticManager.shared.softImpact()

        // Check subscription before allowing access
        guard SubscriptionService.shared.requireSubscription() else {
            return
        }

        let pasteboard = UIPasteboard.general

        // Check for video URL
        if pasteboard.hasURLs, let url = pasteboard.url {
            // Check if URL points to a video file
            let videoExtensions = ["mp4", "mov", "avi", "mkv", "webm", "flv", "wmv", "m4v"]
            if videoExtensions.contains(url.pathExtension.lowercased()) {
                Task {
                    await addItems(from: [url], securityScoped: false)
                }
                return
            }
        }

        // Check for video data types
        let videoTypes = ["public.movie", "public.mpeg-4", "com.apple.quicktime-movie"]
        for type in videoTypes {
            if let data = pasteboard.data(forPasteboardType: type) {
                // Save to temp file and load
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("clipboard_video_\(Int(Date().timeIntervalSince1970)).mp4")
                do {
                    try data.write(to: tempURL)
                    Task {
                        await addItems(from: [tempURL], securityScoped: false)
                    }
                    return
                } catch {
                    errorMessage = "Failed to save clipboard video"
                }
            }
        }

        errorMessage = "No video found in clipboard"
        HapticManager.shared.error()
    }

    // MARK: - Queue Management

    func addItems(from urls: [URL], securityScoped: Bool = false) async {
        isLoadingItems = true

        for url in urls {
            // Skip duplicates
            if items.contains(where: { $0.sourceURL == url }) {
                continue
            }

            let item = BatchConversionItem(
                sourceURL: url,
                isSecurityScoped: securityScoped
            )

            items.append(item)
            HapticManager.shared.softImpact()

            // Load metadata in background
            await loadItemMetadata(for: item.id)
        }

        isLoadingItems = false
    }

    func removeItem(_ item: BatchConversionItem) {
        HapticManager.shared.softImpact()
        items.removeAll { $0.id == item.id }
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        HapticManager.shared.softImpact()
        items.remove(at: index)
    }

    func clearQueue() {
        HapticManager.shared.softImpact()
        items.removeAll()
        results.removeAll()
    }

    // MARK: - Metadata Loading

    private func loadItemMetadata(for itemId: UUID) async {
        guard let index = items.firstIndex(where: { $0.id == itemId }) else { return }

        // Update status to loading
        items[index].status = .loading

        let url = items[index].sourceURL
        let converter = VideoConverter()

        do {
            // Get file size
            if let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
               let fileSize = attributes[.size] as? Int64 {
                items[index].fileSize = fileSize
            }

            // Get duration
            let duration = try await converter.getVideoDuration(from: url)
            items[index].duration = duration

            // Generate thumbnail
            if let thumbnailData = try await converter.generateThumbnail(from: url) {
                items[index].thumbnail = UIImage(data: thumbnailData)
            }

            // Mark as ready
            items[index].status = .ready
        } catch {
            print("Failed to load metadata for \(url.lastPathComponent): \(error)")
            // Still mark as ready - we can try to convert without metadata
            items[index].status = .ready
        }
    }

    // MARK: - Conversion

    func convertVideo() async {
        guard !items.isEmpty else {
            errorMessage = "No video selected"
            return
        }

        // Check subscription before allowing conversion
        guard SubscriptionService.shared.requireSubscription() else {
            return
        }

        isConverting = true
        results.removeAll()
        HapticManager.shared.softImpact()

        if isSingleMode {
            // Single video conversion
            await convertSingleVideo()
        } else {
            // Batch conversion
            await startBatchConversion()
        }
    }

    private func convertSingleVideo() async {
        guard let item = items.first else { return }

        let url = item.sourceURL

        // Update status
        items[0].status = .converting(progress: 0.0)
        currentConvertingIndex = 0

        do {
            let converter = VideoConverter()

            // Simulate progress updates
            let progressTask = Task {
                var progress = 0.0
                while progress < 0.9 && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    progress += 0.05
                    await MainActor.run {
                        if self.items.indices.contains(0) {
                            self.items[0].status = .converting(progress: min(progress, 0.9))
                        }
                    }
                }
            }

            let audioData = try await converter.extractAudio(
                from: url,
                to: selectedFormat
            )

            progressTask.cancel()

            // Update status to completed
            items[0].status = .completed(audioData: audioData)

            // Store the converted data for single result view
            convertedAudioData = audioData

            // Save to history
            await saveToHistory(item: item, audioData: audioData)

            HapticManager.shared.success()
            showResultView = true
        } catch {
            items[0].status = .failed(error: error.localizedDescription)
            errorMessage = "Conversion failed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isConverting = false
        currentConvertingIndex = nil
    }

    private func startBatchConversion() async {
        // Process items with limited concurrency
        await withTaskGroup(of: (Int, BatchConversionResult).self) { group in
            var runningTasks = 0
            var nextIndex = 0

            while nextIndex < items.count || runningTasks > 0 {
                // Add new tasks if we haven't reached the limit
                while runningTasks < maxConcurrentConversions && nextIndex < items.count {
                    let index = nextIndex
                    nextIndex += 1
                    runningTasks += 1

                    group.addTask {
                        let result = await self.convertItemAt(index)
                        return (index, result)
                    }
                }

                // Wait for a task to complete
                if let (_, result) = await group.next() {
                    runningTasks -= 1
                    await MainActor.run {
                        self.results.append(result)
                    }
                }
            }
        }

        isConverting = false
        currentConvertingIndex = nil

        // Show results
        if !results.isEmpty {
            HapticManager.shared.success()
            showResultView = true
        }
    }

    private func convertItemAt(_ index: Int) async -> BatchConversionResult {
        guard items.indices.contains(index) else {
            return BatchConversionResult(
                id: UUID(),
                item: items[index],
                audioData: nil,
                error: "Invalid index",
                convertedFormat: selectedFormat
            )
        }

        // Update status to converting
        await MainActor.run {
            items[index].status = .converting(progress: 0.0)
            currentConvertingIndex = index
        }

        let item = items[index]
        let url = item.sourceURL

        do {
            let converter = VideoConverter()

            // Simulate progress updates
            let progressTask = Task {
                var progress = 0.0
                while progress < 0.9 && !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    progress += 0.05
                    await MainActor.run {
                        if self.items.indices.contains(index) {
                            self.items[index].status = .converting(progress: min(progress, 0.9))
                        }
                    }
                }
            }

            let audioData = try await converter.extractAudio(from: url, to: selectedFormat)

            progressTask.cancel()

            // Update status to completed
            await MainActor.run {
                if items.indices.contains(index) {
                    items[index].status = .completed(audioData: audioData)
                }
            }

            // Save to history
            await saveToHistory(item: item, audioData: audioData)

            return BatchConversionResult(
                id: UUID(),
                item: item,
                audioData: audioData,
                error: nil,
                convertedFormat: selectedFormat
            )
        } catch {
            await MainActor.run {
                if items.indices.contains(index) {
                    items[index].status = .failed(error: error.localizedDescription)
                }
            }

            return BatchConversionResult(
                id: UUID(),
                item: item,
                audioData: nil,
                error: error.localizedDescription,
                convertedFormat: selectedFormat
            )
        }
    }

    func cancelConversion() {
        conversionTask?.cancel()
        conversionTask = nil
        isConverting = false

        // Reset any converting items to ready
        for index in items.indices {
            if case .converting = items[index].status {
                items[index].status = .ready
            }
        }

        HapticManager.shared.softImpact()
    }

    // MARK: - History

    private func saveToHistory(item: BatchConversionItem, audioData: Data) async {
        let thumbnailId = UUID()
        let audioId = UUID()

        do {
            // Save thumbnail if available
            if let thumbnail = item.thumbnail,
               let thumbnailData = thumbnail.jpegData(compressionQuality: 0.8) {
                _ = try MediaStorageService.shared.saveFile(thumbnailData, withId: thumbnailId)
            } else {
                // Generate new thumbnail
                let converter = VideoConverter()
                if let thumbnailData = try await converter.generateThumbnail(from: item.sourceURL) {
                    _ = try MediaStorageService.shared.saveFile(thumbnailData, withId: thumbnailId)
                }
            }

            // Save audio
            _ = try MediaStorageService.shared.saveFile(audioData, withId: audioId)

            // Create history item
            let historyItem = ConversionHistoryItem(
                originalVideoId: thumbnailId,
                convertedAudioId: audioId,
                fromFormat: item.originalFormat,
                toFormat: selectedFormat,
                fileSize: Int64(audioData.count),
                videoDuration: item.duration
            )

            await ConversionHistoryService.shared.addConversion(historyItem)
        } catch {
            print("Failed to save to history: \(error)")
        }
    }

    // MARK: - Retry Failed

    func retryFailed() async {
        // Reset failed items to ready
        for index in items.indices {
            if items[index].status.isFailed {
                items[index].status = .ready
            }
        }

        // Remove failed results
        results.removeAll { !$0.isSuccess }

        // Start conversion again
        await convertVideo()
    }

    func reset() {
        items.removeAll()
        results.removeAll()
        convertedAudioData = nil
        errorMessage = nil
        showResultView = false
        isConverting = false
        currentConvertingIndex = nil
    }
}

// MARK: - Video Transferable for PhotosPicker
struct VideoTransferable: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let tempDirectory = FileManager.default.temporaryDirectory
            let fileName = "video_\(UUID().uuidString).mov"
            let destinationURL = tempDirectory.appendingPathComponent(fileName)

            try FileManager.default.copyItem(at: received.file, to: destinationURL)
            return Self(url: destinationURL)
        }
    }
}
