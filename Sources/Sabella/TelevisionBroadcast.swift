#if os(tvOS)
import SwiftUI
import UIKit
import AVFoundation
import Combine
import OSLog
@_exported import KSPlayer
import SabellaKSPlayerWorkaround

public enum SabellaTVDVRAction: Hashable, Sendable {
    case none, play, pause, rewind, fastForward
}

public struct SabellaTVPlayerSurface: UIViewRepresentable {
    private let player: AVPlayer
    private let gravity: AVLayerVideoGravity
    public init(player: AVPlayer, gravity: AVLayerVideoGravity = .resizeAspect) { self.player = player; self.gravity = gravity }
    public func makeUIView(context: Context) -> PlayerView { let view = PlayerView(); view.playerLayer.player = player; view.playerLayer.videoGravity = gravity; return view }
    public func updateUIView(_ view: PlayerView, context: Context) { view.playerLayer.player = player; view.playerLayer.videoGravity = gravity }
    public final class PlayerView: UIView {
        public override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

/// Sabella's complete single-stream playback presentation. Applications may
/// supply any decoding surface, but Sabella owns every visible state and all
/// remote interaction around it.
public struct SabellaTVSinglePlayback<Media: View>: View {
    private let productName: String
    private let station: String
    private let title: String?
    private let isAudioOnly: Bool
    private let isBuffering: Bool
    private let isPlaying: Bool
    private let isFailed: Bool
    private let isDemo: Bool
    private let dvrVisible: Bool
    private let currentTime: Double
    private let duration: Double
    private let quality: String?
    private let dvrAction: SabellaTVDVRAction
    private let retry: () -> Void
    private let select: () -> Void
    private let restart: () -> Void
    private let togglePlayback: () -> Void
    private let skipBackward: () -> Void
    private let skipForward: () -> Void
    private let showTransport: () -> Void
    private let exit: () -> Void
    @ViewBuilder private let media: Media

    public init(
        productName: String,
        station: String,
        title: String? = nil,
        isAudioOnly: Bool,
        isBuffering: Bool,
        isPlaying: Bool,
        isFailed: Bool,
        isDemo: Bool = false,
        dvrVisible: Bool = false,
        currentTime: Double = 0,
        duration: Double = 0,
        quality: String? = nil,
        dvrAction: SabellaTVDVRAction = .none,
        retry: @escaping () -> Void,
        select: @escaping () -> Void,
        restart: @escaping () -> Void,
        togglePlayback: @escaping () -> Void,
        skipBackward: @escaping () -> Void,
        skipForward: @escaping () -> Void,
        showTransport: @escaping () -> Void,
        exit: @escaping () -> Void,
        @ViewBuilder media: () -> Media
    ) {
        self.productName = productName
        self.station = station
        self.title = title
        self.isAudioOnly = isAudioOnly
        self.isBuffering = isBuffering
        self.isPlaying = isPlaying
        self.isFailed = isFailed
        self.isDemo = isDemo
        self.dvrVisible = dvrVisible
        self.currentTime = currentTime
        self.duration = duration
        self.quality = quality
        self.dvrAction = dvrAction
        self.retry = retry
        self.select = select
        self.restart = restart
        self.togglePlayback = togglePlayback
        self.skipBackward = skipBackward
        self.skipForward = skipForward
        self.showTransport = showTransport
        self.exit = exit
        self.media = media()
    }

    public var body: some View {
        ZStack {
            if isFailed {
                SabellaTVPlaybackFailure(
                    title: station,
                    message: "Could not connect to the stream.",
                    retry: retry
                )
            } else {
                if !isAudioOnly {
                    media
                }

                if isAudioOnly {
                    SabellaTVRadioNowPlaying(
                        station: station,
                        title: title,
                        buffering: isBuffering,
                        active: isPlaying
                    )
                }

                if isDemo {
                    SabellaTVDemoOverlay(productName: productName, buffering: isBuffering)
                }

                if dvrVisible {
                    SabellaTVDVROverlay(
                        currentTime: currentTime,
                        duration: duration,
                        quality: quality,
                        action: dvrAction
                    )
                }

                if isBuffering, !isAudioOnly {
                    ProgressView()
                        .scaleEffect(1.6)
                        .tint(.white)
                }
            }
        }
        .ignoresSafeArea()
        .focusable()
        .onTapGesture(perform: select)
        .onLongPressGesture(perform: restart)
        .onPlayPauseCommand(perform: togglePlayback)
        .onMoveCommand { direction in
            switch direction {
            case .left: skipBackward()
            case .right: skipForward()
            case .up, .down: showTransport()
            default: break
            }
        }
        .onExitCommand(perform: exit)
    }
}

/// Sabella's complete live-channel playback contract. The consuming product
/// supplies channel data; Sabella owns media presentation, focus, remote
/// commands, channel tuning, loading/failure states, and TV/radio behavior.
/// `onPlaybackActivityChanged` reports coalesced semantic changes on the main
/// actor. `.playing` is emitted only after the selected engine reports that
/// media is advancing.
@MainActor
public struct SabellaTVLivePlayer: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding private var selection: String
    @Binding private var guideVisible: Bool
    @StateObject private var playback: SabellaTVLivePlaybackModel

