//
//  ConverterViewModel.swift
//  HEIC to JPG
//
//  Created by Claude on 11/14/25.
//

import SwiftUI
import Combine
import PhotosUI
import UniformTypeIdentifiers

@MainActor
class ConverterViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedFormat: ImageFormat = .jpg
    @Published var selectedImage: UIImage?
    @Published var isConverting = false
    @Published var showPhotoPicker = false
    @Published var showFilePicker = false
    @Published var showFormatPicker = false
    @Published var errorMessage: String?
    @Published var convertedImageData: Data?
    @Published var showResultView = false
    @Published var originalImageFormat: String = "HEIC"

    // MARK: - Photo Picker
    @Published var selectedPhotoItem: PhotosPickerItem?

    // MARK: - Methods

    func selectFromPhotos() {
        HapticManager.shared.softImpact()
        showPhotoPicker = true
    }

    func selectFromFiles() {
        HapticManager.shared.softImpact()
        showFilePicker = true
    }

    func pasteImage() {
        HapticManager.shared.softImpact()

        // Check if clipboard has an image
        if let image = UIPasteboard.general.image {
            selectedImage = image
            // Clipboard images are typically PNG
            originalImageFormat = "PNG"
        } else {
            errorMessage = "No image found in clipboard"
        }
    }

    // Helper method to detect image format from data
    func detectImageFormat(from data: Data) -> String {
        // Check magic bytes to identify format
        guard data.count >= 12 else { return "Unknown" }

        let bytes = [UInt8](data.prefix(12))

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return "JPEG"
        }

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "PNG"
        }

        // GIF: 47 49 46 38
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
            return "GIF"
        }

        // BMP: 42 4D
        if bytes[0] == 0x42 && bytes[1] == 0x4D {
            return "BMP"
        }

        // TIFF: 49 49 2A 00 (little endian) or 4D 4D 00 2A (big endian)
        if (bytes[0] == 0x49 && bytes[1] == 0x49 && bytes[2] == 0x2A && bytes[3] == 0x00) ||
           (bytes[0] == 0x4D && bytes[1] == 0x4D && bytes[2] == 0x00 && bytes[3] == 0x2A) {
            return "TIFF"
        }

        // HEIC/HEIF: Check for 'ftyp' box and heic/mif1 brand
        // Bytes 4-7 should be 'ftyp'
        if bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            // Check for heic brand (bytes 8-11)
            if data.count >= 16 {
                let brandBytes = [UInt8](data[8..<12])
                let brand = String(bytes: brandBytes, encoding: .ascii) ?? ""
                if brand.contains("heic") || brand.contains("mif1") {
                    return "HEIC"
                }
            }
        }

        // PDF: 25 50 44 46 (%PDF)
        if bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46 {
            return "PDF"
        }

        return "Unknown"
    }

    func loadImageFromData(_ data: Data) {
        // Detect format before creating UIImage
        originalImageFormat = detectImageFormat(from: data)

        // Create UIImage from data
        if let image = UIImage(data: data) {
            selectedImage = image
        }
    }

    func loadPhotoPickerItem() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                loadImageFromData(data)
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }

    func convertImage() async {
        guard let selectedImage else {
            errorMessage = "No image selected"
            return
        }

        isConverting = true
        HapticManager.shared.softImpact()

        do {
            let converter = ImageConverter()
            let convertedData = try await converter.convert(
                image: selectedImage,
                to: selectedFormat
            )

            // Store the converted data
            convertedImageData = convertedData

            // Save to history
            saveConversionToHistory(
                originalImage: selectedImage,
                convertedData: convertedData
            )

            HapticManager.shared.success()

            // Show result view
            showResultView = true
        } catch {
            errorMessage = "Conversion failed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isConverting = false
    }

    private func saveConversionToHistory(originalImage: UIImage, convertedData: Data) {
        // Get original image data
        guard let originalData = originalImage.pngData() else {
            return
        }

        // Create history item
        let historyItem = ConversionHistoryItem(
            originalImageData: originalData,
            convertedImageData: convertedData,
            fromFormat: originalImageFormat,
            toFormat: selectedFormat,
            fileSize: Int64(convertedData.count)
        )

        // Save to history service
        ConversionHistoryService.shared.addConversion(historyItem)
    }

    func reset() {
        selectedImage = nil
        convertedImageData = nil
        selectedPhotoItem = nil
        errorMessage = nil
        showResultView = false
    }
}
