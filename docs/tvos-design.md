# Television design guidance

Sabella's television API is designed for a remote, a ten-foot viewing distance,
and a shared room. It is not a responsive web layout enlarged to 16:9.

## Product principles

- Keep focus and selection distinct. Focus uses scale, depth, contrast, and
  motion; selection changes application state only after activation.
- Put content before chrome. Navigation stays shallow and the current screen
  preserves enough context to make the next remote movement predictable.
- Help people decide. Context badges should explain relevance (for example,
  “Top 10 today” or “Because you watch travel”), not repeat genres already in
  metadata. Progress belongs directly on resumable artwork.
- Mix formats intentionally. Landscape cards scan quickly for episodic and live
  media; posters support cinematic browsing. Do not alternate ratios randomly
  within one shelf.
- Use editorial rails to reduce choice overload. A named collection, a short
  thesis, and a bounded set of titles should communicate a human point of view.
- Keep discovery shortcuts visible. Search, saved content, and profiles should
  not depend on a hidden edge gesture or a long remote traversal.
- Treat autoplay as a product decision, not a component default. Sabella does
  not start preview audio or video. If a product adds previews, respect Reduce
  Motion, avoid surprise audio, and make stopping them immediate.
- Prefer the platform video player. `SabellaTVPlaybackOverlay` is custom chrome
  for branded or non-video demonstrations; production video should use the
  system player unless the product requires a custom transport.
- Design accessibility into the material. `SabellaTVScreen` strengthens its
  background when Reduce Transparency is enabled, and focus motion is disabled
  when Reduce Motion is enabled.

## Component roles

`SabellaTVHero` leads a browse or detail surface. `SabellaTVShelf` is a compact,
task-oriented row. `SabellaTVEditorialRail` adds a curatorial argument before a
row. `SabellaTVCard` supports landscape or poster artwork, an optional relevance
badge, and bounded watch progress. `SabellaTVContextBadge` is also available for
live, entitlement, ranking, and availability labels.

## Catalog acceptance

The tvOS catalog demonstrates browse, details, playback, and state surfaces.
Browse must show visible top navigation and search, landscape progress cards,
and a poster-based editorial collection. Every control must be reachable and
activatable with directional focus and Select; Play/Pause must toggle playback.

## Research basis

- [Apple: Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/)
- [Apple: Playing video](https://developer.apple.com/design/human-interface-guidelines/playing-video)
- [Apple: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Netflix: 2025 TV experience](https://about.netflix.com/en/news/unveiling-our-innovative-new-tv-experience)
- [Google TV: conversational discovery](https://blog.google/products-and-platforms/platforms/google-tv/gemini-google-tv/)
- [Amazon Fire TV: feature rotator](https://advertising.amazon.com/en-ca/resources/ad-specs/fire-tv/feature-rotator)

These sources establish current platform and product patterns, not a mandate to
copy any one service. Sabella deliberately excludes recommendation algorithms,
advertising placement, autoplay policy, and generative search from its visual
component layer.
