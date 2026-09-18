import SwiftUI

/// The main screen: pick a session duration and start/stop a CR playback
/// session (acoustic-cr-session spec - "Session duration selection and
/// auto-stop", "Pitch match required before a session").
struct MainSessionView: View {
    let frequencyStore: FrequencyStore
    let onRequestPitchMatch: () -> Void

    private static let durationOptions: [(label: String, seconds: TimeInterval)] = [
        ("15 min", 15 * 60),
        ("30 min", 30 * 60),
        ("1 hour", 60 * 60),
        ("2 hours", 2 * 60 * 60),
        ("4 hours", 4 * 60 * 60),
        ("6 hours", 6 * 60 * 60),
    ]

    @State private var engine = CRAudioEngine()
    @State private var selectedDuration: TimeInterval = 60 * 60
    @State private var remainingTime: TimeInterval?
    @State private var isPlaying = false
    @State private var errorMessage: String?

    private var storedFrequency: Double? { frequencyStore.get() }

    var body: some View {
        VStack(spacing: 24) {
            if let storedFrequency {
                Text("Matched frequency: \(Int(storedFrequency.rounded())) Hz")
                    .font(.headline)
                    .accessibilityIdentifier("mainMatchedFrequencyLabel")
            }

            if isPlaying {
                if let remainingTime {
                    Text(Self.timeString(remainingTime))
                        .font(.system(size: 44, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .accessibilityIdentifier("remainingTimeLabel")
                }
                Button("Stop Session") {
                    engine.stopSession()
                    isPlaying = false
                    remainingTime = nil
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("stopSessionButton")
            } else {
                Picker("Session Duration", selection: $selectedDuration) {
                    ForEach(Self.durationOptions, id: \.seconds) { option in
                        Text(option.label).tag(option.seconds)
                    }
                }
                .pickerStyle(.wheel)
                .accessibilityIdentifier("sessionDurationPicker")

                Button("Start Session") {
                    start()
                }
                .buttonStyle(.borderedProminent)
                .disabled(storedFrequency == nil)
                .accessibilityIdentifier("startSessionButton")

                if storedFrequency == nil {
                    Text("Match your tinnitus frequency first.")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Spacer()

            Button(storedFrequency == nil ? "Match Tinnitus Frequency" : "Re-Match Tinnitus Frequency") {
                engine.stopSession()
                isPlaying = false
                onRequestPitchMatch()
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("rematchButton")
        }
        .padding()
        .onAppear {
            engine.onSessionFinished = {
                isPlaying = false
                remainingTime = nil
            }
        }
        .task(id: isPlaying) {
            guard isPlaying else { return }
            while !Task.isCancelled, engine.isSessionActive {
                remainingTime = engine.remainingTime
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }

    private func start() {
        guard let storedFrequency else { return }
        do {
            try engine.startSession(ft: storedFrequency, duration: selectedDuration)
            isPlaying = true
            remainingTime = selectedDuration
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't start playback: \(error.localizedDescription)"
        }
    }

    private static func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    MainSessionView(frequencyStore: FrequencyStore(), onRequestPitchMatch: {})
}
