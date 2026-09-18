import Foundation

/// Derives the 4-tone CR stimulus set from a matched tinnitus frequency,
/// per the RESET trial's G1 protocol: 4 tones equally spaced on a
/// logarithmic scale within [0.5 * ft, 2 * ft] (design.md - "Tone-set
/// math: log-equal spacing including both endpoints").
enum ToneSetDerivation {
    /// Returns [f1, f2, f3, f4] in ascending order, with f1 == 0.5*ft and
    /// f4 == 2*ft exactly.
    static func deriveTones(ft: Double) -> [Double] {
        let lowerBound = 0.5 * ft
        let ratio = 4.0 // (2*ft) / (0.5*ft)
        return (0..<4).map { index in
            lowerBound * pow(ratio, Double(index) / 3.0)
        }
    }
}