    private let channels: [SabellaTVChannel]
    private let guideTitle: String
    private let hasMoreChannels: Bool
    private let loadingMoreChannels: Bool
    private let loadMoreChannels: () -> Void
    private let onSelectionChanged: (SabellaTVChannel) -> Void
    private let onExit: () -> Void

    public init(
        channels: [SabellaTVChannel],
        selection: Binding<String>,
        guideVisible: Binding<Bool>,
        guideTitle: String = "All Channels",
        hasMoreChannels: Bool = false,
        loadingMoreChannels: Bool = false,
        loadMoreChannels: @escaping () -> Void = {},
        onSelectionChanged: @escaping (SabellaTVChannel) -> Void = { _ in },
        onPlaybackActivityChanged: @escaping @MainActor @Sendable (SabellaTVPlaybackActivity) -> Void = { _ in },
        onExit: @escaping () -> Void
    ) {
        precondition(!channels.isEmpty, "SabellaTVLivePlayer requires at least one channel")
        self.channels = channels
        _selection = selection
        _guideVisible = guideVisible
        self.guideTitle = guideTitle
        self.hasMoreChannels = hasMoreChannels
        self.loadingMoreChannels = loadingMoreChannels
        self.loadMoreChannels = loadMoreChannels
        self.onSelectionChanged = onSelectionChanged
        _playback = StateObject(
            wrappedValue: SabellaTVLivePlaybackModel(
                onPlaybackActivityChanged: onPlaybackActivityChanged
            )
        )
        self.onExit = onExit
    }

    public var body: some View {
        ZStack {
            if playback.hasFailed {
                // A failed automatic stream has no trustworthy medium. Keep the
                // failure state visually quiet instead of exposing a stale or
                // provisional radio presentation beneath the guide.
                Color.black
            } else if playback.isRadio {
                SabellaTVRadioNowPlaying(
                    station: selectedChannel.name,
                    title: selectedChannel.now,
                    buffering: playback.isBuffering,
                    active: playback.isPlaying,
                    mark: selectedChannel.mark,
                    tone: selectedChannel.tone
                )
                .transition(.opacity)
            } else {
                Color.black
                if playback.isUsingKSPlayer,
                   let coordinator = playback.ksCoordinator,
                   let url = playback.currentURL {
                    KSVideoPlayer(coordinator: coordinator, url: url, options: playback.ksOptions)
                        .id(playback.playbackID)
                        .transition(.opacity)
                } else {
                    SabellaTVPlayerSurface(player: playback.player, gravity: .resizeAspectFill)
                        .transition(.opacity)
                }
            }

            if playback.hasFailed, !guideVisible {
                SabellaTVPlaybackFailure(
                    title: selectedChannel.name,
                    message: "The live signal could not be loaded."
                ) {
                    playback.tune(selectedChannel)
                }
            } else if playback.isBuffering, !playback.isRadio {
                ProgressView()
                    .scaleEffect(1.6)
                    .tint(.white)
            }

            if guideVisible {
                SabellaTVChannelGuide(
                    channels: channels,
                    selection: selection,
                    title: guideTitle,
                    isPlaying: playback.isPlaying,
                    isMuted: playback.isMuted,
                    resolvedMedia: playback.resolvedMedia,
                    hasMoreChannels: hasMoreChannels,
                    loadingMoreChannels: loadingMoreChannels,
                    loadMoreChannels: loadMoreChannels,
                    togglePlayback: playback.togglePlayback,
                    toggleMute: playback.toggleMute
                ) { channel in
                    selection = channel.id
                    playback.tune(channel)
                    onSelectionChanged(channel)
                    withAnimation(playbackAnimation) { guideVisible = false }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                SabellaTVPlaybackRemoteCapture(label: "Show \(guideTitle) channel guide") {
                    withAnimation(playbackAnimation) { guideVisible = true }
                }
            }
        }
        .ignoresSafeArea()
        .task(id: selection) {
            guard let channel = channels.first(where: { $0.id == selection }) else { return }
            playback.tune(channel)
        }
        .onDisappear { playback.stop() }
        .onPlayPauseCommand { playback.togglePlayback() }
        .onChange(of: scenePhase) { _, phase in playback.handleScenePhase(phase, channel: selectedChannel) }
        .onExitCommand {
            if guideVisible {
                withAnimation(playbackAnimation) { guideVisible = false }
            } else {
                playback.stop()
                onExit()
            }
        }
    }

    private var selectedChannel: SabellaTVChannel {
        channels.first { $0.id == selection } ?? channels[0]
    }

    private var playbackAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.34)
    }
}

