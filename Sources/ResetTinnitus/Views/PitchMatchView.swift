import SwiftUI

/// Pitch-matching flow: play a live sine tone the user tunes until it
/// matches their tinnitus, then store it (tinnitus-frequency-profile spec
/// - "Pitch-matching flow", "Single-value frequency persistence",
/// "Re-adjustment", "Frequency range validation").
struct PitchMatchView: View {
    let frequencyStore: FrequencyStore
    let onComplete: () -> Void

    @State private var player = PitchMatchTonePlayer()
    @State private var sliderFraction: Double
    @State private var errorMessage: String?

    init(frequencyStore: FrequencyStore, onComplete: @escaping () -> Void) {
        self.frequencyStore = frequencyStore
        self.onComplete = onComplete
        let initialHz = frequencyStore.get() ?? 4000
        _sliderFraction = State(initialValue: PitchRange.sliderFraction(fromFrequency: initialHz))
    }

    private var currentFrequency: Double {
        PitchRange.frequency(fromSliderFraction: sliderFraction)
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Match the Tone")
                .font(.title2.bold())

            Text("Adjust the slider until the tone matches the pitch of your tinnitus.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            Text("\(Int(currentFrequency.rounded())) Hz")
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .accessibilityIdentifier("pitchMatchFrequencyLabel")

            Slider(value: $sliderFraction, in: 0...1)
                .padding(.horizontal)
                .accessibilityIdentifier("pitchMatchSlider")
                .onChange(of: sliderFraction) { _, _ in
                    player.update(frequencyHz: currentFrequency)
                }

            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

            Spacer()

            Button("This Matches My Tinnitus") {
                frequencyStore.set(PitchRange.clamp(currentFrequency))
                player.stop()
                onComplete()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("pitchMatchConfirmButton")
        }
        .padding()
        .onAppear {
            do {
                try player.start(initialFrequencyHz: currentFrequency)
            } catch {
                errorMessage = "Couldn't start audio: \(error.localizedDescription)"
            }
        }
        .onDisappear {
            player.stop()
        }
    }
}

#Preview {
    PitchMatchView(frequencyStore: FrequencyStore(), onComplete: {})
}
