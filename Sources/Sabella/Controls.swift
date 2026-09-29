import SwiftUI

public struct BleeckerField<Content: View>: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let description: String?
    let error: String?
    let optional: Bool
    @ViewBuilder let content: Content

    public init(_ label: String, description: String? = nil, error: String? = nil, optional: Bool = false, @ViewBuilder content: () -> Content) {
        self.label = label; self.description = description; self.error = error; self.optional = optional; self.content = content()
    }

    public init(label: String, description: String? = nil, error: String? = nil, optional: Bool = false, @ViewBuilder content: () -> Content) {
        self.init(label, description: description, error: error, optional: optional, content: content)
    }

    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).bleeckerFont(.primary, size: 13, weight: .medium).foregroundStyle(p.textPrimary)
                Spacer()
                if optional { Text("Optional").bleeckerFont(.secondary, size: 11).foregroundStyle(p.textSecondary) }
            }
            content
            if let description { Text(description).bleeckerFont(.secondary, size: 12).foregroundStyle(p.textSecondary) }
            if let error { Text(error).bleeckerFont(.secondary, size: 12).foregroundStyle(p.destructive) }
        }
    }
}

public struct BleeckerTextField: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.bleeckerTextScale) private var textScale
    @FocusState private var focused: Bool
    let placeholder: String
    @Binding var text: String
    let systemImage: String?
    let error: Bool
    let size: BleeckerControlSize
    let font: Font?

    public init(placeholder: String, text: Binding<String>, systemImage: String? = nil, error: Bool = false, size: BleeckerControlSize = .md, font: Font? = nil) {
        self.placeholder = placeholder; _text = text; self.systemImage = systemImage; self.error = error; self.size = size; self.font = font
    }

    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        let resolvedFont = font ?? BleeckerTypography.primary((size == .sm ? 12 : 14) * textScale)
        HStack(spacing: 10) {
            if let systemImage { Image(systemName: systemImage).font(.system(size: 14, weight: .medium)).foregroundStyle(p.textSecondary) }
            TextField(placeholder, text: $text).textFieldStyle(.plain).font(resolvedFont).focused($focused)
            if systemImage == "magnifyingglass", !text.isEmpty {
                Button { text = "" } label: { Image(systemName: "xmark").font(.system(size: 10, weight: .bold)) }
                    .buttonStyle(.plain).foregroundStyle(p.textSecondary).padding(4).background(p.muted).clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(.horizontal, horizontalPadding).frame(minHeight: height * textScale)
        .background(isEnabled ? p.card : p.muted.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui))
        .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(error ? p.destructive : focused ? p.sea.opacity(0.75) : p.border, lineWidth: 1) }
        .shadow(color: focused ? p.sea.opacity(0.10) : p.deepSea.opacity(0.025), radius: focused ? 4 : 1, y: 1)
        .opacity(isEnabled ? 1 : 0.6)
        .animation(.easeOut(duration: BleeckerDuration.control), value: focused)
    }

    private var height: CGFloat { switch size { case .sm: 36; case .md: 40; case .lg: 44 } }
    private var horizontalPadding: CGFloat { switch size { case .sm: 12; case .md: 14; case .lg: 16 } }
}

public struct BleeckerSecureField: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.bleeckerTextScale) private var textScale
    @Binding var text: String
    let placeholder: String
    @State private var revealed = false
    public init(_ placeholder: String, text: Binding<String>) { self.placeholder = placeholder; _text = text }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        HStack {
            if revealed { TextField(placeholder, text: $text).textFieldStyle(.plain) }
            else { SecureField(placeholder, text: $text).textFieldStyle(.plain) }
            Button { revealed.toggle() } label: { Image(systemName: revealed ? "eye.slash" : "eye") }.buttonStyle(.plain).foregroundStyle(p.textSecondary)
        }
        .font(BleeckerTypography.primary(14 * textScale))
        .padding(.horizontal, 14)
        .frame(minHeight: 40 * max(1, textScale))
        .bleeckerSurface(radius: BleeckerRadius.ui)
    }
}

