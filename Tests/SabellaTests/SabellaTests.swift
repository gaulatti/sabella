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
