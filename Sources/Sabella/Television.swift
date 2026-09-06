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

public struct SabellaTVScreen<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    @ViewBuilder private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let palette = BleeckerPalette.resolve(scheme)
        ZStack {
            LinearGradient(
                colors: [palette.background, palette.deepSea.opacity(0.7), .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            content
                .safeAreaPadding(.horizontal, 72)
                .safeAreaPadding(.vertical, 44)
        }
        .foregroundStyle(palette.textPrimary)
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
    private let action: () -> Void
    @ViewBuilder private let artwork: Artwork

    public init(
        title: String,
        subtitle: String,
        width: CGFloat = 330,
        action: @escaping () -> Void,
        @ViewBuilder artwork: () -> Artwork
    ) {
        self.title = title
        self.subtitle = subtitle
        self.width = width
        self.action = action
        self.artwork = artwork()
    }

    public var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                artwork
                    .frame(width: width, height: width * 0.56)
                    .clipped()
                    .overlay(alignment: .bottomLeading) {
                        LinearGradient(colors: [.clear, .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                Text(title)
                    .font(BleeckerTypography.primary(24, weight: .semibold))
                    .lineLimit(1)
                Text(subtitle)
                    .font(BleeckerTypography.secondary(18))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
            .frame(width: width, alignment: .leading)
            .padding(12)
            .background(focused ? .white.opacity(0.13) : .clear, in: RoundedRectangle(cornerRadius: 24))
            .scaleEffect(focused ? 1.09 : 1)
            .shadow(color: focused ? .black.opacity(0.62) : .clear, radius: 30, y: 16)
        }
        .buttonStyle(.plain)
        .focused($focused)
        .zIndex(focused ? 1 : 0)
        .animation(reduceMotion ? nil : .easeOut(duration: BleeckerDuration.enter), value: focused)
        .accessibilityLabel("\(title), \(subtitle)")
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
                LazyHStack(spacing: 30) {
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
    private let skipBackward: () -> Void
    private let skipForward: () -> Void

    public init(
        title: String,
        subtitle: String,
        isPlaying: Binding<Bool>,
        elapsed: TimeInterval,
        duration: TimeInterval,
        skipBackward: @escaping () -> Void = {},
        skipForward: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        _isPlaying = isPlaying
        self.elapsed = elapsed
        self.duration = duration
        self.skipBackward = skipBackward
        self.skipForward = skipForward
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(BleeckerTypography.primary(34, weight: .bold))
                Text(subtitle).font(BleeckerTypography.secondary(20)).foregroundStyle(.white.opacity(0.68))
            }
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
            HStack(spacing: 28) {
                Button(action: skipBackward) { Label("Back 10", systemImage: "gobackward.10") }
                Button { isPlaying.toggle() } label: {
                    Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                }
                Button(action: skipForward) { Label("Forward 10", systemImage: "goforward.10") }
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
