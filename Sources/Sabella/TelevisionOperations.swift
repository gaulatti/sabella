#if os(tvOS)
import SwiftUI

public struct SabellaTVAmbientBackground: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let animated: Bool
    @State private var phase = false

    public init(animated: Bool = true) {
        self.animated = animated
    }

    public var body: some View {
        let palette = BleeckerPalette.resolve(scheme)
        LinearGradient(
            colors: [
                palette.background,
                palette.deepSea.opacity(phase ? 0.92 : 0.58),
                palette.sea.opacity(phase ? 0.18 : 0.08),
                palette.background,
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .onAppear {
            guard animated, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) { phase = true }
        }
    }
}

public struct SabellaTVChromeHeader: View {
    private let productName: String
    private let showsClock: Bool

    public init(productName: String, showsClock: Bool = true) {
        self.productName = productName
        self.showsClock = showsClock
    }

    public var body: some View {
        HStack {
            BleeckerBrandLockup(name: productName)
            Spacer()
            if showsClock {
                SabellaTVClock()
            }
        }
        .frame(minHeight: 76)
        .accessibilityElement(children: .contain)
    }
}

public struct SabellaTVClock: View {
    public init() {}

    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            Text(context.date, format: .dateTime.hour().minute().second())
                .font(BleeckerTypography.mono(22, weight: .medium))
                .tracking(1.2)
                .foregroundStyle(BleeckerPalette.dark.textSecondary)
        }
        .accessibilityLabel("Current time")
    }
}

public struct SabellaTVNavigationHeader<Value: Hashable, Utilities: View>: View {
    private let productName: String
    @Binding private var selection: Value
    private let items: [SabellaTVNavigationItem<Value>]
    private let utilities: Utilities
    @Binding private var focusRequested: Bool
    @Binding private var contentFocusRequested: Bool
    @FocusState private var focusedItem: Value?

    public init(
        productName: String,
        selection: Binding<Value>,
        items: [SabellaTVNavigationItem<Value>],
        focusRequested: Binding<Bool> = .constant(false),
        contentFocusRequested: Binding<Bool> = .constant(false),
        @ViewBuilder utilities: () -> Utilities
    ) {
        self.productName = productName
        _selection = selection
        self.items = items
        _focusRequested = focusRequested
        _contentFocusRequested = contentFocusRequested
        self.utilities = utilities()
    }

    public var body: some View {
        HStack(spacing: 32) {
            BleeckerBrandLockup(name: productName)
            Spacer(minLength: 52)
            SabellaTVNavigationBar(
                selection: $selection,
                items: items,
                focusedItem: $focusedItem,
                requestContentFocus: {
                    focusedItem = nil
                    contentFocusRequested = true
                }
            )
            Spacer(minLength: 52)
            utilities
        }
        .frame(minHeight: 76)
        .accessibilityElement(children: .contain)
        .onChange(of: focusRequested) { _, requested in
            guard requested else { return }
            focusedItem = items.contains(where: { $0.value == selection })
                ? selection
                : items.first?.value
            focusRequested = false
        }
    }
}

public struct SabellaTVUserButton: View {
    private let selected: Bool
    private let action: () -> Void

    public init(selected: Bool, action: @escaping () -> Void) {
        self.selected = selected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 29, weight: .semibold))
                .foregroundStyle(selected ? .white : .white.opacity(0.72))
                .frame(width: 58, height: 58)
        }
        .buttonStyle(SabellaTVHeaderButtonStyle(selected: selected))
        .focusEffectDisabled()
        .accessibilityLabel("User and settings")
    }
}

private struct SabellaTVHeaderButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused
    let selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(focused ? BleeckerPalette.dark.deepSea : .clear, in: Circle())
            .overlay {
                Circle().strokeBorder(
                    focused || selected ? BleeckerPalette.dark.sea : .clear,
                    lineWidth: focused ? 3 : 2
                )
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
    }
}

public struct SabellaTVChromeScreen<Content: View>: View {
    private let productName: String
    private let content: Content

    public init(productName: String, @ViewBuilder content: () -> Content) {
        self.productName = productName
        self.content = content()
    }

