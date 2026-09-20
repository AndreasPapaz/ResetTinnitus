import AVFoundation
import os

enum CRAudioEngineError: Error {
    case formatCreationFailed
}

/// Owns the `AVAudioEngine`/`AVAudioSession` lifecycle for one CR playback
/// session: real-time sine synthesis from a precomputed `CRSessionSchedule`,
/// background-capable playback, and sample-accurate auto-stop at the end of
/// the session (design.md - "Real-time synthesis via AVAudioSourceNode" and
/// "Background audio via AVAudioSession .playback category").
@MainActor
final class CRAudioEngine {
    /// Peak sample amplitude. Never boosted above unity gain — the
    /// device's own volume (and any OS-level loudness limiting) remains
    /// the only ceiling (design.md - "No software gain above unity").
    private static let peakAmplitude: Float = 0.4

    // Not `private` so integration tests (`@testable import`) can install a
    // tap on `engine.mainMixerNode` to verify real rendered audio output.
    let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var renderState: RenderState?

    private(set) var isSessionActive = false

    /// Called on the main thread when a session reaches the end of its
    /// precomputed schedule on its own (not from a manual `stopSession()`).
    var onSessionFinished: (() -> Void)?

    /// Time remaining in the active session, or `nil` if no session is
    /// active. Safe to read from the main thread while the render thread
    /// is concurrently advancing playback.
    var remainingTime: TimeInterval? {
        guard isSessionActive, let renderState else { return nil }
        let schedule = renderState.schedule
        let remainingSamples = max(0, schedule.totalSamples - renderState.renderedSampleCount())
        return Double(remainingSamples) / schedule.sampleRate
    }

    func startSession(ft: Double, duration: TimeInterval) throws {
        stopSession()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)

        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48000

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw CRAudioEngineError.formatCreationFailed
        }

        let schedule = CRSessionSchedule(ft: ft, duration: duration, sampleRate: sampleRate)
        let state = RenderState(schedule: schedule) { [weak self] in
            Task { @MainActor in
                self?.handleSessionFinished()
            }
        }
        renderState = state

        let peakAmplitude = Self.peakAmplitude
        let node = AVAudioSourceNode(format: format) { @Sendable isSilence, _, frameCount, audioBufferList in
            isSilence.pointee = false
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            state.render(frameCount: Int(frameCount), ablPointer: ablPointer, peakAmplitude: peakAmplitude)
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        sourceNode = node

        try engine.start()
        isSessionActive = true
    }

    func stopSession() {
        guard isSessionActive else { return }
        isSessionActive = false
        engine.stop()
        if let sourceNode {
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
        }
        sourceNode = nil
        renderState = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func handleSessionFinished() {
        guard isSessionActive else { return }
        onSessionFinished?()
        stopSession()
    }
}

/// Real-time-safe render state: the render thread is the sole writer of
/// `renderedSampleCount` (via a single lock taken once per callback, not
/// per sample); `schedule` is immutable and needs no lock to read.
private final class RenderState: @unchecked Sendable {
    let schedule: CRSessionSchedule
    private let counters: OSAllocatedUnfairLock<Counters>
    private let onFinished: @Sendable () -> Void

    private struct Counters: Sendable {
        var renderedSampleCount: Int = 0
        var hasFinished = false
    }

    init(schedule: CRSessionSchedule, onFinished: @escaping @Sendable () -> Void) {
        self.schedule = schedule
        self.counters = OSAllocatedUnfairLock(initialState: Counters())
        self.onFinished = onFinished
    }

    func renderedSampleCount() -> Int {
        counters.withLock { $0.renderedSampleCount }
    }

    /// Called only from the audio render thread.
    func render(frameCount: Int, ablPointer: UnsafeMutableAudioBufferListPointer, peakAmplitude: Float) {
        let startIndex = counters.withLock { state -> Int in
            let start = state.renderedSampleCount
            state.renderedSampleCount += frameCount
            return start
        }

        var reachedEnd = false
        for buffer in ablPointer {
            guard let mData = buffer.mData else { continue }
            let out = mData.assumingMemoryBound(to: Float.self)
            for frame in 0..<frameCount {
                let sampleIndex = startIndex + frame
                if let raw = schedule.sampleValue(at: sampleIndex) {
                    out[frame] = Float(raw) * peakAmplitude
                } else {
                    out[frame] = 0
                    reachedEnd = true
                }
            }
        }

        guard reachedEnd else { return }
        let shouldFire = counters.withLock { state -> Bool in
            guard !state.hasFinished else { return false }
            state.hasFinished = true
            return true
        }
        if shouldFire {
            onFinished()
        }
    }
}
