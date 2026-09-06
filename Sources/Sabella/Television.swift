#if os(tvOS)
import SwiftUI

public struct SabellaTVContent: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let systemImage: String

    public init(id: String, title: String, subtitle: String, systemImage: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

public struct SabellaTVChannelGroupSummary: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let channelCount: Int
    public let systemImage: String

    public init(id: String, name: String, channelCount: Int, systemImage: String = "rectangle.3.group.fill") {
        self.id = id
        self.name = name
        self.channelCount = channelCount
        self.systemImage = systemImage
    }
}

public struct SabellaTVChannelGroupBrowser: View {
    private let groups: [SabellaTVChannelGroupSummary]
    @Binding private var focusedGroupID: String?
    @Binding private var headerFocusRequested: Bool
    @Binding private var contentFocusRequested: Bool
    private let browseAll: () -> Void
    private let select: (SabellaTVChannelGroupSummary) -> Void
    @FocusState private var focusedID: String?
    @FocusState private var browseAllFocused: Bool

    public init(
        groups: [SabellaTVChannelGroupSummary],
        focusedGroupID: Binding<String?>,
        headerFocusRequested: Binding<Bool> = .constant(false),
        contentFocusRequested: Binding<Bool> = .constant(false),
        browseAll: @escaping () -> Void,
        select: @escaping (SabellaTVChannelGroupSummary) -> Void
    ) {
        self.groups = groups
        _focusedGroupID = focusedGroupID
        _headerFocusRequested = headerFocusRequested
        _contentFocusRequested = contentFocusRequested
        self.browseAll = browseAll
        self.select = select
    }

    public var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 42) {
                SabellaTVHero(
                    eyebrow: "Your television",
                    title: "Live, organized your way",
                    synopsis: "Choose a channel group, then move between live television and radio without leaving playback.",
                    metadata: [
                        "\(groups.count) group\(groups.count == 1 ? "" : "s")",
                        "\(channelCount) live channel\(channelCount == 1 ? "" : "s")",
                    ]
                ) {
                    LinearGradient(
                        colors: [BleeckerPalette.dark.deepSea, BleeckerPalette.dark.sea, BleeckerPalette.dark.terracotta],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .overlay(alignment: .trailing) {
                        Image(systemName: "play.tv.fill")
                            .font(.system(size: 230, weight: .ultraLight))
                            .foregroundStyle(.white.opacity(0.14))
                            .padding(.trailing, 96)
                    }
                } actions: {
                    Button(action: browseAll) {
                        Label("Browse all groups", systemImage: "square.grid.2x2.fill")
                    }
                    .buttonStyle(SabellaTVPrimaryButtonStyle())
                    .focused($browseAllFocused)
                    .onMoveCommand { direction in
                        guard direction == .up else { return }
                        browseAllFocused = false
                        headerFocusRequested = true
                    }
                }

                VStack(alignment: .leading, spacing: 18) {
                    Text("Featured groups")
                        .font(BleeckerTypography.primary(32, weight: .bold))
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal) {
                            LazyHStack(spacing: 40) {
                                ForEach(featuredGroups) { item in
                                    SabellaTVChannelGroupTile(
                                        item: item,
                                        focusedID: $focusedID,
                                        select: rememberAndSelect
                                    )
                                    .id(item.id)
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.vertical, 28)
                            .padding(.horizontal, 12)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollIndicators(.hidden)
                        .scrollClipDisabled()
                        .task {
                            guard let focusedGroupID,
                                  featuredGroups.contains(where: { $0.id == focusedGroupID }) else { return }
                            proxy.scrollTo(focusedGroupID, anchor: .center)
                            await Task.yield()
                            focusedID = focusedGroupID
                        }
                    }
                }
                .focusSection()
            }
            .padding(.bottom, 80)
        }
        .scrollIndicators(.hidden)
        .onChange(of: focusedID) { _, id in
            if let id { focusedGroupID = id }
        }
        .onChange(of: contentFocusRequested) { _, requested in
            guard requested else { return }
            focusedID = nil
            browseAllFocused = true
            contentFocusRequested = false
        }
    }

    private var channelCount: Int {
        groups.reduce(0) { $0 + $1.channelCount }
    }

    private var featuredGroups: [SabellaTVIndexedChannelGroup] {
        Array(indexedGroups.filter { $0.group.channelCount > 0 }.prefix(4))
    }

    private var indexedGroups: [SabellaTVIndexedChannelGroup] {
        groups.enumerated().map { SabellaTVIndexedChannelGroup(index: $0.offset, group: $0.element) }
    }

    private func rememberAndSelect(_ item: SabellaTVIndexedChannelGroup) {
        guard item.group.channelCount > 0 else { return }
        focusedGroupID = item.id
        select(item.group)
    }
}

