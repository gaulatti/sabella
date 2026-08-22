# Bleecker → Sabella parity

The goal is behavioral and visual convergence, not DOM emulation. Native platform affordances remain native.

## Native now

- Foundation: tokens, light/dark palettes, typography, spacing, radii, motion, surface modifier, all public contracts
- Actions: Button, IconButton, ButtonGroup, Toggle style, ToggleGroup/SegmentedControl
- Forms: Field, Input, SecureField, SearchInput, TextArea, Select, Checkbox, Switch, RadioGroup, Stepper
- Surfaces: Card, Panel, Separator, Skeleton, BauhausBackground
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

## Catalog release gate

Every public visual Sabella type is registered in the separate
`SabellaCatalogSupport` target and rendered by a gallery in `SabellaCatalog`.
`swift test` discovers public `View`, `ButtonStyle`, and `ToggleStyle` types and
fails when registration falls behind the library surface. The tvOS catalog
records `BleeckerDateRangePicker` and `BleeckerFileInput` as explicit platform
exceptions because their underlying native APIs are unavailable there; all
other visual contracts are exercised on macOS, iPhone, iPad, and Apple TV.
