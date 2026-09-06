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
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(context.date, format: .dateTime.hour().minute().second())
                        .font(BleeckerTypography.mono(22, weight: .medium))
                        .tracking(1.2)
                        .foregroundStyle(BleeckerPalette.dark.textSecondary)
                }
            }
        }
        .frame(minHeight: 76)
        .accessibilityElement(children: .contain)
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

public struct SabellaTVChannelHome: View {
    private let productName: String
    private let state: SabellaTVChannelHomeState
    private let retry: () -> Void
    private let select: (SabellaTVChannelGroupSummary) -> Void

    public init(
        productName: String,
        state: SabellaTVChannelHomeState,
        retry: @escaping () -> Void,
        select: @escaping (SabellaTVChannelGroupSummary) -> Void
    ) {
        self.productName = productName
        self.state = state
        self.retry = retry
        self.select = select
    }

    public var body: some View {
        SabellaTVChromeScreen(productName: productName) {
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
                SabellaTVChannelGroupBrowser(groups: groups, select: select)
                    .padding(.horizontal, 84)
                    .padding(.bottom, 44)
            }
        }
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
                        if let title, !title.isEmpty {
                            Text(title)
                                .font(BleeckerTypography.secondary(31, weight: .medium))
                                .foregroundStyle(.white.opacity(0.76))
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
                    .frame(width: 650, alignment: .leading)
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
                Text(title).font(BleeckerTypography.primary(48, weight: .bold)).multilineTextAlignment(.center)
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
