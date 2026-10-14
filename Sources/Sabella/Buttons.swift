import SwiftUI

private struct BleeckerJoinedButtonsKey: EnvironmentKey {
    static let defaultValue = false
}

private struct BleeckerIconEdgeKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

extension EnvironmentValues {
    var bleeckerJoinedButtons: Bool {
        get { self[BleeckerJoinedButtonsKey.self] }
        set { self[BleeckerJoinedButtonsKey.self] = newValue }
    }
    var bleeckerIconEdge: CGFloat? {
        get { self[BleeckerIconEdgeKey.self] }
        set { self[BleeckerIconEdgeKey.self] = newValue }
    }
}

public struct BleeckerButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.bleeckerTextScale) private var textScale
    @Environment(\.bleeckerJoinedButtons) private var joined
    @Environment(\.bleeckerIconEdge) private var iconEdge
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    public let variant: BleeckerButtonVariant
    public let size: BleeckerButtonSize

    public init(_ variant: BleeckerButtonVariant = .primary, size: BleeckerButtonSize = .md) {
        self.variant = variant
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        let palette = BleeckerPalette.resolve(scheme)
        configuration.label
            .font(BleeckerTypography.primary(fontSize * textScale, weight: .medium))
            .foregroundStyle(foreground(palette, role: configuration.role))
            .padding(.horizontal, iconEdge == nil ? horizontalPadding : 0)
            .frame(minWidth: iconEdge, maxWidth: iconEdge,
                   minHeight: iconEdge ?? (variant == .link ? nil : height), maxHeight: iconEdge)
            .background(background(palette, pressed: configuration.isPressed, role: configuration.role))
            .clipShape(RoundedRectangle(cornerRadius: joined ? 0 : BleeckerRadius.button, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: joined ? 0 : BleeckerRadius.button).strokeBorder(border(palette, role: configuration.role), lineWidth: 1) }
            .offset(y: configuration.isPressed && !joined && !reduceMotion ? 1 : 0)
            .scaleEffect(configuration.isPressed && !joined && !reduceMotion ? 0.99 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(reduceMotion ? nil : .easeOut(duration: BleeckerDuration.control), value: configuration.isPressed)
    }

    private var height: CGFloat { switch size { case .xs: 28; case .sm: 36; case .md: 40; case .lg: 48 } }
    private var horizontalPadding: CGFloat { switch size { case .xs: 10; case .sm: 14; case .md: 18; case .lg: 24 } }
    private var fontSize: CGFloat { switch size { case .xs: 12; case .sm: 13; case .md: 14; case .lg: 15 } }

    private func foreground(_ p: BleeckerPalette, role: ButtonRole?) -> Color {
        if role == .destructive && variant != .destructive { return p.destructive }
        return switch variant {
        case .primary: p.primaryForeground
        case .outline: p.sea
        case .destructive: p.destructiveForeground
        default: p.textPrimary
        }
    }

    private func background(_ p: BleeckerPalette, pressed: Bool, role: ButtonRole?) -> Color {
        if role == .destructive && variant != .destructive {
            return pressed ? p.destructive.opacity(0.08) : p.card
        }
        return switch variant {
        case .primary: pressed ? p.deepSea : p.primary
        case .secondary: pressed ? p.muted : p.card
        case .outline: pressed ? p.sea.opacity(0.08) : .clear
        case .subtle: pressed ? p.sand.opacity(0.3) : p.lightSand.opacity(0.75)
        case .ghost, .link: pressed ? p.muted : .clear
        case .destructive: pressed ? p.destructive.opacity(0.9) : p.destructive
        }
    }

    private func border(_ p: BleeckerPalette, role: ButtonRole?) -> Color {
        if role == .destructive && variant != .destructive { return p.destructive.opacity(0.35) }
        return switch variant {
        case .primary: p.primary
        case .secondary: p.border
        case .outline: p.sea.opacity(0.5)
        case .destructive: p.destructive
        default: .clear
        }
    }
}

public struct BleeckerButton<Label: View>: View {
    let variant: BleeckerButtonVariant
    let size: BleeckerButtonSize
    let loading: Bool
    let action: () -> Void
    @ViewBuilder let label: Label

