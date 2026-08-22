import Sabella
import SwiftUI
#if !os(tvOS)
import UniformTypeIdentifiers
#endif

struct NavigationGallery: View {
    @State private var tab = "overview"
    @State private var page = 2

    private let tabs = [
        BleeckerSelectOption(value: "overview", label: "Overview"),
        BleeckerSelectOption(value: "activity", label: "Activity"),
        BleeckerSelectOption(value: "settings", label: "Settings")
    ]

    var body: some View {
        CatalogSection("Brand and hierarchy") {
            VStack(alignment: .leading, spacing: 20) {
                BleeckerBrandLockup(name: "Sabella")
                BleeckerBreadcrumb([
                    BleeckerBreadcrumbItem("Library", systemImage: "books.vertical"),
                    BleeckerBreadcrumbItem("Components"),
                    BleeckerBreadcrumbItem("Navigation")
                ])
                BleeckerPageHeader(eyebrow: "Workspace", title: "Navigation", description: "A page header with a primary action.") {
                    BleeckerButton(size: .sm) { } label: { Text("New item") }
                }
                BleeckerSectionHeader("Recent projects", subtitle: "Updated this week") { Button("View all") { } }
            }
        }
        CatalogSection("Sidebar and tabs") {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(spacing: 4) {
                        BleeckerSidebarItem("Overview", systemImage: "square.grid.2x2", selected: true) { }
                        BleeckerSidebarItem("Analytics", systemImage: "chart.bar", selected: false) { }
                    }.frame(width: 240)
                    Spacer()
                }
                BleeckerTabs(selection: $tab, options: tabs)
                BleeckerPagination(page: page, pageCount: 7) { page = $0 }
            }
        }
        CatalogSection("Disclosure") {
            BleeckerAccordion("What is Sabella?", expanded: true) {
                Text("A native SwiftUI component library sharing contracts with Bleecker.")
            }
        }
    }
}

struct DataDisplayGallery: View {
    private let rows = [SampleItem(title: "Palermo", detail: "Updated 2m ago"), SampleItem(title: "Napoli", detail: "Updated 1h ago"), SampleItem(title: "Roma", detail: "Updated yesterday")]

    var body: some View {
        CatalogSection("Avatars and icon badges") {
            FlowLayout(spacing: 14) {
                ForEach(BleeckerAvatarSize.allCases, id: \.self) { BleeckerAvatar(name: "Ada Lovelace", size: $0) }
                ForEach(BleeckerIconBadgeVariant.allCases, id: \.self) { BleeckerIconBadge("sparkles", variant: $0) }
            }
        }
        CatalogSection("Metrics") {
            BleeckerDashboardGrid(minimumColumnWidth: 190) {
                BleeckerStatCard("Revenue", value: 48250, format: .currency, systemImage: "dollarsign", delta: 0.12)
                BleeckerStatCard("Conversion", value: 0.184, format: .percent, systemImage: "percent", delta: -0.02)
                BleeckerStatCard("Visitors", value: 128400, format: .compact, systemImage: "person.2", delta: 0.08)
            }
        }
        CatalogSection("Data list") {
            BleeckerDataList(rows) { row in
                HStack { BleeckerAvatar(name: row.title, size: .sm); VStack(alignment: .leading) { Text(row.title).font(.headline); Text(row.detail).font(.caption).foregroundStyle(.secondary) }; Spacer(); BleeckerStatusBadge("Live", variant: .live) }
            }
        }
        CatalogSection("Timeline and filters") {
            VStack(alignment: .leading, spacing: 14) {
                BleeckerTimelineItem("Catalog created", date: "Today") { Text("The initial showcase was generated.") }
                BleeckerTimelineItem("Components indexed", date: "Today", last: true) { Text("Public views were organized by family.") }
                FlowLayout(spacing: 8) {
                    BleeckerFilterChip("SwiftUI", selected: true, remove: { }) { }
                    BleeckerFilterChip("macOS") { }
                    Text("Open search"); BleeckerKbd("⌘"); BleeckerKbd("K")
                }
            }
        }
    }
}

