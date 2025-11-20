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
        } else {
            errorMessage = "No image found in clipboard"
        }
    }

    func loadPhotoPickerItem() async {
        guard let selectedPhotoItem else { return }

        do {
            if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                if let image = UIImage(data: data) {
                    selectedImage = image
                }
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
