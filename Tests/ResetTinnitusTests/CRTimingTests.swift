import XCTest
@testable import ResetTinnitus

final class CRTimingTests: XCTestCase {
    func testCycleLengthMatchesTargetRateAt48kHz() {
        let sampleRate = 48000.0
        let cycleSamples = CRTiming.cycleLengthInSamples(sampleRate: sampleRate)
        let cycleSeconds = Double(cycleSamples) / sampleRate
        // Target: 1 / 1.5 Hz ≈ 0.6667s (≈667ms), within half a millisecond.
        XCTAssertEqual(cycleSeconds, 1.0 / 1.5, accuracy: 0.0005)
    }

    func testToneSlotIsQuarterOfCycle() {
        let sampleRate = 44100.0
        let cycleSamples = CRTiming.cycleLengthInSamples(sampleRate: sampleRate)
        let slotSamples = CRTiming.toneSlotLengthInSamples(sampleRate: sampleRate)
        XCTAssertEqual(slotSamples * 4, cycleSamples, accuracy: 4)
    }

    func testFadeLengthIsFiveMilliseconds() {
        let sampleRate = 48000.0
        let fadeSamples = CRTiming.fadeLengthInSamples(sampleRate: sampleRate)
        XCTAssertEqual(Double(fadeSamples) / sampleRate, 0.005, accuracy: 0.0001)
    }

    func testSessionLengthInSamplesForOneHour() {
        let sampleRate = 48000.0
        let samples = CRTiming.sessionLengthInSamples(duration: 3600, sampleRate: sampleRate)
        XCTAssertEqual(samples, 3600 * 48000)
    }
}
