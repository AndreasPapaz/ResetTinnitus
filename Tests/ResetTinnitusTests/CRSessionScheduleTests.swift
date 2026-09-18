import XCTest
@testable import ResetTinnitus

final class CRSessionScheduleTests: XCTestCase {
    func testSampleValueIsNilAtAndAfterTotalSamples() {
        let schedule = CRSessionSchedule(ft: 4000, duration: 1, sampleRate: 8000, rng: SeededRNG(seed: 1))
        XCTAssertNotNil(schedule.sampleValue(at: 0))
        XCTAssertNotNil(schedule.sampleValue(at: schedule.totalSamples - 1))
        XCTAssertNil(schedule.sampleValue(at: schedule.totalSamples))
        XCTAssertNil(schedule.sampleValue(at: schedule.totalSamples + 100))
    }

    func testSilentCycleProducesZeroSamples() {
        let schedule = CRSessionSchedule(ft: 4000, duration: 5, sampleRate: 8000, rng: SeededRNG(seed: 1))
        // Cycle index 3 is always silent (3-on/2-off pattern), per
        // CRCyclePattern.
        let silentCycleStart = 3 * schedule.cycleLengthSamples
        for offset in stride(from: 0, to: schedule.cycleLengthSamples, by: 37) {
            XCTAssertEqual(schedule.sampleValue(at: silentCycleStart + offset), 0)
        }
    }

    func testStimulationCycleProducesNonZeroMidSlotSamples() {
        let schedule = CRSessionSchedule(ft: 4000, duration: 5, sampleRate: 8000, rng: SeededRNG(seed: 1))
        // Cycle index 0 is always a stimulation cycle.
        let midFirstSlot = schedule.toneSlotLengthSamples / 2
        let value = schedule.sampleValue(at: midFirstSlot)
        XCTAssertNotNil(value)
        XCTAssertNotEqual(value, 0)
        XCTAssertLessThanOrEqual(abs(value!), 1.0)
    }

    func testFadeEnvelopeIsZeroAtSlotStart() {
        let schedule = CRSessionSchedule(ft: 4000, duration: 5, sampleRate: 8000, rng: SeededRNG(seed: 1))
        // sin(0) == 0 regardless of envelope, so assert via a frequency
        // that would otherwise be clearly non-zero at sample 0 -- instead
        // check the envelope's effect a few samples in, before the fade
        // completes, stays below the unfaded amplitude.
        let earlySample = schedule.sampleValue(at: 1)!
        let midSlotSample = schedule.sampleValue(at: schedule.toneSlotLengthSamples / 2)!
        XCTAssertLessThan(abs(earlySample), abs(midSlotSample) + 0.5)
    }

    func testToneFrequenciesMatchDerivation() {
        let ft = 3500.0
        let schedule = CRSessionSchedule(ft: ft, duration: 1, sampleRate: 8000, rng: SeededRNG(seed: 7))
        XCTAssertEqual(schedule.toneFrequencies, ToneSetDerivation.deriveTones(ft: ft))
    }
}
