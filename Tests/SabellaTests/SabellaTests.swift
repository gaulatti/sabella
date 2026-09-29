import Testing
import SwiftUI
import Foundation
import SabellaCatalogSupport
@testable import Sabella
#if os(macOS)
import AppKit
#endif

#if os(macOS)
@Test @MainActor func remainingControlsGrowWithHostTextScale() {
    func fittedHeight<Content: View>(_ content: Content, scale: CGFloat) -> CGFloat {
        let host = NSHostingView(rootView: content.environment(\.bleeckerTextScale, scale))
        return host.fittingSize.height
    }

    let secure = BleeckerSecureField("Password", text: .constant("sample"))
    let radio = BleeckerRadioGroup(selection: .constant("all"), options: [
        BleeckerSelectOption(value: "all", label: "All"),
        BleeckerSelectOption(value: "relevant", label: "Relevant")
    ])
    let stepper = BleeckerStepper("Minimum", value: .constant(2), in: 0...10)
    let select = BleeckerSelect(selection: .constant("all"), options: [
        BleeckerSelectOption(value: "all", label: "All"),
        BleeckerSelectOption(value: "relevant", label: "Relevant")
    ])

    for control in [
        ("Secure field", fittedHeight(secure, scale: 1), fittedHeight(secure, scale: 1.3)),
        ("Radio group", fittedHeight(radio, scale: 1), fittedHeight(radio, scale: 1.3)),
        ("Stepper", fittedHeight(stepper, scale: 1), fittedHeight(stepper, scale: 1.3)),
        ("Select", fittedHeight(select, scale: 1), fittedHeight(select, scale: 1.3))
    ] {
        #expect(control.2 > control.1, "\(control.0) did not grow at the host's large text scale")
    }
}
#endif

@Test func tokensMatchBleeckerSource() {
    #expect(BleeckerSpacing.detail == 4)
    #expect(BleeckerSpacing.page == 64)
    #expect(BleeckerRadius.button == 7)
    #expect(BleeckerRadius.card == 12)
    #expect(BleeckerDuration.control == 0.19)
}

@Test @MainActor func categoryLabelsOnCardsMeetSmallTextContrastAcrossHues() {
    func luminance(_ rgb: (red: Double, green: Double, blue: Double)) -> Double {
        let channels = [rgb.red, rgb.green, rgb.blue].map { value in
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]
    }

    for scheme in [ColorScheme.light, .dark] {
        let card: (red: Double, green: Double, blue: Double) = scheme == .dark
            ? (24 / 255, 37 / 255, 51 / 255) : (1, 1, 1)
        let cardLuminance = luminance(card)
        var worst = (ratio: Double.infinity, hue: 0, intensity: 0)
        for hue in 0..<360 {
            for intensity in 0...10 {
                let rgb = BleeckerAttentionSurface<EmptyView>.labelAccentComponents(
                    hue: Double(hue), intensity: Double(intensity), scheme: scheme)
                let labelLuminance = luminance(rgb)
                let ratio = (max(cardLuminance, labelLuminance) + 0.05) /
                            (min(cardLuminance, labelLuminance) + 0.05)
                if ratio < worst.ratio { worst = (ratio, hue, intensity) }
            }
        }
        #expect(worst.ratio >= 4.5,
                "\(scheme) hue \(worst.hue) intensity \(worst.intensity): \(worst.ratio):1")
    }
}

@Test func bundledBrandFontsRegisterWithoutSubstitution() {
    SabellaFonts.register()

    for postScriptName in SabellaFonts.postScriptNames {
        #expect(SabellaFonts.isRegistered(postScriptName: postScriptName))
    }
}

@Test func publicContractsRemainComplete() {
    #expect(BleeckerButtonVariant.allCases.count == 7)
    #expect(BleeckerCardVariant.allCases.count == 5)
    #expect(BleeckerAlertType.allCases.count == 4)
    #expect(BleeckerAvatarSize.allCases.count == 5)
}