@MainActor
private final class SabellaTVLivePlaybackModel: ObservableObject {
    let player = AVPlayer()
    let ksOptions: KSOptions
    @Published private(set) var ksCoordinator: KSVideoPlayer.Coordinator?
    @Published private(set) var currentURL: URL?
    @Published private(set) var isUsingKSPlayer = false
    @Published private(set) var playbackID = UUID()
    @Published private(set) var isBuffering = true
    @Published private(set) var hasFailed = false
    @Published private(set) var isPlaying = true
    @Published private(set) var isMuted = false
    @Published private(set) var isRadio = false
    @Published private(set) var resolvedMedia: [String: SabellaTVChannelMedium] = [:]

    private var channelID: String?
    private var monitorTask: Task<Void, Never>?
    private var classificationTask: Task<Void, Never>?
    private var resolverTask: Task<Void, Never>?
    private var recoveryTask: Task<Void, Never>?
    private var recoveryAttempt = 0
    private var resumeWhenActive = false
    private var playbackRequested = false
    private var activityCoordinator = SabellaTVPlaybackActivityCoordinator()
    private let onPlaybackActivityChanged: @MainActor @Sendable (SabellaTVPlaybackActivity) -> Void

    init(
        onPlaybackActivityChanged: @escaping @MainActor @Sendable (SabellaTVPlaybackActivity) -> Void
    ) {
        self.onPlaybackActivityChanged = onPlaybackActivityChanged
        SabellaInstallKSPlayerWorkaround()
        let ksOptions = KSOptions()
        ksOptions.userAgent = Self.streamUserAgent
        self.ksOptions = ksOptions
        player.actionAtItemEnd = .pause
        player.automaticallyWaitsToMinimizeStalling = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback)
            try session.setActive(true)
        } catch {
            hasFailed = true
        }
    }

    func tune(_ channel: SabellaTVChannel) {
        guard channelID != channel.id || hasFailed else { return }
        if channelID == channel.id {
            publish(activityCoordinator.beginRecovery(channelID: channel.id))
        } else {
            publish(activityCoordinator.tune(to: channel.id))
        }
        channelID = channel.id
        recoveryAttempt = 0
        playbackRequested = true
        start(channel)
    }

    private func start(_ channel: SabellaTVChannel) {
        guard channelID == channel.id else { return }
        tearDownCurrentEngine()
        isRadio = effectiveMedium(for: channel) == .radio

        switch SabellaTVPlaybackEnginePolicy.engine(for: channel.streamURL) {
        case .ffmpeg:
            Self.log.info("decoder=ffmpeg channel=\(channel.id, privacy: .public) source=url")
            playWithKSPlayer(channel)
        case .native:
            Self.log.info("decoder=avplayer channel=\(channel.id, privacy: .public) source=url")
            playWithAVPlayer(channel)
        case nil:
            resolverTask = Task { @MainActor [weak self] in
                guard let self else { return }
                let probe = await self.probe(channel.streamURL)
                guard !Task.isCancelled, self.channelID == channel.id else { return }
                if SabellaTVPlaybackEnginePolicy.engine(
                    for: channel.streamURL,
                    contentType: probe.contentType,
                    leadingBytes: probe.leadingBytes
                ) == .ffmpeg {
                    Self.log.info("decoder=ffmpeg channel=\(channel.id, privacy: .public) source=probe")
                    self.playWithKSPlayer(channel)
                } else {
                    Self.log.info("decoder=avplayer channel=\(channel.id, privacy: .public) source=probe")
                    self.playWithAVPlayer(channel)
                }
            }
        }
    }

    private func playWithAVPlayer(_ channel: SabellaTVChannel) {
        guard channelID == channel.id else { return }
        currentURL = channel.streamURL
        isUsingKSPlayer = false
        publish(activityCoordinator.selectEngine(.avPlayer, for: channel.id))

        let asset = AVURLAsset(
            url: channel.streamURL,
            options: [
                "AVURLAssetHTTPHeaderFieldsKey": [
                    "User-Agent": Self.streamUserAgent,
                    "Accept": "*/*",
                    "Icy-MetaData": "1",
                ],
            ]
        )
        let item = AVPlayerItem(asset: asset)

        player.replaceCurrentItem(with: item)
        player.isMuted = isMuted
        player.play()

        monitorTask = Task { @MainActor [weak self] in
            guard let self else { return }
            while !Task.isCancelled, self.channelID == channel.id {
                switch item.status {
                case .failed:
                    self.scheduleRecovery(for: channel)
                    return
                case .readyToPlay:
                    switch self.player.timeControlStatus {
                    case .playing where self.player.rate > 0:
                        self.publish(
                            self.activityCoordinator.receive(
                                .advancing,
                                from: .avPlayer,
                                for: channel.id
                            )
                        )
                    case .waitingToPlayAtSpecifiedRate:
                        self.publish(
                            self.activityCoordinator.receive(
                                .buffering,
                                from: .avPlayer,
                                for: channel.id
                            )
                        )
                    case .paused:
                        let signal: SabellaTVPlaybackActivitySignal = self.playbackRequested
                            ? .buffering
                            : .paused
                        self.publish(
                            self.activityCoordinator.receive(
                                signal,
                                from: .avPlayer,
                                for: channel.id
                            )
                        )
                    default:
                        self.publish(
                            self.activityCoordinator.receive(
                                .buffering,
                                from: .avPlayer,
                                for: channel.id
                            )
                        )
                    }
                    if channel.medium == .automatic,
                       self.resolvedMedia[channel.id] == .radio,
                       item.presentationSize.width > 0 {
                        self.resolvedMedia[channel.id] = .television
                        self.isRadio = false
                    }
                    if channel.medium == .automatic, self.classificationTask == nil {
                        self.classificationTask = Task { @MainActor [weak self] in
                            await self?.classify(item: item, channelID: channel.id)
                        }
                    }
                case .unknown:
                    self.isBuffering = true
                @unknown default:
                    self.isBuffering = true
                }
                try? await Task.sleep(for: .milliseconds(250))
            }
        }
    }

    private func playWithKSPlayer(_ channel: SabellaTVChannel) {
        guard channelID == channel.id else { return }
        currentURL = channel.streamURL
        isUsingKSPlayer = true
        playbackID = UUID()
        publish(activityCoordinator.selectEngine(.ksPlayer, for: channel.id))

        let coordinator = KSVideoPlayer.Coordinator()
        coordinator.isMuted = isMuted
        coordinator.isScaleAspectFill = true
        coordinator.onStateChanged = { [weak self] _, state in
            Task { @MainActor [weak self] in
                self?.handleKSState(state, channel: channel)
            }
        }
        coordinator.onFinish = { [weak self] _, error in
            guard error != nil else { return }
            Task { @MainActor [weak self] in
                self?.scheduleRecovery(for: channel)
            }
        }
        ksCoordinator = coordinator
        _ = coordinator.makeView(url: channel.streamURL, options: ksOptions)
    }

    private func handleKSState(_ state: KSPlayerState, channel: SabellaTVChannel) {
        guard channelID == channel.id else { return }
        switch state {
        case .preparing, .buffering, .initialized:
            publish(activityCoordinator.receive(.buffering, from: .ksPlayer, for: channel.id))
        case .readyToPlay:
            publish(activityCoordinator.receive(.buffering, from: .ksPlayer, for: channel.id))
        case .bufferFinished:
            let mediaIsAdvancing = ksCoordinator?.playerLayer?.player.isPlaying == true
                && ksCoordinator?.playerLayer?.player.playbackState == .playing
            publish(
                activityCoordinator.receive(
                    mediaIsAdvancing ? .advancing : .buffering,
                    from: .ksPlayer,
                    for: channel.id
                )
            )
            if channel.medium == .automatic, classificationTask == nil {
                classificationTask = Task { @MainActor [weak self] in
                    await self?.classifyKSPlayer(channelID: channel.id)
                }
            }
        case .paused:
            playbackRequested = false
            publish(activityCoordinator.receive(.paused, from: .ksPlayer, for: channel.id))
        case .playedToTheEnd, .error:
            scheduleRecovery(for: channel)
        }
    }

    func togglePlayback() {
        guard let channelID else { return }
        if playbackRequested {
            playbackRequested = false
            if isUsingKSPlayer {
                ksCoordinator?.playerLayer?.pause()
            } else {
                player.pause()
            }
            let engine: SabellaTVPlaybackActivityEngine = isUsingKSPlayer ? .ksPlayer : .avPlayer
            publish(activityCoordinator.receive(.paused, from: engine, for: channelID))
        } else {
            playbackRequested = true
            publish(activityCoordinator.resume(channelID: channelID))
            if isUsingKSPlayer {
                ksCoordinator?.playerLayer?.play()
            } else {
                player.play()
            }
        }
    }

    func toggleMute() {
        isMuted.toggle()
        player.isMuted = isMuted
        ksCoordinator?.isMuted = isMuted
    }

    func handleScenePhase(_ phase: ScenePhase, channel: SabellaTVChannel) {
        switch phase {
        case .background:
            let shouldSuspend = switch channel.backgroundPlayback {
            case .automatic: !isRadio
            case .suspend: true
            case .audio: false
            }
            guard shouldSuspend else { return }
            resumeWhenActive = playbackRequested
            playbackRequested = false
            if isUsingKSPlayer {
                ksCoordinator?.playerLayer?.pause()
            } else {
                player.pause()
            }
            let engine: SabellaTVPlaybackActivityEngine = isUsingKSPlayer ? .ksPlayer : .avPlayer
            publish(activityCoordinator.receive(.paused, from: engine, for: channel.id))
        case .active:
            guard resumeWhenActive else { return }
            resumeWhenActive = false
            playbackRequested = true
            publish(activityCoordinator.resume(channelID: channel.id))
            if isUsingKSPlayer {
                ksCoordinator?.playerLayer?.play()
            } else {
                player.play()
            }
        case .inactive:
            break
        @unknown default:
            break
        }
    }

    func stop() {
        publish(activityCoordinator.stop())
        tearDownCurrentEngine()
        channelID = nil
        currentURL = nil
        recoveryAttempt = 0
        playbackRequested = false
        resumeWhenActive = false
    }

    private func effectiveMedium(for channel: SabellaTVChannel) -> SabellaTVChannelMedium {
        channel.medium == .automatic ? resolvedMedia[channel.id] ?? .automatic : channel.medium
    }

    private func classify(item: AVPlayerItem, channelID: String) async {
        var confirmedAudioOnlySamples = 0

        for sample in 0..<3 {
            guard !Task.isCancelled, self.channelID == channelID else { return }

            let videoTracks = try? await item.asset.loadTracks(withMediaType: .video)
            let audioTracks = try? await item.asset.loadTracks(withMediaType: .audio)
            guard !Task.isCancelled, self.channelID == channelID else { return }

            if item.presentationSize.width > 0 || videoTracks?.isEmpty == false {
                resolvedMedia[channelID] = .television
                isRadio = false
                return
            }

            if videoTracks?.isEmpty == true, audioTracks?.isEmpty == false {
                confirmedAudioOnlySamples += 1
            }

            if sample < 2 {
                try? await Task.sleep(for: .milliseconds(750))
            }
        }

        guard confirmedAudioOnlySamples == 3, self.channelID == channelID else { return }
        resolvedMedia[channelID] = .radio
        isRadio = true
    }

    private func classifyKSPlayer(channelID: String) async {
        var confirmedAudioOnlySamples = 0

        for sample in 0..<3 {
            guard !Task.isCancelled, self.channelID == channelID,
                  let mediaPlayer = ksCoordinator?.playerLayer?.player else { return }

            if mediaPlayer.naturalSize.width > 0 || !mediaPlayer.tracks(mediaType: .video).isEmpty {
                resolvedMedia[channelID] = .television
                isRadio = false
                return
            }

            if mediaPlayer.tracks(mediaType: .video).isEmpty,
               !mediaPlayer.tracks(mediaType: .audio).isEmpty {
                confirmedAudioOnlySamples += 1
            }

            if sample < 2 {
                try? await Task.sleep(for: .milliseconds(750))
            }
        }

        guard confirmedAudioOnlySamples == 3, self.channelID == channelID else { return }
        resolvedMedia[channelID] = .radio
        isRadio = true
    }

    private func scheduleRecovery(for channel: SabellaTVChannel) {
        guard channelID == channel.id, recoveryTask == nil else { return }
        guard recoveryAttempt < Self.maximumRecoveryAttempts else {
            playbackRequested = false
            publish(activityCoordinator.fail(channelID: channel.id))
            return
        }

        let engine: SabellaTVPlaybackActivityEngine = isUsingKSPlayer ? .ksPlayer : .avPlayer
        publish(activityCoordinator.receive(.buffering, from: engine, for: channel.id))
        let delay = Self.recoveryDelays[recoveryAttempt]
        recoveryAttempt += 1
        Self.log.notice("retry=\(self.recoveryAttempt, privacy: .public) channel=\(channel.id, privacy: .public)")
        recoveryTask = Task { @MainActor [weak self] in
            if delay > .zero {
                try? await Task.sleep(for: delay)
            }
            guard let self, !Task.isCancelled, self.channelID == channel.id else { return }
            self.recoveryTask = nil
            self.publish(self.activityCoordinator.beginRecovery(channelID: channel.id))
            self.start(channel)
        }
    }

    private func publish(_ activities: [SabellaTVPlaybackActivity]) {
        for activity in activities {
            publish(activity)
        }
    }

    private func publish(_ activity: SabellaTVPlaybackActivity?) {
        guard let activity else { return }
        switch activity.state {
        case .starting, .buffering:
            isBuffering = true
            isPlaying = false
            hasFailed = false
        case .playing:
            isBuffering = false
            isPlaying = true
            hasFailed = false
        case .paused, .stopped:
            isBuffering = false
            isPlaying = false
            hasFailed = false
        case .failed:
            isBuffering = false
            isPlaying = false
            hasFailed = true
        }
        onPlaybackActivityChanged(activity)
    }

    private func tearDownCurrentEngine() {
        monitorTask?.cancel()
        monitorTask = nil
        classificationTask?.cancel()
        classificationTask = nil
        resolverTask?.cancel()
        resolverTask = nil
        recoveryTask?.cancel()
        recoveryTask = nil
        player.pause()
        player.replaceCurrentItem(with: nil)
        ksCoordinator?.resetPlayer()
        ksCoordinator = nil
        isUsingKSPlayer = false
    }

    private func probe(_ url: URL) async -> (contentType: String?, leadingBytes: Data) {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue(Self.streamUserAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("1", forHTTPHeaderField: "Icy-MetaData")

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            var leadingBytes = Data()
            leadingBytes.reserveCapacity(Self.probeByteCount)
            for try await byte in bytes {
                leadingBytes.append(byte)
                if leadingBytes.count == Self.probeByteCount {
                    break
                }
            }
            return (
                (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type"),
                leadingBytes
            )
        } catch {
            return (nil, Data())
        }
    }

    private static let streamUserAgent = "VLC/3.0.21 LibVLC/3.0.21"
    private static let log = Logger(subsystem: "com.gaulatti.sabella", category: "LivePlayback")
    private static let maximumRecoveryAttempts = 3
    private static let recoveryDelays: [Duration] = [.seconds(2), .seconds(5), .zero]
    private static let probeByteCount = 188 * 3
}

