//
//  VideoConverter.swift
//  Video to Audio
//
//  Handles video-to-audio extraction using AVFoundation.
//

import AVFoundation
import Foundation
import UIKit

enum ConversionError: LocalizedError {
    case invalidVideo
    case conversionFailed
    case unsupportedFormat
    case exportFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidVideo:
            return "Invalid video file"
        case .conversionFailed:
            return "Failed to extract audio"
        case .unsupportedFormat:
            return "Unsupported format"
        case .exportFailed(let message):
            return "Export failed: \(message)"
        }
    }
}

actor VideoConverter {

    /// Extracts audio from a video file and converts it to the specified format
    /// - Parameters:
    ///   - videoURL: URL to the source video file
    ///   - format: The target audio format
    /// - Returns: Data containing the extracted audio
    func extractAudio(from videoURL: URL, to format: AudioFormat) async throws -> Data {
        let asset = AVAsset(url: videoURL)

        // Check if asset has audio tracks
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw ConversionError.invalidVideo
        }

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw ConversionError.conversionFailed
        }

        // Create temporary output URL
        let tempDirectory = FileManager.default.temporaryDirectory
        let outputFileName = "\(UUID().uuidString).\(format.fileExtension)"
        let outputURL = tempDirectory.appendingPathComponent(outputFileName)

        // Clean up any existing file
        try? FileManager.default.removeItem(at: outputURL)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = getOutputFileType(for: format)

        // Perform export
        await exportSession.export()

        // Check export status
        switch exportSession.status {
        case .completed:
            // Read the exported file
            let audioData = try Data(contentsOf: outputURL)
            // Clean up temp file
            try? FileManager.default.removeItem(at: outputURL)
            return audioData

        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw ConversionError.exportFailed(errorMessage)

        case .cancelled:
            throw ConversionError.conversionFailed

        default:
            throw ConversionError.conversionFailed
        }
    }

    /// Gets the appropriate AVFileType for the target audio format
    private func getOutputFileType(for format: AudioFormat) -> AVFileType {
        switch format {
        case .mp3:
            // Note: AVAssetExportSession doesn't directly support MP3
            // We'll use M4A and can convert to MP3 with additional processing if needed
            return .m4a
        case .m4a, .aac:
            return .m4a
        case .wav:
            return .wav
        case .aiff:
            return .aiff
        case .flac:
            // FLAC isn't natively supported, fallback to M4A
            return .m4a
        }
    }

    /// Gets the duration of a video file in seconds
    func getVideoDuration(from videoURL: URL) async throws -> Double {
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration)
        return CMTimeGetSeconds(duration)
    }

    /// Generates a thumbnail image from a video at a specific time
    func generateThumbnail(from videoURL: URL, at time: CMTime = .zero) async throws -> Data? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 400, height: 400)

        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage.jpegData(compressionQuality: 0.8)
        } catch {
            return nil
        }
    }
}
