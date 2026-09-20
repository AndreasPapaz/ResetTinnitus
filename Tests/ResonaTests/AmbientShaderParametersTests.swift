import XCTest
@testable import Resona

final class AmbientShaderParametersTests: XCTestCase {
    func testStimulationIsBrighterThanSilentAtSameFrequency() {
        let now = Date()
        let stimStart = now.addingTimeInterval(-0.1) // elapsed 0.1s -> stimulation
        let silentStart = now.addingTimeInterval(-2.1) // elapsed 2.1s -> silent
        let stim = AmbientShaderParameters(
            state: .session(frequencyHz: 4000, sessionStartDate: stimStart), now: now, reduceMotion: false
        )
        let silent = AmbientShaderParameters(
            state: .session(frequencyHz: 4000, sessionStartDate: silentStart), now: now, reduceMotion: false
        )
        XCTAssertGreaterThan(stim.intensity, silent.intensity)
        XCTAssertGreaterThan(stim.morphAmount, silent.morphAmount)
    }

    func testRestrainedIsLowestIntensity() {
        let now = Date()
        let restrained = AmbientShaderParameters(state: .restrained, now: now, reduceMotion: false)
        let pitchMatch = AmbientShaderParameters(state: .pitchMatch(frequencyHz: 4000), now: now, reduceMotion: false)
        let session = AmbientShaderParameters(
            state: .session(frequencyHz: 4000, sessionStartDate: now.addingTimeInterval(-0.1)),
            now: now, reduceMotion: false
        )
        XCTAssertLessThan(restrained.intensity, pitchMatch.intensity)
        XCTAssertLessThan(restrained.intensity, session.intensity)
    }

    func testReduceMotionZeroesMorphAmountForEveryState() {
        let now = Date()
        let states: [AmbientState] = [
            .restrained,
            .pitchMatch(frequencyHz: 4000),
            .session(frequencyHz: 4000, sessionStartDate: now.addingTimeInterval(-0.1)),
        ]
        for state in states {
            let params = AmbientShaderParameters(state: state, now: now, reduceMotion: true)
            XCTAssertEqual(params.morphAmount, 0)
        }
    }

    func testReduceMotionStillConveysFrequencyColor() {
        let now = Date()
        let low = AmbientShaderParameters(state: .pitchMatch(frequencyHz: 100), now: now, reduceMotion: true)
        let high = AmbientShaderParameters(state: .pitchMatch(frequencyHz: 10000), now: now, reduceMotion: true)
        XCTAssertNotEqual(low.colorA, high.colorA)
    }

    func testReduceMotionStillConveysSessionPhase() {
        let now = Date()
        let stimStart = now.addingTimeInterval(-0.1)
        let silentStart = now.addingTimeInterval(-2.1)
        let stim = AmbientShaderParameters(
            state: .session(frequencyHz: 4000, sessionStartDate: stimStart), now: now, reduceMotion: true
        )
        let silent = AmbientShaderParameters(
            state: .session(frequencyHz: 4000, sessionStartDate: silentStart), now: now, reduceMotion: true
        )
        XCTAssertGreaterThan(stim.intensity, silent.intensity, "phase-driven intensity should still differ even with motion suppressed")
    }
}
