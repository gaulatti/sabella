/// A semantic snapshot of playback for the currently tuned live channel.
/// Consumers may measure time only while `state` is `.playing`; Sabella owns
/// the engine-specific lifecycle that produces these values.
public struct SabellaTVPlaybackActivity: Hashable, Sendable {
    public enum State: String, CaseIterable, Hashable, Sendable {
        case starting
        case buffering
        case playing
        case paused
        case failed
        case stopped
    }

    public let channelID: String
    public let state: State

    public init(channelID: String, state: State) {
        self.channelID = channelID
        self.state = state
    }
}

enum SabellaTVPlaybackActivityEngine: CaseIterable {
    case avPlayer
    case ksPlayer
}

enum SabellaTVPlaybackActivitySignal {
    case buffering
    case advancing
    case paused
}

/// The single coalescing boundary shared by the AVPlayer and KSPlayer adapters.
/// It also rejects late observations from a replaced engine or channel.
struct SabellaTVPlaybackActivityCoordinator {
    private(set) var activeChannelID: String?
    private(set) var engine: SabellaTVPlaybackActivityEngine?
    private(set) var latestActivity: SabellaTVPlaybackActivity?

    mutating func tune(to channelID: String) -> [SabellaTVPlaybackActivity] {
        guard activeChannelID != channelID else { return [] }

        var activities: [SabellaTVPlaybackActivity] = []
        if let activeChannelID,
           let stopped = emit(.stopped, for: activeChannelID, acceptsInactiveChannel: true) {
            activities.append(stopped)
        }

        activeChannelID = channelID
        engine = nil
        if let starting = emit(.starting, for: channelID) {
            activities.append(starting)
        }
        return activities
    }

    mutating func selectEngine(
        _ engine: SabellaTVPlaybackActivityEngine,
        for channelID: String
    ) -> SabellaTVPlaybackActivity? {
        guard activeChannelID == channelID else { return nil }
        self.engine = engine
        return emit(.buffering, for: channelID)
    }

    mutating func receive(
        _ signal: SabellaTVPlaybackActivitySignal,
        from engine: SabellaTVPlaybackActivityEngine,
        for channelID: String
    ) -> SabellaTVPlaybackActivity? {
        guard activeChannelID == channelID, self.engine == engine else { return nil }
        let state: SabellaTVPlaybackActivity.State = switch signal {
        case .buffering: .buffering
        case .advancing: .playing
        case .paused: .paused
        }
        return emit(state, for: channelID)
    }

    mutating func resume(channelID: String) -> SabellaTVPlaybackActivity? {
        emit(.starting, for: channelID)
    }

    mutating func beginRecovery(channelID: String) -> SabellaTVPlaybackActivity? {
        guard activeChannelID == channelID else { return nil }
        engine = nil
        return emit(.starting, for: channelID)
    }

    mutating func fail(channelID: String) -> SabellaTVPlaybackActivity? {
        emit(.failed, for: channelID)
    }

    mutating func stop() -> SabellaTVPlaybackActivity? {
        guard let activeChannelID else { return nil }
        let activity = emit(.stopped, for: activeChannelID, acceptsInactiveChannel: true)
        self.activeChannelID = nil
        engine = nil
        return activity
    }

    private mutating func emit(
        _ state: SabellaTVPlaybackActivity.State,
        for channelID: String,
        acceptsInactiveChannel: Bool = false
    ) -> SabellaTVPlaybackActivity? {
        guard acceptsInactiveChannel || activeChannelID == channelID else { return nil }
        let activity = SabellaTVPlaybackActivity(channelID: channelID, state: state)
        guard activity != latestActivity else { return nil }
        latestActivity = activity
        return activity
    }
}
