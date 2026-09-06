#if os(tvOS)
import AVKit
import Sabella
import SwiftUI
import UIKit

private enum TelevisionPage: String, Hashable {
    case browse = "Browse"
    case detail = "Details"
    case playback = "Live TV"
    case states = "States"
    case search
    case profiles

    static let navigation: [TelevisionPage] = [.browse, .detail, .playback, .states]
}

struct SabellaTelevisionCatalog: View {
    @State private var page = TelevisionPage.browse
    @State private var selectedContentID = "coast"
    @State private var query = ""
    @State private var activeProfile = "Javier"
    @State private var isWatchlisted = false

    private let content = [
        SabellaTVContent(id: "coast", title: "The Southern Coast", subtitle: "Travel · 48 min", systemImage: "water.waves"),
        SabellaTVContent(id: "city", title: "After Midnight", subtitle: "Drama · 6 episodes", systemImage: "building.2.crop.circle"),
        SabellaTVContent(id: "signal", title: "Signal Lost", subtitle: "Thriller · 1h 42m", systemImage: "antenna.radiowaves.left.and.right"),
        SabellaTVContent(id: "kitchen", title: "Sunday Table", subtitle: "Food · New episode", systemImage: "fork.knife"),
        SabellaTVContent(id: "archive", title: "The Archive", subtitle: "Documentary · 52 min", systemImage: "archivebox"),
    ]

