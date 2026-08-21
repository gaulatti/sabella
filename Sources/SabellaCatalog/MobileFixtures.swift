import Sabella
import SwiftUI

// Catalog-only fixtures for the Thompson mobile contracts. G-176 owns the
// reusable Sabella application-shell API; these stay out of the library target.
/// A value-backed destination displayed by ``CatalogAppTabBar``.
struct CatalogAppTab<Value: Hashable>: Identifiable {
    let value: Value
    let label: String
    let systemImage: String
    let badge: Int?

    var id: Value { value }

    init(_ value: Value, label: String, systemImage: String, badge: Int? = nil) {
        self.value = value
        self.label = label
        self.systemImage = systemImage
        self.badge = badge
    }
}

/// Thompson's bottom-tab navigation, expressed with native SwiftUI buttons.
struct CatalogAppTabBar<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme
    @Binding private var selection: Value
    private let tabs: [CatalogAppTab<Value>]

    init(selection: Binding<Value>, tabs: [CatalogAppTab<Value>]) {
        _selection = selection
        self.tabs = tabs
    }

    var body: some View {
        let palette = BleeckerPalette.resolve(scheme)
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                Button {
                    selection = tab.value
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: tab.value == selection ? .semibold : .regular))
                            .overlay(alignment: .topTrailing) {
                                if let badge = tab.badge, badge > 0 {
                                    Text(badge > 99 ? "99+" : String(badge))
                                        .font(BleeckerTypography.primary(8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .frame(minWidth: 15, minHeight: 15)
                                        .background(palette.sunset, in: Capsule())
                                        .offset(x: 10, y: -7)
                                }
                            }
                        Text(tab.label)
                            .font(BleeckerTypography.primary(10, weight: tab.value == selection ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(tab.value == selection ? palette.sea : palette.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
                .accessibilityAddTraits(tab.value == selection ? .isSelected : [])
            }
        }
        .padding(.top, 5)
        .background(palette.card)
        .overlay(alignment: .top) { BleeckerSeparator() }
    }
}

/// A safe-area-aware application shell with optional mobile bottom tabs.
struct CatalogMobileAppShell<Value: Hashable, Header: View, Content: View, Footer: View>: View {
    @Binding private var selection: Value
    private let tabs: [CatalogAppTab<Value>]
    @ViewBuilder private let header: Header
    @ViewBuilder private let content: Content
    @ViewBuilder private let footer: Footer

    init(
        selection: Binding<Value>,
        tabs: [CatalogAppTab<Value>] = [],
        @ViewBuilder header: () -> Header,
        @ViewBuilder footer: () -> Footer,
        @ViewBuilder content: () -> Content
    ) {
        _selection = selection
        self.tabs = tabs
        self.header = header()
        self.footer = footer()
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabs.isEmpty {
                CatalogAppTabBar(selection: $selection, tabs: tabs)
            }
        }
    }
}

extension CatalogMobileAppShell where Footer == EmptyView {
    init(
        selection: Binding<Value>,
        tabs: [CatalogAppTab<Value>] = [],
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(selection: selection, tabs: tabs, header: header, footer: { EmptyView() }, content: content)
    }
}

/// An adaptive administration shell: persistent navigation when wide, a drawer when compact.
struct CatalogAdminShell<Sidebar: View, Header: View, Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Binding private var navigationPresented: Bool
    private let breakpoint: CGFloat
    private let sidebarWidth: CGFloat
    @ViewBuilder private let sidebar: Sidebar
    @ViewBuilder private let header: Header
    @ViewBuilder private let content: Content

    init(
        navigationPresented: Binding<Bool>,
        breakpoint: CGFloat = 768,
        sidebarWidth: CGFloat = 300,
        @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        _navigationPresented = navigationPresented
        self.breakpoint = breakpoint
        self.sidebarWidth = sidebarWidth
        self.sidebar = sidebar()
        self.header = header()
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width >= breakpoint {
                wideLayout
            } else {
                compactLayout
            }
        }
    }

    private var wideLayout: some View {
        let palette = BleeckerPalette.resolve(scheme)
        return HStack(spacing: 0) {
            sidebar
                .frame(width: sidebarWidth)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(palette.card)
            BleeckerSeparator(vertical: true)
            VStack(spacing: 0) {
                header
                BleeckerSeparator()
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(palette.background)
        .foregroundStyle(palette.textPrimary)
    }

    private var compactLayout: some View {
        let palette = BleeckerPalette.resolve(scheme)
        return ZStack(alignment: .leading) {
            VStack(spacing: 0) {
                header
                    .overlay(alignment: .leading) {
                        BleeckerIconButton("line.3.horizontal", accessibilityLabel: "Open navigation", variant: .ghost) {
                            withAnimation(.easeOut(duration: BleeckerDuration.control)) { navigationPresented = true }
                        }
                        .padding(.leading, 8)
                    }
                BleeckerSeparator()
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if navigationPresented {
                palette.deepSea.opacity(0.46)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { closeNavigation() }
                    .accessibilityLabel("Close navigation")

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        BleeckerIconButton("xmark", accessibilityLabel: "Close navigation", variant: .ghost) {
                            closeNavigation()
                        }
                    }
                    .frame(minHeight: 56)
                    .padding(.horizontal, 10)
                    sidebar.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .frame(width: min(sidebarWidth, 360))
                .background(palette.card)
                .transition(.move(edge: .leading))
                .shadow(color: palette.deepSea.opacity(0.24), radius: 24, x: 8)
            }
        }
        .background(palette.background)
        .foregroundStyle(palette.textPrimary)
    }

    private func closeNavigation() {
        withAnimation(.easeOut(duration: BleeckerDuration.control)) { navigationPresented = false }
    }
}
