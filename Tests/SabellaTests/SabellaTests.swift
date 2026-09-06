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
