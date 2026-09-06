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

Bleecker, Sabella, and Thompson are proprietary parts of the Gaulatti identity
system for Gaulatti products and websites. They are not white-label or fungible
themes. Brand components therefore ship the authoritative Gaulatti artwork and
do not expose a consumer-supplied logo override.

## Private package consumption

Sabella is distributed as a private Swift package. The initial release is
`0.1.0`; authorized consumers should accept compatible `0.1.x` fixes while
excluding the next potentially breaking pre-1.0 minor:

```swift
.package(
    url: "https://github.com/gaulatti/sabella.git",
    .upToNextMinor(from: "0.1.0")
)
```

Application targets link only `.product(name: "Sabella", package: "Sabella")`.
The equivalent version range is `>= 0.1.0, < 0.2.0`. Compatible fixes use
`0.1.x`; breaking public API changes before 1.0 use a new `0.x.0` minor. Release
tags are immutable, so a faulty release is corrected with a new version instead
of moving an existing tag.

The repository remains private. Developers and CI use their existing authorized
GitHub credentials to resolve it; never embed a token, deploy key, or other
credential in source, Xcode projects, workflow logs, or documentation.

Sabella uses Swift tools 6.0 and supports macOS 14+, iOS/iPadOS 17+, and tvOS
17+. `SabellaCatalog` and `SabellaShellExamples` are development and release-gate
executables, not dependencies of the application library.

Sabella bundles static Thin-through-Black faces for the Encode Sans and Libre
Franklin typefaces used by its typography tokens and registers them from the
package resource bundle on first use. Consumers do not need to install fonts or
add `UIAppFonts` entries. The font files are distributed under the SIL Open Font
License included beside the assets in `Sources/Sabella/Resources/Fonts`.

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
- tvOS presents a television-first showcase instead of the cross-platform
  component inventory. It exercises cinematic hero and detail layouts,
  remote-focusable content cards and shelves, playback transport, and full-screen
  TV state surfaces through the reusable `SabellaTV*` APIs.

The television surface includes `SabellaTVScreen`, `SabellaTVNavigationBar`,
`SabellaTVHero`, `SabellaTVCard`, `SabellaTVContextBadge`,
`SabellaTVShelf`, `SabellaTVEditorialRail`, `SabellaTVChannelGuide`,
`SabellaTVPrimaryButtonStyle`, and `SabellaTVPlaybackOverlay`. These APIs exist
only when compiling for tvOS so application code cannot accidentally treat the
television interaction model as a desktop or touch layout.

See [`docs/tvos-design.md`](docs/tvos-design.md) for the product patterns behind
the API and guidance on focus, artwork, discovery, playback, and accessibility.

Run `swift test` before release. The catalog coverage test discovers every
public Sabella `View`, `ButtonStyle`, and `ToggleStyle` from library source and
compares it with `SabellaCatalogCoverage.registeredComponents`. The suite also
contains a deliberately omitted fake component to prove that the gate fails on
missing registration.

## Release gate

Every pull request and update to `main` runs the macOS package release gate. It
validates the manifest, builds the `Sabella` product, runs all tests, builds the
catalog and shell executables, and compiles a clean temporary consumer that
imports representative controls and an application shell through only the
`Sabella` library product.

Run the same gate locally:

```shell
scripts/validate-release.sh
```

After a reviewed release commit lands on remote `main`, create its immutable
semantic-version tag. The tag workflow verifies that the commit belongs to
remote `main`, resolves the private package as an external consumer using the
tagged compatible range, and only then publishes the private GitHub Release
from `docs/releases/<version>.md`. Release `0.1.0` uses
[`docs/releases/0.1.0.md`](docs/releases/0.1.0.md).

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
