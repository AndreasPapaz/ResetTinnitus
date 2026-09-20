import Foundation

/// The adjustable pitch-matching range and its mapping to/from a linear
/// (0...1) slider fraction via a logarithmic scale, per the
/// tinnitus-frequency-profile spec's "Frequency range validation" and
/// "Pitch-matching flow" (log scale, suited to pitch perception).
enum PitchRange {
    static let minHz = 100.0
    static let maxHz = 10000.0

    static func clamp(_ hz: Double) -> Double {
        min(max(hz, minHz), maxHz)
    }

    static func frequency(fromSliderFraction fraction: Double) -> Double {
        let clampedFraction = min(max(fraction, 0), 1)
        return minHz * pow(maxHz / minHz, clampedFraction)
    }

    static func sliderFraction(fromFrequency hz: Double) -> Double {
        log(clamp(hz) / minHz) / log(maxHz / minHz)
    }
}
