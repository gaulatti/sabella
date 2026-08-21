import Sabella
import SabellaCatalogSupport
import SwiftUI

@main
struct SabellaCatalogApp: App {
    var body: some Scene {
#if os(macOS)
        WindowGroup("Sabella Catalog") {
            CatalogRootView()
                .frame(minWidth: 920, minHeight: 680)
        }
        .defaultSize(width: 1180, height: 820)
#else
        WindowGroup("Sabella Catalog") {
            CatalogPlatformRootView()
        }
#endif
    }
}

struct CatalogPlatformRootView: View {
    var body: some View {
#if os(tvOS)
        TVCatalogRootView()
#else
        CatalogRootView()
#endif
    }
}

enum CatalogPage: String, CaseIterable, Identifiable {
    case foundations = "Foundations"
    case buttons = "Buttons"
    case controls = "Controls"
    case feedback = "Feedback"
    case surfaces = "Surfaces"
    case navigation = "Navigation"
    case dataDisplay = "Data Display"
    case charts = "Charts"
    case overlays = "Overlays"
    case layouts = "Layouts"
    case extended = "Extended"
    case mobile = "Mobile"

    var id: Self { self }

    var icon: String {
        switch self {
        case .foundations: "paintpalette"
        case .buttons: "cursorarrow.click"
        case .controls: "switch.2"
        case .feedback: "exclamationmark.bubble"
        case .surfaces: "square.on.square"
        case .navigation: "signpost.right"
        case .dataDisplay: "list.bullet.rectangle"
        case .charts: "chart.xyaxis.line"
        case .overlays: "macwindow.on.rectangle"
        case .layouts: "rectangle.3.group"
        case .extended: "square.grid.3x3"
        case .mobile: "iphone"
        }
    }

    var summary: String {
        switch self {
        case .foundations: "Color, typography, spacing, radius, and utility styles."
        case .buttons: "Actions, icon buttons, groups, toggles, and segmented controls."
        case .controls: "Interactive fields and selection controls with live state."
        case .feedback: "Status, alerts, loading, progress, and empty states."
        case .surfaces: "Cards, panels, separators, skeletons, and backgrounds."
        case .navigation: "Branding, page hierarchy, tabs, pagination, and disclosure."
        case .dataDisplay: "Avatars, metrics, lists, timelines, filters, and keyboard hints."
        case .charts: "Line, area, bar, pie, scatter, and sparkline charts."
        case .overlays: "Modal content, tooltips, menus, and command search."
        case .layouts: "Dashboard, shell, header, footer, and multi-panel composition."
        case .extended: "Activity, feeds, specialized inputs, filters, media, and carousels."
        case .mobile:
#if os(tvOS)
            "Remote-focused navigation and television-scale application shells."
#else
            "Bottom tabs and adaptive application shells in device canvases."
#endif
        }
    }
}

enum CatalogAppearance: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    var id: Self { self }
    var scheme: ColorScheme? { self == .light ? .light : self == .dark ? .dark : nil }
}

enum CatalogTextSize: String, CaseIterable, Identifiable {
    case small = "Small"
    case standard = "Standard"
    case large = "Large"
    case accessibility = "Accessibility"
    var id: Self { self }
    var value: DynamicTypeSize {
        switch self {
        case .small: .small
        case .standard: .large
        case .large: .xxxLarge
        case .accessibility: .accessibility2
        }
    }
}

