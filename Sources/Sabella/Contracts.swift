import Foundation

public enum BleeckerThemeMode: String, CaseIterable, Sendable { case light, dark, system }
public enum BleeckerButtonVariant: String, CaseIterable, Sendable { case primary, secondary, outline, subtle, ghost, link, destructive }
public enum BleeckerButtonSize: String, CaseIterable, Sendable { case xs, sm, md, lg }
public enum BleeckerControlSize: String, CaseIterable, Sendable { case sm, md, lg }
public enum BleeckerStatusBadgeVariant: String, CaseIterable, Sendable { case live, offline, warning, info, `default` }
public enum BleeckerCardPadding: String, CaseIterable, Sendable { case none, sm, md, lg }
public enum BleeckerCardVariant: String, CaseIterable, Sendable { case surface, outlined, elevated, subtle, transparent }
public enum BleeckerProgressSize: String, CaseIterable, Sendable { case sm, md, lg }
public enum BleeckerProgressVariant: String, CaseIterable, Sendable { case `default`, success, warning, destructive }
public enum BleeckerIconButtonSize: String, CaseIterable, Sendable { case sm, md, lg }
public enum BleeckerIconButtonVariant: String, CaseIterable, Sendable { case `default`, subtle, ghost }
public enum BleeckerToggleSize: String, CaseIterable, Sendable { case sm, md, lg }
public enum BleeckerToggleVariant: String, CaseIterable, Sendable { case `default`, outline }
public enum BleeckerAlertType: String, CaseIterable, Sendable { case success, error, info, warning }
public enum BleeckerMetricFormat: String, CaseIterable, Sendable { case number, currency, percent, compact }
public enum BleeckerAvatarSize: String, CaseIterable, Sendable { case xs, sm, md, lg, xl }
public enum BleeckerLoadingSize: String, CaseIterable, Sendable { case sm, md, lg }
public enum BleeckerIconBadgeSize: String, CaseIterable, Sendable { case md, lg }
public enum BleeckerIconBadgeVariant: String, CaseIterable, Sendable { case primary, subtle, outlined }
public enum BleeckerSelectionOrientation: String, CaseIterable, Sendable { case vertical, horizontal }
