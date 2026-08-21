import Testing
@testable import Sabella

@Test func tokensMatchBleeckerSource() {
    #expect(BleeckerSpacing.detail == 4)
    #expect(BleeckerSpacing.page == 64)
    #expect(BleeckerRadius.button == 7)
    #expect(BleeckerRadius.card == 12)
    #expect(BleeckerDuration.control == 0.19)
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
