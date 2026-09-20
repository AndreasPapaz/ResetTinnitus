import SwiftUI

/// Pitch-matching flow: play a live sine tone the user tunes until it
/// matches their tinnitus, then store it (tinnitus-frequency-profile spec
/// - "Pitch-matching flow", "Single-value frequency persistence",
/// "Re-adjustment", "Frequency range validation"). The ambient shape's
/// color follows the selected frequency live (visual-identity spec -
/// "Shape color reflects pitch-match frequency").
struct PitchMatchView: View {
    let frequencyStore: FrequencyStore
    let onComplete: () -> Void

    @State private var player = PitchMatchTonePlayer()
    @State private var sliderFraction: Double
    @State private var errorMessage: String?
    // @ScaledMetric (not a fixed .font(size:)) so this key readout still
    // grows with Dynamic Type (visual-identity spec - "Key text scales
    // with Dynamic Type").
    @ScaledMetric private var frequencyFontSize: CGFloat = 40

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
        ZStack {
            AmbientCanvas(state: .pitchMatch(frequencyHz: currentFrequency))

            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    Text("Match the Tone")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Adjust the slider until the tone matches the pitch of your tinnitus.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.85))

                    Text("\(Int(currentFrequency.rounded())) Hz")
                        .font(.system(size: frequencyFontSize, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .accessibilityIdentifier("pitchMatchFrequencyLabel")
                }
                .ambientContentCard()

                Slider(value: $sliderFraction, in: 0...1)
                    .padding(.horizontal)
                    .tint(.white)
                    .accessibilityIdentifier("pitchMatchSlider")
                    .onChange(of: sliderFraction) { _, _ in
                        player.update(frequencyHz: currentFrequency)
                    }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .ambientContentCard()
                }

                Spacer()

                Button("This Matches My Tinnitus") {
                    frequencyStore.set(PitchRange.clamp(currentFrequency))
                    player.stop()
                    onComplete()
                }
                .buttonStyle(.pill)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("pitchMatchConfirmButton")
            }
            .padding()
        }
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
