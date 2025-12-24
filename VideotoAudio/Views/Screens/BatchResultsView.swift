//
//  BatchResultsView.swift
//  Video to Audio
//
//  Displays batch conversion results with share/save options.
//

import SwiftUI

struct BatchResultsView: View {
    let results: [BatchConversionResult]
    let format: AudioFormat
    let onDismiss: () -> Void
    let onRetryFailed: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var animateItems = false
    @State private var showShareSheet = false
    @State private var shareItems: [URL] = []

    private var successfulResults: [BatchConversionResult] {
        results.filter { $0.isSuccess }
    }

    private var failedResults: [BatchConversionResult] {
        results.filter { !$0.isSuccess }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Header
                summaryHeader

                // Results List
                ScrollView {
                    LazyVStack(spacing: 12) {
                        // Successful conversions
                        if !successfulResults.isEmpty {
                            sectionHeader("Completed", count: successfulResults.count, color: .green)

                            ForEach(Array(successfulResults.enumerated()), id: \.element.id) { index, result in
                                BatchQueueItemCompactView(
                                    result: result,
                                    onShare: { shareResult(result) },
                                    onSave: { saveResult(result) }
                                )
                                .opacity(animateItems ? 1 : 0)
                                .offset(y: animateItems ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(index) * 0.05),
                                    value: animateItems
                                )
                            }
                        }

                        // Failed conversions
                        if !failedResults.isEmpty {
                            sectionHeader("Failed", count: failedResults.count, color: .red)
                                .padding(.top, successfulResults.isEmpty ? 0 : 16)

                            ForEach(Array(failedResults.enumerated()), id: \.element.id) { index, result in
                                BatchQueueItemCompactView(
                                    result: result,
                                    onShare: {},
                                    onSave: {}
                                )
                                .opacity(animateItems ? 1 : 0)
                                .offset(y: animateItems ? 0 : 20)
                                .animation(
                                    .spring(response: 0.5, dampingFraction: 0.7)
                                        .delay(Double(successfulResults.count + index) * 0.05),
                                    value: animateItems
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)

                // Bottom Actions
                actionBar
            }
            .background(Color.appSecondaryBackground(for: colorScheme).ignoresSafeArea())
            .navigationBarHidden(true)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateItems = true
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
            }
        }
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        VStack(spacing: 16) {
            // Success indicator
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: failedResults.isEmpty ?
                                [Color.green.opacity(0.3), Color.green.opacity(0.1)] :
                                [Color.orange.opacity(0.3), Color.orange.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: failedResults.isEmpty ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .font(.roundedSystem(size: 40))
                    .foregroundColor(failedResults.isEmpty ? .green : .orange)
            }

            VStack(spacing: 4) {
                Text(failedResults.isEmpty ? "All Conversions Complete" : "Conversion Complete")
                    .font(.roundedTitle2())
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Text("\(successfulResults.count) of \(results.count) converted successfully")
                    .font(.roundedSubheadline())
                    .foregroundColor(.gray)
            }

            // Total size
            if !successfulResults.isEmpty {
                let totalSize = successfulResults.compactMap { $0.audioData?.count }.reduce(0, +)
                Text("Total size: \(formatFileSize(totalSize))")
                    .font(.roundedCaption())
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color.appSecondaryBackground(for: colorScheme))
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String, count: Int, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text("\(title) (\(count))")
                .font(.roundedSubheadline())
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        VStack(spacing: 12) {
            // Share All button (only if there are successful conversions)
            if successfulResults.count > 1 {
                Button(action: shareAll) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.roundedHeadline())
                        Text("Share All (\(successfulResults.count))")
                            .font(.roundedHeadline())
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(colorScheme == .dark ? Color.white : Color.black)
                    )
                    .foregroundColor(colorScheme == .dark ? .black : .white)
                }
                .buttonStyle(ScaleDownButtonStyle())
            }

            // Retry Failed button (only if there are failed conversions)
            if !failedResults.isEmpty {
                Button(action: {
                    HapticManager.shared.softImpact()
                    onRetryFailed()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.roundedHeadline())
                        Text("Retry Failed (\(failedResults.count))")
                            .font(.roundedHeadline())
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.orange.opacity(0.2))
                    )
                    .foregroundColor(.orange)
                }
                .buttonStyle(ScaleDownButtonStyle())
            }

            // Done button
            Button(action: {
                HapticManager.shared.softImpact()
                onDismiss()
            }) {
                Text("Done")
                    .font(.roundedHeadline())
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.5, blue: 1.0),
                                        Color(red: 0.0, green: 0.3, blue: 0.9)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(ScaleDownButtonStyle())
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.appSecondaryBackground(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28)
                .stroke(
                    (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                )
        )
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func shareResult(_ result: BatchConversionResult) {
        guard let data = result.audioData else { return }
        let url = createTempFile(for: result, data: data)
        shareItems = [url]
        showShareSheet = true
    }

    private func saveResult(_ result: BatchConversionResult) {
        guard let data = result.audioData else { return }
        let url = createTempFile(for: result, data: data)

        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func shareAll() {
        HapticManager.shared.softImpact()

        var urls: [URL] = []
        for result in successfulResults {
            guard let data = result.audioData else { continue }
            let url = createTempFile(for: result, data: data)
            urls.append(url)
        }

        shareItems = urls
        showShareSheet = true
    }

    private func createTempFile(for result: BatchConversionResult, data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let sanitizedTitle = result.item.title.replacingOccurrences(of: "/", with: "-")
        let fileName = "\(sanitizedTitle).\(format.fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        // Remove existing file if any
        try? FileManager.default.removeItem(at: fileURL)

        do {
            try data.write(to: fileURL)
        } catch {
            print("Failed to write temp file: \(error)")
        }

        return fileURL
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    BatchResultsView(
        results: [],
        format: .mp3,
        onDismiss: {},
        onRetryFailed: {}
    )
    .preferredColorScheme(.dark)
}