    public var body: some View {
        ZStack {
            SabellaTVAmbientBackground()
            VStack(spacing: 0) {
                SabellaTVChromeHeader(productName: productName)
                    .padding(.horizontal, 84)
                    .padding(.top, 38)
                    .padding(.bottom, 22)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}

public enum SabellaTVChannelHomeState {
    case loading
    case failed(message: String)
    case empty
    case ready([SabellaTVChannelGroupSummary])
}

public enum SabellaTVChannelBrowserPage: Hashable, Sendable {
    case home
    case channels
    case user
}

public struct SabellaTVUserAction: Identifiable, Hashable, Sendable {
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

public struct SabellaTVChannelHome: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let productName: String
    private let state: SabellaTVChannelHomeState
    @Binding private var page: SabellaTVChannelBrowserPage
    @Binding private var focusedGroupID: String?
    private let userName: String?
    private let userDetail: String
    private let userActions: [SabellaTVUserAction]
    private let retry: () -> Void
    private let selectUserAction: (SabellaTVUserAction) -> Void
    private let select: (SabellaTVChannelGroupSummary) -> Void
    @State private var headerFocusRequested = false
    @State private var contentFocusRequested = false

    public init(
        productName: String,
        state: SabellaTVChannelHomeState,
        page: Binding<SabellaTVChannelBrowserPage>,
        focusedGroupID: Binding<String?>,
        userName: String?,
        userDetail: String,
        userActions: [SabellaTVUserAction],
        retry: @escaping () -> Void,
        selectUserAction: @escaping (SabellaTVUserAction) -> Void,
        select: @escaping (SabellaTVChannelGroupSummary) -> Void
    ) {
        self.productName = productName
        self.state = state
        _page = page
        _focusedGroupID = focusedGroupID
        self.userName = userName
        self.userDetail = userDetail
        self.userActions = userActions
        self.retry = retry
        self.selectUserAction = selectUserAction
        self.select = select
    }

    public var body: some View {
        ZStack {
            SabellaTVAmbientBackground()
            VStack(spacing: 0) {
                SabellaTVNavigationHeader(
                    productName: productName,
                    selection: $page,
                    items: [
                        SabellaTVNavigationItem(.home, title: "Home"),
                        SabellaTVNavigationItem(.channels, title: "Channels"),
                    ],
                    focusRequested: $headerFocusRequested,
                    contentFocusRequested: $contentFocusRequested
                ) {
                    HStack(spacing: 24) {
                        SabellaTVClock()
                        SabellaTVUserButton(selected: page == .user) { page = .user }
                    }
                }
                .padding(.horizontal, 84)
                .frame(height: 132)

                channelContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 84)
                    .padding(.bottom, 44)
                    .clipped()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.34), value: page)
        .onExitCommand {
            if page != .home { page = .home }
        }
    }

    @ViewBuilder
    private var channelContent: some View {
        switch state {
        case .loading:
            SabellaTVLoadingState("Loading channel groups…")
        case let .failed(message):
            SabellaTVChannelHomeMessage(
                eyebrow: "Connection",
                icon: "wifi.exclamationmark",
                title: "Channel groups unavailable",
                message: message,
                actionTitle: "Try again",
                action: retry
            )
        case .empty:
            SabellaTVChannelHomeMessage(
                eyebrow: "Your television",
                icon: "rectangle.3.group",
                title: "No channel groups yet",
                message: "Create a channel group in Celesti to start watching.",
                actionTitle: nil,
                action: retry
            )
        case let .ready(groups):
            switch page {
            case .home:
                SabellaTVChannelGroupBrowser(
                    groups: groups,
                    focusedGroupID: $focusedGroupID,
                    headerFocusRequested: $headerFocusRequested,
                    contentFocusRequested: $contentFocusRequested,
                    browseAll: { page = .channels },
                    select: select
                )
                .transition(.opacity)
            case .channels:
                SabellaTVChannelGroupDirectory(
                    groups: groups,
                    focusedGroupID: $focusedGroupID,
                    headerFocusRequested: $headerFocusRequested,
                    contentFocusRequested: $contentFocusRequested,
                    select: select
                )
                .transition(.opacity)
            case .user:
                SabellaTVUserSettings(
                    name: userName,
                    detail: userDetail,
                    actions: userActions,
                    headerFocusRequested: $headerFocusRequested,
                    select: selectUserAction
                )
                .transition(.opacity)
            }
        }
    }
}

public struct SabellaTVUserSettings: View {
    private let name: String?
    private let detail: String
    private let actions: [SabellaTVUserAction]
    @Binding private var headerFocusRequested: Bool
    private let select: (SabellaTVUserAction) -> Void
    @FocusState private var focusedActionID: String?

    public init(
        name: String?,
        detail: String,
        actions: [SabellaTVUserAction],
        headerFocusRequested: Binding<Bool> = .constant(false),
        select: @escaping (SabellaTVUserAction) -> Void
    ) {
        self.name = name
        self.detail = detail
        self.actions = actions
        _headerFocusRequested = headerFocusRequested
        self.select = select
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 76) {
            VStack(alignment: .leading, spacing: 18) {
                SabellaTVSectionLabel("User and settings")
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 112, weight: .light))
                    .foregroundStyle(BleeckerPalette.dark.sea)
                    .padding(.top, 20)
                if let displayName {
                    Text(displayName)
                        .font(BleeckerTypography.primary(44, weight: .bold))
                } else {
                    Text("Name unavailable")
                        .font(BleeckerTypography.primary(34, weight: .bold))
                        .foregroundStyle(BleeckerPalette.dark.textSecondary)
                }
                Text(detail)
                    .font(BleeckerTypography.secondary(21))
                    .foregroundStyle(BleeckerPalette.dark.textSecondary)
            }
            .frame(width: 470, alignment: .leading)

            VStack(alignment: .leading, spacing: 18) {
                Text("Actions")
                    .font(BleeckerTypography.primary(30, weight: .bold))
                ForEach(actions) { action in
                    Button { select(action) } label: {
                        HStack(spacing: 18) {
                            Image(systemName: action.systemImage)
                                .font(.system(size: 28, weight: .semibold))
                                .frame(width: 48)
                            VStack(alignment: .leading, spacing: 5) {
                                Text(action.title)
                                    .font(BleeckerTypography.primary(25, weight: .bold))
                                Text(action.subtitle)
                                    .font(BleeckerTypography.secondary(19))
                                    .foregroundStyle(BleeckerPalette.dark.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .frame(width: 640)
                        .frame(minHeight: 88)
                    }
                    .buttonStyle(SabellaTVSettingsButtonStyle())
                    .focusEffectDisabled()
                    .focused($focusedActionID, equals: action.id)
                    .onMoveCommand { direction in
                        guard direction == .up, action.id == actions.first?.id else { return }
                        focusedActionID = nil
                        headerFocusRequested = true
                    }
                }
            }
        }
        .padding(.horizontal, 72)
        .padding(.top, 54)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task {
            await Task.yield()
            focusedActionID = actions.first?.id
        }
    }

    private var displayName: String? {
        guard let name else { return nil }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private struct SabellaTVSettingsButtonStyle: ButtonStyle {
    @Environment(\.isFocused) private var focused

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                focused ? BleeckerPalette.dark.deepSea : .white.opacity(0.07),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(focused ? BleeckerPalette.dark.sea : .white.opacity(0.08), lineWidth: focused ? 3 : 1)
            }
            .opacity(configuration.isPressed ? 0.84 : 1)
    }
}

private struct SabellaTVChannelHomeMessage: View {
    let eyebrow: String
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: () -> Void

    var body: some View {
        HStack(spacing: 70) {
            VStack(alignment: .leading, spacing: 22) {
                SabellaTVSectionLabel(eyebrow)
                Text(title)
                    .font(BleeckerTypography.primary(58, weight: .bold))
                    .tracking(-1)
                Text(message)
                    .font(BleeckerTypography.secondary(26))
                    .foregroundStyle(BleeckerPalette.dark.textSecondary)
                    .frame(maxWidth: 720, alignment: .leading)
                if let actionTitle {
                    Button(actionTitle, action: action)
                        .buttonStyle(SabellaTVPrimaryButtonStyle())
                        .padding(.top, 18)
                }
            }
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 190, weight: .ultraLight))
                .foregroundStyle(BleeckerPalette.dark.sea.opacity(0.48))
                .frame(width: 440, height: 440)
                .background(BleeckerPalette.dark.deepSea.opacity(0.46), in: Circle())
        }
        .padding(.horizontal, 118)
        .padding(.bottom, 70)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

public struct SabellaTVStatusPill: View {
    private let text: String
    private let color: Color

    public init(_ text: String, color: Color) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 11) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text)
                .font(BleeckerTypography.mono(15, weight: .bold))
                .tracking(1.4)
        }
        .foregroundStyle(BleeckerPalette.dark.textPrimary.opacity(0.86))
        .padding(.horizontal, 18)
        .frame(minHeight: 38)
        .background(.black.opacity(0.58), in: Capsule())
        .overlay { Capsule().strokeBorder(.white.opacity(0.12)) }
        .accessibilityElement(children: .combine)
    }
}

