# Expeditions — Design System v1.0

**Status:** Approved direction / implementation specification; **not** a claim that assets or UI have already been implemented.  
**Date:** 5 November 2026  
**Target:** Flutter 3.47.9, Dart, Material 3, Android-first and web (600 logical-pixel maximum content width).  
**Files:** this specification + `design_tokens_v1.json` + `CLAUDE_HANDOFF.md`.  
**Source basis:** `APP_AUDIT.md` (4 Nov 2026), `CONCEPT_BOARD_REVIEW.md` (5 Nov 2026), v0.8 screenshots, the original five brand references, and the three subsequent concept-board iterations. If a concept illustration conflicts with an existing functional requirement, **the functional requirement wins**.

> **Implementation principle:** The brand is established. The work is to translate it into a robust design system, not to redesign the brand or copy a flattened AI-generated screenshot. Live Flutter widgets own all text, controls, icons and state; real album covers come from the catalogue. Asset images are for identity and noninteractive illustrations only.

## 0. Decisions, boundaries and unresolved data

| Topic | v1 decision |
|---|---|
| Brand | **Expeditions**; original vinyl + mountain negative-space logo is canonical; reference is `music-app-logo-v2.png`, not a later approximate redraw. |
| Visual language | Flat editorial minimalism, confident geometric headings, warm cream on deep forest-green surfaces, restrained cream outlines, strong real album covers. No glossy effects, realistic AI scenery, decorative shadows or arbitrary gradients. |
| Theme | Ship **dark branded theme only** in v1. Semantic roles allow a light theme later; do not invent or ship an unreviewed light mode. |
| Tabs | **Discover / Expeditions / You**, always visible, preserving each tab's navigation stack and re-tap/back behaviour. |
| Data | Keep `Store`, catalogue, scoring, persistence and all current navigation functions intact. No backend, AI-scoring or playback features introduced under a design-system task. |
| Listening stages | Base Camp, Foothills, High Altitude, Summit are **preassigned approachability categories**, never user quality ratings or numeric levels. The UI term is **Listening Stage**. |
| Ratings | 0–10 in increments of 0.5; whole scores display `9` (not `9.0`), halves `9.5`; `null` displays **–**, distinct from a valid 0 score. |
| Motion | Crisp and restrained. No persistent pulsing, automatic carousel movement, parallax or gratuitous scenic transitions. Respect reduced motion. |
| Shadows | None as default; use tonal surfaces, 1px hairlines and selective outlines instead. |
| Assets | Real album art; next album's cover on expedition cards; genres use custom geometric icons (12 families), **no photorealistic AI-generated scenery**. |
| Your Range | Five substantial, differentiated mountains: **height derives solely from assigned stage**, while numeric badges show the **user's rating**. Unscored albums must not imply any stage. |

**Known coverage limitation.** The concept review reports **15 staged albums out of 9,120**. The earlier audit's approximate catalogue count differs; Claude must read the actual current catalogue and report the current count rather than assume one is correct. Most albums therefore require an explicit *stage not assigned* state. This project **must not fabricate difficulty values**. Data coverage is a separate roadmap item, not a prerequisite to shipping accurate UI states.

**Scope of this document.** This fixes the theme, common component system, interaction rules, baseline layout rules, Your Range visual geometry, icon conventions and QA standards. Per-screen exact compositions and approved SVG production files remain **separate deliverables**. Never treat a conceptual mockup as complete specifications for screens/states it omits.

---

## 1. Colour system

All colours below are **opaque sRGB HEX** unless explicitly called out as a translucent scrim. Use semantic roles (`AppColors`) inside widgets, never raw HEX values in screen code. The core forest/ivory pair is from the approved brand references; supporting tones are proposed refinements.

### 1.1 Primitive palette

| Token | HEX | Intended role |
|---|---|---|
| `forest900` | `#0F2423` | Deepest chrome, shadowless inset surface |
| `forest800` | `#172C2B` | **Canonical branded forest**; page background |
| `forest700` | `#24403C` | Raised cards, input surfaces |
| `forest650` | `#304D48` | Selected or elevated green surface |
| `paper50` | `#F3F0E7` | **Canonical warm off-white**; primary text and dominant CTA |
| `paper200` | `#C4D1CC` | Secondary text |
| `paper300` | `#AABDB5` | Tertiary informative labels, dimmed controls |
| `borderSubtle` | `#557C71` | Decorative hairlines only |
| `borderFunctional` | `#76968B` | Edges communicating an actionable element |
| `mint200` | `#B6E0C6` | Rating fill, progress fill, positive feedback |
| `amber200` | `#F6D48C` | Warning |
| `coral200` | `#F4B7B1` | Error/destructive warning text |