@Test func selectOptionUsesValueIdentity() {
    let option = BleeckerSelectOption(value: 42, label: "Answer")
    #expect(option.id == 42)
    #expect(!option.disabled)
}

@Test func applicationTabsPreserveDestinationIdentityAndAccessibility() {
    let tab = BleeckerAppTab(
        "inbox",
        label: "Inbox",
        systemImage: "tray",
        badge: 3,
        accessibilityLabel: "Editorial inbox"
    )
    #expect(tab.id == "inbox")
    #expect(tab.badge == 3)
    #expect(tab.accessibilityLabel == "Editorial inbox")
    #expect(!tab.disabled)
}

@Test func shellLayoutAdaptsByAvailableWidthAndPlatform() {
    #expect(BleeckerShellLayout.adminPresentation(width: 390, platform: .iOS) == .drawer)
    #expect(BleeckerShellLayout.adminPresentation(width: 600, platform: .iPadOS) == .drawer)
    #expect(BleeckerShellLayout.adminPresentation(width: 1024, platform: .iPadOS) == .sidebar)
    #expect(BleeckerShellLayout.adminPresentation(width: 500, platform: .macOS) == .sidebar)
    #expect(BleeckerShellLayout.adminPresentation(width: 1920, platform: .tvOS) == .television)
}

@Test func tabNavigationUsesPlatformNativePlacement() {
    #expect(BleeckerShellLayout.tabPresentation(platform: .iOS) == .bottomBar)
    #expect(BleeckerShellLayout.tabPresentation(platform: .iPadOS) == .bottomBar)
    #expect(BleeckerShellLayout.tabPresentation(platform: .macOS) == .toolbar)
    #expect(BleeckerShellLayout.tabPresentation(platform: .tvOS) == .television)
}

@Test func catalogCoversEveryPublicVisualComponent() throws {
    let testFile = URL(fileURLWithPath: #filePath)
    let sourceDirectory = testFile
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/Sabella")
    let expression = try NSRegularExpression(
        pattern: #"public struct (Bleecker[A-Za-z0-9]+)(?:<[^\n]+>)?: (?:View|ButtonStyle|ToggleStyle)"#
    )
    let files = try FileManager.default.contentsOfDirectory(
        at: sourceDirectory,
        includingPropertiesForKeys: nil
    ).filter { $0.pathExtension == "swift" }
    var publicComponents = Set<String>()

    for file in files {
        let source = try String(contentsOf: file, encoding: .utf8)
        let range = NSRange(source.startIndex..., in: source)
        for match in expression.matches(in: source, range: range) {
            guard let nameRange = Range(match.range(at: 1), in: source) else { continue }
            publicComponents.insert(String(source[nameRange]))
        }
    }

    #expect(
        SabellaCatalogCoverage.missingComponents(publicComponents: publicComponents).isEmpty
    )
}

@Test func catalogCoverageGateDetectsAnOmittedFixture() {
    let missing = SabellaCatalogCoverage.missingComponents(
        publicComponents: ["BleeckerButton", "BleeckerDeliberatelyOmitted"],
        registeredComponents: ["BleeckerButton"]
    )
    #expect(missing == ["BleeckerDeliberatelyOmitted"])
}

@Test func televisionCatalogCoversEveryPublicTVVisual() throws {
    let sourceFile = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .appendingPathComponent("Sources/Sabella/Television.swift")
    let source = try String(contentsOf: sourceFile, encoding: .utf8)
    let expression = try NSRegularExpression(
        pattern: #"public struct (SabellaTV[A-Za-z0-9]+)(?:<[^\n]+>)?: (?:View|ButtonStyle)"#
    )
    let range = NSRange(source.startIndex..., in: source)
    let components = Set(expression.matches(in: source, range: range).compactMap { match in
        Range(match.range(at: 1), in: source).map { String(source[$0]) }
    })

    #expect(SabellaCatalogCoverage.missingTelevisionComponents(publicComponents: components).isEmpty)
}

