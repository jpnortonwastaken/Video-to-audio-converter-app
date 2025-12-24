//
//  BatchConversionItem.swift
//  Video to Audio
//
//  Model for batch conversion queue items.
//

import Foundation
import SwiftUI

// MARK: - Batch Item Status

enum BatchItemStatus: Equatable, Sendable {
    case pending
    case loading
    case ready
    case converting(progress: Double)
    case completed(audioData: Data)
    case failed(error: String)

    var isTerminal: Bool {
        switch self {
        case .completed, .failed:
            return true
        default:
            return false
        }
    }

    var isCompleted: Bool {
        if case .completed = self {
            return true
        }
        return false
    }

    var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    var progress: Double {
        switch self {
        case .completed:
            return 1.0
        case .converting(let progress):
            return progress
        default:
            return 0.0
        }
    }
}

// MARK: - Batch Conversion Item

struct BatchConversionItem: Identifiable {
    let id: UUID
    let sourceURL: URL
    var title: String
    var thumbnail: UIImage?
    var duration: Double?
    var originalFormat: String
    var status: BatchItemStatus
    var isSecurityScoped: Bool
    var fileSize: Int64?
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        sourceURL: URL,
        title: String? = nil,
        isSecurityScoped: Bool = false
    ) {
        self.id = id
        self.sourceURL = sourceURL
        self.title = title ?? sourceURL.deletingPathExtension().lastPathComponent
        self.originalFormat = sourceURL.pathExtension.uppercased()
        self.status = .pending
        self.isSecurityScoped = isSecurityScoped
        self.dateAdded = Date()
    }

    // MARK: - Computed Properties

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var formattedFileSize: String? {
        guard let size = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    var statusIcon: String {
        switch status {
        case .pending:
            return "clock"
        case .loading:
            return "arrow.down.circle"
        case .ready:
            return "checkmark.circle"
        case .converting:
            return "arrow.triangle.2.circlepath"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.circle.fill"
        }
    }

    var statusColor: Color {
        switch status {
        case .pending:
            return .gray
        case .loading:
            return .blue
        case .ready:
            return .green
        case .converting:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

// MARK: - Batch Conversion Result

struct BatchConversionResult: Identifiable {
    let id: UUID
    let item: BatchConversionItem
    let audioData: Data?
    let error: String?
    let convertedFormat: AudioFormat

    var isSuccess: Bool { audioData != nil }

    var formattedFileSize: String? {
        guard let data = audioData else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(data.count))
    }
}
