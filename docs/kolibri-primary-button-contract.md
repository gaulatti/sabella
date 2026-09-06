# Kolibri primary-button contract decision

## Decision

**Adapt, with explicit gaps.** Sabella can consume Kolibri's renderer-neutral
`button.primary` structure, semantic parts, event, action, and empty
asset/behavior sets without changing Sabella's public API. Kolibri 0.1.0 does
not describe tokens, named states, appearance, responsive rules, Dynamic Type,
or native input semantics, so it is not sufficient to generate or replace the
hand-authored SwiftUI implementation.

Sabella owns native behavior. The contract is a checked, versioned input to a
consumer proof; it is not a runtime dependency and it never overwrites source.

## Immutable input

The complete private release bundle is committed under
`Tests/Fixtures/Kolibri/0.1.0` so the proof has no sibling checkout, feature
branch, registry, network, or unpublished-package dependency.

| Field | Pin |
| --- | --- |
| Producer | private `gaulatti/kolibri` repository |
| Repository commit containing the bundle | `f14a631a001f867e208be6053ac07df32fda4dca` |
| Release path | `contract/releases/0.1.0` |
| Release version | `0.1.0` |
| Schema version | `1.0.0` |
| Bundle source revision | `24e6905a0a6b9e6dae08b0832781b0f06f8c0b5f` |
| Manifest SHA-256 | `aec1a74fb557ab0a5d254b5ac8d98306e552dc88cdb6ebeeb6f98d1460cfe134` |
| Selected fixture | `fixtures/static-component.json` |

`scripts/validate-kolibri-contract.sh` first checks the manifest pin, then runs
the release bundle's dependency-free validator. The validator verifies all six
artifact sizes and SHA-256 values, validates all three producer fixtures, and
validates the selected consumer fixture. The release gate invokes this check
before compiling Sabella.

`button.primary` is the only interactive component in Kolibri 0.1.0. It is
therefore the bounded representative family for this Sabella proof and the
family the pending Bleecker proof must use to preserve the cross-repository
comparison. No result from that still-pending proof is claimed here.

## Contract mapping

| Contract item | Classification | Sabella mapping |
| --- | --- | --- |
| `button` / `root` | Native adaptation | `BleeckerButton` with `BleeckerButtonStyle(.primary)` on macOS/iOS; native `Button` with `SabellaTVPrimaryButtonStyle` on tvOS |
| `span` / `label` | Native adaptation | SwiftUI `Text`; the native button owns label exposure |
| `press` event | Native adaptation | Platform-native pointer, touch, keyboard, accessibility, or remote activation |
| `submit` / `emit` action | Exact | Sabella action closure |
| Empty assets | Exact | No external asset required |
| Empty ordered behaviors | Exact | No synthetic sequence required |
| Tokens | Producer defect | Schema 1.0.0 has no token field; Sabella continues to use `BleeckerPalette`, typography, spacing, radius, and duration tokens |
| Named states | Producer defect | Schema 1.0.0 has no state field; native state coverage is classified below |
| Appearance | Producer defect | Schema 1.0.0 has no light/dark contract |
| Responsive rules | Producer defect | Schema 1.0.0 has no responsive contract |

## Native state and platform ownership

| State or capability | macOS | iOS/iPadOS | tvOS |
| --- | --- | --- | --- |
| Enabled | Native adaptation: SwiftUI `Button` | Native adaptation: SwiftUI `Button` | Native adaptation: SwiftUI `Button` |
| Pressed | Native adaptation: `ButtonStyle.Configuration.isPressed` | Native adaptation: `ButtonStyle.Configuration.isPressed` | Native adaptation: `ButtonStyle.Configuration.isPressed` |
| Disabled | Native adaptation: SwiftUI disabled environment | Native adaptation: SwiftUI disabled environment | Native adaptation: SwiftUI disabled environment |
| Focused | Platform exception: keyboard focus | Platform exception: full-keyboard and accessibility focus | Platform exception: directional focus with visible Sabella treatment |
| Loading | Native adaptation: `BleeckerButton(loading:)` | Native adaptation: `BleeckerButton(loading:)` | Unsupported by `SabellaTVPrimaryButtonStyle` |
| Activation | Pointer, Return, Space, accessibility action | Touch, keyboard, Switch Control, accessibility action | Siri Remote Select or accessibility action; focus movement does not activate |
| Accessibility | Native button role, child label, activation, and disabled state | Native button role, child label, activation, and disabled state | Native button role, child label, activation, and disabled state |
| Appearance | Sabella light/dark semantic palettes | Sabella light/dark semantic palettes | Platform exception: the television catalog is intentionally dark |
| Layout | Platform exception: container-owned native layout | Platform exception: compact/regular container-owned layout | Platform exception: ten-foot spacing and focus targets |
| Dynamic Type | Unsupported: current fixed custom-font size does not establish scaling | Unsupported: current fixed custom-font size does not establish scaling | Unsupported: current fixed custom-font size does not establish scaling |

The Dynamic Type result is intentionally negative. The catalog exposes text-size
controls, but `BleeckerButtonStyle` and `SabellaTVPrimaryButtonStyle` currently
use fixed custom-font sizes. The snapshots fail if this classification changes
without a reviewed fixture update; a future scaling change needs its own native
implementation and visual acceptance evidence.

## Deterministic proof

`KolibriContractTests.swift` decodes the selected fixture and rejects changes to
its release/schema metadata, entrypoint, component identity, semantic tree,
event, action, asset set, or behavior set. It renders sorted, newline-stable
consumer snapshots for macOS, iOS/iPadOS, and tvOS and compares them with the
committed files under `Tests/SabellaTests/Snapshots/KolibriPrimaryButton`.

The focused tests also prove that tvOS remote Select and accessibility
activation trigger the mapped action, directional focus movement does not,
disabled controls cannot activate, every selected native state and semantic
part has a classification, and the referenced Sabella button implementations
still use native SwiftUI `Button` and focus/pressed inputs. Any unexplained
contract or adapter drift fails the test suite.

The component catalog contains the same proof surface:

- macOS/iOS/iPadOS show the primary button's enabled, loading, and disabled
  states and retain the catalog's light/dark and text-size controls;
- tvOS shows enabled and disabled primary actions in the remote-focusable
  States page using `SabellaTVPrimaryButtonStyle`.

## Boundaries

- Sabella's public library API is unchanged.
- The private Kolibri repository remains private; no package, release, hosted
  artifact, demo, or documentation was published.
- No private WGU source or provenance checkout was read, copied, or modified.
- No Kolibri source or generated output is imported at runtime.
- This proof does not claim that the pending Bleecker consumer proof, a
  cross-repository integration ticket, VoiceOver on physical hardware, Siri
  Remote hardware, or an application product integration has completed.

## Reproduce

```shell
scripts/validate-kolibri-contract.sh
swift test --filter Kolibri
scripts/validate-release.sh
scripts/run-catalog.sh macos
scripts/run-catalog.sh ios
scripts/run-catalog.sh ipad
SABELLA_CATALOG_PAGE=states scripts/run-catalog.sh tvos
```