public struct SabellaTVChannelGroupDirectory: View {
    private let groups: [SabellaTVChannelGroupSummary]
    @Binding private var focusedGroupID: String?
    @Binding private var headerFocusRequested: Bool
    @Binding private var contentFocusRequested: Bool
    private let select: (SabellaTVChannelGroupSummary) -> Void
    @FocusState private var focusedID: String?

    public init(
        groups: [SabellaTVChannelGroupSummary],
        focusedGroupID: Binding<String?>,
        headerFocusRequested: Binding<Bool> = .constant(false),
        contentFocusRequested: Binding<Bool> = .constant(false),
        select: @escaping (SabellaTVChannelGroupSummary) -> Void
    ) {
        self.groups = groups
        _focusedGroupID = focusedGroupID
        _headerFocusRequested = headerFocusRequested
        _contentFocusRequested = contentFocusRequested
        self.select = select
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        SabellaTVSectionLabel("Channel directory")
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                            Text("All groups")
                                .font(BleeckerTypography.primary(46, weight: .bold))
                            Text("\(groups.count)")
                                .font(BleeckerTypography.mono(24, weight: .bold))
                                .foregroundStyle(BleeckerPalette.dark.sea)
                        }
                        Text("Choose a group to open its live television and radio lineup.")
                            .font(BleeckerTypography.secondary(21))
                            .foregroundStyle(BleeckerPalette.dark.textSecondary)
                    }

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 42) {
                        ForEach(indexedGroups) { item in
                            SabellaTVChannelGroupTile(
                                item: item,
                                focusedID: $focusedID,
                                requestsHeaderOnUp: item.index < columns.count,
                                requestHeaderFocus: requestHeaderFocus,
                                select: rememberAndSelect
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 20)
                    .focusSection()
                }
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)
            .task {
                let target = focusedGroupID.flatMap { id in
                    groups.contains(where: { $0.id == id }) ? id : nil
                } ?? groups.first(where: { $0.channelCount > 0 })?.id
                guard let target else { return }
                proxy.scrollTo(target, anchor: .center)
                await Task.yield()
                focusedID = target
            }
            .onChange(of: focusedID) { _, id in
                guard let id else { return }
                focusedGroupID = id
                withAnimation(.easeOut(duration: 0.24)) {
                    proxy.scrollTo(id, anchor: .center)
                }
            }
            .onChange(of: contentFocusRequested) { _, requested in
                guard requested else { return }
                let target = focusedGroupID.flatMap { id in
                    groups.contains(where: { $0.id == id }) ? id : nil
                } ?? groups.first(where: { $0.channelCount > 0 })?.id
                focusedID = target
                if let target {
                    withAnimation(.easeOut(duration: 0.24)) {
                        proxy.scrollTo(target, anchor: .center)
                    }
                }
                contentFocusRequested = false
            }
        }
    }

    private var columns: [GridItem] {
        Array(repeating: GridItem(.fixed(360), spacing: 48), count: 4)
    }

    private var indexedGroups: [SabellaTVIndexedChannelGroup] {
        groups.enumerated().map { SabellaTVIndexedChannelGroup(index: $0.offset, group: $0.element) }
    }

    private func rememberAndSelect(_ item: SabellaTVIndexedChannelGroup) {
        guard item.group.channelCount > 0 else { return }
        focusedGroupID = item.id
        select(item.group)
    }

    private func requestHeaderFocus() {
        focusedID = nil
        headerFocusRequested = true
    }
}

private struct SabellaTVIndexedChannelGroup: Identifiable {
    let index: Int
    let group: SabellaTVChannelGroupSummary
    var id: String { group.id }
}

private struct SabellaTVChannelGroupTile: View {
    let item: SabellaTVIndexedChannelGroup
    let focusedID: FocusState<String?>.Binding
    var requestsHeaderOnUp = false
    var requestHeaderFocus: () -> Void = {}
    let select: (SabellaTVIndexedChannelGroup) -> Void

    private var focused: Bool { focusedID.wrappedValue == item.id }

