//
//  ImageStorageService.swift
//  HEIC to JPG
//
//  Created by Claude on 11/23/25.
//

import Foundation
import UIKit

/// Service for managing persistent image storage on disk
final class ImageStorageService: @unchecked Sendable {
    static nonisolated(unsafe) let shared = ImageStorageService()

    private nonisolated(unsafe) let fileManager = FileManager.default
    private let storageDirectory: URL

    private init() {
        // Create dedicated directory for conversion history images
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageDirectory = documentsDirectory.appendingPathComponent("ConversionHistory", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save Images

    /// Saves image data to disk and returns the file URL
    nonisolated func saveImage(_ data: Data, withId id: UUID) throws -> URL {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).dat")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    // MARK: - Load Images

    /// Loads image data from disk
    nonisolated func loadImage(withId id: UUID) throws -> Data {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).dat")
        return try Data(contentsOf: fileURL)
    }

    /// Loads image data from a file URL
    nonisolated func loadImage(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    // MARK: - Delete Images

    /// Deletes an image file from disk
    nonisolated func deleteImage(withId id: UUID) throws {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).dat")
        try fileManager.removeItem(at: fileURL)
    }

    /// Deletes an image file at the given URL
    nonisolated func deleteImage(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    // MARK: - Cleanup

    /// Clears all stored images (useful for clearing history)
    nonisolated func clearAllImages() throws {
        let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Gets the total size of all stored images in bytes
    nonisolated func getTotalStorageSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for fileURL in contents {
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
               let fileSize = resourceValues.fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
}