**Verified contrast** (WCAG relative luminance calculation, normal text target ≥4.5:1): `paper50` on `forest800` **12.87:1**, `paper50` on `forest900` **14.21:1**, `paper200` on `forest700` **7.12:1**, `paper300` on `forest700` **5.69:1**. Do not use `borderSubtle` as informative text or as the *sole* boundary identifying a control.

### 1.2 Semantic palette

| Role | Primitive | Where to use |
|---|---|---|
| `page` | `forest800` | Scaffold background |
| `chrome` | `forest900` | Bottom nav, fixed rating dock, app bar if separated |
| `surfaceRaised` | `forest700` | Expedition cards, input backgrounds, track sheets |
| `surfaceSelected` | `forest650` | Pressed/selected tonal panel |
| `surfaceSunken` | `forest900` | Subtle wells / artwork placeholders |
| `textPrimary` | `paper50` | Titles and body |
| `textSecondary` | `paper200` | Artist, metadata, supporting text |
| `textTertiary` | `paper300` | Caption/disabled explanation (not essential actions) |
| `textOnLight` | `forest900` | Text on cream CTA |
| `primaryButtonFill` | `paper50` | Highest-priority button |
| `primaryButtonText` | `forest900` | Text/icon inside filled button |
| `secondaryButtonBorder` | `borderFunctional` | Outlined button boundaries |
| `lineDecorative` | `borderSubtle` | Passive divider |
| `lineFunctional` | `borderFunctional` | Functional border / selection delineation |
| `focusRing` | `paper50` | 2 px keyboard/focus outline |
| `ratingFill`, `progressFill`, `success` | `mint200` | State fill; never alone encodes success |
| `ratingTrack`, `progressTrack` | `forest650` | Slider/progress background |
| `warning` / `error` | `amber200` / `coral200` | Status with explicit text/icon |
| `snowCap` | `paper50` | Range graphic |
| `mountainLit`, `mountainShadow`, `mountainBase` | `borderFunctional`, `forest650`, `forest700` | Range graphic only |
| `unscoredOutline` | `paper300` | Unassigned stage |

Overlaid text on real album art: never rely on the image itself for legibility. Put text inside an **opaque** green panel, cream chip, or a dedicated fixed-contrast plate. If a scrim is necessary for a cropped art background, use `forest900` at 88% opacity behind text and test contrast on white, black and highly saturated covers. **Never tint, recolour, distort or replace the actual square cover image**; the scrim sits on a separate overlay. No algorithmic colour extraction from covers in v1.

States: pressed = `surfaceSelected` or translucent ivory overlay (~8%); selected = tonal change **plus** icon/shape/border; disabled = reduced prominence plus semantic disabled state (never rely on opacity alone for critical text); focus = 2px cream ring with 2px outer gap; error = coral text+icon and explanatory copy. Do not use different listening-stage colours as the sole identifier; shape and label are primary.

---

## 2. Typography

**Production choices, not yet encoded in the app:** **Outfit** for display headings and wordmark-adjacent large text; **Inter** for content, controls and scores. Both should be obtained by Claude from official, licence-permitting distributions and bundled locally with their licence notices. These reproduce the intent of the reference boards; the source raster boards did **not** name a font, so they are not guaranteed exact matches. Do not distribute or attach font binaries from this design-system package.

| Role | Family | Size / line px | Weight | Tracking (Flutter logical px) | Usage |
|---|---|---:|---:|---:|---|
| `display` | Outfit | 32 / 38 | 800 | −0.40 | Rare hero headline |
| `screenTitle` | Outfit | 28 / 34 | 700 | −0.35 | Discover, Expeditions, You |
| `sectionTitle` | Outfit | 20 / 26 | 700 | −0.15 | Tracklist, Your Range, genre sections |
| `cardTitle` | Inter | 15 / 20 | 600 | −0.10 | Album, expedition names |
| `body` | Inter | 15 / 22 | 400 | 0.00 | Main UI body |
| `bodySmall` | Inter | 13 / 19 | 400 | 0.00 | Artist, helpful metadata |
| `label` | Inter | 12 / 16 | 600 | +0.80 | Uppercase stage/section tags only |
| `caption` | Inter | 12 / 17 | 400 | +0.05 | Short ancillary text |
| `score` | Inter | 24 / 29 | 700 | −0.50 | Main rating value, tabular digits |
| `scoreSmall` | Inter | 12 / 16 | 700 | 0.00 | Card score badges, tabular digits |

**Rules:** `TextStyle.height = lineHeight / fontSize` (e.g. body `22/15`); use `FontFeature.tabularFigures()` for score and count displays; avoid font weights below 400 in primary UI; never use letter-spaced 12 px uppercase as multi-line body copy; no essential text below 12 px. Text respects the system scale, including 1.3× and 2×. All album/artist names use real catalogue strings; do not bake text into artwork. Normal grid title max 2 lines; artist max 1, with semantics reading full value. Detail page long titles may wrap to 3+ lines; avoid fixed-height headers.

