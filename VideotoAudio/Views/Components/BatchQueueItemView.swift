//
//  BatchQueueItemView.swift
//  Video to Audio
//
//  Individual queue item card for batch conversion.
//

import SwiftUI

struct BatchQueueItemView: View {
    let item: BatchConversionItem
    let onRemove: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            thumbnailView

            // Info
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(item.title)
                    .font(.roundedSubheadline())
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)

                // Format and duration row
                HStack(spacing: 8) {
                    // Format badge
                    formatBadge

                    // Duration
                    if let duration = item.formattedDuration {
                        Text(duration)
                            .font(.roundedCaption())
                            .foregroundColor(.gray)
                    }
                }

                // File size
                if let size = item.formattedFileSize {
                    Text(size)
                        .font(.roundedCaption())
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            // Status indicator or remove button
            statusView
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appTertiaryBackground(for: colorScheme))
        )
    }

    // MARK: - Thumbnail View

    private var thumbnailView: some View {
        Group {
            if let thumbnail = item.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if case .loading = item.status {
                // Loading placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground(for: colorScheme))
                    .frame(width: 70, height: 70)
                    .overlay(
                        LoadingSpinner(size: 20)
                    )
            } else {
                // Default placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.appCardBackground(for: colorScheme))
                    .frame(width: 70, height: 70)
                    .overlay(
                        Image(systemName: "video")
                            .font(.roundedTitle3())
                            .foregroundColor(.gray)
                    )
            }
        }
    }

    // MARK: - Format Badge

    private var formatBadge: some View {
        Text(item.originalFormat)
            .font(.roundedCaption())
            .fontWeight(.medium)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(colorForFormat(item.originalFormat).opacity(0.2))
            )
            .overlay(
                Capsule()
                    .stroke(
                        colorForFormat(item.originalFormat).opacity(0.4),
                        style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [3, 3])
                    )
            )
    }

    // MARK: - Status View

    @ViewBuilder
    private var statusView: some View {
        switch item.status {
        case .pending, .loading:
            // Loading indicator
            LoadingSpinner(size: 24)

        case .ready:
            // Remove button
            Button(action: {
                HapticManager.shared.softImpact()
                onRemove()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.roundedTitle2())
                    .foregroundColor(.gray)
            }
            .buttonStyle(ScaleDownButtonStyle())

        case .converting(let progress):
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    .frame(width: 32, height: 32)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 32, height: 32)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))")
                    .font(.roundedSystem(size: 10))
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }

        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.roundedTitle2())
                .foregroundColor(.green)

        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.roundedTitle2())
                .foregroundColor(.red)
        }
    }

    // MARK: - Helpers

    private func colorForFormat(_ format: String) -> Color {
        switch format.uppercased() {
        case "MP4", "MOV", "AVI", "MKV", "WEBM", "FLV", "WMV":
            return .blue
        case "MP3":
            return .red
        case "M4A", "AAC":
            return .orange
        case "WAV":
            return .green
        case "FLAC":
            return .purple
        case "AIFF":
            return .teal
        default:
            return .gray
        }
    }
}

// MARK: - Compact Version for Results

struct BatchQueueItemCompactView: View {
    let result: BatchConversionResult
    let onShare: () -> Void
    let onSave: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = result.item.thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.appCardBackground(for: colorScheme))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: result.isSuccess ? "waveform" : "exclamationmark.triangle")
                            .font(.roundedBody())
                            .foregroundColor(result.isSuccess ? .gray : .red)
                    )
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.item.title)
                    .font(.roundedSubheadline())
                    .fontWeight(.medium)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(result.item.originalFormat)
                        .font(.roundedCaption2())
                        .foregroundColor(.gray)

                    Image(systemName: "arrow.right")
                        .font(.roundedSystem(size: 8))
                        .foregroundColor(.gray)

                    Text(result.convertedFormat.displayName)
                        .font(.roundedCaption2())
                        .foregroundColor(.gray)

                    if let size = result.formattedFileSize {
                        Text("•")
                            .font(.roundedCaption2())
                            .foregroundColor(.gray)

                        Text(size)
                            .font(.roundedCaption2())
                            .foregroundColor(.gray)
                    }
                }

                if let error = result.error {
                    Text(error)
                        .font(.roundedCaption2())
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Actions for successful conversions
            if result.isSuccess {
                HStack(spacing: 8) {
                    Button(action: {
                        HapticManager.shared.softImpact()
                        onShare()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.roundedBody())
                            .foregroundColor(.blue)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.15))
                            )
                    }
                    .buttonStyle(ScaleDownButtonStyle())

                    Button(action: {
                        HapticManager.shared.softImpact()
                        onSave()
                    }) {
                        Image(systemName: "arrow.down.circle")
                            .font(.roundedBody())
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                            )
                    }
                    .buttonStyle(ScaleDownButtonStyle())
                }
            } else {
                Image(systemName: "xmark.circle.fill")
                    .font(.roundedTitle3())
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.appTertiaryBackground(for: colorScheme))
        )
    }
}

#Preview {
    VStack(spacing: 16) {
        BatchQueueItemView(
            item: BatchConversionItem(
                sourceURL: URL(fileURLWithPath: "/example/video.mp4")
            ),
            onRemove: {}
        )
    }
    .padding()
    .background(Color.appSecondaryBackground(for: .dark))
    .preferredColorScheme(.dark)
}
