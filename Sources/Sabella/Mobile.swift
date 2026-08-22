import SwiftUI
#if os(iOS)
import UIKit
#endif

/// The platform family used when resolving an adaptive shell presentation.
public enum BleeckerShellPlatform: String, CaseIterable, Sendable {
    case iOS
    case iPadOS
    case macOS
    case tvOS
}

/// The native navigation treatment selected for an application shell.
public enum BleeckerShellPresentation: String, CaseIterable, Sendable {
    case bottomBar
    case drawer
    case sidebar
    case toolbar
    case television
}

/// Pure layout policy shared by runtime shells, previews, and tests.
public enum BleeckerShellLayout {
    public static func adminPresentation(
        width: CGFloat,
        platform: BleeckerShellPlatform,
        breakpoint: CGFloat = 768
    ) -> BleeckerShellPresentation {
        switch platform {
        case .macOS: .sidebar
        case .tvOS: .television
        case .iOS, .iPadOS: width >= breakpoint ? .sidebar : .drawer
        }
    }

    public static func tabPresentation(platform: BleeckerShellPlatform) -> BleeckerShellPresentation {
        switch platform {
        case .iOS, .iPadOS: .bottomBar
        case .macOS: .toolbar
        case .tvOS: .television
        }
    }
}

private var currentShellPlatform: BleeckerShellPlatform {
#if os(macOS)
    .macOS
#elseif os(tvOS)
    .tvOS
#elseif os(iOS)
    UIDevice.current.userInterfaceIdiom == .pad ? .iPadOS : .iOS
#else
    .iOS
#endif
}

/// A value-backed destination displayed by ``BleeckerAppTabBar``.
public struct BleeckerAppTab<Value: Hashable>: Identifiable {
    public let value: Value
    public let label: String
    public let systemImage: String
    public let badge: Int?
    public let accessibilityLabel: String
    public let disabled: Bool

    public var id: Value { value }

    public init(
        _ value: Value,
        label: String,
        systemImage: String,
        badge: Int? = nil,
        accessibilityLabel: String? = nil,
        disabled: Bool = false
    ) {
        self.value = value
        self.label = label
        self.systemImage = systemImage
        self.badge = badge
        self.accessibilityLabel = accessibilityLabel ?? label
        self.disabled = disabled
    }
}

/// Thompson's bottom-tab navigation, expressed with native SwiftUI buttons.
public struct BleeckerAppTabBar<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme
    @Binding private var selection: Value
    private let tabs: [BleeckerAppTab<Value>]
#if os(tvOS)
    @FocusState private var focusedTab: Value?
#endif

    public init(selection: Binding<Value>, tabs: [BleeckerAppTab<Value>]) {
        _selection = selection
        self.tabs = tabs
    }

    public var body: some View {
#if os(tvOS)
        televisionBody
#else
        compactBody
#endif
    }

    private var compactBody: some View {
        let palette = BleeckerPalette.resolve(scheme)
        return HStack(spacing: 0) {
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
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(tab.value == selection ? palette.sea : palette.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(tab.disabled)
                .accessibilityLabel(tab.accessibilityLabel)
                .accessibilityValue(tab.badge.map { "\($0) notifications" } ?? "")
                .accessibilityAddTraits(tab.value == selection ? .isSelected : [])
            }
        }
        .padding(.top, 5)
        .background(palette.card)
        .overlay(alignment: .top) { BleeckerSeparator() }
    }

#if os(tvOS)
    private var televisionBody: some View {
        let palette = BleeckerPalette.resolve(scheme)
        return HStack(spacing: BleeckerSpacing.group) {
            ForEach(tabs) { tab in
                Button {
                    selection = tab.value
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .font(.title2.weight(tab.value == selection ? .bold : .medium))
                        Text(tab.label).font(BleeckerTypography.primary(18, weight: .semibold))
                        if let badge = tab.badge, badge > 0 {
                            Text(badge > 99 ? "99+" : String(badge))
                                .font(BleeckerTypography.primary(13, weight: .bold))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 3)
                                .background(palette.sunset, in: Capsule())
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 112)
                    .foregroundStyle(tab.value == selection ? palette.sea : palette.textPrimary)
                    .background(focusedTab == tab.value ? palette.card : .clear, in: RoundedRectangle(cornerRadius: BleeckerRadius.card))
                    .overlay {
                        RoundedRectangle(cornerRadius: BleeckerRadius.card)
                            .strokeBorder(tab.value == selection ? palette.sea : .clear, lineWidth: 3)
                    }
                }
                .buttonStyle(.plain)
                .focused($focusedTab, equals: tab.value)
                .disabled(tab.disabled)
                .accessibilityLabel(tab.accessibilityLabel)
                .accessibilityValue(tab.badge.map { "\($0) notifications" } ?? "")
                .accessibilityAddTraits(tab.value == selection ? .isSelected : [])
            }
        }
        .padding(.horizontal, 64)
        .padding(.vertical, 20)
        .background(palette.card.opacity(0.96))
    }
#endif
}

/// A safe-area-aware application shell with optional mobile bottom tabs.
public struct BleeckerMobileAppShell<Value: Hashable, Header: View, Content: View, Footer: View>: View {
    @Binding private var selection: Value
    private let tabs: [BleeckerAppTab<Value>]
    @ViewBuilder private let header: Header
    @ViewBuilder private let content: Content
    @ViewBuilder private let footer: Footer