---

## 3. Sizing, spacing and responsive layout

**Base unit:** Flutter logical px, not physical screen pixels. Use the spacing scale `0, 2, 4, 8, 12, 16, 24, 32, 40, 48`. Standard gutter = **16**; between sections = **24**; inside cards = **12–16**; between grid cards = **8 horizontal / 12 vertical**. Layout elements should share a consistent left edge. Hard-coded per-screen exceptions need a named design token.

**Radii:** `0 / 4 / 8 / 12 / 16 / 24 / full`; app cards 12, square covers 8, modal sheets top 24, pills full. Use no drop shadows by default. Divider height 1 physical pixel and spacing handled externally (avoid putting 24px inside Divider itself).

| Element | v1 dimension |
|---|---|
| Tap/keyboard target (all functional touch controls) | At least **48×48**; visible icon may be 20–24 |
| Primary button | 52 tall; minimum 48 target; side padding ≥16 |
| Secondary/tertiary button | 48 tall, full accessibility target |
| Standard icon | 24 viewBox, 20 actual visible icon as appropriate |
| Toolbar/AppBar | 56 tall **plus** top system safe inset handled by Scaffold |
| Bottom navigation | **72** tall **plus** bottom system gesture inset, never obscure content |
| Fixed album/song rating dock | **72** tall excluding conditional Next row |
| Conditional expedition Next row | **40** tall, tap target extends to 48 |
| Score cell in rating dock | width 68, full 72-high tap region |
| Grid cover | responsive card width, always 1:1 |
| Cover named sizes | 44, 64, 112, 160, 224; use fluid sizing where needed |
| Hero album cover | `min(240, max(200, 0.56 × viewportWidth))` at normal text; keep 1:1 |
| Expedition progress line | 6 tall; one equal-length segment per stop |
| Range canvas | ~260 minimum at 360–412; may grow with text and safe areas |

**Breakpoints:** At 360 and 412 dp wide (primary), 3 album grid columns; at 480–600 dp, 4 columns (within centered 600-dp app cap). Under 2× text scaling, switch to 2 columns on phones to protect readable titles; do **not** shrink text or crop controls to preserve 3 columns. Grid card height must derive from content, never a rigid 0.56 aspect ratio for the entire portrait card. Width formula: `(contentWidth - (columns−1)×8) / columns`; `contentWidth = viewportWidth − 32` up to 600 cap. At 360: 104 dp card width; at 412: ≈121 dp; at 600/4 columns: 136 dp. All headers, modals, track rows and cards can expand vertically under larger text. Scroll under safe areas without obscuring action targets.

**Desktop/web:** centered viewport max 600 with deep green exterior. Hover and visible focus states; mouse wheel scroll, keyboard Enter/Space semantics, Escape to dismiss overlays where supported. Do not force desktop layouts or additional sidebars in v1. Android status bars and gesture insets follow actual device; iPhone-style status-bar elements from AI concepts are **not part of the design**.

---

## 4. Component contract (shared library)

Every interactive component must define default, hover (web), pressed, focused, selected/active, disabled (if supported), loading, successful/error states as applicable. `Semantics` covers names, role, state and available action. Visible icon sizes may be small; the **hit region remains ≥48**.

### 4.1 Cover and real artwork

- `Cover`: square `AspectRatio(1)`, radius 8; render cover at original aspect, never colourised. For source artwork, use current existing URL/caching pipeline (`cached_network_image` Android and web fallback). Maintain cache decode sizing.
- **Loading:** green recessed panel with simple record glyph at center; no rainbow placeholder gradients. On successful network load, 200ms crossfade; on permanent failure show same branded placeholder plus appropriate accessible description.
- **Hero/shared element:** 240ms easeInOutCubic only between tapped grid/list cover and album detail cover when both are on screen and in the router. Disable spatial effect under reduced motion. No forced extra navigation.

### 4.2 Album card — grid

- Portrait composition: square cover, then album title (2 lines), artist (1 line), optional listening-stage label under artist. No fixed total height. 12px outer corner radius if a tonal backing is needed; never box every card unnecessarily.
- Inside cover **only** bookmark (top-right) and user's saved score (bottom-right). Bookmark icon 20 inside at least 48px tap region; score a stable contrast-checked opaque chip, 12px score text. Make sure 48px bookmark hit box doesn't steal the cover's main tap action; test overlapping hit regions.
- Charts additionally show rank **outside the cover**, next to title or above the card; release type likewise a muted text label below. Locked trail state is a trail-only layer, not a permanent grid overlay.
- One tap on cover/title opens album. One tap on bookmark toggles Listen later; long press remains optional shortcut with Undo. Score display does not block artwork navigation. When bookmarking, icon changes fill (100ms) and announces saved/removed state.
- On search/genre grids, keep artist text legible and make accessibility label read `{title}, {artist}, your rating {value or not rated}, listening stage {stage or unassigned}`.

