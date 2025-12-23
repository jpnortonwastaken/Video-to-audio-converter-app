//
//  MediaStorageService.swift
//  Video to Audio
//
//  Service for managing persistent media storage on disk.
//

import Foundation
import UIKit

/// Service for managing persistent media file storage on disk
final class MediaStorageService: @unchecked Sendable {
    static nonisolated(unsafe) let shared = MediaStorageService()

    private nonisolated(unsafe) let fileManager = FileManager.default
    private let storageDirectory: URL

    private init() {
        // Create dedicated directory for conversion history files
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        storageDirectory = documentsDirectory.appendingPathComponent("ConversionHistory", isDirectory: true)

        // Create directory if it doesn't exist
        try? fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save Files

    /// Saves file data to disk and returns the file URL
    nonisolated func saveFile(_ data: Data, withId id: UUID) throws -> URL {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).dat")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    // MARK: - Load Files

    /// Loads file data from disk
    nonisolated func loadFile(withId id: UUID) throws -> Data {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).dat")
        return try Data(contentsOf: fileURL)
    }

    /// Loads file data from a file URL
    nonisolated func loadFile(from url: URL) throws -> Data {
        return try Data(contentsOf: url)
    }

    // MARK: - Delete Files

    /// Deletes a file from disk
    nonisolated func deleteFile(withId id: UUID) throws {
        let fileURL = storageDirectory.appendingPathComponent("\(id.uuidString).dat")
        try fileManager.removeItem(at: fileURL)
    }

    /// Deletes a file at the given URL
    nonisolated func deleteFile(at url: URL) throws {
        try fileManager.removeItem(at: url)
    }

    // MARK: - Cleanup

    /// Clears all stored files (useful for clearing history)
    nonisolated func clearAllFiles() throws {
        let contents = try fileManager.contentsOfDirectory(at: storageDirectory, includingPropertiesForKeys: nil)
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
    }

    /// Gets the total size of all stored files in bytes
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
