import Foundation

enum SabellaTVAutomaticMediaEvidence {
    case unknown
    case audioOnly
    case video
}

enum SabellaTVAutomaticMediaResult {
    case radio
    case television
}

/// Keeps observing a ready automatic stream until its tracks identify the
/// medium. An audio-only result remains open to a later video track.
@MainActor
enum SabellaTVAutomaticMediumClassifier {
    static func observe(
        sample: () async -> SabellaTVAutomaticMediaEvidence?,
        wait: () async -> Void = { try? await Task.sleep(for: .milliseconds(750)) },
        resolved: (SabellaTVAutomaticMediaResult) -> Void
    ) async {
        var consecutiveAudioOnlySamples = 0
        var reportedRadio = false

        while !Task.isCancelled {
            guard let evidence = await sample(), !Task.isCancelled else { return }
            switch evidence {
            case .video:
                resolved(.television)
                return
            case .audioOnly:
                consecutiveAudioOnlySamples += 1
                if consecutiveAudioOnlySamples >= 3 && !reportedRadio {
                    reportedRadio = true
                    resolved(.radio)
                }
            case .unknown:
                consecutiveAudioOnlySamples = 0
            }
            await wait()
        }
    }
}
