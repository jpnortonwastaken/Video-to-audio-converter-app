//
//  AudioFormat.swift
//  Video to Audio
//
//  Audio format definitions for video-to-audio conversion.
//

import Foundation
import UniformTypeIdentifiers

enum AudioFormat: String, CaseIterable, Identifiable, Codable {
    case mp3 = "MP3"
    case m4a = "M4A"
    case wav = "WAV"
    case aac = "AAC"
    case flac = "FLAC"
    case aiff = "AIFF"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var utType: UTType {
        switch self {
        case .mp3:
            return .mp3
        case .m4a:
            return .mpeg4Audio
        case .wav:
            return .wav
        case .aac:
            return UTType(filenameExtension: "aac") ?? .audio
        case .flac:
            return UTType(filenameExtension: "flac") ?? .audio
        case .aiff:
            return .aiff
        }
    }

    var fileExtension: String {
        switch self {
        case .mp3:
            return "mp3"
        case .m4a:
            return "m4a"
        case .wav:
            return "wav"
        case .aac:
            return "aac"
        case .flac:
            return "flac"
        case .aiff:
            return "aiff"
        }
    }
}
