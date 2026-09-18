import Foundation

/// Converts the CR protocol's rate/slot timing into sample counts at a
/// given engine sample rate, so the render callback can work entirely in
/// samples (design.md - "Real-time synthesis via AVAudioSourceNode":
/// sample counts are the only clock, to avoid wall-clock drift over a
/// multi-hour session).
enum CRTiming {
    /// Cycle repetition rate per the RESET trial's fixed-rate (G1) arm.
    static let cycleRateHz: Double = 1.5
    static let toneSlotsPerCycle = 4
    /// Short linear fade at each tone slot boundary to avoid audible
    /// clicks; taken from within the slot, not added to it.
    static let fadeDurationSeconds: Double = 0.005

    static func cycleLengthInSamples(sampleRate: Double) -> Int {
        Int((sampleRate / cycleRateHz).rounded())
    }

    static func toneSlotLengthInSamples(sampleRate: Double) -> Int {
        cycleLengthInSamples(sampleRate: sampleRate) / toneSlotsPerCycle
    }

    static func fadeLengthInSamples(sampleRate: Double) -> Int {
        Int((fadeDurationSeconds * sampleRate).rounded())
    }

    static func sessionLengthInSamples(duration: TimeInterval, sampleRate: Double) -> Int {
        Int((duration * sampleRate).rounded())
    }
}