private struct SabellaTVPlaybackRemoteCapture: View {
    @FocusState private var focused: Bool
    let label: String
    let showGuide: () -> Void

    var body: some View {
        Color.clear
        .contentShape(Rectangle())
        .focusable()
        .focused($focused)
        .onAppear { focused = true }
        .onTapGesture(perform: showGuide)
        .onMoveCommand { direction in
            if direction == .up || direction == .down { showGuide() }
        }
        .accessibilityLabel(label)
    }
}

public struct SabellaTVDVROverlay: View {
    private let currentTime: Double
    private let duration: Double
    private let quality: String?
    private let action: SabellaTVDVRAction

    public init(currentTime: Double, duration: Double, quality: String? = nil, action: SabellaTVDVRAction = .none) {
        self.currentTime = currentTime
        self.duration = duration
        self.quality = quality
        self.action = action
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack {
                Spacer()
                HStack(spacing: 24) {
                    Text(isLive ? "LIVE" : formatted(currentTime))
                        .font(BleeckerTypography.mono(22, weight: isLive ? .bold : .regular))
                        .foregroundStyle(isLive ? BleeckerPalette.dark.live : .white)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.22)).frame(height: 8)
                            Capsule().fill(isLive ? BleeckerPalette.dark.live : BleeckerPalette.dark.sea)
                                .frame(width: max(8, proxy.size.width * progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                    if !isLive {
                        Text(formatted(duration)).font(BleeckerTypography.mono(22)).foregroundStyle(.white.opacity(0.7))
                    }
                    if let quality {
                        Text(quality).font(BleeckerTypography.mono(15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.62)).padding(.horizontal, 9).padding(.vertical, 4)
                            .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.28)) }
                    }
                }
                .padding(.horizontal, 72).padding(.vertical, 34)
                .background(.black.opacity(0.68))
            }
            if action != .none {
                Image(systemName: actionImage).font(.system(size: 92, weight: .medium)).foregroundStyle(.white.opacity(0.86))
            }
        }
    }

    private var isLive: Bool { duration <= 0 }
    private var progress: CGFloat { isLive ? 1 : min(1, max(0, currentTime / duration)) }
    private var actionImage: String {
        switch action {
        case .none: "circle"
        case .play: "play.fill"
        case .pause: "pause.fill"
        case .rewind: "backward.end.fill"
        case .fastForward: "forward.end.fill"
        }
    }
    private func formatted(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "00:00" }
        let total = Int(seconds), hours = Int(seconds) / 3600
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, total % 3600 / 60, total % 60) : String(format: "%02d:%02d", total / 60, total % 60)
    }
}

