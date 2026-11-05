# Concept Board Review (v1)

**Board reviewed:** `design/mockups/concept_board_v1.png` ("Expeditions App Redesign – UI/UX Specification")
**Compared against:** `design/APP_AUDIT.md`, the v0.8.0 code, and Bailey's requirements of 5 November 2026
**Date:** 5 November 2026
**Author:** Claude Code (technical lead). Read-only review; no app code changed.

Labels used: **Fits** (can be built as shown), **Constraint** (a technical or data limit ChatGPT should design around), **Decision** (needs Bailey's call before specs are final), **Missing** (needs a spec that the board doesn't give).

---

## 1. Summary

The direction is buildable in Flutter, and most of the board's numbers match what the audit recommended: 16 px gutters, 48 px touch targets, 12 px radius, a fixed rating bar, Undo instead of confirmations, and short motion timings. The cover-led layouts and the reduced overlays on album cards fix the audit's biggest visual problems.

Before ChatGPT writes detailed specs, five points matter most:

1. **The board is a dark theme.** Today the app is light-only. Decide: dark only, or dark plus light? (Section 3.1.)
2. **Difficulty data is the main blocker for the Your Range and stage visuals.** Only **15 albums** (the expedition stops) have a difficulty today, out of 9,120. Until AI scoring exists, most Range peaks would all be the same height, and most album pages would have no stage badge. (Section 3.2.)
3. **The board drops several existing functions.** These include the Continue card, the zig-zag trail, decade charts, "Rated by me", genre album rows, sort, track rating buttons, locked stops, and the album page's genres, facts, chart and reviews. Bailey asked to keep all functionality, so ChatGPT needs to place each one. (Section 4.)
4. **"Featured" on Discover has no data source.** Nothing in the app picks a featured album today. (Section 3.4.)
5. **Several screens and states are not on the board.** These are the artist, genre, chart, song, create-expedition, About and Range picker pages, plus every empty, loading, error, locked and unrated state. (Section 5.)

---

## 2. What fits as shown

| Board element | Status | Notes |
|---|---|---|
| Forest green `#172C2B`, deep green `#0F2423`, raised green, warm off-white `#F3F0E7` | Fits | Off-white on forest green is 12.9:1, and on deep green it is 14.2:1 (well above the 4.5:1 minimum) |
| Spacing: 16 px gutter, 24 px sections, 12 px card gap, 12 px radius | Fits | Matches the audit (section 9.3). Replaces today's 10/12/16/20 mix |
| Touch target 48×48, button height 52, bottom nav 72 | Fits | Some controls are 36–44 px today (audit 5.4); these get fixed as part of the redesign |
| Album hero 200–240 px on the album page | Fits | Uses the existing 500 px cover image; looks sharp at 240 px on most phones |
| Album card (grid) with only bookmark + rating on the cover | Fits | Solves the "5 overlays" problem. Rank, type and difficulty still need a home (section 4) |
| Album card (list) with cover, title, artist, rating pill, chevron | Fits | New component |
| Fixed rating bar "9.0 / 10" + slider | Fits | Same position and behaviour as today. See 3.6 for the unrated state |
| Segmented expedition progress bar ("2 of 5") | Fits | One segment per stop; drawn in code |
| Expedition cards showing the next album's cover | Fits | Uses the same "next stop" logic as the Continue card (`nextStop`, `lib/expeditions.dart`). Needs a spec for completed expeditions (no next album) |
| Motion timings (280 / 180 / 100 / 200 / 120 / 400 / 300 ms) | Fits | All achievable with Flutter's built-in animations plus the official `animations` package. Reduced-motion fallbacks need adding (3.8) |
| Interaction principles (keep navigation, fixed rating bar, Undo, large artwork, 4.5:1 contrast, text scaling) | Fits | Same as the audit's Appendix B |
| Tab bar: Discover, Expeditions, You, with a filled selected icon | Fits | Needs a selected/unselected pair for each of the 3 tab icons (today Expeditions has none) |
| Common icon style (play, heart, plus, shuffle, bookmark, mountains, search) | Fits | Either an existing rounded icon set or custom SVGs. Shuffle and play have no function in the app today; see 3.9 |

---

## 3. Technical constraints and decisions

### 3.1 Dark theme (Decision)
- **Observed:** the whole board uses dark green backgrounds with light text. The app is light-only today (`lib/main.dart`). Bailey's earlier rule was "no dark theme".
- **Constraint:** building the tokens for both themes costs little extra, but designing, testing and checking the contrast of every screen twice roughly doubles the visual QA work.
- **Options:** (a) dark only, which matches the board and is quickest; (b) dark by default plus a light version later through the same tokens; (c) follow the phone's system setting from day one.
- **Recommendation:** (b). Build every colour as a named role so a light theme can be added without touching screens. Ship dark first.

