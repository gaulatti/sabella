import Testing
import SwiftUI
import Foundation
import SabellaCatalogSupport
@testable import Sabella

@Test func tokensMatchBleeckerSource() {
    #expect(BleeckerSpacing.detail == 4)
    #expect(BleeckerSpacing.page == 64)
    #expect(BleeckerRadius.button == 7)
    #expect(BleeckerRadius.card == 12)
    #expect(BleeckerDuration.control == 0.19)
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
