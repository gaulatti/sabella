import Sabella
import SwiftUI

struct FoundationsGallery: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let palette = BleeckerPalette.resolve(scheme)
        CatalogSection("Palette", note: "Semantic and brand colors resolved for the current appearance.") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 125))], spacing: 12) {
                swatch("Sea", palette.sea)
                swatch("Desert", palette.desert)
                swatch("Terracotta", palette.terracotta)
                swatch("Sand", palette.sand)
                swatch("Deep Sea", palette.deepSea)
                swatch("Gold", palette.accentGold)
                swatch("Oxblood", palette.accentOxblood)
                swatch("Live", palette.live)
            }
        }
        CatalogSection("Typography") {
            VStack(alignment: .leading, spacing: 14) {
                Text("Encode Sans · Primary").font(BleeckerTypography.primary(24, weight: .semibold))
                Text("Libre Franklin · Secondary text for supporting detail").font(BleeckerTypography.secondary(16))
                Text("IBM Plex Mono · 0123456789").font(BleeckerTypography.mono(15))
                Text("CATALOG EYEBROW").bleeckerEyebrow()
                Text("UTILITY PILL").bleeckerPill()
            }
        }
        CatalogSection("Spacing & radius") {
            VStack(alignment: .leading, spacing: 12) {
                tokenBar("detail", BleeckerSpacing.detail)
                tokenBar("inline", BleeckerSpacing.inline)
                tokenBar("control", BleeckerSpacing.control)
                tokenBar("component", BleeckerSpacing.component)
                tokenBar("group", BleeckerSpacing.group)
                tokenBar("container", BleeckerSpacing.container)
                HStack(spacing: 18) {
                    radius("button", BleeckerRadius.button)
                    radius("card", BleeckerRadius.card)
                    radius("dialog", BleeckerRadius.dialog)
                    radius("pill", BleeckerRadius.pill)
                }.padding(.top, 8)
            }
        }
    }

    private func swatch(_ name: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8).fill(color).frame(height: 62)
            Text(name).font(BleeckerTypography.primary(12, weight: .medium))
        }
    }

    private func tokenBar(_ name: String, _ value: CGFloat) -> some View {
        HStack { CatalogLabel(name); RoundedRectangle(cornerRadius: 3).fill(BleeckerPalette.light.sea).frame(width: max(value * 3, 4), height: 8); Text("\(Int(value)) pt").font(.caption).foregroundStyle(.secondary) }
    }

    private func radius(_ name: String, _ value: CGFloat) -> some View {
        VStack { RoundedRectangle(cornerRadius: value).fill(BleeckerPalette.light.sand).frame(width: 72, height: 58); Text(name).font(.caption) }
    }
}

struct ButtonsGallery: View {
    @State private var selected = "day"
    @FocusState private var focusedAction: String?

    var body: some View {
        CatalogSection("Variants", note: "Every BleeckerButtonVariant at the default size.") {
            FlowLayout(spacing: 12) {
                ForEach(BleeckerButtonVariant.allCases, id: \.self) { variant in
                    BleeckerButton(variant: variant) { } label: { Text(variant.rawValue.capitalized) }
                }
            }
        }
        CatalogSection("Sizes and states") {
            VStack(alignment: .leading, spacing: 16) {
                FlowLayout(spacing: 12) {
                    ForEach(BleeckerButtonSize.allCases, id: \.self) { size in
                        BleeckerButton(size: size) { } label: { Text(size.rawValue.uppercased()) }
                    }
                }
                BleeckerButtonGroup {
                    BleeckerButton(loading: true) { } label: { Text("Loading") }
                    BleeckerButton(variant: .secondary) { } label: { Label("Add", systemImage: "plus") }
                    BleeckerButton(variant: .destructive) { } label: { Text("Delete") }
                }
                .disabled(false)
                Button("Native Button with BleeckerButtonStyle") { }
                    .buttonStyle(BleeckerButtonStyle(.outline, size: .sm))
                BleeckerButton(variant: .secondary) { } label: { Text("Disabled") }
                    .disabled(true)
            }
        }
        CatalogSection("Icon and toggle actions") {
            VStack(alignment: .leading, spacing: 18) {
                FlowLayout(spacing: 12) {
                    ForEach(BleeckerIconButtonVariant.allCases, id: \.self) { variant in
                        BleeckerIconButton("heart", accessibilityLabel: variant.rawValue, variant: variant) { }
                    }
                    ForEach(BleeckerIconButtonSize.allCases, id: \.self) { size in
                        BleeckerIconButton("star", accessibilityLabel: size.rawValue, size: size) { }
                    }
                }
                HStack {
                    Button("Selected") { }.buttonStyle(BleeckerToggleStyle(selected: true))
                    Button("Unselected") { }.buttonStyle(BleeckerToggleStyle(selected: false, variant: .outline))
                }
                BleeckerSegmentedControl(selection: $selected, options: options)
            }
        }
#if os(tvOS)
        CatalogSection("Remote focus states", note: "Use the Siri Remote to move focus and select an action.") {
            HStack(spacing: 28) {
                BleeckerButton { focusedAction = "selected" } label: { Text("Focusable") }
                    .focused($focusedAction, equals: "primary")
                Button("Selected") { }.buttonStyle(BleeckerToggleStyle(selected: true))
                BleeckerButton(loading: true) { } label: { Text("Loading") }
                BleeckerButton(variant: .destructive) { } label: { Text("Error") }
                BleeckerButton(variant: .secondary) { } label: { Text("Disabled") }
                    .disabled(true)
            }
        }
#endif
    }

