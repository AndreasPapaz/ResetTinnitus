import Foundation

/// The two visible states of a CR session's cycle, derived from wall-clock
/// elapsed time rather than polled from CRAudioEngine's locked render
/// state (design.md - "Session-cycle sync: derived from wall-clock
/// elapsed time, not polled from CRAudioEngine"). Reuses the exact same
/// CRCyclePattern pure function the audio engine's schedule is built
/// from, so there's one source of truth for the 3-on/2-off pattern.
enum CyclePhaseKind: Equatable {
    case stimulation
    case silent

    static func current(elapsedSinceSessionStart elapsed: TimeInterval) -> CyclePhaseKind {
        let cycleDuration = 1.0 / CRTiming.cycleRateHz
        let cycleIndex = max(0, Int(elapsed / cycleDuration))
        return CRCyclePattern.isStimulationCycle(atIndex: cycleIndex) ? .stimulation : .silent
    }
}
