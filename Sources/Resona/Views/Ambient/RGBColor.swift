import SwiftUI

/// A plain, testable RGB color (components in 0...1), independent of
/// SwiftUI's `Color` so the frequency/state color math (FrequencyColor,
/// AmbientState) can be unit-tested without touching the view layer.
struct RGBColor: Equatable {
    let red: Double
    let green: Double
    let blue: Double

    init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// - Parameter hex: an 0xRRGGBB value, e.g. 0x5B93C9.
    init(hex: UInt32) {
        red = Double((hex >> 16) & 0xFF) / 255.0
        green = Double((hex >> 8) & 0xFF) / 255.0
        blue = Double(hex & 0xFF) / 255.0
    }

    static func lerp(_ a: RGBColor, _ b: RGBColor, _ t: Double) -> RGBColor {
        let clampedT = min(max(t, 0), 1)
        return RGBColor(
            red: a.red + (b.red - a.red) * clampedT,
            green: a.green + (b.green - a.green) * clampedT,
            blue: a.blue + (b.blue - a.blue) * clampedT
        )
    }

    var color: Color {
        Color(red: red, green: green, blue: blue)
    }

    var simd3: SIMD3<Float> {
        SIMD3<Float>(Float(red), Float(green), Float(blue))
    }
}