    public init(
        variant: BleeckerButtonVariant = .primary,
        size: BleeckerButtonSize = .md,
        loading: Bool = false,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.variant = variant; self.size = size; self.loading = loading; self.action = action; self.label = label()
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: BleeckerSpacing.inline) {
                if loading {
#if os(tvOS)
                    ProgressView()
#else
                    ProgressView().controlSize(.small)
#endif
                }
                label
            }
        }
        .buttonStyle(BleeckerButtonStyle(variant, size: size))
        .disabled(loading)
    }
}

public struct BleeckerIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    let size: BleeckerIconButtonSize
    let variant: BleeckerIconButtonVariant
    let role: ButtonRole?
    let loading: Bool
    let action: () -> Void

    public init(_ systemImage: String, accessibilityLabel: String, size: BleeckerIconButtonSize = .md, variant: BleeckerIconButtonVariant = .default, role: ButtonRole? = nil, loading: Bool = false, action: @escaping () -> Void) {
        self.systemImage = systemImage; self.accessibilityLabel = accessibilityLabel; self.size = size; self.variant = variant; self.role = role; self.loading = loading; self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            Group {
                if loading {
#if os(tvOS)
                    ProgressView()
#else
                    ProgressView().controlSize(.small)
#endif
                }
                else { Image(systemName: systemImage).font(.system(size: glyphSize)) }
            }
        }
            .buttonStyle(BleeckerButtonStyle(buttonVariant, size: buttonSize))
            .environment(\.bleeckerIconEdge, edge)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue(loading ? "In progress" : "")
            .disabled(loading)
    }

    private var edge: CGFloat { switch size { case .sm: 32; case .md: 40; case .lg: 44 } }
    private var glyphSize: CGFloat { switch size { case .sm: 16; case .md: 18; case .lg: 20 } }
    private var buttonSize: BleeckerButtonSize { switch size { case .sm: .xs; case .md: .sm; case .lg: .md } }
    private var buttonVariant: BleeckerButtonVariant { switch variant { case .default: .secondary; case .subtle: .subtle; case .ghost: .ghost } }
}

public struct BleeckerButtonGroup<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let spacing: CGFloat
    @ViewBuilder let content: Content
    public init(spacing: CGFloat = -1, @ViewBuilder content: () -> Content) { self.spacing = spacing; self.content = content() }
    public var body: some View {
        Group {
            if spacing <= 0 {
                HStack(spacing: spacing) { content }
                    .environment(\.bleeckerJoinedButtons, true)
                    .clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.button))
                    .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.button).strokeBorder(BleeckerPalette.resolve(scheme).border) }
            } else {
                HStack(spacing: spacing) { content }
            }
        }
        .accessibilityElement(children: .contain)
    }
}

public struct BleeckerToggleStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    let selected: Bool
    let variant: BleeckerToggleVariant
    public init(selected: Bool, variant: BleeckerToggleVariant = .default) { self.selected = selected; self.variant = variant }
    public func makeBody(configuration: Configuration) -> some View {
        let p = BleeckerPalette.resolve(scheme)
        configuration.label
            .foregroundStyle(selected ? p.primaryForeground : p.textSecondary)
            .padding(.horizontal, 12).frame(minHeight: 34)
            .background(selected ? p.primary : (configuration.isPressed ? p.muted : .clear))
            .clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.button))
            .overlay { if variant == .outline { RoundedRectangle(cornerRadius: BleeckerRadius.button).strokeBorder(p.border) } }
    }
}

public struct BleeckerSegmentedControl<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var selection: Value
    let options: [BleeckerSelectOption<Value>]
    public init(selection: Binding<Value>, options: [BleeckerSelectOption<Value>]) { _selection = selection; self.options = options }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        HStack(spacing: 2) {
            ForEach(options) { option in
                Button(option.label) { selection = option.value }
                    .bleeckerFont(.primary, size: 13, weight: .medium)
                    .foregroundStyle(selection == option.value ? p.sea : p.textSecondary)
                    .padding(.horizontal, 12).frame(minHeight: 32)
                    .background(selection == option.value ? p.card : .clear)
                    .clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.button))
                    .buttonStyle(.plain).disabled(option.disabled)
            }
        }
        .padding(4).background(p.muted.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 9))
        .overlay { RoundedRectangle(cornerRadius: 9).strokeBorder(p.border) }
    }
}