struct CatalogRootView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selection: CatalogPage? = .foundations
    @State private var search = ""
    @State private var appearance = CatalogAppearance.system
    @State private var textSize = CatalogTextSize.standard

    private var visiblePages: [CatalogPage] {
        guard !search.isEmpty else { return CatalogPage.allCases }
        return CatalogPage.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(search) ||
            $0.summary.localizedCaseInsensitiveContains(search)
        }
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                compactNavigation
            } else {
                splitNavigation
            }
        }
        .preferredColorScheme(appearance.scheme)
        .environment(\.dynamicTypeSize, textSize.value)
        .transaction { transaction in
            if reduceMotion { transaction.animation = nil }
        }
    }

    private var splitNavigation: some View {
        NavigationSplitView {
            List(visiblePages, selection: $selection) { page in
                NavigationLink(value: page) {
                    Label(page.rawValue, systemImage: page.icon)
                }
            }
            .navigationTitle("Sabella")
            .searchable(text: $search, prompt: "Find components")
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(CatalogAppearance.allCases) { Text($0.rawValue).tag($0) }
                    }
                    Picker("Type size", selection: $textSize) {
                        ForEach(CatalogTextSize.allCases) { Text($0.rawValue).tag($0) }
                    }
                }
                .controlSize(.small)
                .padding(12)
            }
        } detail: {
            if let selection {
                CatalogPageView(page: selection)
                    .id(selection)
            } else {
                ContentUnavailableView("Choose a component family", systemImage: "square.grid.2x2")
            }
        }
    }

    private var compactNavigation: some View {
        NavigationStack {
            List(visiblePages) { page in
                NavigationLink {
                    CatalogPageView(page: page)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(page.rawValue, systemImage: page.icon)
                        Text(page.summary).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Sabella")
            .searchable(text: $search, prompt: "Find components")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Menu {
                        Picker("Appearance", selection: $appearance) {
                            ForEach(CatalogAppearance.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Appearance", systemImage: "circle.lefthalf.filled")
                    }

                    Menu {
                        Picker("Type size", selection: $textSize) {
                            ForEach(CatalogTextSize.allCases) { Text($0.rawValue).tag($0) }
                        }
                    } label: {
                        Label("Type size", systemImage: "textformat.size")
                    }
                }
            }
        }
    }
}

#if os(tvOS)
struct TVCatalogRootView: View {
    @State private var selection: CatalogPage? = .foundations
    @State private var appearance = CatalogAppearance.system
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        NavigationSplitView {
            List(CatalogPage.allCases, selection: $selection) { page in
                NavigationLink(value: page) {
                    Label(page.rawValue, systemImage: page.icon)
                }
            }
            .navigationTitle("Sabella")
        } detail: {
            CatalogPageView(page: selection ?? .foundations)
                .safeAreaInset(edge: .bottom) {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(CatalogAppearance.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 64)
                }
        }
        .preferredColorScheme(appearance.scheme)
        .transaction { transaction in
            if reduceMotion { transaction.animation = nil }
        }
    }
}
#endif

struct CatalogPageView: View {
    let page: CatalogPage
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                BleeckerPageHeader(eyebrow: "Component catalog", title: page.rawValue, description: page.summary) {
                    BleeckerStatusBadge("Live", variant: .live)
                }

                Group {
                    switch page {
                    case .foundations: FoundationsGallery()
                    case .buttons: ButtonsGallery()
                    case .controls: ControlsGallery()
                    case .feedback: FeedbackGallery()
                    case .surfaces: SurfacesGallery()
                    case .navigation: NavigationGallery()
                    case .dataDisplay: DataDisplayGallery()
                    case .charts: ChartsGallery()
                    case .overlays: OverlaysGallery()
                    case .layouts: LayoutsGallery()
                    case .extended: ExtendedGallery()
                    case .mobile: MobileGallery()
                    }
                }
            }
            .frame(maxWidth: 980, alignment: .leading)
            .padding(pagePadding)
        }
        .background(CatalogBackground())
        .navigationTitle(page.rawValue)
    }

    private var pagePadding: CGFloat {
#if os(tvOS)
        64
#else
        horizontalSizeClass == .compact ? 20 : 32
#endif
    }
}

struct CatalogSection<Content: View>: View {
    let title: String
    let note: String?
    @ViewBuilder let content: Content

    init(_ title: String, note: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.note = note
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            BleeckerSectionHeader(title, subtitle: note) { EmptyView() }
            BleeckerCard(padding: .md, variant: .surface) {
                content.frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct CatalogLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View { Text(text).bleeckerPill() }
}

struct CatalogBackground: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View { BleeckerPalette.resolve(scheme).background.ignoresSafeArea() }
}

struct SampleItem: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
}
