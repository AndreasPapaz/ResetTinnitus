import SwiftUI

/// The shared, full-bleed animated background/shape used on every screen
/// (visual-identity spec - "Ambient background on every screen"). Renders
/// via the `ambientCanvas` Metal shader, driven by a continuously
/// updating `TimelineView` — unless Reduce Motion is enabled, in which
/// case it renders a static frame per SwiftUI re-render (still reflecting
/// state changes like a moved slider or a session's stimulation/silent
/// transition) rather than animating continuously (design.md - "Reduce
/// Motion").
struct AmbientCanvas: View {
    let state: AmbientState

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // A per-view-instance reference point so the shader's `time` argument
    // stays small (seconds since this view appeared, not since the Unix
    // or reference-date epoch) -- Float32 loses sub-second precision at
    // the magnitude `Date.timeIntervalSinceReferenceDate` would produce,
    // which would make the animation visibly stepped instead of smooth.
    @State private var epoch = Date()

    var body: some View {
        GeometryReader { geometry in
            Group {
                if reduceMotion {
                    shaderRectangle(now: Date(), size: geometry.size)
                        .animation(.easeInOut(duration: 0.4), value: state)
                } else {
                    TimelineView(.animation) { context in
                        shaderRectangle(now: context.date, size: geometry.size)
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func shaderRectangle(now: Date, size: CGSize) -> some View {
        let params = AmbientShaderParameters(state: state, now: now, reduceMotion: reduceMotion)
        let time = now.timeIntervalSince(epoch)
        return Rectangle()
            .fill(.black)
            .colorEffect(
                Shader(
                    function: ShaderFunction(library: .default, name: "ambientCanvas"),
                    arguments: [
                        .float(Float(size.width)),
                        .float(Float(size.height)),
                        .float(Float(time)),
                        .float(params.colorA.x), .float(params.colorA.y), .float(params.colorA.z),
                        .float(params.colorB.x), .float(params.colorB.y), .float(params.colorB.z),
                        .float(params.colorC.x), .float(params.colorC.y), .float(params.colorC.z),
                        .float(params.intensity),
                        .float(params.morphAmount),
                    ]
                )
            )
    }
}

#Preview {
    AmbientCanvas(state: .restrained)
}