### 4.3 Album card — list

- Min row height **72**; 56–64 square cover, title, artist, optional stage label, rating badge or dash, trailing chevron (only if navigation). Bookmark must still have a dedicated ≥48 one-tap control on list rows if Listen later is available on corresponding grid cards. Do not put bookmark behind `…`.
- Whole content area opens detail, excluding explicit action controls. On 200% text, row expands; rating and bookmark remain reachable.

### 4.4 Rating bar and slider — foundational behaviour

- Always docked **above persistent tab bar** on album/song detail; `72` high, deep chrome; conditional **Next** row immediately below or directly adjacent inside the fixed dock, at least 48 tap region, only in appropriate expedition context.
- The saved value is on the left in a **68×72** interactive cell; slider takes remaining width with ≥20px side allowance from Android back gesture edge. Use `MediaQuery` insets, never overflow under system gesture controls.
- **Unrated:** value `null`, display **–**, neutral grey-green slider with unrated thumb at low end. This is not score zero. First tap/drag chooses a 0–10 half-step value; save on **pointer release**, not every intermediate tick. Update number live while dragging. **Valid `0`** displays `0`.
- **Rated:** 0–10 in 0.5 increments, whole as `9`, halves as `9.5`; retain `tap score → clear → 3s Undo` semantics. Semantics for score: `Your rating 9 out of 10. Double tap to clear`; custom label for slider `Your album rating; 0 to 10, steps of 0.5` (song/track/expedition substitutes noun). Make slider adjustable by accessibility actions/keyboard.
- **Saving:** do not invent asynchronous back-end persistence; when local store commits after release, play 120ms numeric settle (scale 1.00→1.05→1.00) plus a single subtle haptic; no blocking dialog or extra confirm. Haptic selection-click only when a discrete step changes, avoid an excessive pattern on rapid drags; no haptics on web.
- **Track ratings:** reuse a shared rating slider in the current bottom sheet; **one-tap Rate button per track remains** rather than a three-dot menu. On track rating save, sheet closes on release as today; swipe-to-clear remains. The expedition-level rating slider is **separate in the trail page** but uses the same component styling.

### 4.5 Listening-stage glyphs and badge

**Four genuinely different silhouettes, unified as a system:** identical arch enclosure and cream fill style, but **distinct inner compositions**. Do not treat Summit as a copy of High Altitude with a flag added.

| Stage | Unique geometry — full ~64px | Compact ~24px motif |
|---|---|---|
| **Base Camp** | A single angular tent with doorway/roof canvas and flat ground | Solid triangular tent with opening |
| **Foothills** | Low, continuous curved ridge and a single sun/disc, no pointed mountain | Low wave plus dot |
| **High Altitude** | Three sharp interlocking jagged peaks with staggered ridges | Two/three serrated mountain teeth |
| **Summit** | **One isolated tall, flat-topped or steep monolith / pinnacle**, sharply rising from two stepped rock ledges; one thin winding **switchback path** and tiny summit marker optional. Absolutely no multi-peak zigzag that copies High Altitude | One tall solid pinnacle with distinct stepped base; omit details/flag if too small |

Requirements: all four recognisable in **one colour**, no colour-only differences; icons survive silhouette-only viewing at 16px. Stage primary SVG has `viewBox="0 0 64 64"` including arch frame; compact has `viewBox="0 0 24 24"` with simplified details. Implement separate path shapes, not image generation with inconsistent geometry. Large icon art 64×64, compact visible 16–20 on 24 grid, placed in a 48-tap pill when interactive. Button opens the **existing stage explanation** (no scores or fake tags). Stages remain words + icons, never 1/2/3/4. If no stage, show accessible `Listening stage not assigned` only where it is functionally relevant; never claim a stage.

### 4.6 Genre navigation tiles

- No realistic nature photography or AI-generated scenery. Use 12 cohesive **single-colour geometric vector glyphs** on green surface, 1.8–2px equivalent stroke, with a recognisable symbol plus explicit genre label.
- Families exactly from audit/review: Rock (record grooves), Pop (spark/ring), Hip-Hop (stacked equaliser bars), Electronic (sine wave/circuit), Metal (sharp lightning chevrons), Punk (two torn diagonal slashes), R&B & Soul (heart with waveform), Folk (acoustic string arcs), Jazz (syncopated note motif), Psychedelia (spiral), Experimental & Ambient (concentric ripples), Other (four-dot grid). These are proposed symbols, **not stereotypes or added taxonomy**.
- Visual tile min 96px wide, 88px tall at compact widths; actual full tile is tappable. Display 3 across when opening a compact genre directory. Keep **all existing genre album rows and all genre pages available**, either on Discover below an icon navigation strip or via explicit `See all genres`. A decorative tile must never replace a functioning album browse route without another direct route.
- The first Discover viewport should still feature actual covers. Do not generate fake covers or a Featured recommendation list. If a Featured module is later added, its content must come from existing `Continue` / popularity data, no new backend.

