# Bleecker → Sabella parity

The goal is behavioral and visual convergence, not DOM emulation. Native platform affordances remain native.

## Native now

- Foundation: tokens, light/dark palettes, typography, spacing, radii, motion, surface modifier, all public contracts
- Actions: Button, IconButton, ButtonGroup, Toggle style, ToggleGroup/SegmentedControl
- Forms: Field, Input, SecureField, SearchInput, TextArea, Select, Checkbox, Switch, RadioGroup, Stepper
- Surfaces: AttentionSurface, Card, Panel, Separator, Skeleton, BauhausBackground
- Feedback: Alert, StatusBadge, NotificationBadge, Progress, LoadingSpinner, LoadingOverlay, EmptyState
- Navigation: BrandLockup, SidebarItem, PageHeader, SectionHeader, Breadcrumb, Tabs, Pagination, Accordion
- Data display: Avatar, IconBadge, Metric, StatCard, DataList, Timeline, FilterChip, Kbd
- Layout: DashboardGrid, DashboardSection, adaptive AppShell/AdminShell, value-backed application tabs, compact drawer, persistent sidebar, PanelLayout, Header, Footer
- Overlays: Modal, Tooltip/help, DropdownMenu/ContextMenu primitive, CommandSpotlight
- Charts: Line, Area, Bar, Pie, Donut, Scatter, Sparkline via Swift Charts

## Native adapters still to deepen

- DataTable toolbars/filters/column toggles use the form, menu, pagination, and table primitives; a type-erased universal table API would weaken SwiftUI, so products compose these pieces around typed rows.
- Dialog, AlertDialog, Drawer, Sheet, Popover, HoverCard, ContextMenu, DatePicker, Slider, FileInput, NavigationMenu, Menubar, ScrollArea, and Toast/Sonner map directly to SwiftUI presentation or control APIs and receive Sabella styling at their content boundary.
- Radar, radial, funnel, Sankey, and sunburst charts need custom marks/canvas renderers. The shared chart data and palette contracts are already present.
- MediaLibrary and HeroCarousel are product/data-source dependent; Sabella owns their cards, filters, loading, selection, and layout primitives rather than networking.

## Convergence rule

When Bleecker changes a platform-neutral token or public contract, update Sabella in the same change and extend the parity tests. Platform-specific behavior may diverge only to preserve keyboard navigation, focus, accessibility, menu conventions, or remote interaction.

The [`button.primary` Kolibri proof](docs/kolibri-primary-button-contract.md)
applies that rule to the private neutral 0.1.0 release. Structure, semantic
parts, the event/action pair, and empty assets/behaviors map cleanly; states,
tokens, appearance, responsive behavior, Dynamic Type scaling, and tvOS loading
remain explicit native adaptations, exceptions, unsupported behavior, or
producer gaps rather than implied parity.

## Television boundary

tvOS is not governed by web-component parity. It shares Sabella’s palette,
typography, spacing, and low-level accessibility contracts, then exposes a
television-native `SabellaTV*` surface for remote focus, 10-foot hierarchy,
cinematic hero and detail screens, horizontal content shelves, and playback
transport. Desktop administration, form, and chart components may continue to
compile for shared consumers, but they are not the tvOS catalog or its product
acceptance boundary.

## Catalog release gate

Every public visual Sabella type is registered in the separate
`SabellaCatalogSupport` target and rendered by a gallery in `SabellaCatalog`.
`swift test` discovers public `View`, `ButtonStyle`, and `ToggleStyle` types and
fails when registration falls behind the library surface. The tvOS catalog
records `BleeckerDateRangePicker` and `BleeckerFileInput` as explicit platform
exceptions because their underlying native APIs are unavailable there; all
other visual contracts are exercised on macOS, iPhone, iPad, and Apple TV.

The application-facing `Sabella` library has no dependency on
`SabellaCatalog`, `SabellaCatalogSupport`, or `SabellaShellExamples`. The package
release gate builds those development products independently, then compiles a
temporary external-style consumer through only the library product so catalog
and example support cannot become an accidental transitive requirement.

## Attention surface reference

The attention treatment follows Bleecker `cb891040` for CSS HSL/OKLab color
math, coverage, stop positions, density padding, border occupancy, and circular
radius. The padding-box gradient repeats into the translucent border, as in
the producer CSS.
The native attention surface supplies light primary and secondary foregrounds
because its paint remains dark in both host appearances. Explicit child colors
still take precedence. Rendered text regressions check both host appearances,
hierarchical secondary text and explicit child color preservation. Controls
that supply their own foreground colors remain responsible for those colors.
The catalog renders both densities at calm, moderate, and urgent intensities.
Pinned Chrome fixtures and actual native layout measurements cover these
numeric contracts. Two browser PNGs additionally exercise the macOS native
interior gradient samples and every straight border pixel in portrait and
landscape within two eight-bit code values. Small category text uses a separate accessible paint on
`BleeckerCard`; this adaptation leaves the producer accent unchanged.

The negative-spread shadow is clipped to the exterior of the border box;
a mutation removing that knockout is rejected by the native/browser raster
comparison. Exterior blur and rounded-corner antialiasing still need native visual
acceptance; these raster fixtures do not establish device interaction or
cross-platform pixel equivalence.
