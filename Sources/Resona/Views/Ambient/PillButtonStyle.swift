import SwiftUI

/// Black, high-contrast, pill-shaped primary-action button, matching the
/// Block-inspired "READ MORE" style (proposal.md - "Black, high-contrast
/// pill-shaped buttons for primary actions"). Uses a rounded, bold
/// Dynamic-Type-aware label so it scales without clipping at large text
/// sizes.
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .bold))
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .foregroundStyle(.white)
            .background(Color.black, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
}
