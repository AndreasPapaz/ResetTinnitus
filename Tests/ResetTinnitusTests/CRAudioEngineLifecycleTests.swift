import XCTest
import AVFoundation
@testable import ResetTinnitus

@MainActor
final class CRAudioEngineLifecycleTests: XCTestCase {
    func testStartThenManualStopLeavesSessionDeactivatedAndDoesNotCrash() throws {
        let engine = CRAudioEngine()
        do {
            try engine.startSession(ft: 4000, duration: 60)
        } catch {
            throw XCTSkip("Audio hardware unavailable in this environment: \(error)")
        }
        XCTAssertTrue(engine.isSessionActive)
        XCTAssertEqual(AVAudioSession.sharedInstance().category, .playback)

        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
        XCTAssertNil(engine.remainingTime)

        // Stopping again (already stopped) must also be a safe no-op.
        engine.stopSession()
        XCTAssertFalse(engine.isSessionActive)
    }

    func testSessionAutoStopsAtChosenDuration() async throws {
        let engine = CRAudioEngine()
        let finished = XCTestExpectation(description: "session auto-stopped")
        engine.onSessionFinished = {
            finished.fulfill()
        }

        do {
            // Short enough to keep the test fast, long enough to cross at
            // least one full cycle.
            try engine.startSession(ft: 4000, duration: 1.5)
        } catch {
            throw XCTSkip("Audio hardware unavailable in this environment: \(error)")
        }
        XCTAssertTrue(engine.isSessionActive)

        await fulfillment(of: [finished], timeout: 5)
        XCTAssertFalse(engine.isSessionActive)
    }
}
