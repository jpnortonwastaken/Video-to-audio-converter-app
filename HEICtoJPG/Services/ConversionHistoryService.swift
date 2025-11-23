//
//  ConversionHistoryService.swift
//  HEIC to JPG
//
//  Created by Claude on 11/15/25.
//

import Foundation
import Combine

class ConversionHistoryService: ObservableObject {
    static let shared = ConversionHistoryService()

    @Published var items: [ConversionHistoryItem] = []
    @Published var isLoading = false

    private let userDefaultsKey = "conversionHistory"
    private let maxHistoryItems = 100
    private var hasLoadedOnce = false

    private init() {
        // Don't load synchronously - let views trigger async load
    }

    // Load history asynchronously on first access
    func loadHistoryIfNeeded() async {
        guard !hasLoadedOnce else { return }
        hasLoadedOnce = true

        await MainActor.run {
            isLoading = true
        }

        // Load and decode off the main thread
        let loadedItems = await Task.detached(priority: .userInitiated) {
            guard let data = UserDefaults.standard.data(forKey: self.userDefaultsKey) else {
                print("📂 No existing history found in UserDefaults")
                return [ConversionHistoryItem]()
            }

            do {
                let sizeInMB = Double(data.count) / 1_048_576.0
                print("📂 Loading history data: \(String(format: "%.2f", sizeInMB)) MB")

                let decoder = JSONDecoder()
                let items = try decoder.decode([ConversionHistoryItem].self, from: data)
                print("✅ Successfully loaded \(items.count) items from history")
                return items
            } catch {
                print("❌ Failed to load conversion history: \(error)")
                print("   Error details: \(error.localizedDescription)")
                return [ConversionHistoryItem]()
            }
        }.value

        await MainActor.run {
            self.items = loadedItems
            self.isLoading = false
        }
    }

    func addConversion(_ item: ConversionHistoryItem) async {
        // Ensure history is loaded before adding new items
        await loadHistoryIfNeeded()

        // Add new item at the beginning
        await MainActor.run {
            items.insert(item, at: 0)

            // Limit history size
            if items.count > maxHistoryItems {
                items = Array(items.prefix(maxHistoryItems))
            }
        }

        saveHistory()
    }

    func deleteItem(_ item: ConversionHistoryItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearAll() {
        items.removeAll()
        saveHistory()
    }

    private func saveHistory() {
        let itemsToSave = items
        let key = userDefaultsKey
        Task.detached(priority: .utility) {
            do {
                let encoder = JSONEncoder()
                let data = try encoder.encode(itemsToSave)

                // Log data size for debugging
                let sizeInMB = Double(data.count) / 1_048_576.0
                print("💾 Attempting to save \(itemsToSave.count) items, total size: \(String(format: "%.2f", sizeInMB)) MB")

                // Check if data is too large for UserDefaults (typical limit ~4MB)
                if data.count > 4_000_000 {
                    print("⚠️ WARNING: History data (\(String(format: "%.2f", sizeInMB)) MB) exceeds recommended UserDefaults limit (4MB)")
                }

                UserDefaults.standard.set(data, forKey: key)
                // Force immediate write to disk to prevent data loss on app termination
                let success = UserDefaults.standard.synchronize()

                if success {
                    print("✅ Successfully saved history to disk")
                } else {
                    print("❌ UserDefaults.synchronize() returned false - save may have failed")
                }
            } catch {
                print("❌ Failed to save conversion history: \(error)")
            }
        }
    }
}
