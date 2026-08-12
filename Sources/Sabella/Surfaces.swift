import SwiftUI

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