struct ChartsGallery: View {
    private let series: [BleeckerChartPoint] = [
        .init(series: "Visits", label: "Mon", x: 1, y: 12), .init(series: "Visits", label: "Tue", x: 2, y: 19),
        .init(series: "Visits", label: "Wed", x: 3, y: 15), .init(series: "Visits", label: "Thu", x: 4, y: 28),
        .init(series: "Visits", label: "Fri", x: 5, y: 24), .init(series: "Visits", label: "Sat", x: 6, y: 35)
    ]
    private let segments: [BleeckerChartPoint] = [
        .init(series: "Direct", label: "Direct", x: 1, y: 42), .init(series: "Search", label: "Search", x: 2, y: 31),
        .init(series: "Social", label: "Social", x: 3, y: 19), .init(series: "Other", label: "Other", x: 4, y: 8)
    ]

    var body: some View {
        CatalogSection("Line and area") {
            HStack(spacing: 18) {
                chartCard("Line") { BleeckerLineChart(series) }
                chartCard("Area") { BleeckerLineChart(series, area: true) }
            }
        }
        CatalogSection("Bar, pie, and scatter") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 230))], spacing: 18) {
                chartCard("Bar") { BleeckerBarChart(series) }
                chartCard("Donut") { BleeckerPieChart(segments, innerRadius: 0.58) }
                chartCard("Scatter") { BleeckerScatterChart(series) }
            }
        }
        CatalogSection("Sparkline") {
            HStack { BleeckerMetric("Active users", value: 2840, format: .compact); Spacer(); BleeckerSparkline([10, 18, 14, 26, 23, 31, 39]).frame(width: 220, height: 62) }
        }
    }

    private func chartCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) { CatalogLabel(title); content().frame(minHeight: 180) }.frame(maxWidth: .infinity)
    }
}

struct OverlaysGallery: View {
    @State private var showModal = false
    @State private var query = ""
    private let commands = [SampleItem(title: "Create project", detail: "⌘N"), SampleItem(title: "Open settings", detail: "⌘,"), SampleItem(title: "Toggle appearance", detail: "⌘⇧D")]