### 3.2 Difficulty data vs Your Range peaks and stage badges (Constraint + Decision)
- **Observed:** difficulty comes only from the hand-set expedition stops (15 albums; `difficultyOf`, `lib/expeditions.dart`). AI difficulty scoring was planned for later.
- **Effect:** with today's data, a Your Range of five favourites would usually show five peaks at the same "no difficulty" height. The "substantial, clearly different heights" Bailey wants won't show until most albums have a difficulty. Stage badges will also be missing on almost all album pages, and the "Hardest" chart stays thin.
- **Decision needed:** (a) design the "no difficulty" state properly (for example a neutral low peak with an "unscored" mark) and wait for AI scoring; (b) bring AI difficulty scoring forward so that it ships with the redesign; (c) hand-score a larger set of popular albums first.
- **Recommendation:** (a) for the redesign itself, and move (b) earlier in the roadmap. ChatGPT must design the no-difficulty peak and badge as real states.

### 3.3 Your Range drawing (Constraint)
- **Requirement:** large, pronounced peaks with heights set by difficulty, not rating.
- **Constraint:** the peaks must be **drawn in code** (Flutter `CustomPainter`) because their heights change with the data. The board's shaded, snow-capped peaks are achievable in code with flat shapes: a body, a shadow side and a snow cap. Photographic texture is not achievable this way.
- **Ask ChatGPT for:** a vector peak style (2–3 tones, snow cap shape, ridge line), the height for each of the 4 levels plus "unscored", how the empty-slot state looks, where the rating sits (the board puts it under the peak), and the minimum height that still fits a cover on top at 360 px width.
- **Space note:** five peaks across 360 px gives each slot about 66 px. Covers on the peaks can be about 44–52 px. The board's covers look about 40 px.

### 3.4 Discover "Featured" carousel (Decision)
- **Observed:** the board shows a "Featured" card (In Rainbows) with page dots. Nothing in the app selects featured albums, and there is no backend.
- **Options:** (a) a fixed, hand-picked list in the app (editable in a data file); (b) automatic, for example the most popular albums or the next stop of your current expedition; (c) drop it for now.
- **Constraint:** auto-advancing carousels hurt accessibility. If it moves on its own, it needs a pause control.
- **Recommendation:** (b) "Continue your expedition" plus popular picks. This needs no new data and supports the core loop.

### 3.5 Genre tiles (Decision + assets)
- **Observed:** the board shows 3 icon tiles (Rock, Electronic, Hip-Hop) and "See All". The app has **12 genre families**: Rock, Pop, Hip-hop, Electronic, Metal, Punk, R&B & Soul, Folk, Jazz, Psychedelia, Experimental & Ambient, Other (`data/genres.json`).
- **Needs:** 12 minimalist SVG icons in one style, plus a rule for what the tiles replace. Today Discover shows a sideways row of 20 albums per genre. Do the tiles replace those rows, or sit above them?
- **Recommendation:** tiles in a compact grid (3 across, 4 rows; or one scrolling row), each opening the existing genre page. Keep one or two album rows (for example "Popular") so Discover still shows covers above the fold.