public struct SabellaTVQuadLayout<Cell: View>: View {
    private let expandedIndex: Int?
    private let spacing: CGFloat
    private let cell: (Int) -> Cell

    public init(expandedIndex: Int? = nil, spacing: CGFloat = 6, @ViewBuilder cell: @escaping (Int) -> Cell) {
        self.expandedIndex = expandedIndex
        self.spacing = spacing
        self.cell = cell
    }

    public var body: some View {
        Group {
            if let expandedIndex { cell(expandedIndex) }
            else {
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) { cell(0); cell(1) }
                    HStack(spacing: spacing) { cell(2); cell(3) }
                }
            }
        }
        .background(BleeckerPalette.dark.border)
        .ignoresSafeArea()
    }
}

public struct SabellaTVBroadcastCell<Content: View, Placeholder: View>: View {
    private let selected: Bool
    private let selectionColor: Color
    private let failure: String?
    private let buffering: Bool
    private let content: Content
    private let placeholder: Placeholder

    public init(selected: Bool, selectionColor: Color = BleeckerPalette.dark.sea, failure: String? = nil, buffering: Bool = false, @ViewBuilder content: () -> Content, @ViewBuilder placeholder: () -> Placeholder) {
        self.selected = selected
        self.selectionColor = selectionColor
        self.failure = failure
        self.buffering = buffering
        self.content = content()
        self.placeholder = placeholder()
    }