    private var options: [BleeckerSelectOption<String>] {
        [.init(value: "day", label: "Day"), .init(value: "week", label: "Week"), .init(value: "month", label: "Month")]
    }
}

struct ControlsGallery: View {
    @State private var text = "Sabella"
    @State private var password = "design-system"
    @State private var search = ""
    @State private var notes = "Native Apple-platform components."
    @State private var option = "alpha"
    @State private var toggle = true
    @State private var checked = true
    @State private var count = 3

    private let options = [BleeckerSelectOption(value: "alpha", label: "Alpha"), BleeckerSelectOption(value: "beta", label: "Beta"), BleeckerSelectOption(value: "gamma", label: "Gamma", disabled: true)]

    var body: some View {
        CatalogSection("Text inputs") {
            VStack(alignment: .leading, spacing: 16) {
                BleeckerField("Project name", description: "Shown throughout the workspace.") { BleeckerTextField(placeholder: "Name", text: $text, systemImage: "textformat") }
                BleeckerField("Invalid field", error: "A value is required") { BleeckerTextField(placeholder: "Required", text: .constant(""), error: true) }
                BleeckerSecureField("Password", text: $password)
                BleeckerSearchField(placeholder: "Search the catalog", text: $search)
                BleeckerTextArea(text: $notes, minHeight: 82)
            }
        }
        CatalogSection("Selection") {
            VStack(alignment: .leading, spacing: 18) {
                BleeckerSelect(selection: $option, options: options, systemImage: "folder")
                Toggle("Notifications", isOn: $toggle).toggleStyle(BleeckerSwitchStyle())
                BleeckerCheckbox("Include archived", checked: $checked)
                BleeckerRadioGroup(selection: $option, options: options, orientation: .horizontal)
                BleeckerStepper("Seats", value: $count, in: 1...10)
            }
        }
    }
}

struct FeedbackGallery: View {
    @State private var progress = 0.62

    var body: some View {
        CatalogSection("Status badges") {
            FlowLayout(spacing: 10) {
                ForEach(BleeckerStatusBadgeVariant.allCases, id: \.self) { variant in BleeckerStatusBadge(variant.rawValue.capitalized, variant: variant) }
                BleeckerNotificationBadge(8)
                BleeckerNotificationBadge(128)
            }
        }
        CatalogSection("Alerts") {
            VStack(spacing: 12) {
                ForEach(BleeckerAlertType.allCases, id: \.self) { type in BleeckerAlert(type.rawValue.capitalized, type: type) { Text("This is supporting context for the alert.") } }
            }
        }
        CatalogSection("Progress and loading") {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(BleeckerProgressVariant.allCases, id: \.self) { variant in
                    HStack { CatalogLabel(variant.rawValue); BleeckerProgress(value: progress, variant: variant) }
                }
                HStack(spacing: 20) { ForEach(BleeckerLoadingSize.allCases, id: \.self) { BleeckerLoadingSpinner(size: $0) } }
#if os(tvOS)
                BleeckerSlider(value: $progress)
#else
                Slider(value: $progress)
#endif
            }
        }
        CatalogSection("Empty and loading states") {
            HStack(alignment: .top, spacing: 20) {
                BleeckerEmptyState(title: "Nothing here yet", message: "Create the first item to get started.") { BleeckerButton { } label: { Text("Create") } }
                BleeckerLoadingOverlay("Loading preview").frame(width: 280, height: 190).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct SurfacesGallery: View {
    var body: some View {
        CatalogSection("Card variants") {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                ForEach(BleeckerCardVariant.allCases, id: \.self) { variant in
                    BleeckerCard(padding: .sm, variant: variant) { VStack(alignment: .leading) { CatalogLabel(variant.rawValue); Text("A Sabella surface").font(.headline) } }.frame(minHeight: 110)
                }
            }
        }
        CatalogSection("Surface utilities") {
            VStack(alignment: .leading, spacing: 18) {
                BleeckerPanel(title: "Panel") { Text("Panels provide a titled card composition.") }
                BleeckerSeparator()
                BleeckerSkeleton().frame(height: 18)
                BleeckerSkeleton(radius: BleeckerRadius.pill).frame(width: 180, height: 12)
                Text("bleeckerSurface exposes BleeckerSurfaceModifier")
                    .padding(14)
                    .bleeckerSurface(radius: BleeckerRadius.ui)
                BleeckerBauhausBackground().frame(height: 150).clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content
    init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) { self.spacing = spacing; self.content = content() }
    var body: some View { HStack(spacing: spacing) { content }.fixedSize(horizontal: false, vertical: true) }
}
