import Testing
@testable import Sabella

@MainActor
@Test func automaticAudioOnlyStreamClassifiesAfterLateTrackDiscovery() async {
    var samples: [SabellaTVAutomaticMediaEvidence] = [
        .unknown, .unknown, .unknown, .unknown,
        .audioOnly, .unknown, .audioOnly, .audioOnly, .audioOnly,
    ]
    var results: [SabellaTVAutomaticMediaResult] = []

    await SabellaTVAutomaticMediumClassifier.observe {
        samples.isEmpty ? nil : samples.removeFirst()
    } wait: {
    } resolved: { result in
        results.append(result)
    }

    #expect(results == [.radio])
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