    var body: some View {
        CatalogSection("Tooltip, menu, and modal") {
            FlowLayout(spacing: 16) {
                BleeckerTooltip("Helpful context appears on hover") { BleeckerIconButton("questionmark.circle", accessibilityLabel: "Help") { } }
                BleeckerDropdownMenu(items: [
                    BleeckerMenuItem("Duplicate", systemImage: "plus.square.on.square") { },
                    BleeckerMenuItem("Archive", systemImage: "archivebox") { },
                    BleeckerMenuItem("Delete", systemImage: "trash", destructive: true) { }
                ]) { Label("Actions", systemImage: "ellipsis.circle") }
                BleeckerButton { showModal = true } label: { Text("Open modal") }
            }
            .sheet(isPresented: $showModal) {
                BleeckerModal("Example modal") {
                    VStack(alignment: .leading, spacing: 16) { Text("Modal content uses Sabella's native presentation and surface treatment."); BleeckerButton { showModal = false } label: { Text("Done") } }
                }
            }
        }
        CatalogSection("Command spotlight", note: "The query and result rows are interactive.") {
            BleeckerCommandSpotlight(query: $query, items: filteredCommands) { command in
                HStack { Image(systemName: "command"); Text(command.title); Spacer(); BleeckerKbd(command.detail) }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var filteredCommands: [SampleItem] {
        query.isEmpty ? commands : commands.filter { $0.title.localizedCaseInsensitiveContains(query) }
    }
}

struct LayoutsGallery: View {
    var body: some View {
        CatalogSection("Dashboard composition") {
            BleeckerDashboardSection("Performance", subtitle: "Last 30 days") {
                BleeckerButton(variant: .secondary, size: .sm) { } label: { Text("Export") }
            } content: {
                BleeckerDashboardGrid(minimumColumnWidth: 160) {
                    ForEach(0..<3) { index in BleeckerStatCard("Metric \(index + 1)", value: Double((index + 1) * 1200), format: .compact) }
                }
            }
        }
        CatalogSection("Application shell") {
            BleeckerAppShell(sidebarWidth: 170) {
                VStack { BleeckerBrandLockup(name: "Sabella"); BleeckerSidebarItem("Home", systemImage: "house", selected: true) { }; Spacer() }
            } header: {
                BleeckerHeader { Text("Workspace") } center: { Text("Overview").font(.headline) } trailing: { BleeckerAvatar(name: "Ada") }
            } content: {
                Text("Application content").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 330)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        CatalogSection("Panel layout, header, and footer") {
            VStack(spacing: 18) {
                BleeckerPanelLayout(leadingWidth: 130, trailingWidth: 150) { Text("Leading") } content: { Text("Main content").frame(maxWidth: .infinity) } trailing: { Text("Inspector") }.frame(height: 110)
                BleeckerHeader { BleeckerIconButton("line.3.horizontal", accessibilityLabel: "Menu") { } } center: { BleeckerBrandLockup(name: "Sabella") } trailing: { BleeckerIconButton("person.circle", accessibilityLabel: "Profile") { } }
                BleeckerFooter { Text("Sabella component catalog · Native SwiftUI") }
            }
        }
    }
}

struct ExtendedGallery: View {
    @State private var slider = 0.42
    @State private var code = "123"
    @State private var start = Date()
    @State private var end = Date().addingTimeInterval(86_400 * 7)
    @State private var query = ""
    private let items = [SampleItem(title: "Sea", detail: "Blue"), SampleItem(title: "Desert", detail: "Orange"), SampleItem(title: "Sand", detail: "Neutral")]
    private let progressSegments: [BleeckerProgressSegment] = [
        BleeckerProgressSegment(value: 0.34, color: .blue),
        BleeckerProgressSegment(value: 0.27, color: .orange),
        BleeckerProgressSegment(value: 0.18, color: .red)
    ]

    var body: some View {
        CatalogSection("Activity, feed, and error") {
            VStack(alignment: .leading, spacing: 10) {
                BleeckerActivityItem("Catalog published", detail: "All component families are available.", timestamp: "Just now", systemImage: "checkmark") { BleeckerStatusBadge("New", variant: .info) }
                BleeckerFeedItem(author: "Ada Lovelace", timestamp: "5 min") { Text("Added the native component gallery.") }
                BleeckerErrorState(message: "The preview could not be loaded.") { BleeckerButton(variant: .secondary) { } label: { Text("Try again") } }
            }
        }
        CatalogSection("Progress and specialized inputs") {
            VStack(alignment: .leading, spacing: 18) {
                BleeckerProgressStack(progressSegments)
                BleeckerSlider(value: $slider)
                BleeckerOTPInput(code: $code)
#if !os(tvOS)
                BleeckerDateRangePicker(start: $start, end: $end)
                BleeckerFileInput(allowedContentTypes: [.image, .pdf]) { _ in }
#else
                Text("Date range and file input are unavailable on tvOS.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
#endif
            }
        }
        CatalogSection("Collections and media") {
            VStack(alignment: .leading, spacing: 18) {
                BleeckerCollectionFilters(query: $query) { BleeckerFilterChip("Available", selected: true) { } }
                BleeckerMediaLibrary(items, minimumTileWidth: 140) { item in mediaTile(item) }
                BleeckerHeroCarousel(items) { item in mediaTile(item).frame(width: 360) }.frame(height: 150)
            }
        }
    }

    private func mediaTile(_ item: SampleItem) -> some View {
        BleeckerCard(padding: .sm, variant: .subtle) { VStack(alignment: .leading) { RoundedRectangle(cornerRadius: 8).fill(BleeckerPalette.light.sea.opacity(0.18)).frame(height: 72); Text(item.title).font(.headline); Text(item.detail).font(.caption).foregroundStyle(.secondary) } }
    }
}

struct MobileGallery: View {
    @State private var tab = "home"
    @State private var drawer = false

    private var tabs: [BleeckerAppTab<String>] {
        [BleeckerAppTab("home", label: "Home", systemImage: "house"), BleeckerAppTab("inbox", label: "Inbox", systemImage: "tray", badge: 4), BleeckerAppTab("profile", label: "Profile", systemImage: "person")]
    }

    var body: some View {
#if os(tvOS)
        CatalogSection("Remote tab navigation", note: "Every destination is reachable with focus and select.") {
            BleeckerAppTabBar(selection: $tab, tabs: tabs)
                .frame(maxWidth: 900)
        }
        CatalogSection("Television application shell") {
            BleeckerAdminShell(navigationPresented: $drawer, breakpoint: 700, sidebarWidth: 260) {
                VStack(spacing: 18) {
                    BleeckerBrandLockup(name: "Sabella TV")
                    BleeckerSidebarItem("Overview", systemImage: "square.grid.2x2", selected: true) { }
                    BleeckerSidebarItem("Playback", systemImage: "play.rectangle", selected: false) { }
                    Spacer()
                }
                .padding(24)
            } header: {
                BleeckerHeader { Text("Remote ready") } center: { Text("Living room").font(.headline) } trailing: { BleeckerStatusBadge("Focused", variant: .live) }
                    .padding(.horizontal, 24)
            } content: {
                BleeckerDashboardGrid(minimumColumnWidth: 260) {
                    BleeckerStatCard("Channels", value: 12, format: .number)
                    BleeckerEmptyState(title: "Selection ready", message: "Use the remote to choose a destination.") { EmptyView() }
                }
                .padding(32)
            }
            .frame(height: 540)
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
#else
        CatalogSection("Bottom tab bar") { BleeckerAppTabBar(selection: $tab, tabs: tabs).frame(maxWidth: 430) }
        CatalogSection("Mobile application shell") {
            deviceFrame {
                BleeckerMobileAppShell(selection: $tab, tabs: tabs) {
                    BleeckerHeader { Text("9:41").font(.caption) } center: { Text("Sabella").font(.headline) } trailing: { BleeckerAvatar(name: "Ada", size: .xs) }.padding(.horizontal, 14)
                } content: {
                    VStack(spacing: 18) { BleeckerStatCard("Sessions", value: 18400, format: .compact, delta: 0.14); BleeckerEmptyState(title: "You're all caught up", message: "New activity will appear here.") { EmptyView() }; Spacer() }.padding(16)
                }
            }
        }
        CatalogSection("Adaptive admin shell") {
            BleeckerAdminShell(navigationPresented: $drawer, breakpoint: 540, sidebarWidth: 180) {
                VStack { BleeckerBrandLockup(name: "Admin"); BleeckerSidebarItem("Overview", systemImage: "square.grid.2x2", selected: true) { }; Spacer() }.padding(16)
            } header: {
                BleeckerHeader { EmptyView() } center: { Text("Dashboard").font(.headline) } trailing: { BleeckerAvatar(name: "Ada", size: .sm) }.padding(.horizontal, 14)
            } content: {
                BleeckerDashboardGrid(minimumColumnWidth: 150) { BleeckerStatCard("Users", value: 1200, format: .compact); BleeckerStatCard("Revenue", value: 8400, format: .currency) }.padding(16)
            }
            .frame(height: 330)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
#endif
    }

    private func deviceFrame<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content().frame(width: 390, height: 650).background(Color.primary.opacity(0.025)).clipShape(RoundedRectangle(cornerRadius: 32)).overlay { RoundedRectangle(cornerRadius: 32).strokeBorder(Color.primary.opacity(0.16), lineWidth: 6) }.frame(maxWidth: .infinity)
    }
}
