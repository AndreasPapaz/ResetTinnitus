import Foundation

/// Maps a tinnitus-matching frequency to a color, log-interpolated across
/// three committed anchor points (design.md - "Frequency -> color
/// mapping"). Used by both PitchMatchView (live slider) and
/// MainSessionView (fixed hue for the session) so there is one source of
/// truth for "what color is this frequency."
enum FrequencyColor {
    static let lowAnchor = RGBColor(hex: 0x5B93C9) // 100 Hz - muted blue
    static let midAnchor = RGBColor(hex: 0x6FCFB6) // 1,000 Hz - soft seafoam
    static let highAnchor = RGBColor(hex: 0xE3A468) // 10,000 Hz - warm muted amber
    static let midpointHz = 1000.0

    static func color(forFrequencyHz hz: Double) -> RGBColor {
        let clamped = PitchRange.clamp(hz)
        if clamped <= midpointHz {
            let t = log(clamped / PitchRange.minHz) / log(midpointHz / PitchRange.minHz)
            return .lerp(lowAnchor, midAnchor, t)
        } else {
            let t = log(clamped / midpointHz) / log(PitchRange.maxHz / midpointHz)
            return .lerp(midAnchor, highAnchor, t)
        }
    }
}
