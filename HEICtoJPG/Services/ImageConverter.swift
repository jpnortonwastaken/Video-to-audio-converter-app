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

    /// Normalizes image orientation by redrawing it with the orientation baked in
    /// This ensures EXIF orientation metadata is properly applied to the pixel data
    private func normalizeOrientation(_ image: UIImage) throws -> CGImage {
        guard let cgImage = image.cgImage else {
            throw ConversionError.invalidImage
        }

        // If orientation is already up, no need to redraw
        if image.imageOrientation == .up {
            return cgImage
        }

        // Validate image size
        guard image.size.width > 0 && image.size.height > 0 else {
            throw ConversionError.invalidImage
        }

        // Use UIGraphicsImageRenderer for proper coordinate system handling
        // This ensures top-left origin (UIKit) instead of bottom-left (CGContext)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Use 1:1 scale to preserve exact dimensions
        format.opaque = false // Preserve transparency if present
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        let normalizedUIImage = renderer.image { context in
            // UIImage.draw automatically applies the orientation transformation
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }

        guard let normalizedCGImage = normalizedUIImage.cgImage else {
            throw ConversionError.conversionFailed
        }

        return normalizedCGImage
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
        // Normalize orientation to ensure image is not sideways
        let cgImage = try normalizeOrientation(image)

        // HEIC conversion using CIImage from the normalized CGImage
        let ciImage = CIImage(cgImage: cgImage)

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

        guard let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            throw ConversionError.conversionFailed
        }

        // Normalize orientation to ensure image is not sideways
        let cgImage = try normalizeOrientation(image)

        // Use the actual pixel dimensions of the image, not the point size
        // This ensures the PDF has the correct dimensions regardless of @2x/@3x scale
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)

        guard let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &mediaBox, nil) else {
            throw ConversionError.conversionFailed
        }

        pdfContext.beginPage(mediaBox: &mediaBox)

        // Draw the image - CGContext draws from bottom-left origin (correct for PDF)
        // The mediaBox is already set with the correct dimensions
        pdfContext.draw(cgImage, in: mediaBox)

        pdfContext.endPage()
        pdfContext.closePDF()

        return pdfData as Data
    }

    private func convertToGIF(_ image: UIImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.gif.identifier as CFString, 1, nil) else {
            throw ConversionError.conversionFailed
        }

        // Normalize orientation to ensure image is not sideways
        let cgImage = try normalizeOrientation(image)

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }

        return data as Data
    }

    private func convertToTIFF(_ image: UIImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.tiff.identifier as CFString, 1, nil) else {
            throw ConversionError.conversionFailed
        }

        // Normalize orientation to ensure image is not sideways
        let cgImage = try normalizeOrientation(image)

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }

        return data as Data
    }

    private func convertToBMP(_ image: UIImage) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.bmp.identifier as CFString, 1, nil) else {
            throw ConversionError.conversionFailed
        }

        // Normalize orientation to ensure image is not sideways
        let cgImage = try normalizeOrientation(image)

        CGImageDestinationAddImage(destination, cgImage, nil)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.conversionFailed
        }

        return data as Data
    }
}
