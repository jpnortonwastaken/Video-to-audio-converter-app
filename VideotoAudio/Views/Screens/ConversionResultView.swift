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
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var isDraggingSlider = false
    @State private var playbackTimer: Timer?

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
                                    .fill(Color.appTertiaryBackground(for: colorScheme))
                            )
                            .foregroundColor(colorScheme == .dark ? .white : .black)
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
                .compositingGroup()
                .padding(.horizontal, 24)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
            }
            .background((Color.appSecondaryBackground(for: colorScheme)).ignoresSafeArea(.all))
            .navigationTitle("Conversion Complete")
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
        VStack(spacing: 20) {
            // Audio visualization icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.2),
                                Color.purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "waveform")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .symbolEffect(.variableColor.iterative, isActive: isPlaying)
            }

            // Format label
            Text(format.displayName)
                .font(.roundedTitle2())
                .fontWeight(.semibold)
                .foregroundColor(colorScheme == .dark ? .white : .black)

            // Audio Player Controls
            VStack(spacing: 12) {
                // Progress Bar
                VStack(spacing: 6) {
                    Slider(
                        value: Binding(
                            get: { currentTime },
                            set: { newValue in
                                currentTime = newValue
                                audioPlayer?.currentTime = newValue
                            }
                        ),
                        in: 0...max(duration, 1),
                        onEditingChanged: { editing in
                            isDraggingSlider = editing
                            if !editing {
                                audioPlayer?.currentTime = currentTime
                            }
                        }
                    )
                    .tint(colorScheme == .dark ? .white : .black)

                    // Time Labels
                    HStack {
                        Text(formatTime(currentTime))
                            .font(.roundedCaption())
                            .foregroundColor(.gray)
                            .monospacedDigit()

                        Spacer()

                        Text(formatTime(duration))
                            .font(.roundedCaption())
                            .foregroundColor(.gray)
                            .monospacedDigit()
                    }
                }

                // Playback Controls
                HStack(spacing: 40) {
                    // Skip Backward 15s
                    Button(action: skipBackward) {
                        Image(systemName: "gobackward.15")
                            .font(.roundedSystem(size: 28))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .buttonStyle(ScaleDownButtonStyle())

                    // Play/Pause Button
                    Button(action: togglePlayback) {
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color.white : Color.black)
                                .frame(width: 64, height: 64)

                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.roundedSystem(size: 24))
                                .foregroundColor(colorScheme == .dark ? .black : .white)
                                .offset(x: isPlaying ? 0 : 2)
                        }
                    }
                    .buttonStyle(ScaleDownButtonStyle())

                    // Skip Forward 15s
                    Button(action: skipForward) {
                        Image(systemName: "goforward.15")
                            .font(.roundedSystem(size: 28))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .buttonStyle(ScaleDownButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            prepareAudioPlayer()
        }
    }

    // MARK: - Time Formatting
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    // MARK: - Skip Controls
    private func skipBackward() {
        HapticManager.shared.softImpact()
        let newTime = max(currentTime - 15, 0)
        currentTime = newTime
        audioPlayer?.currentTime = newTime
    }

    private func skipForward() {
        HapticManager.shared.softImpact()
        let newTime = min(currentTime + 15, duration)
        currentTime = newTime
        audioPlayer?.currentTime = newTime
    }

    // MARK: - Prepare Audio Player
    private func prepareAudioPlayer() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let player = try AVAudioPlayer(data: convertedAudioData)
            player.prepareToPlay()
            duration = player.duration
            audioPlayer = player
        } catch {
            print("❌ Failed to prepare audio: \(error)")
        }
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
        // Prepare player if not already done
        if audioPlayer == nil {
            prepareAudioPlayer()
        }

        guard let player = audioPlayer else {
            errorMessage = "Failed to play audio"
            showError = true
            return
        }

        // Set up delegate for playback completion
        player.delegate = AudioPlayerDelegate.shared
        AudioPlayerDelegate.shared.onFinish = {
            stopPlaybackTimer()
            isPlaying = false
            currentTime = 0
        }

        player.play()
        isPlaying = true
        startPlaybackTimer()
    }

    private func stopAudio() {
        audioPlayer?.pause()
        stopPlaybackTimer()
        isPlaying = false
    }

    private func startPlaybackTimer() {
        stopPlaybackTimer()
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let player = audioPlayer, !isDraggingSlider else { return }
            currentTime = player.currentTime
        }
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
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
