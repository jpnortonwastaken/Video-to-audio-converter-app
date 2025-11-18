//
//  HomeView.swift
//  AppFast
//
//  Created by Claude on 11/7/25.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var historyService = ConversionHistoryService.shared
    @State private var itemToDelete: ConversionHistoryItem?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // History Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("History")
                            .font(.roundedLargeTitle())
                            .fontWeight(.bold)
                    }

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 0)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))

                // History Content
                if historyService.items.isEmpty {
                    emptyStateView
                } else {
                    historyListView
                }
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .navigationBarHidden(true)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Delete Conversion", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                itemToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let item = itemToDelete {
                    HapticManager.shared.softImpact()
                    historyService.deleteItem(item)
                    itemToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this conversion from your history?")
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                    .frame(height: 100)

                VStack(spacing: 16) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.roundedSystem(size: 60))
                        .foregroundColor(.gray)

                    Text("No Conversions Yet")
                        .font(.roundedTitle2())
                        .fontWeight(.semibold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)

                    Text("Convert an image to see it here")
                        .font(.roundedBody())
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: 100)
            }
            .frame(maxWidth: .infinity)
            .padding(24)
        }
        .gradientFadeMask()
        .scrollIndicators(.hidden)
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
    }

    // MARK: - History List
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(historyService.items) { item in
                    historyCard(for: item)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 36)
            .padding(.bottom, 100)
        }
        .gradientFadeMask()
        .scrollIndicators(.hidden)
        .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
    }

    // MARK: - Helper Functions
    private func colorForFormat(_ format: String) -> Color {
        switch format.uppercased() {
        case "HEIC":
            return .blue
        case "JPG", "JPEG":
            return .red
        case "PNG":
            return .green
        case "PDF":
            return .orange
        case "GIF":
            return .purple
        case "TIFF":
            return .indigo
        case "WEBP":
            return .teal
        case "BMP":
            return .pink
        default:
            return .gray
        }
    }

    // MARK: - History Card
    private func historyCard(for item: ConversionHistoryItem) -> some View {
        NavigationLink(destination: ConversionResultView(
            convertedImageData: item.convertedImageData,
            format: item.toFormat,
            displayMode: .fullImage
        )) {
            HStack(spacing: 16) {
                // Thumbnail
                if let image = UIImage(data: item.convertedImageData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(item.fromFormat)
                            .font(.roundedCaption())
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForFormat(item.fromFormat).opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(colorForFormat(item.fromFormat).opacity(0.4), lineWidth: 1)
                            )

                        Image(systemName: "arrow.right")
                            .font(.roundedCaption())
                            .foregroundColor(.gray)

                        Text(item.toFormat.displayName)
                            .font(.roundedCaption())
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForFormat(item.toFormat.displayName).opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(colorForFormat(item.toFormat.displayName).opacity(0.4), lineWidth: 1)
                            )
                    }

                    Text(item.formattedDate)
                        .font(.roundedSubheadline())
                        .foregroundColor(.gray)

                    Text(item.formattedFileSize)
                        .font(.roundedCaption())
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.roundedBody())
                    .foregroundColor(.gray)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
        .simultaneousGesture(TapGesture().onEnded {
            HapticManager.shared.softImpact()
        })
        .buttonStyle(ScaleDownButtonStyle())
        .contextMenu {
            Button(role: .destructive) {
                HapticManager.shared.softImpact()
                itemToDelete = item
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

#Preview {
    HomeView()
}
