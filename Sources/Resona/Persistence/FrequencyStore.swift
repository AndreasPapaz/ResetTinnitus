import Foundation

/// The single piece of user data this app persists anywhere: the user's
/// matched tinnitus frequency, in Hz. No other key is ever written through
/// this type or anywhere else in the app.
struct FrequencyStore {
    private static let key = "com.resona.tinnitusFrequencyHz"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func get() -> Double? {
        let value = defaults.double(forKey: Self.key)
        guard defaults.object(forKey: Self.key) != nil else { return nil }
        return value
    }

    func set(_ hz: Double) {
        defaults.set(hz, forKey: Self.key)
    }

    /// Removes the stored value. Only used by the UI-test reset hook
    /// (`-UITestResetState` launch argument) to exercise first-launch
    /// behavior repeatably; not exposed anywhere in the app's own UI.
    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