### 4.7 Expedition tile and progress

- Existing `Continue` card stays at the top of Expeditions. Existing user-created and built-in expedition sections retained. Preserve title, description, `In order`, personal average, expedition rating, progress, creation entry and accessibility.
- The artwork on each expedition card should **feature the square cover of the next album to listen to**. Use existing next-stop selection logic from the repository (inspect source, do not guess album index). The art may occupy a prominent leading image panel; adjacent copy sits on a solid forest surface. If any board suggests a full-width landscape: **reject it**. No AI scenery.
- **Unstarted:** cover of first stop. **In progress:** cover of next uncompleted stop. **Complete:** most recently completed/final album cover **plus prominent `Complete` label**, never pretend it is a next stop. **Artwork missing:** branded record placeholder.
- Progress: 6px line split into equal visual segments equal to stop count, completed segments filled mint, remaining muted; text `2 of 5`. Never use an animated progress simulation that gives the wrong count. Existing `Continue` tap leads directly to the correct next-album context.
- Trail is **sideways-scrolling and zig-zagging**, travelled section solid, upcoming section dashed, larger final stop, locked stops marked with **lock icon + text and contrast**, opens scrolled to the next stop. No invented straight three-cover layout. In-order restrictions, Reset/Edit/Delete menus and Undo must continue to work.

### 4.8 Your Range (key distinctive feature)

This must be a **code-drawn responsive mountain skyline** using `CustomPainter`, not an exported static image. Five slots fill a 328px-wide usable area at a 360px viewport (about 65.6px per slot). Each slot has a visible 48px album-cover target at the **summit** (or a 48px dashed add slot), body facets, prominent ridgeline and a shared baseline. **Substantial, sculptural shapes, not thin triangular outlines**; no realistic texture or photo mountains. The mountain uses two flat faces, optional small snow cap, a sharp silhouette and ridge outline; avoid showing the skyline behind textual lists.

**Stage mapping: measured from common baseline to mountain apex, in logical px:**

| Stage | Height | Shape |
|---|---:|---|
| Base Camp | 80 | Broad low ridge |
| Foothills | 102 | Rounded/rolling ridge with stronger shoulder |
| High Altitude | 130 | Steep split face |
| Summit | **156** | Isolated tall verticalised pinnacle with sharp shoulder and snow cap |
| Stage unknown | **98 visual placeholder only** | Neutral dashed/outlined facet, `?` / `Stage not assigned`, *not* an implied relative rank |
| Empty slot | No assigned height | Dashed cover slot and faint dotted peak; tap opens current Range picker |

On a **260dp canvas**, nominal baseline is y=208, leaving up to 52dp above the Summit apex for 48dp cover. Position the cover so its bottom edge meets or slightly overlaps the peak tip without causing touch targets to overlap. A cover's **rating badge stays on the cover**, as in the audited current behaviour, while heights come solely from stage. Do **not** determine height from 9.5 vs 10.0 or infer a stage from album popularity. Use the same four stage descriptions as everywhere. Unscored albums must be visible, selectable and labelled; don't put every unscored album at Base Camp.

**Interaction:** tap peak opens album; tap empty peak invokes picker (rated albums highest first, as today); removing an occupied slot has a visible accessible alternative to long press and gets Undo. Animate height changes only after stored Range selection updates; no arbitrary animations on every scroll. 200% text: keep the five-peak graphic in its own horizontally constrained region but grow descriptive copy/list below and provide screen-reader summaries for each peak.

### 4.9 Other primitives

| Component | Design and functional contract |
|---|---|
| Buttons | Primary cream fill + dark icon/text, 52 high; secondary 1px functional outline, 48 high; text action 48-high target. All pressed/focus/disabled states. No button that does nothing. |
| Chips | **Filter** (toggle with check/state), **navigation** (chevron/route), **informational** (not tappable) are visually distinct, including semantics. Compact visual 28–32 high but target ≥48 when actionable. |
| Section header | 20px Outfit title, optional count, trailing named action (`See all`, `Sort`). Align to 16px gutter. |
| Search field | 48–52 high, icon 20 and clear action 48 target; results update with typed query as now; make visible search the entry point, don't add duplicate search icon. |
| Sort | Names current order and reverses on selecting same option; ≥48 target; retain on all existing sort pages. |
| Tab navigation | Three tabs, 72 high plus safe inset, 24px paired outline/filled icons, 12px label; selected indicated by icon + tonal capsule + text; re-tap behaviours unchanged. |
| Progress | 6px segmented per stop with textual count. Accessible progress label. |
| Review/track rows | Row min 56/64, grows with text. Keep one-tap Rate; reviews keep write/edit/like/comment/report accessible. |
| Snack bar | Deep chrome panel, cream explanatory text, **Undo** explicit 48 target; destructive changes do not acquire confirmation dialogs. |
| Bottom sheet | Elevated-green surface, 24px top corners, safe-area padding, visible title, accessible close; rating sheet commits on release. |
| Dialog | Branded tonal overlay for review, comment, report, range-full chooser; keyboard and accessibility focus handled. |
| Empty state | Minimal vector pictogram + clear headline + useful action when available, no fake data; do not use AI scenery. |
| Error/retry | Error icon + human-readable cause + one-tap retry if network-related. |
| Skeleton/loading | Static low-contrast placeholders or short fade; **no endless shimmer required**, keep cover load animation 200ms. |
| Rating-spread mountain chart | Preserve existing real-data chart and its scale; repaint in branded palette, hide developer **Test** control from release. |

