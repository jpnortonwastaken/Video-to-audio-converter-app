//
//  ConverterViewModel.swift
//  Video to Audio
//
//  ViewModel for handling video-to-audio conversion.
//

import SwiftUI
import Combine
import AVFoundation
import UniformTypeIdentifiers
import PhotosUI

@MainActor
class ConverterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedFormat: AudioFormat = .mp3
    @Published var selectedVideoURL: URL?
    @Published var videoThumbnail: UIImage?
    @Published var videoDuration: Double?
    @Published var isConverting = false
    @Published var showFilePicker = false
    @Published var showFormatPicker = false
    @Published var errorMessage: String?
    @Published var convertedAudioData: Data?
    @Published var showResultView = false
    @Published var originalVideoFormat: String = "MP4"
    @Published var selectedPhotoItem: PhotosPickerItem?
    @Published var isLoadingFromPhotos = false

    // Track if URL requires security-scoped access (only for Files picker)
    private var isSecurityScoped = false

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

    // MARK: - Methods

    func selectFromFiles() {
        HapticManager.shared.softImpact()

        // Check subscription before allowing access
        guard SubscriptionService.shared.requireSubscription() else {
            return
        }

        showFilePicker = true
    }

    func handlePhotoPickerSelection(_ item: PhotosPickerItem?) async {
        guard let item = item else { return }

        // Check subscription before allowing access
        guard SubscriptionService.shared.requireSubscription() else {
            return
        }

        isLoadingFromPhotos = true
        HapticManager.shared.softImpact()

        do {
            // Load the video data from Photos
            if let movie = try await item.loadTransferable(type: VideoTransferable.self) {
                await loadVideoFromURL(movie.url)
            } else {
                errorMessage = "Could not load video from Photos"
            }
        } catch {
            errorMessage = "Failed to load video: \(error.localizedDescription)"
        }

        isLoadingFromPhotos = false
        selectedPhotoItem = nil
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
                    await loadVideoFromURL(url)
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
                        await loadVideoFromURL(tempURL)
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

    // Helper method to detect video format from URL
    func detectVideoFormat(from url: URL) -> String {
        let ext = url.pathExtension.uppercased()
        if ext.isEmpty {
            return "Unknown"
        }
        return ext
    }

    func loadVideoFromURL(_ url: URL, securityScoped: Bool = false) async {
        // Detect format from file extension
        originalVideoFormat = detectVideoFormat(from: url)

        // Store the URL and security scope status
        selectedVideoURL = url
        isSecurityScoped = securityScoped

        // Generate thumbnail and get duration
        let converter = VideoConverter()

        do {
            // Get duration
            videoDuration = try await converter.getVideoDuration(from: url)

            // Generate thumbnail
            if let thumbnailData = try await converter.generateThumbnail(from: url) {
                videoThumbnail = UIImage(data: thumbnailData)
            }
        } catch {
            print("❌ Failed to load video info: \(error)")
            // Still allow conversion even if thumbnail fails
        }
    }

    func convertVideo() async {
        guard let videoURL = selectedVideoURL else {
            errorMessage = "No video selected"
            return
        }

        // Check subscription before allowing conversion
        guard SubscriptionService.shared.requireSubscription() else {
            return
        }

        isConverting = true
        HapticManager.shared.softImpact()

        // Only use security-scoped access for files from the Files picker
        let needsSecurityScope = isSecurityScoped
        if needsSecurityScope {
            _ = videoURL.startAccessingSecurityScopedResource()
        }

        do {
            let converter = VideoConverter()
            let audioData = try await converter.extractAudio(
                from: videoURL,
                to: selectedFormat
            )

            // Store the converted data
            convertedAudioData = audioData

            // Save to history
            await saveConversionToHistory(
                videoURL: videoURL,
                convertedData: audioData
            )

            HapticManager.shared.success()

            // Show result view
            showResultView = true
        } catch {
            errorMessage = "Conversion failed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        if needsSecurityScope {
            videoURL.stopAccessingSecurityScopedResource()
        }

        isConverting = false
    }

    private func saveConversionToHistory(videoURL: URL, convertedData: Data) async {
        // Generate UUIDs for the files
        let thumbnailId = UUID()
        let audioId = UUID()

        // Save thumbnail to disk
        do {
            let converter = VideoConverter()
            if let thumbnailData = try await converter.generateThumbnail(from: videoURL) {
                _ = try MediaStorageService.shared.saveFile(thumbnailData, withId: thumbnailId)
            }
            _ = try MediaStorageService.shared.saveFile(convertedData, withId: audioId)
        } catch {
            print("❌ Failed to save files to disk: \(error)")
            return
        }

        // Create history item with file IDs
        let historyItem = ConversionHistoryItem(
            originalVideoId: thumbnailId,
            convertedAudioId: audioId,
            fromFormat: originalVideoFormat,
            toFormat: selectedFormat,
            fileSize: Int64(convertedData.count),
            videoDuration: videoDuration
        )

        // Save to history service
        await ConversionHistoryService.shared.addConversion(historyItem)
    }

    func reset() {
        selectedVideoURL = nil
        videoThumbnail = nil
        videoDuration = nil
        convertedAudioData = nil
        errorMessage = nil
        showResultView = false
        isSecurityScoped = false
    }

    var formattedDuration: String? {
        guard let duration = videoDuration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
