import XCTest
@testable import ResetTinnitus

final class PitchRangeTests: XCTestCase {
    func testClampsValuesAboveMax() {
        XCTAssertEqual(PitchRange.clamp(20000), PitchRange.maxHz)
    }

    func testClampsValuesBelowMin() {
        XCTAssertEqual(PitchRange.clamp(10), PitchRange.minHz)
    }

    func testValuesWithinRangeAreUnchanged() {
        XCTAssertEqual(PitchRange.clamp(4000), 4000)
    }

    func testSliderEndpointsMapToRangeEndpoints() {
        XCTAssertEqual(PitchRange.frequency(fromSliderFraction: 0), PitchRange.minHz, accuracy: 0.001)
        XCTAssertEqual(PitchRange.frequency(fromSliderFraction: 1), PitchRange.maxHz, accuracy: 0.001)
    }

    func testFrequencyToSliderFractionRoundTrips() {
        let hz = 4000.0
        let fraction = PitchRange.sliderFraction(fromFrequency: hz)
        XCTAssertEqual(PitchRange.frequency(fromSliderFraction: fraction), hz, accuracy: 0.01)
    }

    func testOutOfRangeSliderFractionIsClamped() {
        XCTAssertEqual(PitchRange.frequency(fromSliderFraction: -1), PitchRange.minHz)
        XCTAssertEqual(PitchRange.frequency(fromSliderFraction: 2), PitchRange.maxHz)
    }
}
