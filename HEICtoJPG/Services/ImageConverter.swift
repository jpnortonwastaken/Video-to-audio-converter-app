//
//  ImageConverter.swift
//  HEIC to JPG
//
//  Created by Claude on 11/14/25.
//

import UIKit
import PDFKit
import UniformTypeIdentifiers

enum ConversionError: LocalizedError {
    case invalidImage
    case conversionFailed
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data"
        case .conversionFailed:
            return "Failed to convert image"
        case .unsupportedFormat:
            return "Unsupported format"
        }
    }
}

actor ImageConverter {
    func convert(image: UIImage, to format: ImageFormat) async throws -> Data {
        switch format {
        case .jpg, .jpeg:
            return try convertToJPEG(image)
        case .png:
            return try convertToPNG(image)
        case .heic:
            return try convertToHEIC(image)
        case .pdf:
            return try convertToPDF(image)
        case .webp:
            // WebP conversion would require additional library
            // For now, fallback to PNG
            return try convertToPNG(image)
        case .gif:
            return try convertToGIF(image)
        case .tiff:
            return try convertToTIFF(image)
        case .bmp:
            return try convertToBMP(image)
        }
    }

    private func convertToJPEG(_ image: UIImage) throws -> Data {
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw ConversionError.conversionFailed
        }
        return data
    }

    private func convertToPNG(_ image: UIImage) throws -> Data {
        guard let data = image.pngData() else {
            throw ConversionError.conversionFailed
        }
        return data
    }

    private func convertToHEIC(_ image: UIImage) throws -> Data {
        // HEIC conversion using UIImage
        let ciImage = CIImage(image: image)
        guard let ciImage = ciImage else {
            throw ConversionError.invalidImage
        }

        let context = CIContext()
        let colorSpace = CGColorSpaceCreateDeviceRGB()

        guard let data = context.heifRepresentation(
            of: ciImage,
            format: .RGBA8,
            colorSpace: colorSpace,
            options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption: 0.9]
        ) else {
            throw ConversionError.conversionFailed
        }

        return data
    }

    private func convertToPDF(_ image: UIImage) throws -> Data {
        let pdfData = NSMutableData()
        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!

        var mediaBox = CGRect(origin: .zero, size: image.size)

        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            throw ConversionError.conversionFailed
        }

        pdfContext.beginPage(mediaBox: &mediaBox)

        guard let cgImage = image.cgImage else {
            throw ConversionError.invalidImage
        }

        pdfContext.draw(cgImage, in: mediaBox)
        pdfContext.endPage()
        pdfContext.closePDF()

        return pdfData as Data
    }

    private func convertToGIF(_ image: UIImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 1, nil),
              let cgImage = image.cgImage else {
            throw ConversionError.conversionFailed
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }

        return data as Data
    }

    private func convertToTIFF(_ image: UIImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.tiff.identifier as CFString, 1, nil),
              let cgImage = image.cgImage else {
            throw ConversionError.conversionFailed
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }

        return data as Data
    }

    private func convertToBMP(_ image: UIImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.bmp.identifier as CFString, 1, nil),
              let cgImage = image.cgImage else {
            throw ConversionError.conversionFailed
        }

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }

        return data as Data
    }
}
