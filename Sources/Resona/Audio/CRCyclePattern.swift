import Foundation

/// What a single CR cycle does: play the 4 tones in some randomized order,
/// or stay silent. Pure data — no audio I/O.
enum CRCyclePhase: Equatable {
    case stimulation(toneOrder: [Int])
    case silent
}

/// The repeating 3-stimulation / 2-silent cycle pattern from the RESET
/// trial's G1 protocol (design.md - cycle pattern decisions).
enum CRCyclePattern {
    static let stimulationCyclesPerBlock = 3
    static let silentCyclesPerBlock = 2
    static let blockLength = stimulationCyclesPerBlock + silentCyclesPerBlock

    /// Whether the given zero-based cycle index (since session start) is a
    /// stimulation cycle (true) or a silent cycle (false).
    static func isStimulationCycle(atIndex cycleIndex: Int) -> Bool {
        precondition(cycleIndex >= 0)
        return cycleIndex % blockLength < stimulationCyclesPerBlock
    }
}

/// Produces the sequence of cycle phases for a session: a stimulation
/// cycle's tone order is freshly randomized every time, per the
/// acoustic-cr-session spec's "Randomized stimulation cycle" requirement.
struct CRCycleSequencer<RNG: RandomNumberGenerator> {
    private var rng: RNG
    private var cycleIndex = 0

    init(rng: RNG) {
        self.rng = rng
    }

    mutating func nextPhase() -> CRCyclePhase {
        defer { cycleIndex += 1 }
        guard CRCyclePattern.isStimulationCycle(atIndex: cycleIndex) else {
            return .silent
        }
        let toneOrder = Array(0..<4).shuffled(using: &rng)
        return .stimulation(toneOrder: toneOrder)
    }
}

extension CRCycleSequencer where RNG == SystemRandomNumberGenerator {
    init() {
        self.init(rng: SystemRandomNumberGenerator())
    }
}
