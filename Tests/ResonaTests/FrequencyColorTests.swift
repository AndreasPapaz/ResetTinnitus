import XCTest
@testable import Resona

final class FrequencyColorTests: XCTestCase {
    func testAnchorColorsAreExact() {
        XCTAssertEqual(FrequencyColor.color(forFrequencyHz: 100), FrequencyColor.lowAnchor)
        XCTAssertEqual(FrequencyColor.color(forFrequencyHz: 1000), FrequencyColor.midAnchor)
        XCTAssertEqual(FrequencyColor.color(forFrequencyHz: 10000), FrequencyColor.highAnchor)
    }

    func testInterpolatesSmoothlyInLowSegment() {
        // Walking from 100Hz to 1000Hz, each step should move monotonically
        // closer to the mid anchor with no abrupt jumps.
        let steps = stride(from: 100.0, through: 1000.0, by: 50.0).map {
            FrequencyColor.color(forFrequencyHz: $0)
        }
        for i in 1..<steps.count {
            let delta = colorDistance(steps[i - 1], steps[i])
            XCTAssertLessThan(delta, 0.15, "expected a small, gradual color step between adjacent frequencies")
        }
    }

    func testInterpolatesSmoothlyInHighSegment() {
        let steps = stride(from: 1000.0, through: 10000.0, by: 500.0).map {
            FrequencyColor.color(forFrequencyHz: $0)
        }
        for i in 1..<steps.count {
            let delta = colorDistance(steps[i - 1], steps[i])
            XCTAssertLessThan(delta, 0.15, "expected a small, gradual color step between adjacent frequencies")
        }
    }

    func testLowAndHighFrequenciesAreVisiblyDistinct() {
        let low = FrequencyColor.color(forFrequencyHz: 100)
        let high = FrequencyColor.color(forFrequencyHz: 10000)
        let maxChannelDelta = max(
            abs(low.red - high.red),
            abs(low.green - high.green),
            abs(low.blue - high.blue)
        )
        XCTAssertGreaterThan(maxChannelDelta, 0.2, "expected 100Hz and 10,000Hz to be visibly distinct colors")
    }

    func testOutOfRangeFrequenciesClampToAnchors() {
        XCTAssertEqual(FrequencyColor.color(forFrequencyHz: 10), FrequencyColor.lowAnchor)
        XCTAssertEqual(FrequencyColor.color(forFrequencyHz: 50000), FrequencyColor.highAnchor)
    }

    private func colorDistance(_ a: RGBColor, _ b: RGBColor) -> Double {
        sqrt(pow(a.red - b.red, 2) + pow(a.green - b.green, 2) + pow(a.blue - b.blue, 2))
    }
}
