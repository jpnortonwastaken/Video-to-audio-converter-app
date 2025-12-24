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

        // Determine the appropriate preset and output type
        let (preset, outputFileType, intermediateExtension) = getExportConfiguration(for: format)

        // Create export session
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw ConversionError.conversionFailed
        }

        // Create temporary output URL for the export
        let tempDirectory = FileManager.default.temporaryDirectory
        let exportFileName = "\(UUID().uuidString).\(intermediateExtension)"
        let exportURL = tempDirectory.appendingPathComponent(exportFileName)

        // Clean up any existing file
        try? FileManager.default.removeItem(at: exportURL)

        exportSession.outputURL = exportURL
        exportSession.outputFileType = outputFileType

        // Perform export
        await exportSession.export()

        // Check export status
        switch exportSession.status {
        case .completed:
            // If we need to convert from M4A to another format (WAV, AIFF)
            if needsPostConversion(for: format) {
                let convertedData = try await convertAudioFormat(from: exportURL, to: format)
                try? FileManager.default.removeItem(at: exportURL)
                return convertedData
            } else {
                // Read the exported file directly
                let audioData = try Data(contentsOf: exportURL)
                try? FileManager.default.removeItem(at: exportURL)
                return audioData
            }

        case .failed:
            let errorMessage = exportSession.error?.localizedDescription ?? "Unknown error"
            throw ConversionError.exportFailed(errorMessage)

        case .cancelled:
            throw ConversionError.conversionFailed

        default:
            throw ConversionError.conversionFailed
        }
    }

    /// Determines if the format requires post-conversion from M4A
    private func needsPostConversion(for format: AudioFormat) -> Bool {
        switch format {
        case .wav, .aiff:
            return true
        case .mp3, .m4a, .aac, .flac:
            return false
        }
    }

    /// Gets the export configuration for a given format
    /// Returns: (preset, outputFileType, intermediateExtension)
    private func getExportConfiguration(for format: AudioFormat) -> (String, AVFileType, String) {
        switch format {
        case .wav, .aiff:
            // Export to M4A first, then convert to target format
            return (AVAssetExportPresetAppleM4A, .m4a, "m4a")
        case .mp3, .m4a, .aac, .flac:
            // M4A/AAC use native M4A export; MP3/FLAC fall back to M4A
            return (AVAssetExportPresetAppleM4A, .m4a, "m4a")
        }
    }

    /// Converts audio from M4A to WAV or AIFF format using AVAudioFile
    private func convertAudioFormat(from sourceURL: URL, to format: AudioFormat) async throws -> Data {
        // Capture format properties before any async work to avoid actor isolation issues
        let fileExtension = format.fileExtension

        let sourceFile = try AVAudioFile(forReading: sourceURL)
        let processingFormat = sourceFile.processingFormat

        let tempDirectory = FileManager.default.temporaryDirectory
        let outputFileName = "\(UUID().uuidString).\(fileExtension)"
        let outputURL = tempDirectory.appendingPathComponent(outputFileName)

        // Clean up any existing file
        try? FileManager.default.removeItem(at: outputURL)

        // Determine the output settings based on format
        let outputSettings = createAudioSettings(for: format, sampleRate: processingFormat.sampleRate, channels: processingFormat.channelCount)

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputSettings,
            commonFormat: processingFormat.commonFormat,
            interleaved: processingFormat.isInterleaved
        )

        // Read and write in chunks to handle large files efficiently
        let bufferSize: AVAudioFrameCount = 4096
        guard let buffer = AVAudioPCMBuffer(pcmFormat: processingFormat, frameCapacity: bufferSize) else {
            throw ConversionError.conversionFailed
        }

        while sourceFile.framePosition < sourceFile.length {
            try sourceFile.read(into: buffer)
            try outputFile.write(from: buffer)
        }

        // Read the converted file
        let audioData = try Data(contentsOf: outputURL)
        try? FileManager.default.removeItem(at: outputURL)

        return audioData
    }

    /// Creates audio settings for the target format
    private func createAudioSettings(for format: AudioFormat, sampleRate: Double, channels: AVAudioChannelCount) -> [String: Any] {

        switch format {
        case .wav:
            return [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
        case .aiff:
            return [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: true,
                AVLinearPCMIsNonInterleaved: false
            ]
        default:
            return [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: sampleRate,
                AVNumberOfChannelsKey: channels
            ]
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
