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

    private let userDefaultsKey = "conversionHistory"
    private let maxHistoryItems = 100

    private init() {
        loadHistory()
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
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(items)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("❌ Failed to save conversion history: \(error)")
        }
    }

    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return
        }

        do {
            let decoder = JSONDecoder()
            items = try decoder.decode([ConversionHistoryItem].self, from: data)
        } catch {
            print("❌ Failed to load conversion history: \(error)")
        }
    }
}