public struct BleeckerSearchField: View {
    let placeholder: String
    @Binding var text: String
    public init(placeholder: String, text: Binding<String>) { self.placeholder = placeholder; _text = text }
    public var body: some View { BleeckerTextField(placeholder: placeholder, text: $text, systemImage: "magnifyingglass") }
}

public struct BleeckerTextArea: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.bleeckerTextScale) private var textScale
    @Binding var text: String
    let minHeight: CGFloat
    public init(text: Binding<String>, minHeight: CGFloat = 96) { _text = text; self.minHeight = minHeight }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
#if os(tvOS)
        TextField("", text: $text)
            .font(BleeckerTypography.primary(14 * textScale)).padding(10).frame(minHeight: minHeight).background(p.card)
            .clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(p.border) }
#else
        TextEditor(text: $text).font(BleeckerTypography.primary(14 * textScale)).scrollContentBackground(.hidden)
            .padding(10).frame(minHeight: minHeight).background(p.card).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(p.border) }
#endif
    }
}

public struct BleeckerSelectOption<Value: Hashable>: Identifiable {
    public let value: Value
    public let label: String
    public let disabled: Bool
    public var id: Value { value }
    public init(value: Value, label: String, disabled: Bool = false) { self.value = value; self.label = label; self.disabled = disabled }
}

public struct BleeckerSelect<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.bleeckerTextScale) private var textScale
    @Binding var selection: Value
    let options: [BleeckerSelectOption<Value>]
    let placeholder: String
    let systemImage: String?
    @State private var presented = false

    public init(selection: Binding<Value>, options: [BleeckerSelectOption<Value>], placeholder: String = "Select…", systemImage: String? = nil) {
        _selection = selection; self.options = options; self.placeholder = placeholder; self.systemImage = systemImage
    }

    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
#if os(tvOS)
        Picker(placeholder, selection: $selection) {
            ForEach(options) { option in Text(option.label).tag(option.value) }
        }
        .disabled(!isEnabled)
#else
        Button { presented.toggle() } label: {
            HStack(spacing: 10) {
                if let systemImage { Image(systemName: systemImage).foregroundStyle(p.sea) }
                Text(options.first { $0.value == selection }?.label ?? placeholder).lineLimit(1)
                Spacer(minLength: 12)
                Image(systemName: "chevron.down").font(.system(size: 11, weight: .semibold)).foregroundStyle(p.textSecondary)
            }
            .bleeckerFont(.primary, size: 14).foregroundStyle(p.textPrimary).padding(.horizontal, 14)
            .frame(minHeight: 40 * max(1, textScale))
            .background(p.card).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(presented ? p.sea.opacity(0.75) : p.border) }
        }
        .buttonStyle(.plain).opacity(isEnabled ? 1 : 0.6).disabled(!isEnabled)
        .popover(isPresented: $presented, arrowEdge: .bottom) {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(options) { option in
                        Button { selection = option.value; presented = false } label: {
                            HStack { Text(option.label).lineLimit(1); Spacer(); if option.value == selection { Image(systemName: "checkmark").foregroundStyle(p.sea) } }
                                .bleeckerFont(.primary, size: 14).foregroundStyle(option.value == selection ? p.sea : p.textPrimary)
                                .padding(.horizontal, 12)
                                .frame(minHeight: 36 * max(1, textScale)).contentShape(Rectangle())
                        }.buttonStyle(.plain).disabled(option.disabled)
                    }
                }.padding(4)
            }.frame(minWidth: 220, maxHeight: 288).background(p.popover)
        }
#endif
    }
}

public struct BleeckerSwitchStyle: ToggleStyle {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        let p = BleeckerPalette.resolve(scheme)
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: 12) {
                ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                    Capsule().fill(configuration.isOn ? p.sea : p.muted).overlay { Capsule().strokeBorder(configuration.isOn ? .clear : p.border) }.frame(width: 36, height: 20)
                    Circle().fill(.white).shadow(color: p.deepSea.opacity(0.18), radius: 1, y: 1).frame(width: 16, height: 16).padding(2)
                }
                configuration.label.bleeckerFont(.primary, size: 14, weight: .medium).foregroundStyle(p.textPrimary)
            }
        }.buttonStyle(.plain).animation(.easeOut(duration: BleeckerDuration.standard), value: configuration.isOn)
    }
}

