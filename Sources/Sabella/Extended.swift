import SwiftUI
#if !os(tvOS)
import UniformTypeIdentifiers
#endif

public struct BleeckerActivityItem<Actions: View>: View {
    @Environment(\.colorScheme) private var scheme
    let title: String; let detail: String; let timestamp: String; let systemImage: String; @ViewBuilder let actions: Actions
    public init(_ title: String, detail: String, timestamp: String, systemImage: String = "clock", @ViewBuilder actions: () -> Actions) { self.title = title; self.detail = detail; self.timestamp = timestamp; self.systemImage = systemImage; self.actions = actions() }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); HStack(alignment: .top, spacing: 12) { BleeckerIconBadge(systemImage, variant: .subtle); VStack(alignment: .leading, spacing: 3) { Text(title).font(BleeckerTypography.primary(14, weight: .semibold)); Text(detail).font(BleeckerTypography.secondary(12)).foregroundStyle(p.textSecondary); Text(timestamp).font(BleeckerTypography.secondary(10)).foregroundStyle(p.textSecondary) }; Spacer(); actions }.padding(.vertical, 8) }
}

public struct BleeckerFeedItem<Content: View>: View {
    let author: String; let timestamp: String; @ViewBuilder let content: Content
    public init(author: String, timestamp: String, @ViewBuilder content: () -> Content) { self.author = author; self.timestamp = timestamp; self.content = content() }
    public var body: some View { HStack(alignment: .top, spacing: 12) { BleeckerAvatar(name: author, size: .sm); VStack(alignment: .leading, spacing: 6) { HStack { Text(author).font(BleeckerTypography.primary(13, weight: .semibold)); Text(timestamp).font(BleeckerTypography.secondary(11)).foregroundStyle(.secondary) }; content } }.padding(.vertical, 8) }
}

public struct BleeckerErrorState<Actions: View>: View {
    let title: String; let message: String; @ViewBuilder let actions: Actions
    public init(_ title: String = "Something went wrong", message: String, @ViewBuilder actions: () -> Actions) { self.title = title; self.message = message; self.actions = actions() }
    public var body: some View { BleeckerEmptyState(icon: "exclamationmark.triangle", title: title, message: message) { actions } }
}

public struct BleeckerProgressSegment: Identifiable, Sendable {
    public let id: String; public let value: Double; public let color: Color
    public init(id: String = UUID().uuidString, value: Double, color: Color) { self.id = id; self.value = value; self.color = color }
}

public struct BleeckerProgressStack: View {
    @Environment(\.colorScheme) private var scheme
    let segments: [BleeckerProgressSegment]; let height: CGFloat
    public init(_ segments: [BleeckerProgressSegment], height: CGFloat = 8) { self.segments = segments; self.height = height }
    public var body: some View { let p = BleeckerPalette.resolve(scheme); GeometryReader { proxy in HStack(spacing: 2) { ForEach(segments) { segment in Rectangle().fill(segment.color).frame(width: max(0, proxy.size.width * segment.value)) } }.background(p.muted).clipShape(Capsule()) }.frame(height: height) }
}

public struct BleeckerSlider: View {
    @Environment(\.colorScheme) private var scheme
    @Binding var value: Double; let range: ClosedRange<Double>; let step: Double?
    public init(value: Binding<Double>, in range: ClosedRange<Double> = 0...1, step: Double? = nil) { _value = value; self.range = range; self.step = step }
    public var body: some View {
        let p = BleeckerPalette.resolve(scheme)
#if os(tvOS)
        HStack(spacing: 12) {
            Button { value = max(range.lowerBound, value - increment) } label: { Image(systemName: "minus") }
            BleeckerProgress(value: (value - range.lowerBound) / (range.upperBound - range.lowerBound)).frame(minWidth: 120)
            Button { value = min(range.upperBound, value + increment) } label: { Image(systemName: "plus") }
        }.foregroundStyle(p.textPrimary)
#else
        Group { if let step { Slider(value: $value, in: range, step: step) } else { Slider(value: $value, in: range) } }.tint(p.sea)
#endif
    }
    private var increment: Double { step ?? ((range.upperBound - range.lowerBound) / 20) }
}

public struct BleeckerOTPInput: View {
    @Binding var code: String; let length: Int
    public init(code: Binding<String>, length: Int = 6) { _code = code; self.length = length }
    public var body: some View { BleeckerTextField(placeholder: String(repeating: "•", count: length), text: Binding(get: { code }, set: { code = String($0.filter(\.isNumber).prefix(length)) }), font: BleeckerTypography.mono(20, weight: .semibold)).multilineTextAlignment(.center).accessibilityLabel("Verification code") }
}

#if !os(tvOS)
public struct BleeckerDateRangePicker: View {
    @Binding var start: Date; @Binding var end: Date; let range: ClosedRange<Date>?
    public init(start: Binding<Date>, end: Binding<Date>, in range: ClosedRange<Date>? = nil) { _start = start; _end = end; self.range = range }
    public var body: some View { HStack { datePicker("From", selection: $start); Image(systemName: "arrow.right").foregroundStyle(.secondary); datePicker("To", selection: $end) } }
    @ViewBuilder private func datePicker(_ title: String, selection: Binding<Date>) -> some View { if let range { DatePicker(title, selection: selection, in: range, displayedComponents: .date).labelsHidden() } else { DatePicker(title, selection: selection, displayedComponents: .date).labelsHidden() } }
}

public struct BleeckerFileInput: View {
    let title: String; let allowedContentTypes: [UTType]; let onResult: (Result<[URL], Error>) -> Void
    @State private var importing = false
    public init(_ title: String = "Choose file…", allowedContentTypes: [UTType], onResult: @escaping (Result<[URL], Error>) -> Void) { self.title = title; self.allowedContentTypes = allowedContentTypes; self.onResult = onResult }
    public var body: some View { Button(title) { importing = true }.buttonStyle(BleeckerButtonStyle(.secondary)).fileImporter(isPresented: $importing, allowedContentTypes: allowedContentTypes, allowsMultipleSelection: true, onCompletion: onResult) }
}
#endif

public struct BleeckerCollectionFilters<Content: View>: View {
    @Binding var query: String; @ViewBuilder let content: Content
    public init(query: Binding<String>, @ViewBuilder content: () -> Content) { _query = query; self.content = content() }
    public var body: some View { HStack(spacing: 10) { BleeckerSearchField(placeholder: "Search", text: $query); content }.frame(minHeight: 40) }
}

public struct BleeckerMediaLibrary<Item: Identifiable, Tile: View>: View {
    let items: [Item]; let minimumTileWidth: CGFloat; let tile: (Item) -> Tile
    public init(_ items: [Item], minimumTileWidth: CGFloat = 160, @ViewBuilder tile: @escaping (Item) -> Tile) { self.items = items; self.minimumTileWidth = minimumTileWidth; self.tile = tile }
    public var body: some View { LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumTileWidth), spacing: 16)], spacing: 16) { ForEach(items) { tile($0) } } }
}

public struct BleeckerHeroCarousel<Item: Identifiable, Slide: View>: View {
    let items: [Item]; let slide: (Item) -> Slide
    public init(_ items: [Item], @ViewBuilder slide: @escaping (Item) -> Slide) { self.items = items; self.slide = slide }
    public var body: some View { ScrollView(.horizontal) { LazyHStack(spacing: 16) { ForEach(items) { slide($0).containerRelativeFrame(.horizontal) } }.scrollTargetLayout() }.scrollTargetBehavior(.viewAligned(limitBehavior: .always)).scrollIndicators(.hidden) }
}