public struct SabellaTVSectionLabel: View {
    private let text: String

    public init(_ text: String) { self.text = text }

    public var body: some View {
        Text(text.uppercased())
            .font(BleeckerTypography.mono(16, weight: .bold))
            .tracking(4.5)
            .foregroundStyle(BleeckerPalette.dark.sea)
    }
}

public struct SabellaTVPanelModifier: ViewModifier {
    private let radius: CGFloat

    public init(radius: CGFloat = 30) { self.radius = radius }

    public func body(content: Content) -> some View {
        content
            .background(.black.opacity(0.28), in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(.white.opacity(0.1), lineWidth: 1.5) }
    }
}

public extension View {
    func sabellaTVPanel(radius: CGFloat = 30) -> some View {
        modifier(SabellaTVPanelModifier(radius: radius))
    }
}

public struct SabellaTVLoadingState: View {
    private let message: String

    public init(_ message: String) { self.message = message }

    public var body: some View {
        VStack(spacing: 22) {
            ProgressView().scaleEffect(1.45).tint(BleeckerPalette.dark.sea)
            Text(message)
                .font(BleeckerTypography.secondary(28, weight: .medium))
                .foregroundStyle(BleeckerPalette.dark.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct SabellaTVRegistration<Code: View>: View {
    private let deviceID: String
    private let code: Code
    private let demo: () -> Void
    public init(deviceID: String, demo: @escaping () -> Void, @ViewBuilder code: () -> Code) { self.deviceID = deviceID; self.demo = demo; self.code = code() }
    public var body: some View {
        HStack(spacing: 72) {
            VStack(alignment: .leading, spacing: 24) {
                SabellaTVSectionLabel("Device link")
                Text(deviceID).font(BleeckerTypography.primary(84, weight: .semibold))
                Text("Enter this code in the app to register this device").font(BleeckerTypography.secondary(34)).foregroundStyle(BleeckerPalette.dark.textSecondary)
                Button("Demo Mode", action: demo).buttonStyle(SabellaTVPrimaryButtonStyle()).padding(.top, 22)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(54).sabellaTVPanel()
            VStack(spacing: 28) {
                SabellaTVSectionLabel("Quick register")
                code.frame(width: 360, height: 360).padding(27).background(.white, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                Text("Scan to register").font(BleeckerTypography.secondary(28)).foregroundStyle(BleeckerPalette.dark.textSecondary)
            }.frame(maxWidth: .infinity).padding(54).sabellaTVPanel()
        }.padding(.horizontal, 96).padding(.vertical, 48).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

public struct SabellaTVStandby: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let deviceID: String
    private let nickname: String?
    @State private var pulse = false
    public init(deviceID: String, nickname: String? = nil) { self.deviceID = deviceID; self.nickname = nickname }
    public var body: some View {
        ZStack {
            Circle().fill(RadialGradient(colors: [BleeckerPalette.dark.sea.opacity(pulse ? 0.34 : 0.08), .clear], center: .center, startRadius: 18, endRadius: 390)).frame(width: 690, height: 690).scaleEffect(pulse ? 1.18 : 1)
            VStack(spacing: 28) {
                SabellaTVSectionLabel("System")
                Text("Standby").font(BleeckerTypography.primary(78, weight: .semibold))
                if let nickname, !nickname.isEmpty { Text(nickname).font(BleeckerTypography.primary(46, weight: .medium)) }
                Text(deviceID).font(BleeckerTypography.mono(25, weight: .medium)).foregroundStyle(BleeckerPalette.dark.textSecondary)
                SabellaTVStatusPill("READY", color: BleeckerPalette.dark.live).padding(.top, 12)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity).onAppear { guard !reduceMotion else { return }; withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { pulse = true } }
    }
}

public struct SabellaTVDemoOverlay: View {
    private let productName: String
    private let buffering: Bool
    public init(productName: String, buffering: Bool) { self.productName = productName; self.buffering = buffering }
    public var body: some View {
        VStack(spacing: 18) {
            SabellaTVChromeHeader(productName: productName)
            HStack { SabellaTVStatusPill(buffering ? "DEMO BUFFERING" : "DEMO LIVE", color: buffering ? BleeckerPalette.dark.desert : BleeckerPalette.dark.live); Spacer() }
            Spacer()
        }.padding(.horizontal, 84).padding(.top, 38)
        .background(LinearGradient(colors: [BleeckerPalette.dark.background.opacity(0.95), BleeckerPalette.dark.background.opacity(0.62), .clear], startPoint: .top, endPoint: .bottom).frame(maxHeight: 430), alignment: .top)
    }
}

public struct SabellaTVSignalVisualizer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let active: Bool
    private let buffering: Bool

    public init(active: Bool, buffering: Bool = false) {
        self.active = active
        self.buffering = buffering
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion || !active)) { timeline in
            Canvas { context, size in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                let count = 28
                let gap: CGFloat = 5
                let width = max(2, (size.width - gap * CGFloat(count - 1)) / CGFloat(count))
                for index in 0..<count {
                    let wave = (sin(phase * 3.2 + Double(index) * 0.68) + 1) / 2
                    let envelope = sin(Double(index + 1) / Double(count + 1) * .pi)
                    let energy = buffering ? 0.22 : 0.76
                    let height = max(4, size.height * CGFloat(0.08 + wave * envelope * energy))
                    let rect = CGRect(x: CGFloat(index) * (width + gap), y: size.height - height, width: width, height: height)
                    context.fill(Path(roundedRect: rect, cornerRadius: width / 2), with: .color(BleeckerPalette.dark.sunset.opacity(0.42 + wave * 0.4)))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

public struct SabellaTVRadioNowPlaying: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let station: String
    private let title: String?
    private let buffering: Bool
    private let active: Bool
    private let mark: String
    private let tone: SabellaTVChannelTone

    public init(
        station: String,
        title: String? = nil,
        buffering: Bool = false,
        active: Bool = true,
        mark: String? = nil,
        tone: SabellaTVChannelTone = .gold
    ) {
        self.station = station
        self.title = title
        self.buffering = buffering
        self.active = active
        self.mark = mark ?? String(station.prefix(3)).uppercased()
        self.tone = tone
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: reduceMotion || !active)) { timeline in
            let phase = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                LinearGradient(
                    colors: [BleeckerPalette.dark.deepSea, tone.color.opacity(0.72), .black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Canvas { context, size in
                    for index in 0..<7 {
                        let offset = CGFloat(index) * 68
                        let pulse = reduceMotion ? 0.5 : (sin(phase * 1.25 + Double(index) * 0.8) + 1) / 2
                        let diameter = min(size.width, size.height) * (0.28 + CGFloat(pulse) * 0.18) + offset
                        let rect = CGRect(
                            x: size.width * 0.72 - diameter / 2,
                            y: size.height * 0.5 - diameter / 2,
                            width: diameter,
                            height: diameter
                        )
                        context.stroke(Path(ellipseIn: rect), with: .color(.white.opacity(0.045)), lineWidth: 18)
                    }
                }
                .blur(radius: 1)

                HStack(spacing: 72) {
                    ZStack {
                        Circle().fill(.black.opacity(0.34))
                        Circle().stroke(.white.opacity(0.14), lineWidth: 2)
                        Text(mark)
                            .font(BleeckerTypography.primary(94, weight: .bold))
                            .tracking(-3)
                            .foregroundStyle(tone.color)
                    }
                    .frame(width: 330, height: 330)
                    .shadow(color: .black.opacity(0.45), radius: 48, y: 24)

                    VStack(alignment: .leading, spacing: 14) {
                        Label("LIVE RADIO", systemImage: "waveform")
                            .font(BleeckerTypography.mono(17, weight: .bold))
                            .tracking(2)
                            .foregroundStyle(BleeckerPalette.dark.accentGold)
                        Text(station)
                            .font(BleeckerTypography.primary(58, weight: .bold))
                            .tracking(-1)
                            .lineLimit(2)
                            .truncationMode(.tail)
                            .allowsTightening(true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let title, !title.isEmpty {
                            Text(title)
                                .font(BleeckerTypography.secondary(31, weight: .medium))
                                .foregroundStyle(.white.opacity(0.76))
                                .lineLimit(2)
                                .truncationMode(.tail)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        HStack(spacing: 10) {
                            Circle()
                                .fill(buffering ? BleeckerPalette.dark.desert : active ? BleeckerPalette.dark.live : BleeckerPalette.dark.textSecondary)
                                .frame(width: 10, height: 10)
                            Text(buffering ? "BUFFERING" : active ? "ON AIR" : "PAUSED")
                        }
                        .font(BleeckerTypography.mono(15, weight: .bold))
                        .foregroundStyle(.white.opacity(0.68))
                        .padding(.top, 12)
                    }
                    .frame(width: 650, height: 390, alignment: .leading)
                    .clipped()
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(station), live radio, \(title ?? ""), \(active ? "playing" : "paused")")
    }
}

public struct SabellaTVPlaybackFailure: View {
    private let title: String
    private let message: String
    private let retry: () -> Void

    public init(title: String, message: String, retry: @escaping () -> Void) {
        self.title = title
        self.message = message
        self.retry = retry
    }

    public var body: some View {
        ZStack {
            BleeckerPalette.dark.accentOxblood
            VStack(spacing: 22) {
                Image(systemName: "antenna.radiowaves.left.and.right.slash").font(.system(size: 64))
                SabellaTVSectionLabel("Signal unavailable")
                Text(title)
                    .font(BleeckerTypography.primary(48, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .allowsTightening(true)
                    .frame(maxWidth: 920)
                Text(message).font(BleeckerTypography.secondary(24)).foregroundStyle(.white.opacity(0.72))
                Button("Retry", action: retry).buttonStyle(SabellaTVPrimaryButtonStyle())
            }
            .padding(52)
        }
        .foregroundStyle(.white)
    }
}

public struct SabellaTVCallsignOverlay: View {
    private let nickname: String?
    private let deviceCode: String
    @State private var opacity: Double = 0

    public init(nickname: String? = nil, deviceCode: String) {
        self.nickname = nickname
        self.deviceCode = deviceCode
    }

    public var body: some View {
        GeometryReader { proxy in
            let hasNickname = nickname?.isEmpty == false
            ZStack(alignment: .bottom) {
                Rectangle().strokeBorder(BleeckerPalette.dark.sunset.opacity(0.9), lineWidth: 5)
                    .shadow(color: BleeckerPalette.dark.sunset.opacity(0.7), radius: 18).padding(3)
                ZStack(alignment: .bottom) {
                    LinearGradient(colors: [.clear, .black.opacity(0.88), .black.opacity(0.98)], startPoint: .top, endPoint: .bottom)
                    VStack(spacing: 15) {
                        if let nickname, !nickname.isEmpty {
                            Text(nickname).font(BleeckerTypography.primary(48, weight: .bold)).multilineTextAlignment(.center).lineLimit(2).minimumScaleFactor(0.6)
                        }
                        Text(deviceCode.uppercased()).font(BleeckerTypography.mono(22, weight: .semibold)).tracking(3)
                            .padding(.horizontal, 24).padding(.vertical, 10).background(.black.opacity(0.45), in: Capsule()).overlay { Capsule().strokeBorder(.white.opacity(0.22)) }
                    }.padding(.horizontal, 120).padding(.bottom, 58)
                }.frame(height: max(hasNickname ? 330 : 260, proxy.size.height * 0.31))
            }.ignoresSafeArea()
        }
        .foregroundStyle(.white).opacity(opacity).allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { opacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { withAnimation(.easeIn(duration: 4)) { opacity = 0 } }
        }
    }
}
#endif
