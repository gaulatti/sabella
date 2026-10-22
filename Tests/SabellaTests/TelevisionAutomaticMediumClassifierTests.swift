import Testing
@testable import Sabella

@MainActor
@Test func automaticAudioOnlyStreamClassifiesAfterLateTrackDiscovery() async {
    var samples: [SabellaTVAutomaticMediaEvidence] = [
        .unknown, .unknown, .unknown, .unknown,
        .audioOnly, .unknown, .audioOnly, .audioOnly, .audioOnly,
    ]
    var results: [SabellaTVAutomaticMediaResult] = []
    var sampled = 0
    var resolvedAtSamples: [Int] = []

    await SabellaTVAutomaticMediumClassifier.observe {
        guard !samples.isEmpty else { return nil }
        sampled += 1
        return samples.removeFirst()
    } wait: {
    } resolved: { result in
        results.append(result)
        resolvedAtSamples.append(sampled)
    }

    #expect(results == [.radio])
    #expect(resolvedAtSamples == [9])
}

@MainActor
@Test(.timeLimit(.minutes(1)))
func cancelledAutomaticClassificationIgnoresAnInFlightSample() async {
    let (sampleStarted, started) = AsyncStream<Void>.makeStream()
    var pendingSample: CheckedContinuation<SabellaTVAutomaticMediaEvidence?, Never>?
    var results: [SabellaTVAutomaticMediaResult] = []
    var waits = 0

    let observation = Task { @MainActor in
        defer { started.finish() }
        await SabellaTVAutomaticMediumClassifier.observe {
            await withCheckedContinuation { continuation in
                pendingSample = continuation
                started.yield(())
            }
        } wait: {
            waits += 1
        } resolved: { result in
            results.append(result)
        }
    }

    for await _ in sampleStarted { break }
    started.finish()
    #expect(pendingSample != nil)
    observation.cancel()
    pendingSample?.resume(returning: .video)
    await observation.value

    #expect(results.isEmpty)
    #expect(waits == 0)
}

@MainActor
@Test func automaticStreamCorrectsRadioWhenVideoTrackArrives() async {
    var samples: [SabellaTVAutomaticMediaEvidence] = [
        .audioOnly, .audioOnly, .audioOnly, .unknown, .video,
    ]
    var results: [SabellaTVAutomaticMediaResult] = []

    await SabellaTVAutomaticMediumClassifier.observe {
        samples.isEmpty ? nil : samples.removeFirst()
    } wait: {
    } resolved: { result in
        results.append(result)
    }

    #expect(results == [.radio, .television])
}