@Test func televisionPlaybackEngineRoutesTransportStreamsThroughFFmpeg() throws {
    let transportStream = try #require(URL(string: "https://example.com/live/channel.ts?token=abc"))
    let parameterizedMIME = try #require(URL(string: "https://example.com/live/channel"))

    #expect(SabellaTVPlaybackEnginePolicy.engine(for: transportStream) == .ffmpeg)
    #expect(
        SabellaTVPlaybackEnginePolicy.engine(
            for: parameterizedMIME,
            contentType: "Video/MP2T; charset=binary"
        ) == .ffmpeg
    )
}

@Test func televisionPlaybackEngineKeepsHLSOnNativePlayback() throws {
    let hls = try #require(URL(string: "https://example.com/live/master.m3u8"))
    let unknown = try #require(URL(string: "https://example.com/live/channel"))

    #expect(SabellaTVPlaybackEnginePolicy.engine(for: hls) == .native)
    #expect(SabellaTVPlaybackEnginePolicy.engine(for: unknown) == nil)
}

@Test func televisionPlaybackEngineRecognizesOpaqueTransportStreamBytes() throws {
    let opaqueURL = try #require(URL(string: "https://example.com/live/157993"))
    var packets = Data(repeating: 0, count: 188 * 3)
    packets[0] = 0x47
    packets[188] = 0x47
    packets[376] = 0x47

    #expect(
        SabellaTVPlaybackEnginePolicy.engine(
            for: opaqueURL,
            contentType: nil,
            leadingBytes: packets
        ) == .ffmpeg
    )
}

@Test func televisionPlaybackEnginesShareSemanticActivityOrdering() {
    let avPlayer = playbackActivitySequence(for: .avPlayer)
    let ksPlayer = playbackActivitySequence(for: .ksPlayer)
    let expected = [
        activity("news", .starting),
        activity("news", .buffering),
        activity("news", .playing),
        activity("news", .buffering),
        activity("news", .playing),
    ]

    #expect(avPlayer == expected)
    #expect(ksPlayer == expected)
}

@Test func televisionPlaybackActivityCoalescesRepeatedEngineState() {
    var coordinator = SabellaTVPlaybackActivityCoordinator()
    acceptsSendable(activity("news", .starting))
    #expect(coordinator.tune(to: "news") == [activity("news", .starting)])
    #expect(coordinator.selectEngine(.avPlayer, for: "news") == activity("news", .buffering))
    #expect(coordinator.receive(.buffering, from: .avPlayer, for: "news") == nil)
    #expect(coordinator.receive(.advancing, from: .avPlayer, for: "news") == activity("news", .playing))
    #expect(coordinator.receive(.advancing, from: .avPlayer, for: "news") == nil)
}

@Test func televisionPlaybackActivityCoversPauseSceneRecoveryAndFailure() {
    var coordinator = SabellaTVPlaybackActivityCoordinator()
    var sequence = coordinator.tune(to: "news")
    append(coordinator.selectEngine(.ksPlayer, for: "news"), to: &sequence)
    append(coordinator.receive(.advancing, from: .ksPlayer, for: "news"), to: &sequence)

    // Remote pause/resume and scene suspension/resume use these same semantic
    // transitions; neither resume reports playing before the engine advances.
    append(coordinator.receive(.paused, from: .ksPlayer, for: "news"), to: &sequence)
    append(coordinator.resume(channelID: "news"), to: &sequence)
    append(coordinator.receive(.advancing, from: .ksPlayer, for: "news"), to: &sequence)
    append(coordinator.receive(.paused, from: .ksPlayer, for: "news"), to: &sequence)
    append(coordinator.resume(channelID: "news"), to: &sequence)
    append(coordinator.receive(.advancing, from: .ksPlayer, for: "news"), to: &sequence)

    // A recoverable engine error ends playing time, starts a fresh attempt,
    // and waits for a new engine before playing can be emitted again.
    append(coordinator.receive(.buffering, from: .ksPlayer, for: "news"), to: &sequence)
    append(coordinator.beginRecovery(channelID: "news"), to: &sequence)
    #expect(coordinator.receive(.advancing, from: .ksPlayer, for: "news") == nil)
    append(coordinator.selectEngine(.ksPlayer, for: "news"), to: &sequence)
    append(coordinator.receive(.advancing, from: .ksPlayer, for: "news"), to: &sequence)
    append(coordinator.fail(channelID: "news"), to: &sequence)

    #expect(sequence.map(\.state) == [
        .starting, .buffering, .playing,
        .paused, .starting, .playing,
        .paused, .starting, .playing,
        .buffering, .starting, .buffering, .playing, .failed,
    ])
}

