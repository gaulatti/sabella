#if os(tvOS)
import SwiftUI
import UIKit
import AVFoundation

public enum SabellaTVDVRAction: Hashable, Sendable {
    case none, play, pause, rewind, fastForward
}

public struct SabellaTVPlayerSurface: UIViewRepresentable {
    private let player: AVPlayer
    private let gravity: AVLayerVideoGravity
    public init(player: AVPlayer, gravity: AVLayerVideoGravity = .resizeAspect) { self.player = player; self.gravity = gravity }
    public func makeUIView(context: Context) -> PlayerView { let view = PlayerView(); view.playerLayer.player = player; view.playerLayer.videoGravity = gravity; return view }
    public func updateUIView(_ view: PlayerView, context: Context) { view.playerLayer.player = player; view.playerLayer.videoGravity = gravity }
    public final class PlayerView: UIView {
        public override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

public struct SabellaTVDVROverlay: View {
    private let currentTime: Double
    private let duration: Double
    private let quality: String?
    private let action: SabellaTVDVRAction

    public init(currentTime: Double, duration: Double, quality: String? = nil, action: SabellaTVDVRAction = .none) {
        self.currentTime = currentTime
        self.duration = duration
        self.quality = quality
        self.action = action
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack {
                Spacer()
                HStack(spacing: 24) {
                    Text(isLive ? "LIVE" : formatted(currentTime))
                        .font(BleeckerTypography.mono(22, weight: isLive ? .bold : .regular))
                        .foregroundStyle(isLive ? BleeckerPalette.dark.live : .white)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule().fill(.white.opacity(0.22)).frame(height: 8)
                            Capsule().fill(isLive ? BleeckerPalette.dark.live : BleeckerPalette.dark.sea)
                                .frame(width: max(8, proxy.size.width * progress), height: 8)
                        }
                    }
                    .frame(height: 8)
                    if !isLive {
                        Text(formatted(duration)).font(BleeckerTypography.mono(22)).foregroundStyle(.white.opacity(0.7))
                    }
                    if let quality {
                        Text(quality).font(BleeckerTypography.mono(15, weight: .bold))
                            .foregroundStyle(.white.opacity(0.62)).padding(.horizontal, 9).padding(.vertical, 4)
                            .overlay { RoundedRectangle(cornerRadius: 6).strokeBorder(.white.opacity(0.28)) }
                    }
                }
                .padding(.horizontal, 72).padding(.vertical, 34)
                .background(.black.opacity(0.68))
            }
            if action != .none {
                Image(systemName: actionImage).font(.system(size: 92, weight: .medium)).foregroundStyle(.white.opacity(0.86))
            }
        }
    }

    private var isLive: Bool { duration <= 0 }
    private var progress: CGFloat { isLive ? 1 : min(1, max(0, currentTime / duration)) }
    private var actionImage: String {
        switch action {
        case .none: "circle"
        case .play: "play.fill"
        case .pause: "pause.fill"
        case .rewind: "backward.end.fill"
        case .fastForward: "forward.end.fill"
        }
    }
    private func formatted(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds > 0 else { return "00:00" }
        let total = Int(seconds), hours = Int(seconds) / 3600
        return hours > 0 ? String(format: "%d:%02d:%02d", hours, total % 3600 / 60, total % 60) : String(format: "%02d:%02d", total / 60, total % 60)
    }
}

public struct SabellaTVQuadLayout<Cell: View>: View {
    private let expandedIndex: Int?
    private let spacing: CGFloat
    private let cell: (Int) -> Cell

    public init(expandedIndex: Int? = nil, spacing: CGFloat = 6, @ViewBuilder cell: @escaping (Int) -> Cell) {
        self.expandedIndex = expandedIndex
        self.spacing = spacing
        self.cell = cell
    }

    public var body: some View {
        Group {
            if let expandedIndex { cell(expandedIndex) }
            else {
                VStack(spacing: spacing) {
                    HStack(spacing: spacing) { cell(0); cell(1) }
                    HStack(spacing: spacing) { cell(2); cell(3) }
                }
            }
        }
        .background(BleeckerPalette.dark.border)
        .ignoresSafeArea()
    }
}

public struct SabellaTVBroadcastCell<Content: View, Placeholder: View>: View {
    private let selected: Bool
    private let selectionColor: Color
    private let failure: String?
    private let buffering: Bool
    private let content: Content
    private let placeholder: Placeholder

