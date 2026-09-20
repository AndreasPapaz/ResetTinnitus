import Foundation

/// Derives the shader's color/intensity inputs from an `AmbientState`.
/// - Restrained: fixed low-saturation seafoam/lavender gradient, lowest
///   intensity and morph amount (design.md - "Idle/restrained state
///   palette").
/// - Pitch-match / session: colors derived from `FrequencyColor`, with
///   session stimulation cycles brighter/more distorted than silent
///   cycles (design.md - "Session cycle -> shape state").
/// When Reduce Motion is enabled, morph amount is zeroed so the shape
/// stops distorting/pulsing while color still conveys state (visual-
/// identity spec - "Reduce Motion accessibility fallback").
struct AmbientShaderParameters {
    let colorA: SIMD3<Float>
    let colorB: SIMD3<Float>
    let colorC: SIMD3<Float>
    let intensity: Float
    let morphAmount: Float

    private static let restrainedSeafoam = RGBColor(hex: 0x6FCFB6)
    private static let restrainedLavender = RGBColor(hex: 0xA9A0D9)
    private static let white = RGBColor(hex: 0xFFFFFF)
    private static let black = RGBColor(hex: 0x000000)

    /// - Parameter now: the moment to render as. For `.session`, this is
    ///   compared against the state's `sessionStartDate` to derive the
    ///   live stimulation/silent phase; ignored by the other cases.
    init(state: AmbientState, now: Date, reduceMotion: Bool) {
        let resolvedMorphAmount: Float

        switch state {
        case .restrained:
            let mid = RGBColor.lerp(Self.restrainedSeafoam, Self.restrainedLavender, 0.5)
            colorA = Self.restrainedSeafoam.simd3
            colorB = Self.restrainedLavender.simd3
            colorC = mid.simd3
            intensity = 0.3
            resolvedMorphAmount = 0.15

        case .pitchMatch(let frequencyHz):
            let base = FrequencyColor.color(forFrequencyHz: frequencyHz)
            colorA = base.simd3
            colorB = RGBColor.lerp(base, Self.white, 0.3).simd3
            colorC = RGBColor.lerp(base, Self.black, 0.2).simd3
            intensity = 0.6
            resolvedMorphAmount = 0.35

        case .session(let frequencyHz, let sessionStartDate):
            let elapsed = now.timeIntervalSince(sessionStartDate)
            let phase = CyclePhaseKind.current(elapsedSinceSessionStart: elapsed)
            let base = FrequencyColor.color(forFrequencyHz: frequencyHz)
            let isStimulation = phase == .stimulation
            colorA = base.simd3
            colorB = RGBColor.lerp(base, Self.white, isStimulation ? 0.4 : 0.1).simd3
            colorC = RGBColor.lerp(base, Self.black, isStimulation ? 0.1 : 0.35).simd3
            intensity = isStimulation ? 0.9 : 0.4
            resolvedMorphAmount = isStimulation ? 0.5 : 0.2
        }

        morphAmount = reduceMotion ? 0 : resolvedMorphAmount
    }
}
