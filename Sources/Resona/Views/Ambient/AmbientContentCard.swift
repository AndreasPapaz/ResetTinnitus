import SwiftUI

/// A translucent dark card behind screen content, so text stays legible
/// against the animated ambient background regardless of its current hue
/// (visual-identity spec - "Text remains legible and scalable over the
/// ambient background"). Matches the Block-inspired reference's own
/// black content-card motif.
struct AmbientContentCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

extension View {
    func ambientContentCard() -> some View {
        modifier(AmbientContentCard())
    }
}
