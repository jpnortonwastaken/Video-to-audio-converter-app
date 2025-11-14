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
    case jpeg = "JPEG"
    case pdf = "PDF"
    case png = "PNG"
    case gif = "GIF"
    case tiff = "TIFF"
    case webp = "WEBP"
    case bmp = "BMP"
    case heic = "HEIC"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var utType: UTType {
        switch self {
        case .jpg, .jpeg:
            return .jpeg
        case .png:
            return .png
        case .heic:
            return .heic
        case .pdf:
            return .pdf
        case .webp:
            return .webP
        case .gif:
            return .gif
        case .tiff:
            return .tiff
        case .bmp:
            return .bmp
        }
    }

    var fileExtension: String {
        switch self {
        case .jpg:
            return "jpg"
        case .jpeg:
            return "jpeg"
        case .png:
            return "png"
        case .heic:
            return "heic"
        case .pdf:
            return "pdf"
        case .webp:
            return "webp"
        case .gif:
            return "gif"
        case .tiff:
            return "tiff"
        case .bmp:
            return "bmp"
        }
    }
}
