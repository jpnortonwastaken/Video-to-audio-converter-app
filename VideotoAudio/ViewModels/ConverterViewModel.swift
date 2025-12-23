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

    // Helper method to detect video format from URL
    func detectVideoFormat(from url: URL) -> String {
        let ext = url.pathExtension.uppercased()
        if ext.isEmpty {
            return "Unknown"
        }
        return ext
    }

    func loadVideoFromURL(_ url: URL) async {
        // Detect format from file extension
        originalVideoFormat = detectVideoFormat(from: url)

        // Store the URL
        selectedVideoURL = url

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

        do {
            // Need security scoped access for the file
            guard videoURL.startAccessingSecurityScopedResource() else {
                errorMessage = "Cannot access video file"
                isConverting = false
                return
            }
            defer { videoURL.stopAccessingSecurityScopedResource() }

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
    }

    var formattedDuration: String? {
        guard let duration = videoDuration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
