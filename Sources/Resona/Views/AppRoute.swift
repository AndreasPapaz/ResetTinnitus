import Foundation

/// Which screen the app opens to. Presence/absence of the stored tinnitus
/// frequency is the only signal used — no separate "onboarding complete"
/// flag is stored (tinnitus-frequency-profile spec - "First-launch
/// disclaimer").
enum AppRoute: Equatable {
    case disclaimer
    case pitchMatch
    case main

    static func initialRoute(hasStoredFrequency: Bool) -> AppRoute {
        hasStoredFrequency ? .main : .disclaimer
    }
}
