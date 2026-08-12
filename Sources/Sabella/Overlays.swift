import SwiftUI

public struct BleeckerModal<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    let title: String; let width: CGFloat; @ViewBuilder let content: Content
    public init(_ title: String, width: CGFloat = 480, @ViewBuilder content: () -> Content) { self.title = title; self.width = width; self.content = content() }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); VStack(spacing: 0) { HStack { Text(title).font(BleeckerTypography.primary(18, weight: .semibold)); Spacer(); BleeckerIconButton("xmark", accessibilityLabel: "Close", variant: .ghost) { dismiss() } }.padding(20); BleeckerSeparator(); content.padding(20) }.frame(width: width).background(p.card).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.dialog)).shadow(color: p.deepSea.opacity(0.24), radius: 32, y: 12) }
}

public struct BleeckerTooltip<Content: View>: View {
    let text: String; @ViewBuilder let content: Content
    public init(_ text: String, @ViewBuilder content: () -> Content) { self.text = text; self.content = content() }
    public var body: some View { content.help(text).accessibilityHint(text) }
}

public struct BleeckerMenuItem: Identifiable {
    public let id = UUID(); public let title: String; public let systemImage: String?; public let destructive: Bool; public let action: () -> Void
    public init(_ title: String, systemImage: String? = nil, destructive: Bool = false, action: @escaping () -> Void) { self.title = title; self.systemImage = systemImage; self.destructive = destructive; self.action = action }
}

public struct BleeckerDropdownMenu<Label: View>: View {
    let items: [BleeckerMenuItem]; @ViewBuilder let label: Label
    public init(items: [BleeckerMenuItem], @ViewBuilder label: () -> Label) { self.items = items; self.label = label() }
    public var body: some View { Menu { ForEach(items) { item in Button(role: item.destructive ? .destructive : nil, action: item.action) { SwiftUI.Label(item.title, systemImage: item.systemImage ?? "circle") } } } label: { label }.menuStyle(.borderlessButton) }
}

public struct BleeckerCommandSpotlight<Item: Identifiable, Row: View>: View {
    @Binding var query: String; let items: [Item]; let row: (Item) -> Row
    public init(query: Binding<String>, items: [Item], @ViewBuilder row: @escaping (Item) -> Row) { _query = query; self.items = items; self.row = row }
    public var body: some View { VStack(spacing: 0) { BleeckerSearchField(placeholder: "Search commands", text: $query).padding(12); BleeckerSeparator(); ScrollView { LazyVStack(alignment: .leading, spacing: 2) { ForEach(items) { item in row(item).padding(.horizontal, 12).frame(minHeight: 38) } }.padding(.vertical, 6) } }.frame(width: 520, height: 380).bleeckerSurface(radius: BleeckerRadius.dialog) }
}
