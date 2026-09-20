import Foundation

/// What the ambient background/shape should show, per design.md's
/// "Component structure" decision. `DisclaimerView` and an idle
/// `MainSessionView` use `.restrained`; `PitchMatchView` uses
/// `.pitchMatch`; an active session uses `.session`.
///
/// `.session` carries `sessionStartDate` rather than a precomputed phase
/// so `AmbientCanvas` can derive the live stimulation/silent phase itself
/// on every animation frame (design.md - "Session-cycle sync: derived
/// from wall-clock elapsed time") — the enum value itself stays constant
/// for the whole session; only time moves.
enum AmbientState: Equatable {
    case restrained
    case pitchMatch(frequencyHz: Double)
    case session(frequencyHz: Double, sessionStartDate: Date)
}