    var body: some View {
        Group {
            if page == .playback {
                CatalogPlayback(title: selectedContent.title) { page = .browse }
            } else {
                SabellaTVScreen {
                    VStack(alignment: .leading, spacing: 30) {
                HStack(spacing: 32) {
                    BleeckerBrandLockup(name: "Sabella")
                    Spacer(minLength: 52)
                    SabellaTVNavigationBar(
                        selection: $page,
                        items: TelevisionPage.navigation.map { SabellaTVNavigationItem($0, title: $0.rawValue) }
                    )
                    Spacer(minLength: 52)
                    HStack(spacing: 18) {
                        Button { page = .search } label: { Label("Search", systemImage: "magnifyingglass") }
                            .buttonStyle(SabellaTVPrimaryButtonStyle())
                        Button { page = .profiles } label: {
                            Label(activeProfile, systemImage: "person.crop.circle.fill")
                                .labelStyle(.iconOnly)
                                .font(.system(size: 34))
                                .accessibilityLabel("Choose profile, current profile \(activeProfile)")
                        }
                        .buttonStyle(SabellaTVPrimaryButtonStyle())
                    }
                }
                .frame(minHeight: 76)

                        Group {
                            switch page {
                            case .browse: browse
                            case .detail: detail
                            case .states: states
                            case .search: search
                            case .profiles: profiles
                            case .playback: EmptyView()
                            }
                        }
                        .id(page)
                    }
                }
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
                    ) { select(item) } artwork: { artwork(item) }
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
                    ) { select(item) } artwork: { artwork(item) }
                }
            }
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
    }

    private var detail: some View {
        let item = selectedContent
        return SabellaTVHero(
            eyebrow: "Sabella Original",
            title: item.title,
            synopsis: "A complete television detail flow for \(item.title), with playable media and persistent watchlist state.",
            metadata: ["2026", "48 min", "Documentary", "4K"]
        ) {
            LinearGradient(colors: [BleeckerPalette.dark.deepSea, BleeckerPalette.dark.sea, BleeckerPalette.dark.desert], startPoint: .bottomLeading, endPoint: .topTrailing)
                .overlay { Image(systemName: item.systemImage).font(.system(size: 230)).foregroundStyle(.white.opacity(0.16)) }
        } actions: {
            Button { page = .playback } label: { Label("Play", systemImage: "play.fill") }
                .buttonStyle(SabellaTVPrimaryButtonStyle())
            Button { isWatchlisted.toggle() } label: {
                Label(isWatchlisted ? "In Watchlist" : "Add to Watchlist", systemImage: isWatchlisted ? "checkmark" : "plus")
            }
                .buttonStyle(SabellaTVPrimaryButtonStyle())
        }
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

    private var search: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Search")
                .font(BleeckerTypography.primary(48, weight: .bold))
            TextField("Title, genre, or mood", text: $query)
                .font(BleeckerTypography.secondary(28))
                .padding(.horizontal, 26)
                .frame(height: 76)
                .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
            if searchResults.isEmpty {
                Text("No titles match “\(query)”.")
                    .font(BleeckerTypography.secondary(24))
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                SabellaTVShelf(query.isEmpty ? "All titles" : "Results", items: searchResults) { item in
                    SabellaTVCard(title: item.title, subtitle: item.subtitle) { select(item) } artwork: { artwork(item) }
                }
            }
        }
    }

    private var profiles: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Who’s watching?")
                .font(BleeckerTypography.primary(48, weight: .bold))
            Text("Switching profile changes the household context used by browse recommendations.")
                .font(BleeckerTypography.secondary(23))
                .foregroundStyle(.white.opacity(0.7))
            HStack(spacing: 32) {
                ForEach(["Javier", "Guest", "Family"], id: \.self) { profile in
                    Button {
                        activeProfile = profile
                        page = .browse
                    } label: {
                        VStack(spacing: 18) {
                            Image(systemName: profile == "Family" ? "person.3.fill" : "person.crop.circle.fill")
                                .font(.system(size: 76))
                            Text(profile).font(BleeckerTypography.primary(26, weight: .semibold))
                            if activeProfile == profile { Text("Current").font(BleeckerTypography.secondary(18)) }
                        }
                        .frame(width: 230, height: 230)
                    }
                    .buttonStyle(SabellaTVPrimaryButtonStyle())
                }
            }
            .focusSection()
        }
    }

    private func card(_ item: SabellaTVContent) -> some View {
        SabellaTVCard(title: item.title, subtitle: item.subtitle, context: recommendation(for: item.id)) { select(item) } artwork: { artwork(item) }
    }

    private var selectedContent: SabellaTVContent {
        content.first { $0.id == selectedContentID } ?? content[0]
    }

    private var searchResults: [SabellaTVContent] {
        guard !query.isEmpty else { return content }
        return content.filter { item in
            item.title.localizedCaseInsensitiveContains(query) || item.subtitle.localizedCaseInsensitiveContains(query)
        }
    }

    private func select(_ item: SabellaTVContent) {
        selectedContentID = item.id
        page = .detail
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
        case "coast": "For \(activeProfile)"
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
            Button(action) { page = .browse }.buttonStyle(SabellaTVPrimaryButtonStyle())
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

private struct CatalogPlayback: View {
    @State private var player: AVPlayer
    @State private var isPlaying = true
    @State private var guideVisible = true
    @State private var selectedChannelID = "sky-news"
    private let title: String
    private let close: () -> Void
    private let channels = [
        SabellaTVChannel(
            id: "sky-news",
            streamURL: URL(string: "https://linear901-oo-hls0-prd-gtm.delivery.skycdp.com/v1/master/6404a5d732e04991ed59ac7790b61cc065c9aabd/prod-gb-lin-skynews-hls-25-web/master.m3u8?ads.cdn=https://linear901-oo-hls0-prd-gtm.delivery.skycdp.com&ads.csid=sitesection:SkyNews:Web&manifest.mthost=7a38d30e7dd84cd0872ab4f691c38f58&manifest.region=mediatailor.eu-west-1.amazonaws.com")!,
            number: "501",
            name: "Sky News",
            now: "Sky News Live",
            next: "Headlines and Weather",
            progress: 0.42
        ),
        SabellaTVChannel(
            id: "tagesschau24",
            streamURL: URL(string: "https://tagesschau.akamaized.net/hls/live/2020115/tagesschau/tagesschau_1/master.m3u8")!,
            number: "024",
            name: "tagesschau24",
            now: "Live news",
            next: "Schedule from provider",
            progress: 0.58
        ),
        SabellaTVChannel(
            id: "rtl-1025",
            streamURL: URL(string: "https://streamcdnc1-dd782ed59e2a4e86aabf6fc508674b59.msvdn.net/live/S97044836/tbbP8T1ZRPBL/playlist_video.m3u8")!,
            number: "036",
            name: "RTL 102.5",
            now: "Radiovisione live",
            next: "Schedule from provider",
            progress: 0.31
        ),
        SabellaTVChannel(
            id: "radio-italia",
            streamURL: URL(string: "https://radioitaliatv.akamaized.net/hls/live/2093117/RadioitaliaTV/master.m3u8")!,
            number: "070",
            name: "Radio Italia TV",
            now: "Solo musica italiana",
            next: "Schedule from provider",
            progress: 0.74
        ),
    ]

    init(title: String, close: @escaping () -> Void) {
        let source = "https://linear901-oo-hls0-prd-gtm.delivery.skycdp.com/v1/master/6404a5d732e04991ed59ac7790b61cc065c9aabd/prod-gb-lin-skynews-hls-25-web/master.m3u8?ads.cdn=https://linear901-oo-hls0-prd-gtm.delivery.skycdp.com&ads.csid=sitesection:SkyNews:Web&manifest.mthost=7a38d30e7dd84cd0872ab4f691c38f58&manifest.region=mediatailor.eu-west-1.amazonaws.com"
        guard let url = URL(string: source) else { preconditionFailure("Sky News playback URL is invalid") }
        self.title = title
        self.close = close
        _player = State(initialValue: AVPlayer(url: url))
    }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            CatalogPlayerSurface(player: player)
            if guideVisible {
                SabellaTVChannelGuide(channels: channels, selection: selectedChannelID) { channel in
                    selectedChannelID = channel.id
                    player.replaceCurrentItem(with: AVPlayerItem(url: channel.streamURL))
                    guideVisible = false
                    player.play()
                    isPlaying = true
                }
                .padding(46)
            } else {
                SabellaTVPlaybackOverlay(
                    title: channels.first { $0.id == selectedChannelID }?.name ?? "Live TV",
                    subtitle: "Live HLS playback · \(title) demo surface",
                    isPlaying: $isPlaying,
                    elapsed: 0,
                    duration: 0,
                    isLive: true
                )
                .padding(54)
            }
        }
        .ignoresSafeArea()
        .onAppear { player.play() }
        .onDisappear { player.pause() }
        .onChange(of: isPlaying) { _, playing in playing ? player.play() : player.pause() }
        .onExitCommand {
            if guideVisible { close() } else { guideVisible = true }
        }
    }

}

private struct CatalogPlayerSurface: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.playerLayer.player = player
    }

    final class PlayerView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
#endif
