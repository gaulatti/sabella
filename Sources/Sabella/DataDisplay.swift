import SwiftUI

public struct BleeckerAvatar: View {
    @Environment(\.colorScheme) private var scheme
    let name: String; let image: Image?; let size: BleeckerAvatarSize
    public init(name: String, image: Image? = nil, size: BleeckerAvatarSize = .md) { self.name = name; self.image = image; self.size = size }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        Group { if let image { image.resizable().scaledToFill() } else { Text(initials).font(BleeckerTypography.primary(edge * 0.32, weight: .semibold)).foregroundStyle(p.sea) } }
            .frame(width: edge, height: edge).background(p.muted).clipShape(Circle()).overlay { Circle().strokeBorder(p.border) }.accessibilityLabel(name)
    }
    private var initials: String { name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased() }
    private var edge: CGFloat { switch size { case .xs: 24; case .sm: 32; case .md: 40; case .lg: 52; case .xl: 72 } }
}

public struct BleeckerIconBadge: View {
    @Environment(\.colorScheme) private var scheme
    let systemImage: String; let size: BleeckerIconBadgeSize; let variant: BleeckerIconBadgeVariant
    public init(_ systemImage: String, size: BleeckerIconBadgeSize = .md, variant: BleeckerIconBadgeVariant = .primary) { self.systemImage = systemImage; self.size = size; self.variant = variant }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme); let edge: CGFloat = size == .md ? 36 : 48
        Image(systemName: systemImage).font(.system(size: edge * 0.4, weight: .medium)).foregroundStyle(variant == .primary ? p.primaryForeground : p.sea).frame(width: edge, height: edge).background(variant == .primary ? p.primary : p.muted).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui)).overlay { if variant == .outlined { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(p.sea.opacity(0.4)) } }
    }
}

public struct BleeckerMetric: View {
    @Environment(\.colorScheme) private var scheme
    let label: String; let value: Double; let format: BleeckerMetricFormat; let currencyCode: String
    public init(_ label: String, value: Double, format: BleeckerMetricFormat = .number, currencyCode: String = "USD") { self.label = label; self.value = value; self.format = format; self.currencyCode = currencyCode }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); VStack(alignment: .leading, spacing: 4) { Text(label.uppercased()).font(BleeckerTypography.primary(10, weight: .bold)).tracking(1).foregroundStyle(p.textSecondary); Text(formatted).font(BleeckerTypography.primary(24, weight: .semibold)).foregroundStyle(p.textPrimary).contentTransition(.numericText()) } }
    private var formatted: String { switch format { case .number: value.formatted(.number); case .currency: value.formatted(.currency(code: currencyCode)); case .percent: value.formatted(.percent); case .compact: value.formatted(.number.notation(.compactName)) } }
}

public struct BleeckerStatCard: View {
    let label: String; let value: Double; let format: BleeckerMetricFormat; let systemImage: String; let delta: Double?
    public init(_ label: String, value: Double, format: BleeckerMetricFormat = .number, systemImage: String = "chart.line.uptrend.xyaxis", delta: Double? = nil) { self.label = label; self.value = value; self.format = format; self.systemImage = systemImage; self.delta = delta }
    public var body: some View { BleeckerCard { HStack(alignment: .top) { BleeckerMetric(label, value: value, format: format); Spacer(); VStack(alignment: .trailing, spacing: 8) { BleeckerIconBadge(systemImage, variant: .subtle); if let delta { Text(delta, format: .percent.sign(strategy: .always())).font(BleeckerTypography.primary(11, weight: .semibold)).foregroundStyle(delta >= 0 ? BleeckerPalette.light.live : BleeckerPalette.light.destructive) } } } } }
}

public struct BleeckerDataList<Row: Identifiable, RowContent: View>: View {
    let rows: [Row]; let rowContent: (Row) -> RowContent
    public init(_ rows: [Row], @ViewBuilder rowContent: @escaping (Row) -> RowContent) { self.rows = rows; self.rowContent = rowContent }
    public var body: some View { LazyVStack(spacing: 0) { ForEach(rows) { row in rowContent(row).padding(.vertical, 10); if row.id != rows.last?.id { BleeckerSeparator() } } } }
}

public struct BleeckerTimelineItem<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let title: String; let date: String; let last: Bool; @ViewBuilder let content: Content
    public init(_ title: String, date: String, last: Bool = false, @ViewBuilder content: () -> Content) { self.title = title; self.date = date; self.last = last; self.content = content() }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); HStack(alignment: .top, spacing: 12) { VStack(spacing: 0) { Circle().fill(p.sea).frame(width: 9, height: 9); if !last { Rectangle().fill(p.border).frame(width: 1).frame(maxHeight: .infinity) } }; VStack(alignment: .leading, spacing: 4) { HStack { Text(title).font(BleeckerTypography.primary(14, weight: .semibold)); Spacer(); Text(date).font(BleeckerTypography.secondary(11)).foregroundStyle(p.textSecondary) }; content.font(BleeckerTypography.secondary(13)).foregroundStyle(p.textSecondary) }.padding(.bottom, last ? 0 : 18) } }
}

public struct BleeckerFilterChip: View {
    @Environment(\.colorScheme) private var scheme
    let label: String; let selected: Bool; let remove: (() -> Void)?; let action: () -> Void
    public init(_ label: String, selected: Bool = false, remove: (() -> Void)? = nil, action: @escaping () -> Void) { self.label = label; self.selected = selected; self.remove = remove; self.action = action }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); HStack(spacing: 6) { Button(label, action: action).buttonStyle(.plain); if let remove { Button(action: remove) { Image(systemName: "xmark").font(.caption2) }.buttonStyle(.plain) } }.font(BleeckerTypography.primary(12, weight: .medium)).foregroundStyle(selected ? p.primaryForeground : p.textPrimary).padding(.horizontal, 10).frame(minHeight: 28).background(selected ? p.primary : p.muted).clipShape(Capsule()).overlay { Capsule().strokeBorder(selected ? .clear : p.border) } }
}

public struct BleeckerKbd: View {
    @Environment(\.colorScheme) private var scheme
    let key: String
    public init(_ key: String) { self.key = key }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); Text(key).font(BleeckerTypography.mono(10, weight: .medium)).padding(.horizontal, 6).frame(minHeight: 22).background(p.muted).clipShape(RoundedRectangle(cornerRadius: 4)).overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(p.border) } }
}
