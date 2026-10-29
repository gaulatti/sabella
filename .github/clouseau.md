# Sabella review contract

Sabella is the SwiftUI sibling of Bleecker: a native Apple-platform component
library (macOS, iOS and tvOS) built from the same design tokens and contracts.
Products consume it as a tagged Swift package and rely on its public products
(`Sabella`, `SabellaCatalog`, `SabellaShellExamples`), the Kolibri contract
parity, bundled brand fonts, accessibility and the immutable release path.

Preserve declared public APIs and products, parity with the Bleecker contract
snapshots, accessible names and focus behaviour, platform availability, and the
release path (deterministic archive, checksum, tag-on-main, private immutable
release). A component change needs a catalog entry or test that shows the
behaviour a consumer sees. Bug fixes, meaningful tests, accessibility
corrections, documentation and dependency maintenance serve this existing
package without a new product decision. A new component, a new platform or a
breaking public API needs documentation or a linked requirement that
establishes its need and boundaries. Releases stay a separate, tag-triggered
workflow outside this review contract.

Assess purpose and evidence rather than the number of changed files or lines.
Ask gaulatti for a second opinion for a product-direction or authority decision.
Ordinary implementation uncertainty and repairable bugs belong to automated
investigation, not routine human code review. Changes to review controls (this
contract, `.github/clouseau.json`, the CI workflow, the local recipe) require
explicit owner confirmation.

Every material capability and mechanism must independently score at least 80
for fit, need and proportionality under Clouseau's shared protocol. A causal
technical finding at or above 70 blocks; unrelated features or good scores
cannot average away a defect. Integrity and review-completeness gates remain
independent.

Tests must assert actual behaviour. Reject fabricated coverage, disabled tests,
coverage pragmas or exclusions, swallowed errors and unconditional assertions.
The package and Kolibri contract validation, the build, `swift test`, the
catalog and example builds and the local release-consumer validation remain
mandatory. The shared coverage gate cannot measure Swift: the LLVM export of
SwiftPM carries no branch regions, and the gate requires measured branches.
Local line coverage is recorded honestly for review, the policy selects
`manual` merge mode, and the owner merges every pull request.