@Test func televisionPlaybackActivityStopsOldChannelBeforeStartingNewOne() {
    var coordinator = SabellaTVPlaybackActivityCoordinator()
    _ = coordinator.tune(to: "a")
    _ = coordinator.selectEngine(.avPlayer, for: "a")
    _ = coordinator.receive(.advancing, from: .avPlayer, for: "a")

    #expect(coordinator.tune(to: "b") == [
        activity("a", .stopped),
        activity("b", .starting),
    ])
    #expect(coordinator.receive(.advancing, from: .avPlayer, for: "a") == nil)
    #expect(coordinator.stop() == activity("b", .stopped))
    #expect(coordinator.stop() == nil)
}

#if os(tvOS)
@Test func televisionGroupReturnKeepsSavedPointerUntilInitialFocusRestores() {
    var restoration = SabellaTVGroupFocusRestoration()
    let savedGroupID = "group-on-third-row"

    // tvOS may focus the first visible tile while the saved row is scrolling in.
    #expect(restoration.accepted("first-group") == nil)
    #expect(restoration.accepted(savedGroupID) == nil)
    restoration.finish()
    #expect(restoration.accepted(savedGroupID) == savedGroupID)
    #expect(restoration.accepted("next-group") == "next-group")
}

@Test func televisionGuideClimbsFromFirstChannelAndLoadsOnlyAtFocusedTopEdge() {
    let channels = (1...3).map { number in
        SabellaTVChannel(
            id: "channel-\(number)",
            streamURL: URL(string: "https://example.com/\(number).m3u8")!,
            number: String(number),
            name: "Channel \(number)",
            now: "Live",
            progress: 1
        )
    }

    #expect(SabellaTVChannelGuideOrder.rowsTopToBottom(channels).map(\.id) == [
        "channel-3", "channel-2", "channel-1"
    ])
    #expect(SabellaTVChannelGuideOrder.edgeMove(
        direction: .down, focusedID: "channel-1", channels: channels, hasMore: true
    ) == .lastChannel)
    #expect(SabellaTVChannelGuideOrder.edgeMove(
        direction: .up, focusedID: "channel-3", channels: channels, hasMore: false
    ) == .firstChannel)
    #expect(SabellaTVChannelGuideOrder.edgeMove(
        direction: .up, focusedID: "channel-3", channels: channels, hasMore: true
    ) == .none)
    #expect(!SabellaTVChannelGuideOrder.shouldLoadNextPage(
        highlightedID: "channel-1", channels: channels, hasMore: true, loading: false
    ))
    #expect(SabellaTVChannelGuideOrder.shouldLoadNextPage(
        highlightedID: "channel-3", channels: channels, hasMore: true, loading: false
    ))
    #expect(!SabellaTVChannelGuideOrder.shouldLoadNextPage(
        highlightedID: "channel-3", channels: channels, hasMore: true, loading: true
    ))
    #expect(!SabellaTVChannelGuideOrder.shouldLoadNextPage(
        highlightedID: "channel-3", channels: channels, hasMore: false, loading: false
    ))
}