    public init(selected: Bool, selectionColor: Color = BleeckerPalette.dark.sea, failure: String? = nil, buffering: Bool = false, @ViewBuilder content: () -> Content, @ViewBuilder placeholder: () -> Placeholder) {
        self.selected = selected
        self.selectionColor = selectionColor
        self.failure = failure
        self.buffering = buffering
        self.content = content()
        self.placeholder = placeholder()
    }

    public var body: some View {
        ZStack {
            Color.black
            content
            placeholder
            if let failure {
                BleeckerPalette.dark.accentOxblood.opacity(0.88)
                VStack(spacing: 12) {
                    SabellaTVSectionLabel("Signal unavailable")
                    Text(failure).font(BleeckerTypography.primary(27, weight: .semibold)).multilineTextAlignment(.center)
                }.padding(24)
            } else if buffering {
                ProgressView().scaleEffect(1.35).tint(.white)
            }
        }
        .clipped()
        .overlay { if selected { Rectangle().strokeBorder(selectionColor, lineWidth: 6).allowsHitTesting(false) } }
    }
}

public struct SabellaTVTestPattern: View {
    private let title: String
    private let logoURL: URL?
    private let audioLevel: () -> Float

    public init(title: String, logoURL: URL? = nil, audioLevel: @escaping () -> Float = { 0 }) {
        self.title = title
        self.logoURL = logoURL
        self.audioLevel = audioLevel
    }

    public var body: some View {
        GeometryReader { proxy in
            TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
                Canvas { context, size in draw(context, size, timeline.date, audioLevel()) }
            }
            VStack(spacing: 12) {
                if let logoURL {
                    AsyncImage(url: logoURL) { image in image.resizable().scaledToFit() } placeholder: { BleeckerBrandMark() }
                } else { BleeckerBrandMark() }
                Text(title).font(BleeckerTypography.secondary(18)).foregroundStyle(.black).multilineTextAlignment(.center)
            }
            .padding(18).frame(width: 220, height: 150)
            .background(.white.opacity(0.92))
            .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
        }
    }

    private func draw(_ context: GraphicsContext, _ size: CGSize, _ date: Date, _ level: Float) {
        let dark = Color(white: 0.09)
        context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Color(white: 0.78)))
        var grid = Path()
        for step in 1...5 {
            grid.move(to: CGPoint(x: 0, y: size.height * CGFloat(step) / 6)); grid.addLine(to: CGPoint(x: size.width, y: size.height * CGFloat(step) / 6))
            grid.move(to: CGPoint(x: size.width * CGFloat(step) / 6, y: 0)); grid.addLine(to: CGPoint(x: size.width * CGFloat(step) / 6, y: size.height))
        }
        context.stroke(grid, with: .color(.black.opacity(0.24)))
        context.fill(Path(CGRect(x: 0, y: 0, width: size.width, height: size.height * 0.08)), with: .color(dark))
        context.draw(Text(date, format: .dateTime.weekday().month().day()).font(BleeckerTypography.mono(min(size.width, size.height) * 0.038)).foregroundStyle(.white), at: CGPoint(x: size.width * 0.03, y: size.height * 0.04), anchor: .leading)
        context.draw(Text(date, format: .dateTime.hour().minute().second()).font(BleeckerTypography.mono(min(size.width, size.height) * 0.038)).foregroundStyle(.white), at: CGPoint(x: size.width * 0.97, y: size.height * 0.04), anchor: .trailing)
        let colors = [BleeckerPalette.dark.accentYellow, Color.cyan, BleeckerPalette.dark.live, Color.purple, BleeckerPalette.dark.accentRed, BleeckerPalette.dark.sea]
        let width = size.width * 0.095, start = (size.width - width * CGFloat(colors.count)) / 2
        for (index, color) in colors.enumerated() { context.fill(Path(CGRect(x: start + width * CGFloat(index), y: size.height * 0.08, width: width, height: size.height * 0.1)), with: .color(color)) }
        let meter = min(1, max(0, CGFloat(level)))
        context.fill(Path(CGRect(x: 0, y: size.height * (1 - meter), width: size.width * 0.014, height: size.height * meter)), with: .color(meter > 0.9 ? BleeckerPalette.dark.accentRed : meter > 0.7 ? BleeckerPalette.dark.desert : BleeckerPalette.dark.live))
    }
}

