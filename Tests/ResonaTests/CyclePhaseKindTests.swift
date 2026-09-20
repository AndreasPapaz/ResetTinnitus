import XCTest
@testable import Resona

final class CyclePhaseKindTests: XCTestCase {
    // Cycle duration is 1/1.5s ≈ 0.667s. Pattern: 3 stimulation cycles
    // (0-2.0s), 2 silent cycles (2.0-3.33s), repeating -- the same
    // boundaries CRCyclePatternTests verifies in cycle-index terms.

    func testEarlyElapsedTimeIsStimulation() {
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 0.1), .stimulation)
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 1.9), .stimulation)
    }

    func testMidBlockElapsedTimeIsSilent() {
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 2.1), .silent)
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 3.2), .silent)
    }

    func testNextBlockReturnsToStimulation() {
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 3.4), .stimulation)
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 4.2), .stimulation)
    }

    func testZeroElapsedIsStimulation() {
        XCTAssertEqual(CyclePhaseKind.current(elapsedSinceSessionStart: 0), .stimulation)
    }
}