    public var body: some View {
        ZStack {
            Color.black
            content
            placeholder
            if let failure {
                BleeckerPalette.dark.accentOxblood.opacity(0.88)
                VStack(spacing: 12) {
                    SabellaTVSectionLabel("Signal unavailable")
                    Text(failure).font(BleeckerTypography.primary(27, weight: .semibold)).multilineTextAlignment(.center)
                }.padding(24)
            } else if buffering {
                ProgressView().scaleEffect(1.35).tint(.white)
            }
        }
        .clipped()
        .overlay { if selected { Rectangle().strokeBorder(selectionColor, lineWidth: 6).allowsHitTesting(false) } }
    }
}

public struct SabellaTVTestPattern: View {
    private let title: String
    private let logoURL: URL?
    private let audioLevel: () -> Float

    public init(title: String, logoURL: URL? = nil, audioLevel: @escaping () -> Float = { 0 }) {
        self.title = title
        self.logoURL = logoURL
        self.audioLevel = audioLevel
    }

    public var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                Canvas { context, size in draw(context, size, timeline.date, audioLevel()) }
            }
            VStack(spacing: 12) {
                if let logoURL {
                    AsyncImage(url: logoURL) { image in image.resizable().scaledToFit() } placeholder: { BleeckerBrandMark() }
                } else { BleeckerBrandMark() }
                Text(title).font(BleeckerTypography.secondary(18)).foregroundStyle(.black).multilineTextAlignment(.center)
            }
            .padding(18).frame(width: 220, height: 150)
            .background(.white.opacity(0.92))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func draw(_ context: GraphicsContext, _ size: CGSize, _ date: Date, _ level: Float) {
        let dark = Color(white: 0.09)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.78)))
        var grid = Path()
        for step in 1...5 {
            grid.move(to: CGPoint(x: 0, y: size.height * CGFloat(step) / 6)); grid.addLine(to: CGPoint(x: size.width, y: size.height * CGFloat(step) / 6))
            grid.move(to: CGPoint(x: size.width * CGFloat(step) / 6, y: 0)); grid.addLine(to: CGPoint(x: size.width * CGFloat(step) / 6, y: size.height))
        }
        context.stroke(grid, with: .color(.black.opacity(0.24)))
        context.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.08)), with: .color(dark))
        context.draw(Text(date, format: .dateTime.weekday().month().day()).font(BleeckerTypography.mono(min(size.width, size.height) * 0.038)).foregroundStyle(.white), at: CGPoint(x: size.width * 0.03, y: size.height * 0.04), anchor: .leading)
        context.draw(Text(date, format: .dateTime.hour().minute().second()).font(BleeckerTypography.mono(min(size.width, size.height) * 0.038)).foregroundStyle(.white), at: CGPoint(x: size.width * 0.97, y: size.height * 0.04), anchor: .trailing)
        let colors = [BleeckerPalette.dark.accentYellow, Color.cyan, BleeckerPalette.dark.live, Color.purple, BleeckerPalette.dark.accentRed, BleeckerPalette.dark.sea]
        let width = size.width * 0.095, start = (size.width - width * CGFloat(colors.count)) / 2
        for (index, color) in colors.enumerated() { context.fill(Path(CGRect(x: start + width * CGFloat(index), y: size.height * 0.08, width: width, height: size.height * 0.1)), with: .color(color)) }
        let meter = min(1, max(0, CGFloat(level)))
        context.fill(Path(CGRect(x: 0, y: size.height * (1 - meter), width: size.width * 0.014, height: size.height * meter)), with: .color(meter > 0.9 ? BleeckerPalette.dark.accentRed : meter > 0.7 ? BleeckerPalette.dark.desert : BleeckerPalette.dark.live))
    }
}

