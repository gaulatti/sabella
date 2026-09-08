import SwiftUI

public struct BleeckerStatusBadge: View {
    @Environment(\.colorScheme) private var scheme
    let text: String
    let variant: BleeckerStatusBadgeVariant
    public init(_ text: String, variant: BleeckerStatusBadgeVariant = .default) { self.text = text; self.variant = variant }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        HStack(spacing: 6) { Circle().fill(color(p)).frame(width: 6, height: 6); Text(text) }
            .font(BleeckerTypography.primary(11, weight: .semibold)).foregroundStyle(color(p))
            .padding(.horizontal, 9).frame(minHeight: 24).background(color(p).opacity(0.1)).clipShape(Capsule())
    }
    private func color(_ p: BleeckerPalette) -> Color { switch variant { case .live: p.live; case .offline: p.textSecondary; case .warning: p.desert; case .info: p.sea; case .default: p.textPrimary } }
}

public struct BleeckerAlert<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let type: BleeckerAlertType
    let title: String
    @ViewBuilder let content: Content
    public init(_ title: String, type: BleeckerAlertType = .info, @ViewBuilder content: () -> Content) { self.title = title; self.type = type; self.content = content() }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme); let c = color(p)
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon).foregroundStyle(c).padding(.top, 1)
            VStack(alignment: .leading, spacing: 4) { Text(title).font(BleeckerTypography.primary(14, weight: .semibold)); content.font(BleeckerTypography.secondary(13)) }
        }.foregroundStyle(p.textPrimary).padding(14).background(c.opacity(0.09)).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(c.opacity(0.24)) }
    }
    private var icon: String { switch type { case .success: "checkmark.circle.fill"; case .error: "exclamationmark.triangle.fill"; case .info: "info.circle.fill"; case .warning: "exclamationmark.circle.fill" } }
    private func color(_ p: BleeckerPalette) -> Color { switch type { case .success: p.live; case .error: p.destructive; case .info: p.sea; case .warning: p.desert } }
}

public struct BleeckerProgress: View {
    @Environment(\.colorScheme) private var scheme
    let value: Double
    let size: BleeckerProgressSize
    let variant: BleeckerProgressVariant
    public init(value: Double, size: BleeckerProgressSize = .md, variant: BleeckerProgressVariant = .default) { self.value = value; self.size = size; self.variant = variant }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        GeometryReader { proxy in ZStack(alignment: .leading) { Capsule().fill(p.muted); Capsule().fill(color(p)).frame(width: proxy.size.width * min(max(value, 0), 1)) } }
            .frame(height: height).animation(.easeOut(duration: BleeckerDuration.standard), value: value)
    }
    private var height: CGFloat { switch size { case .sm: 4; case .md: 7; case .lg: 10 } }
    private func color(_ p: BleeckerPalette) -> Color { switch variant { case .default: p.primary; case .success: p.live; case .warning: p.desert; case .destructive: p.destructive } }
}

public struct BleeckerLoadingSpinner: View {
    let size: BleeckerLoadingSize
    public init(size: BleeckerLoadingSize = .md) { self.size = size }
    public var body: some View {
#if os(tvOS)
        ProgressView()
#else
        ProgressView().controlSize(size == .sm ? .small : size == .lg ? .large : .regular)
#endif
    }
}

public struct BleeckerLoadingOverlay: View {
    @Environment(\.colorScheme) private var scheme
    let message: String
    public init(_ message: String = "Loading…") { self.message = message }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        ZStack { p.background.opacity(0.72).ignoresSafeArea(); VStack(spacing: 12) { BleeckerLoadingSpinner(size: .lg); Text(message).font(BleeckerTypography.primary(14, weight: .medium)) }.padding(24).background(p.card).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.dialog)) }
    }
}

public struct BleeckerEmptyState<Actions: View>: View {
    @Environment(\.colorScheme) private var scheme
    let icon: String; let title: String; let message: String; @ViewBuilder let actions: Actions
    public init(icon: String = "tray", title: String, message: String, @ViewBuilder actions: () -> Actions) { self.icon = icon; self.title = title; self.message = message; self.actions = actions() }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        VStack(spacing: 12) { Image(systemName: icon).font(.system(size: 28)).foregroundStyle(p.sea); Text(title).font(BleeckerTypography.primary(17, weight: .semibold)); Text(message).font(BleeckerTypography.secondary(13)).foregroundStyle(p.textSecondary).multilineTextAlignment(.center); actions }.padding(32)
    }
}

public struct BleeckerNotificationBadge: View {
    let count: Int
    public init(_ count: Int) { self.count = count }
    public var body: some View { Text(count > 99 ? "99+" : count.formatted()).font(BleeckerTypography.primary(10, weight: .bold)).foregroundStyle(.white).padding(.horizontal, 6).frame(minHeight: 18).background(BleeckerPalette.light.destructive).clipShape(Capsule()).accessibilityLabel("\(count) notifications") }
}
