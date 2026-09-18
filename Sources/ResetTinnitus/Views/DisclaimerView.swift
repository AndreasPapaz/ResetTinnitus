import SwiftUI

/// First-launch, non-medical disclaimer (tinnitus-frequency-profile spec -
/// "First-launch disclaimer"). Shown only when no tinnitus frequency is
/// stored yet; acknowledging it proceeds to pitch matching.
struct DisclaimerView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Before You Begin")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .center)

            Text("""
            Reset Tinnitus plays a personalized tone pattern based on \
            your own tinnitus pitch, intended as a wellness tool.

            It is not a medical device and is not intended to diagnose, \
            treat, cure, or prevent any disease or condition, including \
            tinnitus. It has not been medically approved.

            Please consult a doctor about your tinnitus, especially \
            before making this part of your routine.
            """)
            .foregroundStyle(.secondary)

            Spacer()

            Button("I Understand", action: onAcknowledge)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("disclaimerAcknowledgeButton")
        }
        .padding()
    }
}

#Preview {
    DisclaimerView(onAcknowledge: {})
}