public struct SabellaTVEmergencyHeader: View {
    public init() {}
    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                HStack {
                    Text(context.date, format: .dateTime.month(.wide).day().year()).font(BleeckerTypography.primary(24, weight: .bold))
                    Spacer()
                    Text(context.date, format: .dateTime.hour().minute().second()).font(BleeckerTypography.mono(27, weight: .bold))
                }.padding(.horizontal, 48)
                BleeckerBrandMark().frame(width: 42, height: 42).foregroundStyle(.white)
            }.foregroundStyle(.white).padding(.vertical, 8)
        }
    }
}

public struct SabellaTVCarouselDots<ID: Hashable>: View {
    private let items: [ID]
    private let active: Set<ID>
    public init(items: [ID], active: Set<ID>) { self.items = items; self.active = active }
    public var body: some View {
        HStack(spacing: 10) { ForEach(items, id: \.self) { item in Circle().fill(.white.opacity(active.contains(item) ? 1 : 0.38)).frame(width: active.contains(item) ? 8 : 6, height: active.contains(item) ? 8 : 6) } }
    }
}

public struct SabellaTVEmergencyLayout<Channels: View, Ticker: View>: View {
    private let allOffline: Bool
    private let channels: Channels
    private let ticker: Ticker
    public init(allOffline: Bool, @ViewBuilder channels: () -> Channels, @ViewBuilder ticker: () -> Ticker) { self.allOffline = allOffline; self.channels = channels(); self.ticker = ticker() }
    public var body: some View {
        GeometryReader { proxy in
            let channelHeight = min(proxy.size.width / 2 * 9 / 16, proxy.size.height - 144)
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color.hex(0xB81122), Color.hex(0x660512), Color.hex(0x1F0006)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                SabellaTVEmergencyHeader().frame(height: 64).offset(y: max(0, ((proxy.size.height - channelHeight) / 2 - 64) / 2))
                channels.frame(width: proxy.size.width, height: channelHeight).position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                if allOffline {
                    VStack(spacing: 12) { Text("ALL ASSIGNED FEEDS OFFLINE").font(BleeckerTypography.primary(30, weight: .bold)); Text("Automatic recovery checks are running").font(BleeckerTypography.secondary(20, weight: .medium)) }
                        .foregroundStyle(.white).padding(.horizontal, 32).padding(.vertical, 24).background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 12)).position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                ticker.frame(width: proxy.size.width, height: 48).clipped().position(x: proxy.size.width / 2, y: proxy.size.height - 24)
            }
        }.ignoresSafeArea()
    }
}

