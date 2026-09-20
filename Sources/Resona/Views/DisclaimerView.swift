import SwiftUI

/// First-launch, non-medical disclaimer (tinnitus-frequency-profile spec -
/// "First-launch disclaimer"). Shown only when no tinnitus frequency is
/// stored yet; acknowledging it proceeds to pitch matching. Uses the
/// restrained ambient state (visual-identity spec - "Restrained idle
/// presentation").
struct DisclaimerView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        ZStack {
            AmbientCanvas(state: .restrained)

            VStack(spacing: 20) {
                Spacer()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Before You Begin")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("""
                    Resona plays a personalized tone pattern based on \
                    your own tinnitus pitch, intended as a wellness tool.

                    It is not a medical device and is not intended to diagnose, \
                    treat, cure, or prevent any disease or condition, including \
                    tinnitus. It has not been medically approved.

                    Please consult a doctor about your tinnitus, especially \
                    before making this part of your routine.
                    """)
                    .foregroundStyle(.white.opacity(0.85))
                }
                .ambientContentCard()

                Spacer()

                Button("I Understand", action: onAcknowledge)
                    .buttonStyle(.pill)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("disclaimerAcknowledgeButton")
            }
            .padding()
        }
    }
}

#Preview {
    DisclaimerView(onAcknowledge: {})
}
