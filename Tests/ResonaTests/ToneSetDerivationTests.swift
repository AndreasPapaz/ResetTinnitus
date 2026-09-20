import XCTest
@testable import Resona

final class ToneSetDerivationTests: XCTestCase {
    func testEndpointsMatchHalfAndDoubleFt() {
        let ft = 4000.0
        let tones = ToneSetDerivation.deriveTones(ft: ft)
        XCTAssertEqual(tones.count, 4)
        XCTAssertEqual(tones.first!, ft * 0.5, accuracy: 0.0001)
        XCTAssertEqual(tones.last!, ft * 2.0, accuracy: 0.0001)
    }

    func testTonesAreLogEquallySpaced() {
        let ft = 3000.0
        let tones = ToneSetDerivation.deriveTones(ft: ft)
        // Equal spacing on a log scale means equal ratios between
        // consecutive tones.
        let ratios = zip(tones.dropFirst(), tones).map { $1 == 0 ? 0 : $0 / $1 }
        for ratio in ratios {
            XCTAssertEqual(ratio, ratios[0], accuracy: 0.0001)
        }
    }

    func testTonesAreAscending() {
        let tones = ToneSetDerivation.deriveTones(ft: 1234)
        XCTAssertEqual(tones, tones.sorted())
    }
}
