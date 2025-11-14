//
//  ImageFormat.swift
//  HEIC to JPG
//
//  Created by Claude on 11/14/25.
//

import Foundation
import UniformTypeIdentifiers

enum ImageFormat: String, CaseIterable, Identifiable {
    case jpg = "JPG"
    case png = "PNG"
    case heic = "HEIC"
    case pdf = "PDF"
    case webp = "WEBP"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var utType: UTType {
        switch self {
        case .jpg:
            return .jpeg
        case .png:
            return .png
        case .heic:
            return .heic
        case .pdf:
            return .pdf
        case .webp:
            return .webP
        }
    }

    var fileExtension: String {
        switch self {
        case .jpg:
            return "jpg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        case .pdf:
            return "pdf"
        case .webp:
            return "webp"
        }
    }
}