---

## 5. Screen contract: what may not disappear

**The concept boards are not inventories of functionality.** Before implementing any screen, Claude must use the audit's screen inventory and produce a table mapping every existing action to its placement in the new design.

| Screen/flow | Functions required in the subsequent screen spec |
|---|---|
| Discover/Search | Live search, artist results, chart entry (Popular, Top rated, Hardest, decades), Rated by me filter, genres, genre album rows, sorting with reverse, album bookmark, nested browse, tab re-tap behaviours. No nonfunctional `Featured` carousel. |
| Album | Big real cover, full title/artist, stage explanation if assigned, genres/subgenres, listen later, Your Range, tracklist, **one-tap track Rate**, tracklist retry, rating-spread chart, release facts, reviews/actions, fixed rating bar, expedition `Next` when relevant. Community stats only if backed by actual data; do not fabricate a platform average. |
| Chart/Genre/Artist | Accurate ranking/order/count, current genre A-Z jump, artist studio-first grouping, minor releases, artist pages and sorts. |
| Song | Separate track rating and review, return-to-album link, real song metadata, fixed rating dock; keep circular vinyl-inspired cover if it still fits. |
| Expeditions list | Continue card, all built-in/user tiles, `+ create`, completion/progress and existing lock/rating labels. Album-cover-led cards. |
| Expedition trail | Sideways **zig-zag**, solid/dashed travelled paths, next-stop auto-position, locked state, larger final stop, reset/edit/delete with Undo, separate expedition rating. |
| Create/Edit expedition | Name + description, reorder, listen-in-order, sort by year, add album picker, validation, save state, remove with Undo where allowed; existing pick flow preserved. |
| You / Your Range | Editable nickname, five mountain slots, stage-based heights, missing stage state, picker/replace/removal, Rated 3-across grid, Listen later, Reviews, list sorting, swipe-to-clear + Undo, About entry. No fake @username or avatar/profile-photo action. |
| Overlays and support | Track rating sheet, review/comment/report, Range-full chooser, About, missing-page, error/empty/loading states. |

**Primary-path tap budget is protected:** Search album → rate = current 2 taps + typing + 1 drag; Listen later = 1 tap; Next expedition stop = 1 tap; track Rate = 1 action from track row; clear rating = 1 tap + optional Undo. No added confirmation steps. No invented play/shuffle controls unless an actual playback function is later implemented.

---

## 6. Motion specification

Use Flutter built-ins where feasible; package `animations` is optional and **requires approval** before installing. `Hero`, `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedScale`, `AnimationController` + existing `CustomPainter` can cover the initial system. All motion tokens are in JSON.

| Token / action | Duration | Curve | Trigger / definition |
|---|---:|---|---|
| `press` | 100ms | easeOutCubic | A press lowers visual scale 1.00→0.98 or changes tonal surface; release restores. Never delay the event callback. |
| `ratingValue` | 120ms | easeOutCubic | Numeric value updates in discrete half steps while dragging; settles after release/commit. |
| `fade` | 180ms | easeOutCubic | Minor state swapping (bookmark, empty/list), tab fade-through if transitions selected. |
| `coverReveal` | 200ms | easeInOut | Cover loading placeholder → real cover, no layout shift. |
| `hero` | 240ms | easeInOutCubic | Shared cover travels from tapped album card into the large detail cover, bounds resolved from actual screens. |
| `screen` | 280ms | easeOutCubic | Page slide/fade (Android back gestures and tab stacks still work). |
| `trail` | 400ms | easeInOutCubic | After rating a stop is **committed**, draw the newly travelled segment forward from previous stop to newly unlocked stop; scroll only enough to reveal it. |
| `rangePeak` | 400ms | easeInOutCubic | When slot content/stage changes, interpolate peak height from old to new; image stays aligned with peak. |
| `completeMoment` | up to 500ms | easeOutCubic | One-time subtle summit/check reveal when an expedition finishes; **does not block rating or navigation**. |