    var body: some View {
        Button { select(item) } label: {
            VStack(alignment: .leading, spacing: 11) {
                LinearGradient(
                    colors: sabellaTVGroupArtworkColors(for: item.index),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay {
                    Image(systemName: item.group.systemImage)
                        .font(.system(size: 92, weight: .light))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .overlay(alignment: .topLeading) {
                    if item.group.channelCount == 0 {
                        SabellaTVContextBadge("EMPTY")
                            .padding(14)
                    } else {
                        SabellaTVLiveBadge()
                            .padding(14)
                    }
                }
                .overlay(alignment: .bottomTrailing) {
                    Text(String(format: "%02d", item.index + 1))
                        .font(BleeckerTypography.mono(22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.66))
                        .padding(20)
                }
                .frame(width: 336, height: 186)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Text(item.group.name)
                    .font(BleeckerTypography.primary(23, weight: .semibold))
                    .foregroundStyle(BleeckerPalette.dark.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.group.channelCount == 0
                    ? "No channels assigned"
                    : "\(item.group.channelCount) live channel\(item.group.channelCount == 1 ? "" : "s")")
                    .font(BleeckerTypography.secondary(19))
                    .foregroundStyle(BleeckerPalette.dark.textSecondary)
                    .lineLimit(1)
            }
            .frame(width: 336, alignment: .leading)
            .padding(12)
            .frame(width: 360, alignment: .leading)
            .background(
                focused ? BleeckerPalette.dark.deepSea.opacity(0.96) : .clear,
                in: RoundedRectangle(cornerRadius: 24, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(
                        focused ? BleeckerPalette.dark.sea : .white.opacity(0.06),
                        lineWidth: focused ? 3 : 1
                    )
            }
            .shadow(color: focused ? BleeckerPalette.dark.sea.opacity(0.22) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(SabellaTVChannelButtonStyle())
        .focusEffectDisabled()
        .focused(focusedID, equals: item.id)
        .disabled(item.group.channelCount == 0)
        .opacity(item.group.channelCount == 0 ? 0.46 : 1)
        .onMoveCommand { direction in
            guard requestsHeaderOnUp, direction == .up else { return }
            requestHeaderFocus()
        }
        .animation(.easeOut(duration: BleeckerDuration.enter), value: focused)
        .accessibilityLabel("\(item.group.name), \(item.group.channelCount) channels")
    }
}

private func sabellaTVGroupArtworkColors(for index: Int) -> [Color] {
    let palettes: [[Color]] = [
        [BleeckerPalette.dark.sea, BleeckerPalette.dark.deepSea],
        [BleeckerPalette.dark.terracotta, BleeckerPalette.dark.accentOxblood],
        [BleeckerPalette.dark.accentGold, BleeckerPalette.dark.deepSea],
        [BleeckerPalette.dark.accentBlue, BleeckerPalette.dark.sea],
    ]
    return palettes[index % palettes.count]
}

public struct SabellaTVChannel: Identifiable, Hashable, Sendable {
    public let id: String
    public let streamURL: URL
    public let number: String
    public let name: String
    public let mark: String
    public let tone: SabellaTVChannelTone
    public let now: String
    public let next: String?
    public let progress: Double
    public let currentTime: String?
    public let nextTime: String?
    public let backgroundPlayback: SabellaTVBackgroundPlayback
    public let medium: SabellaTVChannelMedium

    public init(
        id: String,
        streamURL: URL,
        number: String,
        name: String,
        mark: String? = nil,
        tone: SabellaTVChannelTone = .sea,
        now: String,
        next: String? = nil,
        progress: Double,
        currentTime: String? = nil,
        nextTime: String? = nil,
        backgroundPlayback: SabellaTVBackgroundPlayback = .automatic,
        medium: SabellaTVChannelMedium = .automatic
    ) {
        self.id = id
        self.streamURL = streamURL
        self.number = number
        self.name = name
        self.mark = mark ?? String(name.prefix(3)).uppercased()
        self.tone = tone
        self.now = now
        self.next = next
        self.progress = progress
        self.currentTime = currentTime
        self.nextTime = nextTime
        self.backgroundPlayback = backgroundPlayback
        self.medium = medium
    }
}

public enum SabellaTVChannelMedium: Hashable, Sendable {
    /// Resolve the medium from the ready media item. This is the default for
    /// large lineups whose source data does not explicitly distinguish radio.
    case automatic
    case television
    case radio
}

public enum SabellaTVBackgroundPlayback: Hashable, Sendable {
    /// Continue audio only when automatic media detection resolves the tuned
    /// channel as radio; suspend television playback.
    case automatic

    /// Stop playback when the application leaves the foreground. This is the
    /// default for television and video channels.
    case suspend

    /// Continue audio while backgrounded. Audio-first radio channels must opt in.
    case audio
}

public enum SabellaTVChannelTone: Hashable, Sendable {
    case sea
    case red
    case gold
    case terracotta

    var color: Color {
        switch self {
        case .sea: BleeckerPalette.dark.sea
        case .red: BleeckerPalette.dark.accentRed
        case .gold: BleeckerPalette.dark.accentGold
        case .terracotta: BleeckerPalette.dark.terracotta
        }
    }
}

public enum SabellaTVArtworkRatio: Sendable {
    case landscape
    case poster

    fileprivate var ratio: CGFloat {
        switch self {
        case .landscape: 0.5625
        case .poster: 1.5
        }
    }
}

public struct SabellaTVScreen<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @ViewBuilder private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let palette = BleeckerPalette.resolve(scheme)
        ZStack {
            LinearGradient(
                colors: [palette.background, palette.deepSea.opacity(reduceTransparency ? 1 : 0.7), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            content
                .safeAreaPadding(.horizontal, 96)
                .safeAreaPadding(.vertical, 54)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .foregroundStyle(palette.textPrimary)
    }
}

public struct SabellaTVContextBadge: View {
    private let text: String
    private let systemImage: String?

    public init(_ text: String, systemImage: String? = nil) {
        self.text = text
        self.systemImage = systemImage
    }

    public var body: some View {
        HStack(spacing: 7) {
            if let systemImage { Image(systemName: systemImage) }
            Text(text)
        }
        .font(BleeckerTypography.secondary(18, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .background(.black.opacity(0.72), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

public struct SabellaTVLiveBadge: View {
    private let text: String

    public init(_ text: String = "LIVE") {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "dot.radiowaves.left.and.right")
                .font(.system(size: 15, weight: .bold))
            Text(text)
        }
        .font(BleeckerTypography.secondary(17, weight: .bold))
        .tracking(0.8)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(minHeight: 36)
        .background(
            LinearGradient(
                colors: [BleeckerPalette.dark.accentRed, BleeckerPalette.dark.accentOxblood],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: Capsule()
        )
        .overlay { Capsule().strokeBorder(.white.opacity(0.22), lineWidth: 1) }
        .shadow(color: .black.opacity(0.32), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
    }
}

public struct SabellaTVChannelGuide: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let channels: [SabellaTVChannel]
    private let selection: String
    private let title: String
    private let select: (SabellaTVChannel) -> Void
    private let isPlaying: Bool
    private let isMuted: Bool
    private let resolvedMedia: [String: SabellaTVChannelMedium]
    private let hasMoreChannels: Bool
    private let loadingMoreChannels: Bool
    private let loadMoreChannels: () -> Void
    private let togglePlayback: (() -> Void)?
    private let toggleMute: (() -> Void)?
    @State private var highlightedID: String
    @FocusState private var focusedChannelID: String?
    @Namespace private var channelFocus

    public init(
        channels: [SabellaTVChannel],
        selection: String,
        title: String = "All Channels",
        isPlaying: Bool = true,
        isMuted: Bool = false,
        resolvedMedia: [String: SabellaTVChannelMedium] = [:],
        hasMoreChannels: Bool = false,
        loadingMoreChannels: Bool = false,
        loadMoreChannels: @escaping () -> Void = {},
        togglePlayback: (() -> Void)? = nil,
        toggleMute: (() -> Void)? = nil,
        select: @escaping (SabellaTVChannel) -> Void
    ) {
        precondition(!channels.isEmpty, "SabellaTVChannelGuide requires at least one channel")
        self.channels = channels
        self.selection = selection
        self.title = title
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.resolvedMedia = resolvedMedia
        self.hasMoreChannels = hasMoreChannels
        self.loadingMoreChannels = loadingMoreChannels
        self.loadMoreChannels = loadMoreChannels
        self.togglePlayback = togglePlayback
        self.toggleMute = toggleMute
        self.select = select
        _highlightedID = State(initialValue: selection)
    }

    public var body: some View {
        GeometryReader { proxy in
            let channel = highlightedChannel
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.52)
                LinearGradient(
                    colors: [.black.opacity(0.9), .black.opacity(0.58), .black.opacity(0.16)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    colors: [.clear, .black.opacity(0.68)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 14) {
                        Image(systemName: "chevron.left").foregroundStyle(BleeckerPalette.dark.sea)
                        Text(title)
                            .foregroundStyle(BleeckerPalette.dark.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text("\(channels.count)")
                            .foregroundStyle(BleeckerPalette.dark.sea)
                            .fixedSize()
                    }
                    .font(BleeckerTypography.primary(30, weight: .semibold))
                    .frame(maxWidth: 760, alignment: .leading)
                    Text("TV + Radio · Up / Down to browse · Select to tune")
                        .font(BleeckerTypography.secondary(17))
                        .foregroundStyle(.white.opacity(0.52))
                        .padding(.leading, 38)
                }
                .padding(.top, 52)
                .padding(.leading, 40)

                ScrollViewReader { scrollProxy in
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(channels) { item in
                                SabellaTVChannelRow(
                                    channel: item,
                                    medium: effectiveMedium(for: item),
                                    tuned: selection == item.id,
                                    focused: focusedChannelID == item.id,
                                    highlight: { highlightedID = item.id },
                                    select: { select(item) }
                                )
                                .focused($focusedChannelID, equals: item.id)
                                .id(item.id)
                                .onAppear {
                                    if item.id == channels.last?.id, hasMoreChannels {
                                        loadMoreChannels()
                                    }
                                }
                            }
                            if loadingMoreChannels {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 230, height: 86)
                                    .accessibilityLabel("Loading more channels")
                            }
                        }
                        .padding(.vertical, 320)
                    }
                    .scrollIndicators(.hidden)
                    .frame(width: 410, height: min(proxy.size.height - 190, 760))
                    .clipped()
                    .position(x: 205, y: proxy.size.height * 0.69)
                    .task {
                        highlightedID = selection
                        scrollProxy.scrollTo(selection, anchor: .center)
                        await Task.yield()
                        focusedChannelID = selection
                    }
                    .onChange(of: highlightedID) { _, id in
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
                            scrollProxy.scrollTo(id, anchor: .center)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(guideHeadline(for: channel))
                        .font(BleeckerTypography.primary(48, weight: .medium))
                        .tracking(-0.7)
                        .foregroundStyle(BleeckerPalette.dark.textPrimary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .allowsTightening(true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if shouldShowStation(for: channel) {
                        Text(channel.name)
                            .font(BleeckerTypography.secondary(25, weight: .medium))
                            .foregroundStyle(channel.tone.color)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Text(mediumLabel(for: channel))
                        .font(BleeckerTypography.mono(14, weight: .bold))
                        .tracking(1.4)
                        .foregroundStyle(effectiveMedium(for: channel) == .radio ? BleeckerPalette.dark.accentGold : BleeckerPalette.dark.live)
                    if let currentTime = channel.currentTime {
                        Text(currentTime)
                            .font(BleeckerTypography.secondary(20, weight: .regular))
                            .foregroundStyle(.white.opacity(0.76))
                    }
                    if togglePlayback != nil || toggleMute != nil {
                        HStack(spacing: 18) {
                            if let togglePlayback {
                                guideAction(
                                    isPlaying ? "Pause" : "Play",
                                    systemImage: isPlaying ? "pause.fill" : "play.fill",
                                    action: togglePlayback
                                )
                            }
                            if let toggleMute {
                                guideAction(
                                    isMuted ? "Unmute" : "Mute",
                                    systemImage: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                    action: toggleMute
                                )
                            }
                        }
                        .padding(.top, 16)
                    }
                }
                .frame(width: 640, height: 360, alignment: .leading)
                .clipped()
                .position(x: 790, y: proxy.size.height * 0.55)
                .id(channel.id)
                .transition(.opacity)

                if let next = channel.next {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("UP NEXT")
                            .font(BleeckerTypography.primary(16, weight: .semibold))
                            .tracking(0.7)
                            .foregroundStyle(BleeckerPalette.dark.desert)
                        Text(next)
                            .font(BleeckerTypography.primary(24, weight: .semibold))
                            .foregroundStyle(BleeckerPalette.dark.textPrimary)
                            .lineLimit(2)
                        if let nextTime = channel.nextTime {
                            Text(nextTime)
                                .font(BleeckerTypography.secondary(19))
                                .foregroundStyle(.white.opacity(0.74))
                        }
                        GeometryReader { bar in
                            Capsule().fill(.white.opacity(0.15))
                            Capsule().fill(BleeckerPalette.dark.desert)
                                .frame(width: bar.size.width * min(max(channel.progress, 0), 1))
                        }
                        .frame(width: 220, height: 5)
                        .padding(.top, 12)
                    }
                    .frame(width: 286, alignment: .leading)
                    .position(x: proxy.size.width - 190, y: proxy.size.height * 0.59)
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: highlightedID)
            .focusScope(channelFocus)
        }
        .accessibilityElement(children: .contain)
        .focusSection()
        .onChange(of: selection) { _, id in highlightedID = id }
    }

    private var highlightedChannel: SabellaTVChannel {
        channels.first { $0.id == highlightedID } ?? channels.first { $0.id == selection } ?? channels[0]
    }

    private func effectiveMedium(for channel: SabellaTVChannel) -> SabellaTVChannelMedium {
        channel.medium == .automatic ? resolvedMedia[channel.id] ?? .automatic : channel.medium
    }

    private func mediumLabel(for channel: SabellaTVChannel) -> String {
        switch effectiveMedium(for: channel) {
        case .radio: "LIVE RADIO"
        case .television: "LIVE TELEVISION"
        case .automatic: "LIVE"
        }
    }

    private func guideHeadline(for channel: SabellaTVChannel) -> String {
        channel.now.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? channel.name : channel.now
    }

    private func shouldShowStation(for channel: SabellaTVChannel) -> Bool {
        let headline = guideHeadline(for: channel)
        return headline.compare(
            channel.name,
            options: [.caseInsensitive, .diacriticInsensitive],
            range: nil,
            locale: .current
        ) != .orderedSame
    }

    private func guideAction(_ label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 24, weight: .semibold))
                .frame(width: 62, height: 62)
                .background(.black.opacity(0.58), in: Circle())
        }
        .buttonStyle(SabellaTVChannelButtonStyle())
        .accessibilityLabel(label)
    }
}

private struct SabellaTVChannelRow: View {
    let channel: SabellaTVChannel
    let medium: SabellaTVChannelMedium
    let tuned: Bool
    let focused: Bool
    let highlight: () -> Void
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 12) {
                Text(channel.number)
                    .font(BleeckerTypography.mono(17, weight: .semibold))
                    .foregroundStyle(.white.opacity(focused ? 0.92 : 0.52))
                    .frame(width: 46)
                Text(channel.mark)
                    .font(BleeckerTypography.primary(focused ? 24 : 20, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(channel.tone.color)
                    .frame(width: focused ? 58 : 54)
                Image(systemName: mediumIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(focused ? 0.8 : 0.38))
                    .frame(width: 22)
                if focused {
                    Text(channel.name)
                        .font(BleeckerTypography.secondary(20, weight: .semibold))
                        .foregroundStyle(BleeckerPalette.dark.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: 132, alignment: .leading)
                }
                Spacer(minLength: 0)
                if tuned {
                    Circle()
                        .fill(BleeckerPalette.dark.live)
                        .frame(width: 9, height: 9)
                        .accessibilityLabel("On air")
                }
            }
            .padding(.horizontal, 14)
            .frame(width: focused ? 380 : 230, height: 100, alignment: .leading)
            .clipped()
            .background(focused ? .black.opacity(0.46) : .black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(focused ? BleeckerPalette.dark.sea : .white.opacity(0.04), lineWidth: focused ? 3 : 1)
            }
            .overlay(alignment: .leading) {
                if focused {
                    Capsule().fill(channel.tone.color).frame(width: 4).padding(.vertical, 18)
                }
            }
            .shadow(color: focused ? .black.opacity(0.42) : .clear, radius: 18, y: 10)
        }
        .buttonStyle(SabellaTVChannelButtonStyle())
        .focusEffectDisabled()
        .foregroundStyle(.white)
        .onChange(of: focused) { _, value in if value { highlight() } }
        .animation(.easeOut(duration: 0.22), value: focused)
    }

    private var mediumIcon: String {
        switch medium {
        case .radio: "waveform"
        case .television: "play.tv.fill"
        case .automatic: "antenna.radiowaves.left.and.right"
        }
    }
}

private struct SabellaTVChannelButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

public struct SabellaTVNavigationItem<Value: Hashable>: Identifiable {
    public let value: Value
    public let title: String
    public var id: Value { value }

    public init(_ value: Value, title: String) {
        self.value = value
        self.title = title
    }
}

public struct SabellaTVNavigationBar<Value: Hashable>: View {
    @Binding private var selection: Value
    private let items: [SabellaTVNavigationItem<Value>]
    private let focusedItem: FocusState<Value?>.Binding
    private let requestContentFocus: () -> Void
    @Namespace private var selectionNamespace

    public init(
        selection: Binding<Value>,
        items: [SabellaTVNavigationItem<Value>],
        focusedItem: FocusState<Value?>.Binding,
        requestContentFocus: @escaping () -> Void = {}
    ) {
        _selection = selection
        self.items = items
        self.focusedItem = focusedItem
        self.requestContentFocus = requestContentFocus
    }

    public var body: some View {
        HStack(spacing: 36) {
            ForEach(items) { item in
                Button { selection = item.value } label: {
                    Text(item.title)
                        .font(BleeckerTypography.primary(25, weight: selection == item.value ? .bold : .medium))
                        .foregroundStyle(selection == item.value ? .white : .white.opacity(0.62))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            focusedItem.wrappedValue == item.value ? .white.opacity(0.13) : .clear,
                            in: Capsule()
                        )
                }
                    .buttonStyle(SabellaTVChannelButtonStyle())
                    .focusEffectDisabled()
                    .focused(focusedItem, equals: item.value)
                    .onMoveCommand { direction in
                        guard direction == .down else { return }
                        requestContentFocus()
                    }
                    .padding(.vertical, 8)
                    .overlay(alignment: .bottom) {
                        if selection == item.value {
                            Capsule().fill(BleeckerPalette.dark.sea).frame(height: 4)
                                .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                        }
                    }
                    .animation(.easeOut(duration: BleeckerDuration.control), value: focusedItem.wrappedValue)
            }
        }
        .focusSection()
    }
}

public struct SabellaTVHero<Background: View, Actions: View>: View {
    private let eyebrow: String
    private let title: String
    private let synopsis: String
    private let metadata: [String]
    @ViewBuilder private let background: Background
    @ViewBuilder private let actions: Actions

    public init(
        eyebrow: String,
        title: String,
        synopsis: String,
        metadata: [String] = [],
        @ViewBuilder background: () -> Background,
        @ViewBuilder actions: () -> Actions
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.synopsis = synopsis
        self.metadata = metadata
        self.background = background()
        self.actions = actions()
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            background
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.08), .black.opacity(0.9)],
                        startPoint: .trailing,
                        endPoint: .leading
                    )
                }
            VStack(alignment: .leading, spacing: 18) {
                Text(eyebrow.uppercased())
                    .font(BleeckerTypography.primary(17, weight: .bold))
                    .tracking(2.2)
                    .foregroundStyle(BleeckerPalette.dark.desert)
                Text(title)
                    .font(BleeckerTypography.primary(58, weight: .bold))
                    .lineLimit(2)
                HStack(spacing: 12) {
                    ForEach(metadata, id: \.self) { value in
                        Text(value).font(BleeckerTypography.secondary(20, weight: .medium))
                    }
                }
                .foregroundStyle(.white.opacity(0.76))
                Text(synopsis)
                    .font(BleeckerTypography.secondary(23))
                    .foregroundStyle(.white.opacity(0.84))
                    .lineLimit(3)
                    .frame(maxWidth: 690, alignment: .leading)
                HStack(spacing: 22) { actions }
                    .padding(.top, 8)
                    .focusSection()
            }
            .padding(56)
        }
        .frame(height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

public struct SabellaTVPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(BleeckerTypography.primary(24, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 26)
            .frame(minHeight: 62)
            .background(
                focused ? BleeckerPalette.dark.deepSea.opacity(0.98) : .white.opacity(0.13),
                in: Capsule()
            )
            .overlay {
                Capsule().strokeBorder(
                    focused ? BleeckerPalette.dark.sea : .white.opacity(0.08),
                    lineWidth: focused ? 3 : 1
                )
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .shadow(color: focused ? BleeckerPalette.dark.sea.opacity(0.2) : .clear, radius: 14, y: 6)
            .animation(.easeOut(duration: BleeckerDuration.control), value: focused)
    }
}

public struct SabellaTVCard<Artwork: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var focused: Bool
    private let title: String
    private let subtitle: String
    private let width: CGFloat
    private let artworkRatio: SabellaTVArtworkRatio
    private let context: String?
    private let progress: Double?
    private let enabled: Bool
    private let action: () -> Void
    @ViewBuilder private let artwork: Artwork

    public init(
        title: String,
        subtitle: String,
        width: CGFloat = 330,
        artworkRatio: SabellaTVArtworkRatio = .landscape,
        context: String? = nil,
        progress: Double? = nil,
        enabled: Bool = true,
        action: @escaping () -> Void,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.title = title
        self.subtitle = subtitle
        self.width = width
        self.artworkRatio = artworkRatio
        self.context = context
        self.progress = progress
        self.enabled = enabled
        self.action = action
        self.artwork = artwork()
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                artwork
                    .frame(width: width, height: width * artworkRatio.ratio)
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(alignment: .topLeading) {
                        if let context {
                            SabellaTVContextBadge(context)
                                .padding(14)
                        }
                    }
                    .overlay(alignment: .bottom) {
                        if let progress {
                            GeometryReader { geometry in
                                Capsule()
                                    .fill(.white.opacity(0.32))
                                    .overlay(alignment: .leading) {
                                        Capsule()
                                            .fill(BleeckerPalette.dark.sea)
                                            .frame(width: geometry.size.width * min(max(progress, 0), 1))
                                    }
                            }
                            .frame(height: 7)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 12)
                        }
                    }
                Text(title)
                    .font(BleeckerTypography.primary(24, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(BleeckerTypography.secondary(20))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
            .padding(12)
            .background(focused ? .white.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 24))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(focused ? BleeckerPalette.dark.sea : .clear, lineWidth: 3)
            }
            .shadow(color: focused ? BleeckerPalette.dark.sea.opacity(0.2) : .clear, radius: 18, y: 8)
        }
        .buttonStyle(.plain)
        .focused($focused)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.46)
        .frame(width: width + 32)
        .animation(reduceMotion ? nil : .easeOut(duration: BleeckerDuration.enter), value: focused)
        .accessibilityLabel("\(title), \(subtitle)")
    }
}

