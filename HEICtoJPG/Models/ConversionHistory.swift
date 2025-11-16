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
    let originalImageData: Data
    let convertedImageData: Data
    let fromFormat: String
    let toFormat: ImageFormat
    let date: Date
    let fileSize: Int64

    init(
        id: UUID = UUID(),
        originalImageData: Data,
        convertedImageData: Data,
        fromFormat: String,
        toFormat: ImageFormat,
        date: Date = Date(),
        fileSize: Int64
    ) {
        self.id = id
        self.originalImageData = originalImageData
        self.convertedImageData = convertedImageData
        self.fromFormat = fromFormat
        self.toFormat = toFormat
        self.date = date
        self.fileSize = fileSize
    }

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
}