@Test func televisionChannelPageCommandsFollowGroupOrderAndPageBoundary() {
    #expect(SabellaTVChannelPageNavigation.lastPosition(loadedCount: 3) == 4)
    #expect(SabellaTVChannelPageNavigation.request(position: 2, loadedCount: 3, hasMore: false) == .channel(1))
    #expect(SabellaTVChannelPageNavigation.request(position: 0, loadedCount: 3, hasMore: false) == .lastChannel)
    #expect(SabellaTVChannelPageNavigation.request(position: 4, loadedCount: 3, hasMore: false) == .channel(0))
    #expect(SabellaTVChannelPageNavigation.request(position: -1, loadedCount: 3, hasMore: false) == nil)
    #expect(SabellaTVChannelPageNavigation.request(position: 5, loadedCount: 3, hasMore: false) == nil)
    #expect(SabellaTVChannelPageNavigation.request(position: 101, loadedCount: 100, hasMore: true) == .nextPage(100))
    #expect(SabellaTVChannelPageNavigation.request(position: 101, loadedCount: 101, hasMore: false) == .channel(100))
}

@Test func televisionChannelWrapLoadsEveryPageAndStopsOnFailure() {
    var load = SabellaTVChannelLoadToEnd()
    #expect(load.begin(loadedCount: 100, hasMore: true, loading: false) == .loadMore)
    #expect(load.isActive)
    #expect(load.observe(loadedCount: 200, hasMore: true) == .loadMore)
    #expect(load.observe(loadedCount: 219, hasMore: false) == .finished)
    #expect(!load.isActive)

    #expect(load.begin(loadedCount: 100, hasMore: true, loading: true) == .none)
    #expect(load.observe(loadedCount: 100, hasMore: true) == .failed)
    #expect(!load.isActive)
    #expect(load.begin(loadedCount: 1, hasMore: false, loading: false) == .finished)
}

@Test @MainActor func televisionChannelChangeNoticeReplacesAndExpires() async throws {
    let channels = (1...2).map { number in
        SabellaTVChannel(
            id: "channel-\(number)",
            streamURL: URL(string: "https://example.com/\(number).m3u8")!,
            number: String(format: "%03d", number),
            name: "Channel \(number)",
            now: "Live",
            progress: 1
        )
    }
    let notice = SabellaTVChannelChangeNoticeModel(displayDuration: .milliseconds(30))

    notice.show(channels[0])
    #expect(notice.channel?.id == channels[0].id)
    notice.show(channels[1])
    #expect(notice.channel?.id == channels[1].id)
    try await Task.sleep(for: .milliseconds(120))
    #expect(notice.channel == nil)

    notice.show(channels[0])
    notice.clear()
    #expect(notice.channel == nil)
}

@Test @MainActor func televisionLivePlayerInitializerRemainsSourceCompatible() throws {
    let channel = SabellaTVChannel(
        id: "news",
        streamURL: try #require(URL(string: "https://example.com/live.m3u8")),
        number: "1",
        name: "News",
        now: "Live",
        progress: 1
    )

    _ = SabellaTVLivePlayer(
        channels: [channel],
        selection: .constant(channel.id),
        guideVisible: .constant(true),
        onExit: {}
    )
}
#endif

private func playbackActivitySequence(
    for engine: SabellaTVPlaybackActivityEngine
) -> [SabellaTVPlaybackActivity] {
    var coordinator = SabellaTVPlaybackActivityCoordinator()
    var sequence = coordinator.tune(to: "news")
    append(coordinator.selectEngine(engine, for: "news"), to: &sequence)
    append(coordinator.receive(.advancing, from: engine, for: "news"), to: &sequence)
    append(coordinator.receive(.buffering, from: engine, for: "news"), to: &sequence)
    append(coordinator.receive(.advancing, from: engine, for: "news"), to: &sequence)
    return sequence
}

private func activity(
    _ channelID: String,
    _ state: SabellaTVPlaybackActivity.State
) -> SabellaTVPlaybackActivity {
    SabellaTVPlaybackActivity(channelID: channelID, state: state)
}

private func append(
    _ activity: SabellaTVPlaybackActivity?,
    to sequence: inout [SabellaTVPlaybackActivity]
) {
    if let activity {
        sequence.append(activity)
    }
}

private func acceptsSendable<T: Sendable>(_ value: T) {}
