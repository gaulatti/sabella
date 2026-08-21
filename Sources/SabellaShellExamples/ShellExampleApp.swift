import Sabella
import SwiftUI

private enum ExampleMode: String, CaseIterable, Identifiable {
    case tabs = "Application tabs"
    case admin = "Adaptive admin"
    var id: Self { self }
}

private enum ExampleDestination: String, CaseIterable, Identifiable {
    case home = "Home"
    case devices = "Devices"
    case channels = "Channels"
    case library = "Library"

    var id: Self { self }
    var icon: String {
        switch self {
        case .home: "house"
        case .devices: "tv"
        case .channels: "play.rectangle"
        case .library: "books.vertical"
        }
    }
}

@main
struct SabellaShellExamplesApp: App {
    var body: some Scene {
        WindowGroup("Sabella Shell Examples") {
            ShellExampleRoot()
#if os(macOS)
                .frame(minWidth: 720, minHeight: 560)
#endif
        }
#if os(macOS)
        .defaultSize(width: 1120, height: 760)
#endif
    }
}

private struct ShellExampleRoot: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var mode: ExampleMode
    @State private var selection = ExampleDestination.home
    @State private var navigationPresented: Bool

    init() {
        let arguments = ProcessInfo.processInfo.arguments
#if os(macOS)
        let defaultMode = ExampleMode.admin
        let navigationVisible = true
#elseif os(tvOS)
        let defaultMode = ExampleMode.tabs
        let navigationVisible = true
#else
        let defaultMode = ExampleMode.tabs
        let navigationVisible = false
#endif
        _mode = State(initialValue: arguments.contains("--admin") ? .admin : defaultMode)
        _navigationPresented = State(initialValue: arguments.contains("--admin") ? true : navigationVisible)
    }

    var body: some View {
        Group {
            switch mode {
            case .tabs: tabShell
            case .admin: adminShell
            }
        }
    }

    private var tabShell: some View {
        BleeckerMobileAppShell(selection: $selection, tabs: tabs) {
            exampleHeader
        } content: {
            destinationContent
        }
    }

    private var adminShell: some View {
        BleeckerAdminShell(navigationPresented: $navigationPresented, breakpoint: 760, sidebarWidth: 280) {
            ScrollView {
                VStack(spacing: BleeckerSpacing.detail) {
                    ForEach(ExampleDestination.allCases) { destination in
                        BleeckerSidebarItem(
                            destination.rawValue,
                            systemImage: destination.icon,
                            selected: selection == destination
                        ) {
                            selection = destination
                            navigationPresented = false
                        }
                    }
                }
            }
        } header: {
            exampleHeader
        } content: {
            destinationContent
        }
    }

    private var exampleHeader: some View {
        BleeckerHeader {
            BleeckerBrandLockup(name: "Sabella")
        } center: {
            if !usesCompactHeaderControls {
                Text(selection.rawValue)
                    .font(BleeckerTypography.primary(17, weight: .semibold))
            }
        } trailing: {
            if usesCompactHeaderControls {
                Menu {
                    Picker("Shell example", selection: $mode) {
                        ForEach(ExampleMode.allCases) { Text($0.rawValue).tag($0) }
                    }
                } label: {
                    Label("Shell example", systemImage: "rectangle.2.swap")
                }
            } else {
                Picker("Shell example", selection: $mode) {
                    ForEach(ExampleMode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 300)
            }
        }
        .padding(.horizontal, BleeckerSpacing.component)
    }

    private var usesCompactHeaderControls: Bool {
#if os(tvOS)
        true
#else
        horizontalSizeClass == .compact
#endif
    }

    private var destinationContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BleeckerSpacing.group) {
                BleeckerPageHeader(
                    eyebrow: "Adaptive application shell",
                    title: selection.rawValue,
                    description: "Resize, rotate, use keyboard or pointer input, or move focus with the Siri Remote."
                ) {
                    BleeckerStatusBadge("Native", variant: .live)
                }

                BleeckerDashboardGrid(minimumColumnWidth: 220) {
                    metricCard("Selected route", value: selection.rawValue, icon: selection.icon)
                    metricCard("Navigation", value: mode.rawValue, icon: "sidebar.left")
                    metricCard("Appearance", value: "System", icon: "circle.lefthalf.filled")
                }

                BleeckerCard(variant: .outlined) {
                    VStack(alignment: .leading, spacing: BleeckerSpacing.component) {
                        BleeckerSectionHeader("Platform behavior", subtitle: "The application owns routing; Sabella owns the native frame.") { EmptyView() }
                        Text("Compact touch layouts use safe-area bottom tabs or a dismissible drawer. Wide iPad and macOS layouts keep navigation persistent. Apple TV uses large, focus-visible remote targets.")
                            .font(BleeckerTypography.secondary(14))
                    }
                }
            }
            .padding(BleeckerSpacing.group)
        }
    }

    private func metricCard(_ title: String, value: String, icon: String) -> some View {
        BleeckerCard {
            VStack(alignment: .leading, spacing: BleeckerSpacing.control) {
                Label(title, systemImage: icon)
                    .font(BleeckerTypography.primary(13, weight: .semibold))
                Text(value).font(BleeckerTypography.primary(20, weight: .semibold))
            }
        }
    }

    private var tabs: [BleeckerAppTab<ExampleDestination>] {
        ExampleDestination.allCases.map { destination in
            BleeckerAppTab(
                destination,
                label: destination.rawValue,
                systemImage: destination.icon,
                badge: destination == .channels ? 4 : nil
            )
        }
    }
}
