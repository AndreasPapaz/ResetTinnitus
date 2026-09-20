import XCTest
@testable import Resona

final class AppRouteTests: XCTestCase {
    func testNoStoredFrequencyRoutesToDisclaimer() {
        XCTAssertEqual(AppRoute.initialRoute(hasStoredFrequency: false), .disclaimer)
    }

    func testStoredFrequencyRoutesToMain() {
        XCTAssertEqual(AppRoute.initialRoute(hasStoredFrequency: true), .main)
    }
}
