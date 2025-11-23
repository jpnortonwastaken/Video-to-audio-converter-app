//
//  ConversionHistory.swift
//  HEIC to JPG
//
//  Created by Claude on 11/15/25.
//

import Foundation
import SwiftUI

struct ConversionHistoryItem: Identifiable, Codable {
    let id: UUID
    let originalImageId: UUID  // References file on disk
    let convertedImageId: UUID  // References file on disk
    let fromFormat: String
    let toFormat: ImageFormat
    let date: Date
    let fileSize: Int64

    init(
        id: UUID = UUID(),
        originalImageId: UUID,
        convertedImageId: UUID,
        fromFormat: String,
        toFormat: ImageFormat,
        date: Date = Date(),
        fileSize: Int64
    ) {
        self.id = id
        self.originalImageId = originalImageId
        self.convertedImageId = convertedImageId
        self.fromFormat = fromFormat
        self.toFormat = toFormat
        self.date = date
        self.fileSize = fileSize
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

    // MARK: - Image Loading

    /// Load original image data from disk
    nonisolated func loadOriginalImageData() throws -> Data {
        return try ImageStorageService.shared.loadImage(withId: originalImageId)
    }

    /// Load converted image data from disk
    nonisolated func loadConvertedImageData() throws -> Data {
        return try ImageStorageService.shared.loadImage(withId: convertedImageId)
    }

    /// Load original image as UIImage
    nonisolated func loadOriginalImage() -> UIImage? {
        guard let data = try? loadOriginalImageData() else { return nil }
        return UIImage(data: data)
    }

    /// Load converted image as UIImage
    nonisolated func loadConvertedImage() -> UIImage? {
        guard let data = try? loadConvertedImageData() else { return nil }
        return UIImage(data: data)
    }
}
