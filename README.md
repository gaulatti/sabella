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
