# Sabella

Sabella is the SwiftUI sibling of [Bleecker](../bleecker): a native Apple-platform component library built from the same design tokens and contracts. It targets macOS, iOS, and tvOS and intentionally uses native interaction and accessibility behavior instead of emulating browser controls.

```swift
import Sabella

BleeckerField("Playlist URL") {
    BleeckerTextField(placeholder: "https://…", text: $url, systemImage: "link")
}

Button("Sync") { sync() }
    .buttonStyle(BleeckerButtonStyle(.primary))
```

## Sync policy

`bleecker/src/tokens/source.ts` is the canonical cross-platform token source. Every Bleecker contract has a matching Swift enum in `Contracts.swift`; parity tests lock names and counts. Component parity is tracked in [PARITY.md](PARITY.md).

Components keep the `Bleecker` prefix so product code reads identically across design-system implementations while the module name (`Sabella`) identifies the platform library.

## Component catalog

`SabellaCatalog` is the canonical visual release gate for every supported Apple
platform. It is an executable target that imports `Sabella`; neither the catalog
nor its coverage manifest is included in the library product shipped to
applications.

Run the platform-native catalog from the package root:

```shell
scripts/run-catalog.sh macos
scripts/run-catalog.sh ios
scripts/run-catalog.sh ipad
scripts/run-catalog.sh tvos
```

The simulator commands build, wrap, install, and launch the Swift package
executable on their named runtime. Override the default destination when needed,
for example `SIMULATOR_NAME="iPad mini (A17 Pro)" scripts/run-catalog.sh ipad`.

- macOS uses a resizable split view with search, keyboard navigation, pointer
  behavior, appearance controls, and Dynamic Type controls.
- iPhone uses compact touch navigation and safe-area-aware galleries.
- iPad uses the adaptive split view in portrait, landscape, and resized windows,
  with native pointer and keyboard input.
- tvOS uses a focus-driven split view and remote-operable examples. Date range
  and file input are explicitly excluded because those Sabella components are
  unavailable on tvOS; the catalog names that exception instead of silently
  omitting it.

Run `swift test` before release. The catalog coverage test discovers every
public Sabella `View`, `ButtonStyle`, and `ToggleStyle` from library source and
compares it with `SabellaCatalogCoverage.registeredComponents`. The suite also
contains a deliberately omitted fake component to prove that the gate fails on
missing registration.

## Adaptive application shells

Sabella translates Thompson's value-backed application-tab and administration
shell contracts into native SwiftUI behavior. Applications continue to own
routing and product state; the shell owns safe areas, header/footer composition,
navigation placement, focus, and adaptation to the available width.

```swift
@State private var destination = Destination.home

BleeckerMobileAppShell(
    selection: $destination,
    tabs: [
        BleeckerAppTab(.home, label: "Home", systemImage: "house"),
        BleeckerAppTab(.devices, label: "Devices", systemImage: "tv", badge: 2),
    ]
) {
    AppHeader()
} content: {
    screens[destination]
}
```

`BleeckerMobileAppShell` uses a safe-area bottom bar on iPhone and iPad, a
segmented toolbar on macOS, and large remote-focusable targets on tvOS.
`BleeckerAdminShell` uses a dismissible drawer at compact touch widths,
persistent navigation at wide iPad widths, a native resizable split view on
macOS, and an overscan-aware focus-driven split view on tvOS. Its
`navigationPresented` binding lets application routing close compact navigation
after a destination changes without embedding routing into Sabella.

`BleeckerShellLayout` exposes the width/platform policy for tests and previews.
Platform differences are explicit through `BleeckerShellPlatform`,
`BleeckerShellPresentation`, and the example application.

Run the examples from the package root:

```shell
scripts/run-shell-example.sh macos
scripts/run-shell-example.sh ios
SHELL_EXAMPLE_MODE=admin scripts/run-shell-example.sh ipad
scripts/run-shell-example.sh tvos
```

Set `SIMULATOR_NAME` or `SIMULATOR_ID` to choose another runtime. The simulator
commands build, wrap, install, and launch the Swift package executable. On
macOS, the sidebar uses native window resizing and a Control-Command-S keyboard
shortcut. On tvOS, tab and sidebar destinations participate in the focus engine
with visible focused and selected states. All touch shells respect safe areas,
Dynamic Type, screen-reader selection traits, and reduced-motion preferences.
