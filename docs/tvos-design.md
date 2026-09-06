# Television design guidance

Sabella's television API is designed for a remote, a ten-foot viewing distance,
and a shared room. It is not a responsive web layout enlarged to 16:9.
Sabella is the native expression of the same proprietary Gaulatti identity as
Bleecker and Thompson; the catalog demonstrates that identity rather than a
themeable or white-label product.

## Product principles

- Keep focus and selection distinct. Focus uses scale, depth, contrast, and
  motion; selection changes application state only after activation. Shelves
  reserve space for focused depth so a focused item never obscures its neighbor.
- Put content before chrome. Navigation stays shallow and the current screen
  preserves enough context to make the next remote movement predictable.
- Keep important content inside a five-percent 1080p safe region. Sabella's
  screen container reserves 96 horizontal and 54 vertical points so identity,
  navigation, and controls survive conservative display cropping.
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
- Assume a shared household screen. Profile switching should be visible, while
  private account details and sensitive recommendations stay out of ambient UI.
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

The catalog's Playback surface uses public Sky News, tagesschau24, RTL 102.5,
and Radio Italia TV HLS feeds. Its
overlay declares the stream live, supports Play/Pause, and intentionally omits
fabricated duration and seeking controls because the feed does not advertise a
DVR contract.

Linear television keeps playback behind a remote-navigable channel guide.
`SabellaTVChannelGuide` presents channel number and identity, the current and
next programs, schedule progress, and the selected channel. Selecting a channel
returns to unobstructed video; Menu toggles between full-screen playback and the
guide without stopping the stream. Applications provide the channel lineup,
schedule, entitlement, and stream URLs from their authoritative services.
The guide uses a narrow vertical tuning rail, expands the focused row, places
current-program context near the visual center, and keeps Up Next independent at
the trailing edge. It only displays remote instructions backed by implemented
actions: Up and Down browse the lineup, and Select tunes the focused channel.
The live guide uses a neutral full-picture dimmer, a stronger leading scrim for
the channel rail, and a bottom scrim for metadata. Current and next program
details remain unboxed over the picture. The focused channel alone expands and
gains a thin high-contrast outline; unfocused channels recede into compact,
partially cropped tiles. Green is reserved for actual live status.
Color is semantic rather than decorative: sea blue identifies navigation and
focus, desert identifies future programming, muted blue-gray supports metadata,
and each channel tone is confined to its mark and a narrow identity accent. The
current program title remains the only dominant near-white text.
Playback itself is edge-to-edge and sits outside the browse/header container.
Menu reveals the guide over uninterrupted video; pressing Menu again exits to
Browse. Global navigation must never remain visible during full-screen viewing.
Once a channel is tuned, live viewing is entirely unobstructed. Do not persist a
VOD transport card, implementation labels, duplicate channel metadata, or a
fabricated timeline over linear video. The remote Play/Pause command remains
active, and Menu restores the guide.
Television channels use `.suspend` background playback by default: entering the
background stops both picture and sound, then foreground activation resumes only
if playback had been active. Audio-first radio channels may explicitly opt into
`.audio`; never infer background-audio permission from a channel name or URL.

Television and radio belong to one linear lineup. Declare the medium with
`SabellaTVChannel.medium`: television retains the full-bleed video plane, while
radio replaces an absent picture with a branded, low-motion now-playing surface.
The shared guide keeps tuning behavior consistent and marks each row with its
medium. Radio visualization communicates station identity, current programming,
live/paused state, and sound without fabricating video or a seekable timeline.
The catalog enables the tvOS `audio` background mode solely so channels that
explicitly declare `.audio` can continue playing after the app backgrounds.

Playback changes use a restrained ease-in-out transition: the catalog dissolves
into full-screen video, while the guide enters from the leading edge. Reduce
Motion removes this spatial transition.

The Bleecker mark uses the authoritative transparent `gaulatti.png` brand
master. Its square canvas includes the mark's optical spacing, so tvOS renders
it in a square lockup frame rather than recropping or reconstructing its paths.

## Catalog acceptance

The tvOS catalog demonstrates browse, details, playback, and state surfaces.
Browse must show visible top navigation and search, landscape progress cards,
and a poster-based editorial collection. Every control must be reachable and
activatable with directional focus and Select; Play/Pause must toggle playback.
The header must keep the Bleecker mark, product name, navigation, and utility
actions in separate layout regions without collision at 1080p or 4K.
The tall Gaulatti mark must remain large enough for its detached forms to read
at viewing distance; do not place a divider beside its right-hand stroke.
`SabellaTVScreen` owns the full viewport and pins its content to the top-leading
safe region. Short pages must not vertically center the header, and overflowing
pages must scroll only their body rather than displacing global navigation.

## Research basis

- [Apple: Focus and selection](https://developer.apple.com/design/human-interface-guidelines/focus-and-selection/)
- [Apple: Playing video](https://developer.apple.com/design/human-interface-guidelines/playing-video)
- [Apple: Meet Liquid Glass](https://developer.apple.com/videos/play/wwdc2025/219/)
- [Netflix: 2025 TV experience](https://about.netflix.com/en/news/unveiling-our-innovative-new-tv-experience)
- [Google TV: conversational discovery](https://blog.google/products-and-platforms/platforms/google-tv/gemini-google-tv/)
- [Amazon Fire TV: feature rotator](https://advertising.amazon.com/en-ca/resources/ad-specs/fire-tv/feature-rotator)
- [UX Studio: TV interface practices](https://www.uxstudioteam.com/ux-blog/best-practices-for-designing-tv-interfaces)

These sources establish current platform and product patterns, not a mandate to
copy any one service. Sabella deliberately excludes recommendation algorithms,
advertising placement, autoplay policy, and generative search from its visual
component layer.