public struct SabellaTVEmergencyHeader: View {
    public init() {}
    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ZStack {
                HStack {
                    Text(context.date, format: .dateTime.month(.wide).day().year()).font(BleeckerTypography.primary(24, weight: .bold))
                    Spacer()
                    Text(context.date, format: .dateTime.hour().minute().second()).font(BleeckerTypography.mono(27, weight: .bold))
                }.padding(.horizontal, 48)
                BleeckerBrandMark().frame(width: 42, height: 42).foregroundStyle(.white)
            }.foregroundStyle(.white).padding(.vertical, 8)
        }
    }
}

public struct SabellaTVCarouselDots<ID: Hashable>: View {
    private let items: [ID]
    private let active: Set<ID>
    public init(items: [ID], active: Set<ID>) { self.items = items; self.active = active }
    public var body: some View {
        HStack(spacing: 10) { ForEach(items, id: \.self) { item in Circle().fill(.white.opacity(active.contains(item) ? 1 : 0.38)).frame(width: active.contains(item) ? 8 : 6, height: active.contains(item) ? 8 : 6) } }
    }
}

public struct SabellaTVEmergencyLayout<Channels: View, Ticker: View>: View {
    private let allOffline: Bool
    private let channels: Channels
    private let ticker: Ticker
    public init(allOffline: Bool, @ViewBuilder channels: () -> Channels, @ViewBuilder ticker: () -> Ticker) { self.allOffline = allOffline; self.channels = channels(); self.ticker = ticker() }
    public var body: some View {
        GeometryReader { proxy in
            let channelHeight = min(proxy.size.width / 2 * 9 / 16, proxy.size.height - 144)
            ZStack(alignment: .top) {
                LinearGradient(colors: [Color.hex(0xB81122), Color.hex(0x660512), Color.hex(0x1F0006)], startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
                SabellaTVEmergencyHeader().frame(height: 64).offset(y: max(0, ((proxy.size.height - channelHeight) / 2 - 64) / 2))
                channels.frame(width: proxy.size.width, height: channelHeight).position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                if allOffline {
                    VStack(spacing: 12) { Text("ALL ASSIGNED FEEDS OFFLINE").font(BleeckerTypography.primary(30, weight: .bold)); Text("Automatic recovery checks are running").font(BleeckerTypography.secondary(20, weight: .medium)) }
                        .foregroundStyle(.white).padding(.horizontal, 32).padding(.vertical, 24).background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 12)).position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
                ticker.frame(width: proxy.size.width, height: 48).clipped().position(x: proxy.size.width / 2, y: proxy.size.height - 24)
            }
        }.ignoresSafeArea()
    }
}

public struct SabellaTVMarquee: UIViewRepresentable {
    private let items: [String]
    public init(items: [String]) { self.items = items }
    public func makeUIView(context: Context) -> MarqueeView { let view = MarqueeView(); view.setItems(items); return view }
    public func updateUIView(_ view: MarqueeView, context: Context) { view.setItems(items) }
    public static func dismantleUIView(_ view: MarqueeView, coordinator: ()) { view.stop() }

    @MainActor public final class MarqueeView: UIView {
        private let label = UILabel()
        private var items: [String] = []
        private var width: CGFloat = 0
        public override init(frame: CGRect) { super.init(frame: frame); clipsToBounds = true; addSubview(label) }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        public override func layoutSubviews() { super.layoutSubviews(); label.frame = CGRect(x: 0, y: (bounds.height - label.intrinsicContentSize.height) / 2, width: max(width * 2, 1), height: label.intrinsicContentSize.height); if width > 0, label.layer.animationKeys()?.isEmpty != false { animate() } }
        func setItems(_ newItems: [String]) {
            guard !newItems.isEmpty, newItems != items else { return }
            items = newItems; stop()
            let text = newItems.joined(separator: "     ◆     ") + "     ◆     "
            let attributes: [NSAttributedString.Key: Any] = [.font: UIFont(name: "EncodeSans-Regular", size: 20) ?? UIFont.systemFont(ofSize: 20), .foregroundColor: UIColor.white]
            let cycle = NSAttributedString(string: text, attributes: attributes)
            let doubled = NSMutableAttributedString(attributedString: cycle); doubled.append(cycle); label.attributedText = doubled
            width = ceil(cycle.size().width); setNeedsLayout()
        }
        func stop() { label.layer.removeAllAnimations(); label.transform = .identity }
        private func animate() {
            label.transform = .identity
            UIView.animate(withDuration: max(1, width / 60), delay: 0, options: [.curveLinear, .repeat, .allowUserInteraction]) { self.label.transform = CGAffineTransform(translationX: -self.width, y: 0) }
        }
    }
}
#endif
