import AVFoundation
import os

/// Plays a single continuous sine tone whose frequency can be updated live
/// while it plays, for the pitch-matching flow (tinnitus-frequency-profile
/// spec - "Pitch-matching flow": live tone updates as the user adjusts
/// frequency).
@MainActor
final class PitchMatchTonePlayer {
    private static let peakAmplitude: Float = 0.4

    // Not `private` so tests can install a tap on the real audio graph,
    // mirroring CRAudioEngine's integration-test approach.
    let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var toneState: ToneState?

    private(set) var isPlaying = false

    func start(initialFrequencyHz: Double) throws {
        stop()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)

        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        let sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 48000
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            throw CRAudioEngineError.formatCreationFailed
        }

        let state = ToneState(frequency: initialFrequencyHz, sampleRate: sampleRate)
        toneState = state

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
        isPlaying = true
    }

    func update(frequencyHz: Double) {
        toneState?.setFrequency(frequencyHz)
    }

    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        engine.stop()
        if let sourceNode {
            engine.disconnectNodeOutput(sourceNode)
            engine.detach(sourceNode)
        }
        sourceNode = nil
        toneState = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

/// Real-time-safe tone state: a running phase accumulator so frequency
/// changes (from the pitch-match slider) don't reset phase and click.
private final class ToneState: @unchecked Sendable {
    private struct Data: Sendable {
        var frequency: Double
        var sampleRate: Double
        var phase: Double = 0
    }

    private let lock: OSAllocatedUnfairLock<Data>

    init(frequency: Double, sampleRate: Double) {
        lock = OSAllocatedUnfairLock(initialState: Data(frequency: frequency, sampleRate: sampleRate))
    }

    func setFrequency(_ hz: Double) {
        lock.withLock { $0.frequency = hz }
    }

    /// Called only from the audio render thread.
    func render(frameCount: Int, ablPointer: UnsafeMutableAudioBufferListPointer, peakAmplitude: Float) {
        for buffer in ablPointer {
            guard let mData = buffer.mData else { continue }
            let out = mData.assumingMemoryBound(to: Float.self)
            for frame in 0..<frameCount {
                let value = lock.withLock { data -> Float in
                    let increment = 2.0 * Double.pi * data.frequency / data.sampleRate
                    data.phase += increment
                    if data.phase > 2.0 * Double.pi {
                        data.phase -= 2.0 * Double.pi
                    }
                    return Float(sin(data.phase)) * peakAmplitude
                }
                out[frame] = value
            }
        }
    }
}