public struct SabellaTVEditorialRail<Item: Identifiable, Card: View>: View {
    private let eyebrow: String
    private let title: String
    private let summary: String
    private let items: [Item]
    private let card: (Item) -> Card

    public init(
        eyebrow: String,
        title: String,
        summary: String,
        items: [Item],
        @ViewBuilder card: @escaping (Item) -> Card
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.summary = summary
        self.items = items
        self.card = card
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(eyebrow.uppercased())
                .font(BleeckerTypography.primary(16, weight: .bold))
                .tracking(2)
                .foregroundStyle(BleeckerPalette.dark.desert)
            Text(title).font(BleeckerTypography.primary(38, weight: .bold))
            Text(summary)
                .font(BleeckerTypography.secondary(20))
                .foregroundStyle(.white.opacity(0.68))
                .frame(maxWidth: 780, alignment: .leading)
            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) { ForEach(items) { item in card(item) } }
                    .scrollTargetLayout()
                    .padding(.vertical, 30)
                    .padding(.horizontal, 12)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .focusSection()
        }
    }
}

public struct SabellaTVShelf<Item: Identifiable, Card: View>: View {
    private let title: String
    private let items: [Item]
    private let card: (Item) -> Card

    public init(_ title: String, items: [Item], @ViewBuilder card: @escaping (Item) -> Card) {
        self.title = title
        self.items = items
        self.card = card
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title).font(BleeckerTypography.primary(32, weight: .bold))
            ScrollView(.horizontal) {
                LazyHStack(spacing: 40) {
                    ForEach(items) { item in card(item) }
                }
                .scrollTargetLayout()
                .padding(.vertical, 28)
                .padding(.horizontal, 12)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            .focusSection()
        }
    }
}

