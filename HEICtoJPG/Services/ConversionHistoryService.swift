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
                return [ConversionHistoryItem]()
            }

            do {
                let decoder = JSONDecoder()
                return try decoder.decode([ConversionHistoryItem].self, from: data)
            } catch {
                print("❌ Failed to load conversion history: \(error)")
                return [ConversionHistoryItem]()
            }
        }.value

        await MainActor.run {
            self.items = loadedItems
            self.isLoading = false
        }
    }

    func addConversion(_ item: ConversionHistoryItem) {
        // Add new item at the beginning
        items.insert(item, at: 0)

        // Limit history size
        if items.count > maxHistoryItems {
            items = Array(items.prefix(maxHistoryItems))
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
                UserDefaults.standard.set(data, forKey: key)
                // Force immediate write to disk to prevent data loss on app termination
                UserDefaults.standard.synchronize()
            } catch {
                print("❌ Failed to save conversion history: \(error)")
            }
        }
    }
}
