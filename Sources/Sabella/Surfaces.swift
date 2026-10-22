import SwiftUI

public enum BleeckerAttentionDensity: String, CaseIterable, Sendable {
    case compact, comfortable
}

/// The shared category/urgency surface; platform-native child controls retain
/// their own focus and accessibility semantics.
public struct BleeckerAttentionSurface<Content: View>: View {
    let hue: Double
    let intensity: Double
    let density: BleeckerAttentionDensity
    @ViewBuilder let content: Content

    public init(hue: Double, intensity: Double, density: BleeckerAttentionDensity = .comfortable,
                @ViewBuilder content: () -> Content) {
        self.hue = hue
        self.intensity = intensity
        self.density = density
        self.content = content()
    }

    public var body: some View {
        let style = BleeckerAttentionStyle(hue: hue, intensity: intensity)
        // Match the producer's CSS border-radius circular arcs.
        let shape = RoundedRectangle(cornerRadius: 11, style: .circular)
        let gradient = Gradient(stops: [
            .init(color: style.stops[0].color, location: 0),
            .init(color: style.stops[1].color, location: style.middleStop),
            .init(color: style.stops[2].color, location: style.coverage)
        ]).colorSpace(.perceptual)
        content
            // Attention paint is dark in both host appearances. Supply a
            // readable default while retaining explicit child foregrounds.
            .foregroundStyle(BleeckerPalette.dark.textPrimary, BleeckerPalette.dark.textPrimary.opacity(0.9))
            .padding(density == .compact ? 16 : 20)
            .padding(1) // CSS border occupies layout outside the content padding.
            .background {
                GeometryReader { geometry in
                    if geometry.size.width > 2 && geometry.size.height > 2 {
                        // CSS backgrounds originate in the padding box and
                        // repeat into the translucent one-point border.
                        let tileWidth = geometry.size.width - 2
                        let tileHeight = geometry.size.height - 2
                        let extent = (tileWidth + tileHeight) / 4
                        let start = UnitPoint(x: 0.5 - extent / tileWidth,
                                              y: 0.5 + extent / tileHeight)
                        let end = UnitPoint(x: 0.5 + extent / tileWidth,
                                            y: 0.5 - extent / tileHeight)
                        ZStack {
                            if min(geometry.size.width, geometry.size.height) > 60 {
                                // An outer CSS shadow never paints beneath the
                                // translucent border box. Keep its blur canvas
                                // outside the card and cut the card itself out.
                                shape.inset(by: 30).fill(.black.opacity(0.92))
                                    .blur(radius: 19).offset(y: 16)
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                    .padding(80)
                                    .mask {
                                        Rectangle().fill(.white).overlay {
                                            shape.fill(.white).frame(width: geometry.size.width, height: geometry.size.height)
                                                .blendMode(.destinationOut)
                                        }.compositingGroup()
                                    }
                                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                            ZStack {
                                ForEach(-1...1, id: \.self) { column in
                                    ForEach(-1...1, id: \.self) { row in
                                        Rectangle()
                                            .fill(.linearGradient(gradient, startPoint: start, endPoint: end))
                                            .frame(width: tileWidth, height: tileHeight)
                                            .position(x: geometry.size.width / 2 + CGFloat(column) * tileWidth,
                                                      y: geometry.size.height / 2 + CGFloat(row) * tileHeight)
                                    }
                                }
                            }.mask(shape)
                        }
                    }
                }
            }
            .overlay { shape.strokeBorder(style.border.color, lineWidth: 1) }
    }

    public static func accent(hue: Double, intensity: Double) -> Color {
        BleeckerAttentionStyle(hue: hue, intensity: intensity).accent.color
    }

    /// A separate accessibility role for small text on the actual card paint.
    /// It preserves the category accent whenever that paint already passes.
    public static func labelAccent(hue: Double, intensity: Double, scheme: ColorScheme) -> Color {
        let rgb = labelAccentComponents(hue: hue, intensity: intensity, scheme: scheme)
        return Color(.sRGB, red: rgb.red, green: rgb.green, blue: rgb.blue)
    }

    static func labelAccentComponents(hue: Double, intensity: Double,
                                      scheme: ColorScheme) -> (red: Double, green: Double, blue: Double) {
        let background = scheme == .dark ? BleeckerAttentionRGBA(red: 24 / 255, green: 37 / 255, blue: 51 / 255) :
            BleeckerAttentionRGBA(red: 1, green: 1, blue: 1)
        let label = BleeckerAttentionStyle(hue: hue, intensity: intensity).accent.label(on: background)
        return (label.red, label.green, label.blue)
    }
}

public struct BleeckerCard<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let padding: BleeckerCardPadding
    let variant: BleeckerCardVariant
    @ViewBuilder let content: Content

    public init(padding: BleeckerCardPadding = .md, variant: BleeckerCardVariant = .surface, @ViewBuilder content: () -> Content) {
        self.padding = padding; self.variant = variant; self.content = content()
    }

    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        content.padding(insets).background(background(p)).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.card, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.card).strokeBorder(border(p)) }
            .shadow(color: shadow(p), radius: variant == .elevated ? 20 : 10, y: variant == .elevated ? 8 : 3)
    }

    private var insets: EdgeInsets {
        let amount: CGFloat = switch padding { case .none: 0; case .sm: 16; case .md: 24; case .lg: 32 }
        return EdgeInsets(top: amount, leading: amount, bottom: amount, trailing: amount)
    }
    private func background(_ p: BleeckerPalette) -> Color { switch variant { case .subtle: p.lightSand.opacity(0.5); case .transparent: .clear; default: p.card } }
    private func border(_ p: BleeckerPalette) -> Color { variant == .transparent ? .clear : p.border }
    private func shadow(_ p: BleeckerPalette) -> Color { [.surface, .elevated].contains(variant) ? p.deepSea.opacity(scheme == .dark ? 0 : 0.06) : .clear }
}

public struct BleeckerPanel<Content: View>: View {
    let title: String?
    @ViewBuilder let content: Content
    public init(title: String? = nil, @ViewBuilder content: () -> Content) { self.title = title; self.content = content() }
    public var body: some View {
        BleeckerCard {
            VStack(alignment: .leading, spacing: BleeckerSpacing.component) {
                if let title { Text(title).font(BleeckerTypography.primary(16, weight: .semibold)) }
                content
            }
        }
    }
}

public struct BleeckerSeparator: View {
    @Environment(\.colorScheme) private var scheme
    let vertical: Bool
    public init(vertical: Bool = false) { self.vertical = vertical }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        Rectangle().fill(p.border).frame(width: vertical ? 1 : nil, height: vertical ? nil : 1)
    }
}

public struct BleeckerSkeleton: View {
    @Environment(\.colorScheme) private var scheme
    @State private var phase = false
    let radius: CGFloat
    public init(radius: CGFloat = BleeckerRadius.ui) { self.radius = radius }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        RoundedRectangle(cornerRadius: radius).fill(p.muted).opacity(phase ? 0.45 : 0.9)
            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: phase).onAppear { phase = true }
            .accessibilityHidden(true)
    }
}

public struct BleeckerBauhausBackground: View {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(p.background))
            context.opacity = 0.16
            context.fill(Path(ellipseIn: CGRect(x: size.width * 0.72, y: -size.height * 0.18, width: size.height * 0.62, height: size.height * 0.62)), with: .color(p.desert))
            context.fill(Path(CGRect(x: -size.width * 0.08, y: size.height * 0.72, width: size.width * 0.52, height: size.height * 0.18)), with: .color(p.sea))
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
