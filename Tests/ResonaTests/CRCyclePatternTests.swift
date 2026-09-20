import XCTest
@testable import Resona

final class CRCyclePatternTests: XCTestCase {
    func testThreeOnTwoOffPatternHoldsOverManyCycles() {
        var sequencer = CRCycleSequencer(rng: SeededRNG(seed: 1))
        var phases: [CRCyclePhase] = []
        for _ in 0..<25 {
            phases.append(sequencer.nextPhase())
        }

        for block in stride(from: 0, to: phases.count, by: 5) {
            let window = phases[block..<min(block + 5, phases.count)]
            guard window.count == 5 else { continue }
            let stimulationCount = window.filter {
                if case .stimulation = $0 { return true }
                return false
            }.count
            let silentCount = window.count - stimulationCount
            XCTAssertEqual(stimulationCount, 3)
            XCTAssertEqual(silentCount, 2)

            // 3 stimulation cycles first, then 2 silent, per spec.
            let flags = window.map { phase -> Bool in
                if case .stimulation = phase { return true }
                return false
            }
            XCTAssertEqual(flags, [true, true, true, false, false])
        }
    }

    func testToneOrderVariesAcrossStimulationCycles() {
        var sequencer = CRCycleSequencer(rng: SeededRNG(seed: 42))
        var orders: [[Int]] = []
        var cyclesConsumed = 0
        while orders.count < 6 && cyclesConsumed < 50 {
            if case .stimulation(let order) = sequencer.nextPhase() {
                orders.append(order)
            }
            cyclesConsumed += 1
        }

        XCTAssertEqual(orders.count, 6)
        // Every order must be a permutation of the 4 tone indices.
        for order in orders {
            XCTAssertEqual(Set(order), Set(0..<4))
        }
        // Not every draw should produce the identical order (statistically
        // near-impossible with a real shuffle across 6 draws).
        XCTAssertTrue(Set(orders.map { $0.map(String.init).joined() }).count > 1)
    }

    func testIsStimulationCycleForKnownIndices() {
        XCTAssertTrue(CRCyclePattern.isStimulationCycle(atIndex: 0))
        XCTAssertTrue(CRCyclePattern.isStimulationCycle(atIndex: 1))
        XCTAssertTrue(CRCyclePattern.isStimulationCycle(atIndex: 2))
        XCTAssertFalse(CRCyclePattern.isStimulationCycle(atIndex: 3))
        XCTAssertFalse(CRCyclePattern.isStimulationCycle(atIndex: 4))
        XCTAssertTrue(CRCyclePattern.isStimulationCycle(atIndex: 5)) // next block
    }
}
