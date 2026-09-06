#if os(tvOS)
import Sabella
import SwiftUI

private enum TelevisionPage: String, CaseIterable, Hashable {
    case browse = "Browse"
    case detail = "Details"
    case playback = "Playback"
    case states = "States"
}

struct SabellaTelevisionCatalog: View {
    @State private var page = TelevisionPage.browse
    @State private var isPlaying = true

    private let content = [
        SabellaTVContent(id: "coast", title: "The Southern Coast", subtitle: "Travel · 48 min", systemImage: "water.waves"),
        SabellaTVContent(id: "city", title: "After Midnight", subtitle: "Drama · 6 episodes", systemImage: "building.2.crop.circle"),
        SabellaTVContent(id: "signal", title: "Signal Lost", subtitle: "Thriller · 1h 42m", systemImage: "antenna.radiowaves.left.and.right"),
        SabellaTVContent(id: "kitchen", title: "Sunday Table", subtitle: "Food · New episode", systemImage: "fork.knife"),
        SabellaTVContent(id: "archive", title: "The Archive", subtitle: "Documentary · 52 min", systemImage: "archivebox"),
    ]

    var body: some View {
        SabellaTVScreen {
            VStack(alignment: .leading, spacing: 30) {
                HStack(spacing: 44) {
                    BleeckerBrandLockup(name: "Sabella TV")
                    SabellaTVNavigationBar(
                        selection: $page,
                        items: TelevisionPage.allCases.map { SabellaTVNavigationItem($0, title: $0.rawValue) }
                    )
                    Spacer()
                    Button { } label: { Label("Search", systemImage: "magnifyingglass") }
                        .buttonStyle(SabellaTVPrimaryButtonStyle())
                    BleeckerStatusBadge("TV native", variant: .live)
                }

                Group {
                    switch page {
                    case .browse: browse
                    case .detail: detail
                    case .playback: playback
                    case .states: states
                    }
                }
                .id(page)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var browse: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 42) {
                SabellaTVHero(
                    eyebrow: "Featured tonight",
                    title: "Stories made for the big screen",
                    synopsis: "A television-first Sabella surface with remote focus, cinematic hierarchy, shelves, and playback—not a desktop catalog stretched to 16:9.",
                    metadata: ["4K", "Dolby Atmos", "New"]
                ) {
                    LinearGradient(colors: [BleeckerPalette.dark.sea, BleeckerPalette.dark.terracotta], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .overlay { Image(systemName: "play.tv.fill").font(.system(size: 190)).foregroundStyle(.white.opacity(0.14)) }
                } actions: {
                    Button { page = .playback } label: { Label("Play", systemImage: "play.fill") }
                        .buttonStyle(SabellaTVPrimaryButtonStyle())
                    Button { page = .detail } label: { Label("Details", systemImage: "info.circle") }
                        .buttonStyle(SabellaTVPrimaryButtonStyle())
                }
                SabellaTVShelf("Continue watching", items: content) { item in
                    SabellaTVCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        context: item.id == "coast" ? "Episode 3" : nil,
                        progress: progress(for: item.id)
                    ) { } artwork: { artwork(item) }
                }
                SabellaTVEditorialRail(
                    eyebrow: "Tonight's edit",
                    title: "Slow stories, vivid places",
                    summary: "A human-curated collection for winding down—fewer choices, with a clear point of view.",
                    items: Array(content.reversed())
                ) { item in
                    SabellaTVCard(
                        title: item.title,
                        subtitle: item.subtitle,
                        width: 230,
                        artworkRatio: .poster,
                        context: recommendation(for: item.id)
                    ) { } artwork: { artwork(item) }
                }
            }
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
    }

    private var detail: some View {
        SabellaTVHero(
            eyebrow: "Sabella Original",
            title: "The Southern Coast",
            synopsis: "Follow a disappearing shoreline through the people, music, and rituals that continue to shape it.",
            metadata: ["2026", "48 min", "Documentary", "4K"]
        ) {
            LinearGradient(colors: [BleeckerPalette.dark.deepSea, BleeckerPalette.dark.sea, BleeckerPalette.dark.desert], startPoint: .bottomLeading, endPoint: .topTrailing)
                .overlay { Image(systemName: "water.waves").font(.system(size: 230)).foregroundStyle(.white.opacity(0.16)) }
        } actions: {
            Button { page = .playback } label: { Label("Play", systemImage: "play.fill") }
                .buttonStyle(SabellaTVPrimaryButtonStyle())
            Button { } label: { Label("Add to Watchlist", systemImage: "plus") }
                .buttonStyle(SabellaTVPrimaryButtonStyle())
        }
    }

    private var playback: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: [.black, BleeckerPalette.dark.deepSea], startPoint: .top, endPoint: .bottom)
                .overlay { Image(systemName: "water.waves").font(.system(size: 300)).foregroundStyle(.white.opacity(0.08)) }
            SabellaTVPlaybackOverlay(
                title: "The Southern Coast",
                subtitle: "Chapter 3 · Where the water meets the town",
                isPlaying: $isPlaying,
                elapsed: 1_482,
                duration: 2_880
            )
            .padding(54)
        }
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }

    private var states: some View {
        HStack(spacing: 36) {
            stateCard(icon: "wifi.slash", title: "Connection lost", message: "Check the network and try again.", action: "Retry")
            stateCard(icon: "checkmark.circle", title: "You’re all caught up", message: "New episodes will appear here.", action: "Browse")
            stateCard(icon: "lock.fill", title: "Subscription required", message: "Choose a plan to keep watching.", action: "View plans")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .focusSection()
    }

    private func card(_ item: SabellaTVContent) -> some View {
        SabellaTVCard(title: item.title, subtitle: item.subtitle, context: recommendation(for: item.id)) { } artwork: { artwork(item) }
    }

    private func artwork(_ item: SabellaTVContent) -> some View {
        LinearGradient(colors: [color(for: item.id), BleeckerPalette.dark.deepSea], startPoint: .topLeading, endPoint: .bottomTrailing)
            .overlay { Image(systemName: item.systemImage).font(.system(size: 74)).foregroundStyle(.white.opacity(0.7)) }
    }

    private func progress(for id: String) -> Double {
        switch id {
        case "coast": 0.51
        case "city": 0.18
        case "signal": 0.72
        default: 0.08
        }
    }

    private func recommendation(for id: String) -> String {
        switch id {
        case "coast": "Because you watch travel"
        case "city": "Top 10 today"
        case "signal": "Critics' pick"
        case "kitchen": "New this week"
        default: "Award winner"
        }
    }

    private func stateCard(icon: String, title: String, message: String, action: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: icon).font(.system(size: 64)).foregroundStyle(BleeckerPalette.dark.sea)
            Text(title).font(BleeckerTypography.primary(30, weight: .bold))
            Text(message).font(BleeckerTypography.secondary(20)).foregroundStyle(.white.opacity(0.68)).multilineTextAlignment(.center)
            Button(action) { }.buttonStyle(SabellaTVPrimaryButtonStyle())
        }
        .padding(36)
        .frame(maxWidth: .infinity, minHeight: 360)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 26))
    }

    private func color(for id: String) -> Color {
        switch id {
        case "coast": BleeckerPalette.dark.sea
        case "city": BleeckerPalette.dark.accentOxblood
        case "signal": BleeckerPalette.dark.terracotta
        case "kitchen": BleeckerPalette.dark.desert
        default: BleeckerPalette.dark.accentGold
        }
    }
}
#endif
