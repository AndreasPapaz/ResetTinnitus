import SwiftUI

@main
struct ResonaApp: App {
    init() {
        if ProcessInfo.processInfo.arguments.contains("-UITestResetState") {
            FrequencyStore().clear()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
