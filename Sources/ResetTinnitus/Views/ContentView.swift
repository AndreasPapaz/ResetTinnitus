import SwiftUI

/// Routes between the disclaimer, pitch matching, and main session
/// screens. Presence/absence of the stored tinnitus frequency is the only
/// signal that decides the initial route (AppRoute.initialRoute).
struct ContentView: View {
    private let frequencyStore = FrequencyStore()

    @State private var route: AppRoute

    init() {
        _route = State(initialValue: AppRoute.initialRoute(hasStoredFrequency: FrequencyStore().get() != nil))
    }

    var body: some View {
        switch route {
        case .disclaimer:
            DisclaimerView {
                route = .pitchMatch
            }
        case .pitchMatch:
            PitchMatchView(frequencyStore: frequencyStore) {
                route = .main
            }
        case .main:
            MainSessionView(frequencyStore: frequencyStore) {
                route = .pitchMatch
            }
        }
    }
}

#Preview {
    ContentView()
}
