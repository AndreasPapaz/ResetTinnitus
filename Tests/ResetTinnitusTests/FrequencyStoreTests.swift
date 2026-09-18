import XCTest
@testable import ResetTinnitus

final class FrequencyStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var store: FrequencyStore!

    override func setUp() {
        super.setUp()
        suiteName = "FrequencyStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = FrequencyStore(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testGetReturnsNilBeforeAnyValueIsSet() {
        XCTAssertNil(store.get())
    }

    func testSetThenGetRoundTrips() {
        store.set(4321.5)
        XCTAssertEqual(store.get(), 4321.5)
    }

    func testSetOverwritesPreviousValue() {
        store.set(1000)
        store.set(2000)
        XCTAssertEqual(store.get(), 2000)
    }
}
