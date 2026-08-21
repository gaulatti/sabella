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
