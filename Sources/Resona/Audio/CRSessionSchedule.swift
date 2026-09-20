import Foundation

/// A fully precomputed, immutable schedule of cycle phases for one session,
/// built once before playback starts. A session's duration (and therefore
/// its total cycle count) is known up front, so the entire tone-order
/// randomization for the session can be precomputed before the real-time
/// render callback ever runs — the callback only ever *reads* this
/// immutable value, which needs no lock (design.md's "no allocation/
/// locking on the audio thread" mitigation, realized as the simplest
/// possible form of precomputed hand-off).
struct CRSessionSchedule: Sendable {
    let toneFrequencies: [Double] // f1...f4, ascending
    let cycleLengthSamples: Int
    let toneSlotLengthSamples: Int
    let fadeLengthSamples: Int
    let sampleRate: Double
    let totalSamples: Int
    let phases: [CRCyclePhase]

    init<RNG: RandomNumberGenerator>(ft: Double, duration: TimeInterval, sampleRate: Double, rng: RNG) {
        toneFrequencies = ToneSetDerivation.deriveTones(ft: ft)
        self.sampleRate = sampleRate
        cycleLengthSamples = CRTiming.cycleLengthInSamples(sampleRate: sampleRate)
        toneSlotLengthSamples = CRTiming.toneSlotLengthInSamples(sampleRate: sampleRate)
        fadeLengthSamples = CRTiming.fadeLengthInSamples(sampleRate: sampleRate)
        totalSamples = CRTiming.sessionLengthInSamples(duration: duration, sampleRate: sampleRate)

        let cycleCount = max(1, Int(ceil(Double(totalSamples) / Double(cycleLengthSamples))))
        var sequencer = CRCycleSequencer(rng: rng)
        phases = (0..<cycleCount).map { _ in sequencer.nextPhase() }
    }

    init(ft: Double, duration: TimeInterval, sampleRate: Double) {
        self.init(ft: ft, duration: duration, sampleRate: sampleRate, rng: SystemRandomNumberGenerator())
    }

    /// The linear sample value (before amplitude scaling) at the given
    /// zero-based sample offset since session start, or `nil` once the
    /// session has finished.
    func sampleValue(at sampleIndex: Int) -> Double? {
        guard sampleIndex >= 0, sampleIndex < totalSamples else { return nil }
        let cycleIndex = sampleIndex / cycleLengthSamples
        guard cycleIndex < phases.count else { return 0 }
        let sampleInCycle = sampleIndex % cycleLengthSamples

        switch phases[cycleIndex] {
        case .silent:
            return 0
        case .stimulation(let toneOrder):
            let slotIndex = min(sampleInCycle / toneSlotLengthSamples, toneOrder.count - 1)
            let sampleInSlot = sampleInCycle - slotIndex * toneSlotLengthSamples
            let frequency = toneFrequencies[toneOrder[slotIndex]]
            let raw = sin(2.0 * Double.pi * frequency * Double(sampleInSlot) / sampleRate)
            return raw * fadeEnvelope(sampleInSlot: sampleInSlot)
        }
    }

    private func fadeEnvelope(sampleInSlot: Int) -> Double {
        guard fadeLengthSamples > 0 else { return 1 }
        if sampleInSlot < fadeLengthSamples {
            return Double(sampleInSlot) / Double(fadeLengthSamples)
        }
        let samplesFromSlotEnd = toneSlotLengthSamples - sampleInSlot
        if samplesFromSlotEnd < fadeLengthSamples {
            return Double(max(0, samplesFromSlotEnd)) / Double(fadeLengthSamples)
        }
        return 1
    }
}
