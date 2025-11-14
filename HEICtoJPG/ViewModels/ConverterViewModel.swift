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
    @Published var convertedImage: UIImage?

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

            if let converted = UIImage(data: convertedData) {
                convertedImage = converted
                // Save to photo library or share
                saveConvertedImage(convertedData)
            }

            HapticManager.shared.success()
        } catch {
            errorMessage = "Conversion failed: \(error.localizedDescription)"
            HapticManager.shared.error()
        }

        isConverting = false
    }

    private func saveConvertedImage(_ data: Data) {
        // TODO: Implement save to photo library
        // This will be implemented when we add the save functionality
    }

    func reset() {
        selectedImage = nil
        convertedImage = nil
        selectedPhotoItem = nil
        errorMessage = nil
    }
}