    public init(
        selection: Binding<Value>,
        tabs: [BleeckerAppTab<Value>] = [],
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

    public var body: some View {
#if os(macOS)
        desktopBody
#elseif os(tvOS)
        televisionBody
#else
        touchBody
#endif
    }

    private var touchBody: some View {
        VStack(spacing: 0) {
            header
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabs.isEmpty {
                BleeckerAppTabBar(selection: $selection, tabs: tabs)
            }
        }
    }

#if os(macOS)
    private var desktopBody: some View {
        VStack(spacing: 0) {
            header
            BleeckerSeparator()
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .toolbar {
            if !tabs.isEmpty {
                ToolbarItem(placement: .principal) {
                    Picker("Section", selection: $selection) {
                        ForEach(tabs) { tab in
                            Label(tab.label, systemImage: tab.systemImage).tag(tab.value)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel("Application section")
                }
            }
        }
    }
#endif

#if os(tvOS)
    private var televisionBody: some View {
        VStack(spacing: 0) {
            header
            BleeckerSeparator()
            content.frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !tabs.isEmpty {
                BleeckerAppTabBar(selection: $selection, tabs: tabs)
            }
        }
    }
#endif
}

public extension BleeckerMobileAppShell where Footer == EmptyView {
    init(
        selection: Binding<Value>,
        tabs: [BleeckerAppTab<Value>] = [],
        @ViewBuilder header: () -> Header,
        @ViewBuilder content: () -> Content
    ) {
        self.init(selection: selection, tabs: tabs, header: header, footer: { EmptyView() }, content: content)
    }
}

/// An adaptive administration shell: persistent navigation when wide, a drawer when compact.
public struct BleeckerAdminShell<Sidebar: View, Header: View, Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding private var navigationPresented: Bool
    private let breakpoint: CGFloat
    private let sidebarWidth: CGFloat
    @ViewBuilder private let sidebar: Sidebar
    @ViewBuilder private let header: Header
    @ViewBuilder private let content: Content

    public init(
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

    public var body: some View {
#if os(macOS)
        desktopLayout
#elseif os(tvOS)
        televisionLayout
#else
        touchLayout
#endif
    }

    private var touchLayout: some View {
        GeometryReader { proxy in
            if BleeckerShellLayout.adminPresentation(
                width: proxy.size.width,
                platform: currentShellPlatform,
                breakpoint: breakpoint
            ) == .sidebar {
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
                HStack(spacing: 0) {
                    BleeckerIconButton("line.3.horizontal", accessibilityLabel: "Open navigation", variant: .ghost) {
                        navigationPresented = true
                    }
                    .padding(.leading, 8)
                    header.frame(maxWidth: .infinity)
                }
                BleeckerSeparator()
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .accessibilityHidden(navigationPresented)

            if navigationPresented {
                Button(action: closeNavigation) {
                    palette.deepSea.opacity(0.46)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
                .safeAreaPadding(.vertical)
                .background(palette.card)
                .transition(.move(edge: .leading))
                .shadow(color: palette.deepSea.opacity(0.24), radius: 24, x: 8)
                .accessibilityAddTraits(.isModal)
            }
        }
        .background(palette.background)
        .foregroundStyle(palette.textPrimary)
        .animation(reduceMotion ? nil : .easeOut(duration: BleeckerDuration.control), value: navigationPresented)
    }

    private func closeNavigation() {
        navigationPresented = false
    }

#if os(macOS)
    private var desktopLayout: some View {
        let palette = BleeckerPalette.resolve(scheme)
        return NavigationSplitView(columnVisibility: Binding(
            get: { navigationPresented ? .all : .detailOnly },
            set: { navigationPresented = $0 != .detailOnly }
        )) {
            sidebar
                .padding(BleeckerSpacing.component)
                .frame(maxHeight: .infinity, alignment: .top)
                .background(palette.card)
                .navigationSplitViewColumnWidth(
                    min: min(220, sidebarWidth),
                    ideal: sidebarWidth,
                    max: max(sidebarWidth, 420)
                )
        } detail: {
            VStack(spacing: 0) {
                header
                BleeckerSeparator()
                content.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(palette.background)
        }
        .foregroundStyle(palette.textPrimary)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    navigationPresented.toggle()
                } label: {
                    Label(
                        navigationPresented ? "Hide navigation" : "Show navigation",
                        systemImage: "sidebar.left"
                    )
                }
                .keyboardShortcut("s", modifiers: [.command, .control])
            }
        }
    }
#endif

#if os(tvOS)
    private var televisionLayout: some View {
        let palette = BleeckerPalette.resolve(scheme)
        return HStack(spacing: 0) {
            sidebar
                .padding(.horizontal, 48)
                .padding(.vertical, 32)
                .frame(width: max(sidebarWidth, 420))
                .frame(maxHeight: .infinity, alignment: .topLeading)
                .background(palette.card)
            BleeckerSeparator(vertical: true)
            VStack(spacing: 0) {
                header
                BleeckerSeparator()
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .safeAreaPadding(.horizontal, 48)
                    .safeAreaPadding(.vertical, 32)
            }
            .background(palette.background)
        }
        .background(palette.background)
        .foregroundStyle(palette.textPrimary)
    }
#endif
}
