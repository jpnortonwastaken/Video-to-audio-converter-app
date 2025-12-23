//
//  ConversionHistory.swift
//  Video to Audio
//
//  Data model for conversion history items.
//

import Foundation
import SwiftUI

struct ConversionHistoryItem: Identifiable, Codable {
    let id: UUID
    let originalVideoId: UUID  // References video thumbnail on disk
    let convertedAudioId: UUID  // References audio file on disk
    let fromFormat: String  // Original video format (e.g., "MP4", "MOV")
    let toFormat: AudioFormat
    let date: Date
    let fileSize: Int64
    let videoDuration: Double?  // Duration in seconds

    init(
        id: UUID = UUID(),
        originalVideoId: UUID,
        convertedAudioId: UUID,
        fromFormat: String,
        toFormat: AudioFormat,
        date: Date = Date(),
        fileSize: Int64,
        videoDuration: Double? = nil
    ) {
        self.id = id
        self.originalVideoId = originalVideoId
        self.convertedAudioId = convertedAudioId
        self.fromFormat = fromFormat
        self.toFormat = toFormat
        self.date = date
        self.fileSize = fileSize
        self.videoDuration = videoDuration
    }

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    var formattedDuration: String? {
        guard let duration = videoDuration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - File Loading

    /// Load video thumbnail data from disk
    nonisolated func loadThumbnailData() throws -> Data {
        return try MediaStorageService.shared.loadFile(withId: originalVideoId)
    }

    /// Load converted audio data from disk
    nonisolated func loadConvertedAudioData() throws -> Data {
        return try MediaStorageService.shared.loadFile(withId: convertedAudioId)
    }

    /// Load thumbnail as UIImage
    nonisolated func loadThumbnail() -> UIImage? {
        guard let data = try? loadThumbnailData() else { return nil }
        return UIImage(data: data)
    }
}