public struct BleeckerCheckbox: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var checked: Bool
    let label: String
    let size: BleeckerControlSize
    public init(_ label: String, checked: Binding<Bool>, size: BleeckerControlSize = .md) {
        self.label = label; _checked = checked; self.size = size
    }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        let edge: CGFloat = size == .sm ? 14 : size == .lg ? 22 : 18
        let fontSize: CGFloat = size == .sm ? 11 : size == .lg ? 16 : 14
        Button { checked.toggle() } label: {
            HStack(spacing: size == .sm ? 6 : 10) {
                RoundedRectangle(cornerRadius: 4).fill(checked ? p.primary : p.card).frame(width: edge, height: edge)
                    .overlay { RoundedRectangle(cornerRadius: 4).strokeBorder(checked ? p.primary : p.border) }
                    .overlay { if checked { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundStyle(p.primaryForeground) } }
                Text(label).bleeckerFont(.primary, size: fontSize).foregroundStyle(p.textPrimary)
            }
        }.buttonStyle(.plain)
            .accessibilityAddTraits(checked ? [.isSelected] : [])
            .accessibilityValue(checked ? "Selected" : "Not selected")
    }
}

public struct BleeckerRadioGroup<Value: Hashable>: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.bleeckerTextScale) private var textScale
    @Binding var selection: Value
    let options: [BleeckerSelectOption<Value>]
    let orientation: BleeckerSelectionOrientation
    public init(selection: Binding<Value>, options: [BleeckerSelectOption<Value>], orientation: BleeckerSelectionOrientation = .vertical) { _selection = selection; self.options = options; self.orientation = orientation }
    public var body: some View {
        Group {
            if orientation == .vertical { VStack(alignment: .leading, spacing: 10) { items } }
            else { HStack(spacing: 16) { items } }
        }
    }
    @ViewBuilder private var items: some View {
        let palette = BleeckerPalette.resolve(scheme)
        ForEach(options) { option in
            Button { selection = option.value } label: {
                Label(option.label, systemImage: selection == option.value ? "largecircle.fill.circle" : "circle")
                    .bleeckerFont(.primary, size: 14)
                    .foregroundStyle(palette.textPrimary)
                    .frame(minHeight: 28 * max(1, textScale))
            }.buttonStyle(.plain).disabled(option.disabled)
        }
    }
}

public struct BleeckerStepper: View {
    @Environment(\.colorScheme) private var scheme
    @Environment(\.bleeckerTextScale) private var textScale
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let displayOffset: Int
    public init(_ label: String, value: Binding<Int>, in range: ClosedRange<Int>, step: Int = 1, displayOffset: Int = 0) { self.label = label; _value = value; self.range = range; self.step = step; self.displayOffset = displayOffset }
    public init(label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int = 1, displayOffset: Int = 0) { self.init(label, value: value, in: range, step: step, displayOffset: displayOffset) }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
        HStack(spacing: 0) {
            Text(label).bleeckerFont(.primary, size: 13)
                .foregroundStyle(p.textSecondary).padding(.horizontal, 10).lineLimit(1)
            Divider().frame(height: 24 * max(1, textScale))
            Button { value = max(range.lowerBound, value - step) } label: { Image(systemName: "minus") }.disabled(value <= range.lowerBound)
            Text((value + displayOffset).formatted()).bleeckerFont(.mono, size: 12, weight: .bold)
                .frame(minWidth: 34 * max(1, textScale))
            Button { value = min(range.upperBound, value + step) } label: { Image(systemName: "plus") }.disabled(value >= range.upperBound)
        }.buttonStyle(.borderless).frame(minHeight: 36 * max(1, textScale))
            .background(p.card).clipShape(RoundedRectangle(cornerRadius: BleeckerRadius.ui))
            .overlay { RoundedRectangle(cornerRadius: BleeckerRadius.ui).strokeBorder(p.border) }
    }
}