**Feedback sequence for a rating:** the user drags/taps → numeric label updates immediately → on release existing Store save occurs → after confirmed local update show 120ms settle and optional soft haptic → Undo available on clear. No animation controls persistence. **Reduce motion:** when `MediaQuery.disableAnimationsOf(context)` is true, set spatial/scale/path durations to 0 and replace page effects with instant or minimal fade; do not animate large hero covers or peak growth. Never auto-scroll more than required or animate while the user is dragging the slider. Defer complex animations until the data and screens are stable.

Haptics: selection click on meaningful rating half-step changes (throttle while quickly dragging), one soft feedback on completed stop/success; no haptics on every ordinary button tap. Web: no haptics. Ensure frame performance on lower-end Android: cache genre lists, avoid wide Store rebuilds, animate only opacity/transform or efficient paints and use meaningful `shouldRepaint` comparisons. No expensive blur or parallax on long album grids.

---

## 7. Accessibility contract

1. **Touch:** all actionable regions ≥48×48 logical px; visual icons may be smaller. This includes stage pills, track Rate, Sort, A–Z index, ratings, report icons and header back buttons.
2. **Contrast:** normal text ≥4.5:1 against its actual final surface; large text/non-text controls ≥3:1. Decorative borders can be quieter but cannot be the sole indication of interactivity. Test cover overlays individually.
3. **Text scaling:** support at least system 1.3× and 2× on 360/412/600 widths without clipping essential titles, buttons or lists. Switch grid to two columns when needed; increase heights, allow scrolling and never disable text scaling.
4. **Screen readers:** every actionable control has a label, role and selected/disabled state. Expose a meaningful `Semantics` description for each peak (album + rating + assigned stage/unscored), the trail (current stop, locked/unlocked), chart (real rating counts/distribution) and progress (`2 of 5 albums rated`). Avoid duplicate announcements from `CustomPaint` plus overlapping labels.
5. **Keyboard/web:** visible 2px focus ring, logical tab order, Escape dismiss where supported, Enter/Space activate, sliders adjustable by keyboard.
6. **Gestures:** long-press and swipe actions must have visible alternatives. Make Range removal accessible via a menu/action with Undo; retain existing swipe shortcut. Avoid hidden destructive actions without recovery.
7. **Motion:** honour system Reduce Motion; don't convey state only through animation or colour. Motion is optional feedback; text/icon change is permanent.
8. **Errors:** actionable error messages; never show unusable empty controls. Network-free catalogue screens remain useful without loaded tracklists/covers.
9. **Platform:** preserve Android edge/back gestures, bottom system safe area, and web route/back behaviour. Test on real Android APK, not only web screenshots.

---

## 8. Asset requirements and provenance

**Identity source:** use the provided `music-app-logo-v2.png` as *visual master* for manual vector recreation of the original concentric record grooves + negative-space peaks; preserve proportions and cream fill. A screenshot board is not a downloadable logo asset. Verify the traced SVG overlaid against the actual original before shipping.

**Assets to produce after approving a dedicated source sheet:**

| Priority | Asset | Output |
|---|---|---|
| P0 | Logo mark and lockup | Clean SVG mark, optional wordmark lockup (true text where sensible), flat one-colour |
| P0 | Listening stages | 4 large (~64) + 4 compact (24) SVGs, distinguished by geometry described in 4.5 |
| P0 | Navigation | Three unselected + three selected monochrome 24px glyphs |
| P1 | Genres | 12 matching 24/48 adaptable geometric pictograms |
| P1 | Launcher/splash | Android adaptive icon layers (including monochrome) + branded solid forest native splash; web favicon/icon |
| P2 | Empty/error illustrations | Limited flat vector set where screens need them; no generated realism |

Prefer crisp vectors or Flutter `CustomPainter`; if choosing SVG at runtime, Claude must **request approval** before adding `flutter_svg` (and any build-time launcher/splash packages). Alternative: translate simple icons into Flutter paths and use existing Material glyphs temporarily, but do **not** silently approximate the four unique listening-stage designs with generic icons. Store assets under `assets/brand/`, `assets/icons/`, `assets/illustrations/` and `design/mockups/`, using snake_case; bundle UI assets so offline rendering works. Do not ship the AI concept boards or introduce fake covers as assets. Font binaries must be obtained and licence-checked separately by the developer, not distributed in this package.

---

## 9. Implementation architecture — recommended to Claude

Recommended file structure (adapt to current codebase; a migration need not split every file in its first pass):

