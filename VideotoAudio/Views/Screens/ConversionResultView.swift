//
//  ConversionResultView.swift
//  Video to Audio
//
//  Displays the result of audio extraction with share/save options.
//

import SwiftUI
import AVFoundation

enum ConversionResultDisplayMode {
    case thumbnail  // Square thumbnail with rounded corners (for direct conversions)
    case fullImage  // Full aspect ratio (for history items)
}

struct ConversionResultView: View {
    let convertedAudioData: Data
    let format: AudioFormat
    let displayMode: ConversionResultDisplayMode
    let onDismiss: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?

    // Default initializer with thumbnail mode
    init(convertedAudioData: Data, format: AudioFormat, displayMode: ConversionResultDisplayMode = .thumbnail, onDismiss: (() -> Void)? = nil) {
        self.convertedAudioData = convertedAudioData
        self.format = format
        self.displayMode = displayMode
        self.onDismiss = onDismiss
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Audio Preview
                audioPreviewView
                    .padding(.top, 8)

                Spacer(minLength: 16)

                // File Info and Action Buttons
                VStack(spacing: 16) {
                    // File Info
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Format")
                                .font(.roundedCaption())
                                .foregroundColor(.gray)
                            Text(format.displayName)
                                .font(.roundedHeadline())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Size")
                                .font(.roundedCaption())
                                .foregroundColor(.gray)
                            Text(formatFileSize(convertedAudioData.count))
                                .font(.roundedHeadline())
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }

                    // Share and Save Buttons (side by side)
                    HStack(spacing: 12) {
                        // Share Button
                        Button(action: shareAudio) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.roundedHeadline())
                                Text("Share")
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

                        // Save Button
                        Button(action: saveToFiles) {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.roundedHeadline())
                                Text("Save")
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

                    // Done Button
                    Button(action: {
                        HapticManager.shared.softImpact()
                        stopAudio()
                        if let onDismiss = onDismiss {
                            onDismiss()
                        } else {
                            dismiss()
                        }
                    }) {
                        Text("Done")
                            .font(.roundedHeadline())
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .buttonStyle(ScaleDownButtonStyle())
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            (colorScheme == .dark ? Color(.systemGray3) : Color(.systemGray4)).opacity(0.3),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [7, 8])
                        )
                )
                .compositingGroup()
                .padding(.horizontal, 24)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
            }
            .background((colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground)).ignoresSafeArea(.all))
            .navigationTitle("Extraction Complete")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if onDismiss != nil {
                        Button(action: {
                            HapticManager.shared.softImpact()
                            stopAudio()
                            if let onDismiss = onDismiss {
                                onDismiss()
                            } else {
                                dismiss()
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.roundedSystem(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [createShareableFile()])
        }
        .alert("Success", isPresented: $showSuccessMessage) {
            Button("OK") {
                HapticManager.shared.softImpact()
            }
        } message: {
            Text(successMessage)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                HapticManager.shared.softImpact()
            }
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            stopAudio()
        }
    }

    // MARK: - Audio Preview
    private var audioPreviewView: some View {
        VStack(spacing: 24) {
            // Audio icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)

                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .onTapGesture {
                togglePlayback()
            }

            // Format label
            Text(format.displayName)
                .font(.roundedTitle2())
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            Text("Tap to preview")
                .font(.roundedCaption())
                .foregroundColor(.gray)
        }
        .frame(height: 350)
    }

    // MARK: - Audio Playback
    private func togglePlayback() {
        HapticManager.shared.softImpact()

        if isPlaying {
            stopAudio()
        } else {
            playAudio()
        }
    }

    private func playAudio() {
        do {
            // Configure audio session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            audioPlayer = try AVAudioPlayer(data: convertedAudioData)
            audioPlayer?.delegate = AudioPlayerDelegate.shared
            AudioPlayerDelegate.shared.onFinish = {
                isPlaying = false
            }
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("❌ Failed to play audio: \(error)")
            errorMessage = "Failed to play audio"
            showError = true
        }
    }

    private func stopAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
    }

    // MARK: - Actions
    private func shareAudio() {
        HapticManager.shared.softImpact()
        showShareSheet = true
    }

    private func saveToFiles() {
        HapticManager.shared.softImpact()

        let tempURL = createShareableFile()

        // Use document picker to save
        let activityVC = UIActivityViewController(
            activityItems: [tempURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private func createShareableFile() -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "audio_\(Int(Date().timeIntervalSince1970)).\(format.fileExtension)"
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        do {
            try convertedAudioData.write(to: fileURL)
        } catch {
            print("❌ Failed to write temp file: \(error)")
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

// MARK: - Audio Player Delegate
class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    static let shared = AudioPlayerDelegate()
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.onFinish?()
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
