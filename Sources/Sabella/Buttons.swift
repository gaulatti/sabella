import SwiftUI

public struct BleeckerButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    public let variant: BleeckerButtonVariant
    public let size: BleeckerButtonSize

    public init(_ variant: BleeckerButtonVariant = .primary, size: BleeckerButtonSize = .md) {
        self.variant = variant
        self.size = size
    }

    public func makeBody(configuration: Configuration) -> some View {
        let palette = BleeckerPalette.resolve(scheme)
        configuration.label
            .font(BleeckerTypography.primary(fontSize, weight: .medium))
            .foregroundStyle(foreground(palette))
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: variant == .link ? nil : height)
            .background(background(palette, pressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.button, style: .continuous))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.button).strokeBorder(border(palette), lineWidth: 1) }
            .offset(y: configuration.isPressed ? 1 : 0)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.easeOut(duration: BleeckerDuration.control), value: configuration.isPressed)
    }

    private var height: CGFloat { switch size { case .xs: 28; case .sm: 36; case .md: 40; case .lg: 48 } }
    private var horizontalPadding: CGFloat { switch size { case .xs: 10; case .sm: 14; case .md: 18; case .lg: 24 } }
    private var fontSize: CGFloat { switch size { case .xs: 12; case .sm: 13; case .md: 14; case .lg: 15 } }

    private func foreground(_ p: BleeckerPalette) -> Color {
        switch variant {
        case .primary: p.primaryForeground
        case .outline: p.sea
        case .destructive: p.destructiveForeground
        default: p.textPrimary
        }
    }

    private func background(_ p: BleeckerPalette, pressed: Bool) -> Color {
        switch variant {
        case .primary: pressed ? p.deepSea : p.primary
        case .secondary: pressed ? p.muted : p.card
        case .outline: pressed ? p.sea.opacity(0.08) : .clear
        case .subtle: pressed ? p.sand.opacity(0.3) : p.lightSand.opacity(0.75)
        case .ghost, .link: pressed ? p.muted : .clear
        case .destructive: pressed ? p.destructive.opacity(0.9) : p.destructive
        }
    }

    private func border(_ p: BleeckerPalette) -> Color {
        switch variant {
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
    let action: () -> Void

    public init(_ systemImage: String, accessibilityLabel: String, size: BleeckerIconButtonSize = .md, variant: BleeckerIconButtonVariant = .default, action: @escaping () -> Void) {
        self.systemImage = systemImage; self.accessibilityLabel = accessibilityLabel; self.size = size; self.variant = variant; self.action = action
    }

    public var body: some View {
        Button(action: action) { Image(systemName: systemImage).frame(width: edge, height: edge) }
            .buttonStyle(BleeckerButtonStyle(buttonVariant, size: buttonSize))
            .accessibilityLabel(accessibilityLabel)
    }

    private var edge: CGFloat { switch size { case .sm: 12; case .md: 16; case .lg: 20 } }
    private var buttonSize: BleeckerButtonSize { switch size { case .sm: .xs; case .md: .sm; case .lg: .md } }
    private var buttonVariant: BleeckerButtonVariant { switch variant { case .default: .secondary; case .subtle: .subtle; case .ghost: .ghost } }
}

public struct BleeckerButtonGroup<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    public init(spacing: CGFloat = BleeckerSpacing.inline, @ViewBuilder content: () -> Content) { self.spacing = spacing; self.content = content() }
    public var body: some View { HStack(spacing: spacing) { content } }
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
                    .font(BleeckerTypography.primary(13, weight: .medium))
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