```text
lib/design/
  tokens/
    palette.dart      # raw approved primitives
    app_colors.dart   # semantic roles as ThemeExtension
    app_type.dart     # TextTheme, score/tabular type
    spacing.dart      # shared spacing, radii, cover sizes, chrome sizing
    motion.dart       # durations, curves, reduced motion
  theme.dart          # ColorScheme + Material component themes
  components/
    app_cover.dart, album_card.dart, rating_bar.dart, rating_slider.dart,
    stage_badge.dart, section_header.dart, app_button.dart,
    expedition_tile.dart, range_skyline.dart, state_views.dart
assets/brand/  assets/icons/  assets/illustrations/  assets/fonts/
design/
  DESIGN_SYSTEM_V1.md
  design_tokens_v1.json
  specs/             # future per-screen docs
  mockups/           # references only
```

- Populate `ThemeData(useMaterial3: true)` from **one** semantic dark `ColorScheme` + component themes; keep application `Theme.of(context)` usage. Preserve current architecture and `go_router` tab stacks.
- Use named primitives and semantic token getters; keep raw HEX and geometry in design files only. Components consume tokens; screens compose components.
- First PR/branch: **design tokens + theme + type only**, no user-flow changes. Confirm build/test and that app assets/branding are not silently approximated. Subsequent PRs: cover/card/badges/rating bar, Album page, other screens, motion, then optional assets.
- Do not alter `store.dart`, `catalogue.dart`, `details.dart`, `models.dart`, `expeditions.dart`, persisted keys or saved rating semantics as part of a pure design-system implementation. Any architecture change affecting behaviour requires separate approval.
- Since Android builds run in GitHub Actions, compare web screenshots at **360 / 412 / 600**, and have Bailey test the produced APK on an Android phone for haptics, edge gestures, system status/nav bars and text scaling.
- Keep package additions (`flutter_svg`, `animations`, launcher/splash generators) separately approved; no package is mandatory for starting tokens/theme.

### Acceptance criteria / test gates

- [ ] Palette, fonts, sizes, radii, motion use named tokens; no ad-hoc colour literals in screens.
- [ ] All previously supported screens/routes/actions still work; no fake controls or fabricated app data.
- [ ] Rating: `null/–`, valid `0`, halves, save on release, first-tap selection, clear + Undo, fixed position, next stop work exactly as v0.8.
- [ ] Grid on normal phones: 3 portraits across with real album art, bookmark 1 tap, readable artist/title; 2 columns when scaling requires it.
- [ ] Album/song: track Rate still 1 tap; reviews, genre chips, release facts, chart, song and artist links present.
- [ ] Expeditions: Continue, zig-zag trail, in-order locks, correct next-album-cover mapping, finished state, Create/Edit, Undo retained.
- [ ] Your Range: five substantial peaks, heights from assigned stage only, unknown and empty states, `?` and accessibility, 48px album slots, Undo for removal.
- [ ] All four stage glyphs discernible without labels in silhouette at 24px and recognisable at 16px (then still shown with a label in UI).
- [ ] User-facing strings, list data, album covers and counts are real; no AI-image text, inconsistent brand logo or imaginary functionality.
- [ ] Screen-reader controls labelled; reduce motion and 2× text work; every actionable target ≥48.
- [ ] No regressions in analysis/tests; screenshots reviewed at 360, 412, 600; Android release validated.

### Visual authenticity gate (“does not look AI generated”)

Every implemented screen gets a manual check for: (a) consistent baselines, gutters, optical alignment and type; (b) identical icon stroke/weight and original logo proportions; (c) genuine cover art and correct title/artist metadata; (d) no auto-generated mountains/photos on genre or expedition tiles; (e) no inaccessible microscopic labels; (f) no superfluous decorative cards or fake play/ellipsis controls; (g) sober, restrained animations that match the UI state. Reference boards **cannot** override observed function or content.

---

## 10. What to design next (separate from this completed system)

1. **Production glyphs:** original logo trace, stage 4×2 icons, selected/unselected tabs; small/large samples tested at 16, 24, 64px.
2. **Album detail screen specification:** default unrated, rated, long title, track loading/error, missing artwork, missing stage, open-from-expedition and 200% text variants. Include album metadata, genre chips, reviews, rating spread, track rating and fixed bar. Provide 360/412 mockups and actual Flutter-ready component tree.
3. **Discover**, preserving charts, genres, searches, artist results, tabs and all current filters/sort.
4. **Expeditions list + actual zig-zag trail** (not the simplified straight path in concept art).
5. **Your Range + You** with the detailed mountain visual, unscored state and full list behaviours.
6. **Artist/Genre/Chart/Song/Create/Edit/About and all overlays**; end-to-end visual/functional review and polish.

**Frozen at v1:** foundation tokens and behavioural constraints in this document. **Not yet frozen:** exact typography match to raster reference fonts, detailed per-screen layouts, actual production SVG path geometry, and optional plugin/tool choices. These require visually verified files and app screenshots; Claude must not invent them by extrapolating an AI concept board.