public struct SabellaTVPlaybackOverlay: View {
    @Binding private var isPlaying: Bool
    private let title: String
    private let subtitle: String
    private let elapsed: TimeInterval
    private let duration: TimeInterval
    private let isLive: Bool
    private let skipBackward: () -> Void
    private let skipForward: () -> Void

    public init(
        title: String,
        subtitle: String,
        isPlaying: Binding<Bool>,
        elapsed: TimeInterval,
        duration: TimeInterval,
        isLive: Bool = false,
        skipBackward: @escaping () -> Void = {},
        skipForward: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        _isPlaying = isPlaying
        self.elapsed = elapsed
        self.duration = duration
        self.isLive = isLive
        self.skipBackward = skipBackward
        self.skipForward = skipForward
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(BleeckerTypography.primary(34, weight: .bold))
                Text(subtitle).font(BleeckerTypography.secondary(20)).foregroundStyle(.white.opacity(0.68))
            }
            if isLive {
                SabellaTVContextBadge("LIVE", systemImage: "dot.radiowaves.left.and.right")
            } else {
                ProgressView(value: elapsed, total: max(duration, 1))
                    .tint(BleeckerPalette.dark.sea)
                    .scaleEffect(y: 1.8)
                HStack {
                    Text(elapsed.formattedDuration)
                    Spacer()
                    Text(duration.formattedDuration)
                }
                .font(BleeckerTypography.mono(17, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
            }
            HStack(spacing: 28) {
                if !isLive {
                    Button(action: skipBackward) { Label("Back 10", systemImage: "gobackward.10") }
                }
                Button { isPlaying.toggle() } label: {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                }
                if !isLive {
                    Button(action: skipForward) { Label("Forward 10", systemImage: "goforward.10") }
                }
            }
            .buttonStyle(SabellaTVPrimaryButtonStyle())
            .focusSection()
        }
        .padding(42)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 28))
        .onPlayPauseCommand { isPlaying.toggle() }
    }
}

private extension TimeInterval {
    var formattedDuration: String {
        let seconds = max(0, Int(self))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
#endif