public struct SabellaTVMarquee: UIViewRepresentable {
    private let items: [String]
    public init(items: [String]) { self.items = items }
    public func makeUIView(context: Context) -> MarqueeView { let view = MarqueeView(); view.setItems(items); return view }
    public func updateUIView(_ view: MarqueeView, context: Context) { view.setItems(items) }
    public static func dismantleUIView(_ view: MarqueeView, coordinator: ()) { view.stop() }

    @MainActor public final class MarqueeView: UIView {
        private let label = UILabel()
        private var items: [String] = []
        private var width: CGFloat = 0
        public override init(frame: CGRect) { super.init(frame: frame); clipsToBounds = true; addSubview(label) }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        public override func layoutSubviews() { super.layoutSubviews(); label.frame = CGRect(x: 0, y: (bounds.height - label.intrinsicContentSize.height) / 2, width: max(width * 2, 1), height: label.intrinsicContentSize.height); if width > 0, label.layer.animationKeys()?.isEmpty != false { animate() } }
        func setItems(_ newItems: [String]) {
            guard !newItems.isEmpty, newItems != items else { return }
            items = newItems; stop()
            let text = newItems.joined(separator: "     ◆     ") + "     ◆     "
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "EncodeSans-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20), .foregroundColor: UIColor.white]
            let cycle = NSAttributedString(string: text, attributes: attributes)
            let doubled = NSMutableAttributedString(attributedString: cycle); doubled.append(cycle); label.attributedText = doubled
            width = ceil(cycle.size().width); setNeedsLayout()
        }
        func stop() { label.layer.removeAllAnimations(); label.transform = .identity }
        private func animate() {
            label.transform = .identity
            UIView.animate(withDuration: max(1, width / 60), delay: 0, options: [.curveLinear, .repeat, .allowUserInteraction]) { self.label.transform = CGAffineTransform(translationX: -self.width, y: 0) }
        }
    }
}
#endif
