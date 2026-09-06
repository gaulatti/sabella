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

public struct SabellaTVChannel: Identifiable, Hashable, Sendable {
    public let id: String
    public let streamURL: URL
    public let number: String
    public let name: String
    public let mark: String
    public let now: String
    public let next: String
    public let progress: Double
    public let currentTime: String?
    public let nextTime: String?

    public init(
        id: String,
        streamURL: URL,
        number: String,
        name: String,
        mark: String? = nil,
        now: String,
        next: String,
        progress: Double,
        currentTime: String? = nil,
        nextTime: String? = nil
    ) {
        self.id = id
        self.streamURL = streamURL
        self.number = number
        self.name = name
        self.mark = mark ?? String(name.prefix(3)).uppercased()
        self.now = now
        self.next = next
        self.progress = progress
        self.currentTime = currentTime
        self.nextTime = nextTime
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
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .background(.black.opacity(0.72), in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

public struct SabellaTVChannelGuide: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let channels: [SabellaTVChannel]
    private let selection: String
    private let select: (SabellaTVChannel) -> Void
    private let isPlaying: Bool
    private let isMuted: Bool
    private let togglePlayback: (() -> Void)?
    private let toggleMute: (() -> Void)?
    @State private var highlightedID: String

    public init(
        channels: [SabellaTVChannel],
        selection: String,
        isPlaying: Bool = true,
        isMuted: Bool = false,
        togglePlayback: (() -> Void)? = nil,
        toggleMute: (() -> Void)? = nil,
        select: @escaping (SabellaTVChannel) -> Void
    ) {
        precondition(!channels.isEmpty, "SabellaTVChannelGuide requires at least one channel")
        self.channels = channels
        self.selection = selection
        self.isPlaying = isPlaying
        self.isMuted = isMuted
        self.togglePlayback = togglePlayback
        self.toggleMute = toggleMute
        self.select = select
        _highlightedID = State(initialValue: selection)
    }

    public var body: some View {
        GeometryReader { proxy in
            let channel = highlightedChannel
            ZStack(alignment: .topLeading) {
                Color.black.opacity(0.34)
                LinearGradient(
                    colors: [.black.opacity(0.72), .black.opacity(0.34), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    colors: [.clear, .black.opacity(0.68)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 6) {
                    Label("All Channels (\(channels.count))", systemImage: "chevron.left")
                        .font(BleeckerTypography.primary(30, weight: .semibold))
                    Text("Up / Down to browse · Select to tune")
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
                                    tuned: selection == item.id,
                                    highlight: { highlightedID = item.id },
                                    select: { select(item) }
                                )
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 320)
                    }
                    .scrollIndicators(.hidden)
                    .frame(width: 390, height: min(proxy.size.height - 190, 760))
                    .position(x: 195, y: proxy.size.height * 0.69)
                    .task { scrollProxy.scrollTo(selection, anchor: .center) }
                    .onChange(of: highlightedID) { _, id in
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.28)) {
                            scrollProxy.scrollTo(id, anchor: .center)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(channel.now)
                        .font(BleeckerTypography.primary(48, weight: .medium))
                        .tracking(-0.7)
                        .lineLimit(2)
                    Text(channel.name)
                        .font(BleeckerTypography.secondary(25, weight: .medium))
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
                .frame(width: 620, alignment: .leading)
                .position(x: 740, y: proxy.size.height * 0.55)
                .id(channel.id)
                .transition(.opacity)

                VStack(alignment: .leading, spacing: 8) {
                    Text("UP NEXT")
                        .font(BleeckerTypography.primary(16, weight: .semibold))
                        .tracking(0.7)
                    Text(channel.next)
                        .font(BleeckerTypography.primary(24, weight: .semibold))
                        .lineLimit(2)
                    if let nextTime = channel.nextTime {
                        Text(nextTime)
                            .font(BleeckerTypography.secondary(19))
                            .foregroundStyle(.white.opacity(0.74))
                    }
                    GeometryReader { bar in
                        Capsule().fill(.white.opacity(0.15))
                        Capsule().fill(.white)
                            .frame(width: bar.size.width * min(max(channel.progress, 0), 1))
                    }
                    .frame(width: 220, height: 5)
                    .padding(.top, 12)
                }
                .frame(width: 286, alignment: .leading)
                .position(x: proxy.size.width - 190, y: proxy.size.height * 0.59)
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.24), value: highlightedID)
        }
        .accessibilityElement(children: .contain)
        .focusSection()
    }

    private var highlightedChannel: SabellaTVChannel {
        channels.first { $0.id == highlightedID } ?? channels.first { $0.id == selection } ?? channels[0]
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
    @FocusState private var focused: Bool
    let channel: SabellaTVChannel
    let tuned: Bool
    let highlight: () -> Void
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 14) {
                Text(channel.number)
                    .font(BleeckerTypography.mono(17, weight: .semibold))
                    .foregroundStyle(.white.opacity(focused ? 0.92 : 0.52))
                    .frame(width: 52)
                Text(channel.mark)
                    .font(BleeckerTypography.primary(focused ? 24 : 20, weight: .bold))
                    .tracking(-0.4)
                    .frame(width: focused ? 76 : 68)
                if focused {
                    VStack(alignment: .leading) {
                        Text(channel.name)
                            .font(BleeckerTypography.secondary(20, weight: .semibold))
                            .lineLimit(1)
                    }
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
            .frame(width: focused ? 380 : 230, height: focused ? 118 : 86, alignment: .leading)
            .background(focused ? .black.opacity(0.46) : .black.opacity(0.28), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(focused ? .white.opacity(0.9) : .white.opacity(0.04), lineWidth: focused ? 3 : 1)
            }
            .shadow(color: focused ? .black.opacity(0.42) : .clear, radius: 18, y: 10)
        }
        .buttonStyle(SabellaTVChannelButtonStyle())
        .focusEffectDisabled()
        .focused($focused)
        .foregroundStyle(.white)
        .onChange(of: focused) { _, value in if value { highlight() } }
        .animation(.easeOut(duration: 0.22), value: focused)
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
    @Namespace private var selectionNamespace

    public init(selection: Binding<Value>, items: [SabellaTVNavigationItem<Value>]) {
        _selection = selection
        self.items = items
    }

    public var body: some View {
        HStack(spacing: 36) {
            ForEach(items) { item in
                Button(item.title) { selection = item.value }
                    .font(BleeckerTypography.primary(25, weight: selection == item.value ? .bold : .medium))
                    .foregroundStyle(selection == item.value ? .white : .white.opacity(0.62))
                    .buttonStyle(.plain)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) {
                        if selection == item.value {
                            Capsule().fill(BleeckerPalette.dark.sea).frame(height: 4)
                                .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                        }
                    }
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
            .foregroundStyle(focused ? BleeckerPalette.dark.deepSea : .white)
            .padding(.horizontal, 32)
            .frame(minHeight: 68)
            .background(focused ? .white : .white.opacity(0.16), in: Capsule())
            .scaleEffect(focused ? 1.08 : configuration.isPressed ? 0.97 : 1)
            .shadow(color: focused ? .black.opacity(0.45) : .clear, radius: 24, y: 12)
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
    private let action: () -> Void
    @ViewBuilder private let artwork: Artwork

    public init(
        title: String,
        subtitle: String,
        width: CGFloat = 330,
        artworkRatio: SabellaTVArtworkRatio = .landscape,
        context: String? = nil,
        progress: Double? = nil,
        action: @escaping () -> Void,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.title = title
        self.subtitle = subtitle
        self.width = width
        self.artworkRatio = artworkRatio
        self.context = context
        self.progress = progress
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
            .scaleEffect(focused ? 1.045 : 1)
            .shadow(color: focused ? .black.opacity(0.62) : .clear, radius: 30, y: 16)
        }
        .buttonStyle(.plain)
        .focused($focused)
        .frame(width: width + 32)
        .zIndex(focused ? 1 : 0)
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
