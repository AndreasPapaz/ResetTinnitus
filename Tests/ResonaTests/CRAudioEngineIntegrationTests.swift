import XCTest
import AVFoundation
@testable import Resona

/// Integration coverage standing in for tasks 4.1/4.2's "verify manually
/// by listening" steps: this captures the engine's actual rendered audio
/// (via a tap on the real AVAudioEngine graph, not just the pure
/// CRSessionSchedule math) and asserts on it, since there's no way to
/// literally listen from an automated test run.
@MainActor
final class CRAudioEngineIntegrationTests: XCTestCase {
    func testSessionProducesAlternatingSilenceAndToneSamples() throws {
        let engine = CRAudioEngine()
        let capturedSamples = CapturedSamples()

        let format = engine.engine.mainMixerNode.outputFormat(forBus: 0)
        engine.engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { @Sendable buffer, _ in
            guard let channelData = buffer.floatChannelData else { return }
            let frameLength = Int(buffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData[0], count: frameLength))
            capturedSamples.append(samples)
        }
        defer { engine.engine.mainMixerNode.removeTap(onBus: 0) }

        do {
            // Long enough to cross a full 5-cycle block (≈3.3s at 1.5 Hz)
            // so both stimulation and silent cycles get captured.
            try engine.startSession(ft: 4000, duration: 4)
        } catch {
            throw XCTSkip("Audio hardware unavailable in this environment: \(error)")
        }

        let expectation = expectation(description: "captured enough audio")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 8)

        engine.stopSession()

        let samples = capturedSamples.all()
        XCTAssertFalse(samples.isEmpty, "expected captured audio samples")

        for sample in samples {
            XCTAssertFalse(sample.isNaN)
            XCTAssertLessThanOrEqual(abs(sample), 0.41, "sample exceeds peak amplitude ceiling")
        }

        // Confirms the 3-on/2-off pattern actually manifests in real
        // rendered audio (stimulation cycles are audible, silent cycles
        // are not), not just in the pure schedule math.
        let nonZeroCount = samples.filter { abs($0) > 0.01 }.count
        let nearZeroCount = samples.filter { abs($0) < 0.001 }.count
        XCTAssertGreaterThan(nonZeroCount, 100, "expected audible stimulation-cycle samples")
        XCTAssertGreaterThan(nearZeroCount, 100, "expected near-silent silent-cycle samples")
    }
}

/// Thread-safe accumulator for samples captured on the tap's real-time
/// thread.
private final class CapturedSamples: @unchecked Sendable {
    private let lock = NSLock()
    private var samples: [Float] = []

    func append(_ newSamples: [Float]) {
        lock.lock()
        samples.append(contentsOf: newSamples)
        lock.unlock()
    }

    func all() -> [Float] {
        lock.lock()
        defer { lock.unlock() }
        return samples
    }
}
