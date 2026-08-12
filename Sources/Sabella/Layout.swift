import SwiftUI

public struct BleeckerDashboardGrid<Content: View>: View {
    let minimumColumnWidth: CGFloat; let spacing: CGFloat; @ViewBuilder let content: Content
    public init(minimumColumnWidth: CGFloat = 260, spacing: CGFloat = BleeckerSpacing.component, @ViewBuilder content: () -> Content) { self.minimumColumnWidth = minimumColumnWidth; self.spacing = spacing; self.content = content() }
    public var body: some View { LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumColumnWidth), spacing: spacing)], spacing: spacing) { content } }
}

public struct BleeckerDashboardSection<Actions: View, Content: View>: View {
    let title: String; let subtitle: String?; @ViewBuilder let actions: Actions; @ViewBuilder let content: Content
    public init(_ title: String, subtitle: String? = nil, @ViewBuilder actions: () -> Actions, @ViewBuilder content: () -> Content) { self.title = title; self.subtitle = subtitle; self.actions = actions(); self.content = content() }
    public var body: some View { VStack(alignment: .leading, spacing: BleeckerSpacing.component) { BleeckerSectionHeader(title, subtitle: subtitle) { actions }; content } }
}

public struct BleeckerAppShell<Sidebar: View, Header: View, Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let sidebarWidth: CGFloat; @ViewBuilder let sidebar: Sidebar; @ViewBuilder let header: Header; @ViewBuilder let content: Content
    public init(sidebarWidth: CGFloat = 240, @ViewBuilder sidebar: () -> Sidebar, @ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) { self.sidebarWidth = sidebarWidth; self.sidebar = sidebar(); self.header = header(); self.content = content() }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); HStack(spacing: 0) { sidebar.frame(width: sidebarWidth).padding(16).background(p.card); BleeckerSeparator(vertical: true); VStack(spacing: 0) { header.padding(.horizontal, 24).frame(minHeight: 64); BleeckerSeparator(); content.frame(maxWidth: .infinity, maxHeight: .infinity).padding(24) } }.background(p.background).foregroundStyle(p.textPrimary) }
}

public struct BleeckerPanelLayout<Leading: View, Content: View, Trailing: View>: View {
    let leadingWidth: CGFloat; let trailingWidth: CGFloat; @ViewBuilder let leading: Leading; @ViewBuilder let content: Content; @ViewBuilder let trailing: Trailing
    public init(leadingWidth: CGFloat = 240, trailingWidth: CGFloat = 300, @ViewBuilder leading: () -> Leading, @ViewBuilder content: () -> Content, @ViewBuilder trailing: () -> Trailing) { self.leadingWidth = leadingWidth; self.trailingWidth = trailingWidth; self.leading = leading(); self.content = content(); self.trailing = trailing() }
    public var body: some View { HStack(spacing: 0) { leading.frame(width: leadingWidth); BleeckerSeparator(vertical: true); content.frame(maxWidth: .infinity); BleeckerSeparator(vertical: true); trailing.frame(width: trailingWidth) } }
}

public struct BleeckerHeader<Leading: View, Center: View, Trailing: View>: View {
    @ViewBuilder let leading: Leading; @ViewBuilder let center: Center; @ViewBuilder let trailing: Trailing
    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder center: () -> Center, @ViewBuilder trailing: () -> Trailing) { self.leading = leading(); self.center = center(); self.trailing = trailing() }
    public var body: some View { HStack { leading; Spacer(); center; Spacer(); trailing }.frame(minHeight: 56) }
}

public struct BleeckerFooter<Content: View>: View {
    @Environment(\.colorScheme) private var scheme; @ViewBuilder let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); VStack(spacing: 0) { BleeckerSeparator(); content.padding(.vertical, 20) }.font(BleeckerTypography.secondary(12)).foregroundStyle(p.textSecondary) }
}