### 3.6 Rating display (Decision)
- **Observed:** the board shows "9.0 / 10" and "8.5". Today whole numbers drop the ".0" ("9"), and an unrated album shows "–".
- **Decide:** always one decimal ("9.0"), or as today? Keep the "/ 10"? The unrated state must still show "–" with a grey slider (Bailey's earlier rule). The board doesn't show the unrated state.

### 3.7 Fonts (Decision + licence)
- **Observed:** the board shows a bold geometric display face and a "thin" UI face, without naming either.
- **Constraint:** thin weights (100–300) on dark backgrounds at 13–15 px are hard to read and are likely to fail the board's own accessibility goal. Body text should be Regular (400) or heavier.
- **Needs:** exact font names, the weights used, and an open licence (for example SIL OFL), so the files can be bundled in the app.
- **Type scale:** the pairs "32 / 28", "24 / 20" and so on are ambiguous. Do they mean size / line height, or large / small screen? ChatGPT should state the size, line height and weight for each style.

### 3.8 Motion (Mostly fits; small changes)
- A **haptic on every button press** feels heavy on Android. Recommendation: haptics only on rating steps, saving a rating, and completing an expedition stop.
- **Reduced motion** isn't on the board. When Android's "Remove animations" setting is on, timings drop to near zero and slides become fades.
- **"Expedition trail advance 400 ms slide/flow"** needs a spec: what moves, where, and what triggers it.
- **Cover cross-fade 200 ms:** fits. Today covers appear with no fade (`lib/widgets.dart`).

### 3.9 New or changed functions shown on the board (Decision)
The board shows some controls that do nothing today. Each needs either a function or removal:
- **"…" menu on the album page header and on each track row:** no menu exists today. What goes in it? On tracks, it seems to replace the "Rate" button. That adds a tap to track rating unless the menu opens the rating sheet directly.
- **"Continue Expedition" primary button** on the trail page (new, and a good idea: it opens the next stop). It probably overlaps with the Continue card on the list.
- **Play icon and shuffle icon** in the icon set: the app has no playback or shuffle.
- **Round logo badge** in the top-right of the You screen: a profile picture? The app has no avatars or accounts yet.
- **Search icon in the Discover header** as well as a search bar: duplicates.
- **"Listening Stage" naming:** the board calls difficulty levels "Listening Stages" and "Stage Badge". Is this a rename of "difficulty" in the app's wording? It affects the About page, the "Hardest" chart and sort labels.

### 3.10 Other constraints
- **Status bar:** the board shows an iPhone-style status bar. The app is Android-first; Android's status and navigation bars and its back gesture take space at the top and bottom.
- **Cover art:** covers must be shown unaltered (no tinting or stylising). Some covers are very dark, so on a dark green background they need a subtle 1 px border or a lighter "raised" surface behind them.
- **Small text on green:** secondary grey-green text must stay at or above 4.5:1. For example, `#7F8F8B` on `#172C2B` is only 4.3:1, while `#9AA9A5` is 6.0:1. ChatGPT should specify the exact hex for every text colour.
- **Accent colours:** the board shows a cyan outline on the current trail stop and a light green rating pill, but no defined accent, success, warning or error colours. These are needed for states and for the "Undo" snack bar.
- **Card gap 12 px:** at 360 px wide, three cards across become about 101 px each (about 110 today). Titles then fit about 12–14 characters per line.
- **Large text:** the board's fixed-height cards will need to grow at 130–200% system text size.

---

## 4. Existing functions not shown on the board

Bailey asked to preserve all functionality. ChatGPT needs to place each of these. Recommended places are given only as suggestions.

| Function today | Where it is now | Shown on board? | Suggested home |
|---|---|---|---|
| **Continue card** (last active expedition, next album) | Top of Expeditions (`ContinueCard`) | No | Keep at the top of Expeditions, or as the Discover "Featured" slot |
| **Zig-zag sideways trail**, solid vs dashed line, bigger final stop, opens at the next stop | Trail page (`JourneyTrail`) | Shown as a straight row of 3 small covers with arrows | Decide whether to keep the zig-zag (Bailey approved it in v0.8) |
| **Locked stops** for "In order" expeditions | Trail, cards | No | Locked state needed |
| "In order" flag, your average, your expedition rating on tiles | Expedition tiles | Partly (progress only) | |
| **Reset progress / Edit / Delete** expedition (⋮ menu, Undo) | Trail app bar | ⋮ shown, contents not | Keep in the ⋮ menu |
| "Your expeditions" section and **+ create** | Expeditions | + shown | |
| **Decade charts** (1950s–2020s) | Discover chips | No (only Popular, Top Rated, Hardest) | Inside a "Charts" tile or a scrolling chip row |
| **"Rated by me"** filter | Discover chips | No | Filter on search results |
| **Artists row** (featured and in search results) | Discover | No | |
| **Genre album rows** (20 per genre) and genre pages with A–Z index | Discover, genre page | Replaced by tiles | See 3.5 |
| **Sort** (with tap-again-to-reverse) | Search, genre, artist, You lists | No | Needed on every list |
| **Listen later from any card** (bookmark, long-press) | Album cards | Bookmark on grid card only | Also on list cards? |
| **Track rating** (Rate button, rating sheet, swipe to clear) | Album page tracklist | Replaced by "…" | See 3.9 |
| **Genre and subgenre chips**, difficulty explanation on tap | Album page | No genres; stage badge shown | |
| **Ratings / yours / average column** | Album and song pages | No | Fine to drop until accounts? (audit 12.3, item 9) |
| **Rating spread mountain chart** | Album and song pages | No | Restyle it in the new theme |
| **Release date, duration, label** | Album page | Year only | |
| **Reviews, likes, comments, report** | Album and song pages | No | |
| **Next: [album] after rating an expedition album** | Rating bar | No | Keep under the rating bar |
| **Tap rating number to clear (Undo)** | Rating bar | No | Keep |
| **Swipe to clear** in the Rated list | You | List shown, no hint | |
| **Your Range empty slots, picker, remove** | You | No (all five filled) | Empty and remove states needed; removing should get Undo (audit 7) |
| **Rated list as a 3-across grid** | You | Shown as a list with rating pills | Decision: list or grid? (Bailey's earlier rule was portrait cards about 3 across) |
| **About page** link | Bottom of You | No | |

---

## 5. Screens and states the board doesn't cover

Each of these needs a ChatGPT spec before implementation:

- **Screens:** Artist page, Genre page (with A–Z index), Chart page (numbered), Song page, Track rating sheet, Create/Edit expedition, Your Range picker, About, "Couldn't find this album" page, review/comment/report dialogs, "Your Range is full" chooser.
- **States:** unrated album (rating bar "–"), loading (app start/splash, tracklist, covers), tracklist failed with retry, missing cover placeholder on dark backgrounds, empty lists (Rated, Listen later, Reviews, search with no results, empty charts), locked stop, completed expedition (card and trail), no-difficulty album and peak, Undo snack bar, pressed / focused / disabled versions of every button and chip.
- **Sizes:** each main screen at 360 px and 412 px wide, the web version capped at 600 px, and large system text (200%).
- **Brand assets:** app icon (Android adaptive: foreground, background, monochrome), splash, logo or wordmark, 4 stage icons in large and small sizes, 12 genre icons, 3 tab icons (selected and unselected).

---

## 6. Listening stage icons

- **Requirement:** all four must be clearly distinct.
- **Board:** Base Camp (tent), Foothills (rolling hills), High Altitude (mountain range), Summit (single peak with a path and flag). Base Camp and Foothills are distinct. **High Altitude and Summit are close**: both are mountain outlines in the same frame.
- **Suggestion:** make the difference work at 16 px. For example, use rising peak counts or heights (no peak, low hill, two peaks, one tall peak with a flag), or add a fill level or colour per stage on top of the shape, so colour is never the only difference.
- **Small sizes:** the board's large icons (in circles, with detail lines) won't read at the 12–16 px used on cards and badges. Ask for a simplified small version of each, drawn on a 24 px grid.
- **Format:** single-colour SVGs so the app can tint them. This needs an SVG package (`flutter_svg`), which is a new dependency for Bailey to approve.

---

## 7. Questions for Bailey (to answer before detailed specs)

1. Dark only, or dark now and light later (recommended), or follow the phone's setting?
2. Difficulty data: design an "unscored" peak and badge now and bring AI scoring forward (recommended), or something else?
3. Discover "Featured": hand-picked, automatic (recommended: continue your expedition plus popular), or drop it?
4. Do genre tiles replace the genre album rows or sit above them?
5. Expedition trail: keep the approved zig-zag with a bigger final stop, or move to the board's straight row?
6. Keep the Continue card at the top of Expeditions, now that the cards and trail page both show the next album?
7. Rated list on You: list rows (as on the board) or 3-across cards (as today)?
8. Track rating: what does the track "…" menu do, and should rating a track stay one tap?
9. Is "difficulty" being renamed "listening stage" in the app's wording?
10. Ratings shown as "9.0 / 10" everywhere, or "9" as today?
11. What do the play and shuffle icons and the You-page logo badge do, or should they be removed?
12. Approve in principle: `animations` (official), `flutter_svg`, and launcher/splash generators?

---

## 8. What ChatGPT should deliver next (for implementation)

1. Token tables with exact values: all colours by role (including text greys, accent, success, warning, error, focus, locked, scrim), type styles (family, size, line height, weight, letter spacing), spacing, radii, sizes, motion (duration and curve), and elevation (or the flat alternative).
2. Component specs with every state: album card (grid and list), cover, rating bar (unrated, dragging, saved), stage badge (large and small), chips (filter, navigation, info), buttons, section header, progress bar, expedition card (in progress, complete, locked), Range peak, tab bar, snack bar with Undo, empty, error and loading.
3. Screen specs in the order: album page, Discover, Expeditions list and trail, You and Range, then the remaining screens. Each with its states at 360 px and 412 px, plus 200% text.
4. SVG assets: 4 stage icons (large and small), 12 genre icons, 3 tab icon pairs, app icon layers, logo or wordmark.

Specs work best as tables of token names and px values next to each mockup, rather than as images alone.
