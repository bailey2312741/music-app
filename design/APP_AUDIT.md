# Expeditions: App Audit for the UI/UX Redesign

**Audited build:** v0.8.0 (commit `49a86f0`, `pubspec.yaml` version `0.8.0+9`)
**Date:** 4 November 2026
**Author:** Claude Code (technical lead)
**Audience:** ChatGPT (creative director and UI/UX designer) and Bailey (product owner)
**Scope:** read-only. No app code, dependencies or assets were changed to produce this document.

### How to read this document

Every finding is labelled:

- **Observed:** what the code does today, with the source file.
- **Problem:** why it hurts usability, consistency or the look.
- **Recommendation:** a suggestion for the redesign. Recommendations are **not decisions**. Bailey approves; ChatGPT designs.

File paths are relative to the repository root. "px" means Flutter logical pixels (density-independent, the same unit designers call "dp" or "pt").

Screenshots of every v0.8 screen (phone width, with placeholder gradient covers because the test machine could not reach the cover server) are in the project folder `music-app/aesthetic-audit-v0.8/` (7 contact sheets). They are useful context for ChatGPT, but note the gradient squares stand in for real album art.

---

## Contents

1. Executive summary
2. Technical architecture and key file paths
3. Screen inventory
4. Navigation and user-flow map
5. Layout and component audit
6. Interaction and animation audit
7. Accessibility and usability observations
8. Existing assets and styling inventory
9. Proposed design system architecture
10. Recommended asset integration workflow
11. Phased implementation recommendations
12. Technical risks, constraints and unresolved questions
13. Appendix A: Brief for ChatGPT (what to design first)
14. Appendix B: Hard constraints checklist for designs

---

## 1. Executive summary

**What the app is.** Expeditions is an Android-first (also web) app for rating albums and songs from 0 to 10 in half steps, discovering albums through search, genre rows and charts, and following "expeditions": short guided journeys of 3 to 6 albums drawn as a trail. Each album can carry a listening **difficulty** in four named levels (Base Camp, Foothills, High Altitude, Summit), shown as words and icons, never numbers, so it is not confused with quality. A profile ("You") shows **Your Range**, five favourite albums drawn as a mountain skyline, plus rated albums, a Listen later list and reviews.

**How it is built.** Flutter 3.47.9 (Dart), Material 3 widgets, `go_router` for navigation with three persistent tabs, `shared_preferences` for on-device storage, a bundled 2.2 MB catalogue of about 10,000 albums, and live MusicBrainz look-ups for tracklists. There is no backend yet; accounts and shared ratings are planned for later (Supabase was recommended).

**State of the design.** Functionally the app is in good shape after eight rounds of usability fixes (fixed rating bar, Undo instead of confirmations, 44 px targets on key controls, tab bar on every page, correct back behaviour). Visually it is **stock Material 3**: one line of theme code (`ThemeData(colorSchemeSeed: Colors.teal)` in `lib/main.dart`), the default Roboto font, default Material icons, the default Flutter launcher icon and a white splash screen. The brand colours (`#172C2B`, `#F3F0E7`) do not appear anywhere in the code. The app is still called "Music App" on the phone and "music_app" in the browser tab. A previous visual audit (3 November) scored the look 4/10.

**The good news for the redesign.**

- Almost every colour and text style is read from the Material theme (`Theme.of(context)`), not hard-coded. Replacing the theme alone will recolour and re-type roughly 85 to 90 percent of the app in one step.
- The album card, cover, rating bar, difficulty tag and grids are already shared components in a few files (`lib/widgets.dart`, `lib/page_parts.dart`, `lib/library_screen.dart`, `lib/difficulty.dart`). Restyling those once changes most screens.
- The app is small (about 5,500 lines of UI and logic across 22 files), so a screen-by-screen redesign is realistic.

**The main gaps.**

1. **No design system.** No colour, spacing, radius, type or motion tokens. 66 hand-typed padding values, 5 different corner radii, 7 different cover sizes, 11 text styles plus 4 hand-set font sizes.
2. **No motion at all.** Zero custom animations. Images pop in with no fade (fade explicitly set to zero). Page changes use Flutter's stock transition. No haptics.
3. **No brand identity in the UI.** The mountain theme exists only in the difficulty names, the drawn Your Range skyline, the trail line and the rating "mountain chart". No logo, icon, illustration, texture or custom font.
4. **Fragile fixed sizes.** Cards, rows and the trail use fixed pixel heights. With large system text, titles will be clipped or overflow. Text scaling is not handled anywhere.
5. **Thin accessibility.** One `Semantics` label in the whole app; the drawn charts, skyline and trail are invisible to screen readers; several hidden gestures (long-press, swipe) have no visible alternative.
6. **Cluttered album cards.** Up to five overlays on one cover (number, type, rating, bookmark, lock), plus a difficulty pill and caption under it.

**What the redesign should protect.** The fixed bottom rating bar, Undo-based recovery, three tabs, tab re-tap to scroll up, sideways expedition trail, difficulty-as-words rule, square covers in portrait cards about three across, and all data and business logic (see Appendix B).

---

## 2. Technical architecture and key file paths

### 2.1 Framework, languages and libraries

| Item | Value | Source |
|---|---|---|
| Framework | Flutter 3.47.9 (stable), Dart SDK ^3.13.7 | `pubspec.yaml`, `.github/workflows/build-android.yml` |
| UI kit | Material 3 (`useMaterial3: true`), Material Icons font | `lib/main.dart`, `pubspec.yaml` (`uses-material-design: true`) |
| Navigation | `go_router` ^18.1.2 with `StatefulShellRoute.indexedStack` (3 tabs, each with its own page stack) | `lib/nav.dart` |
| Storage | `shared_preferences` ^2.5.6 (JSON strings on the device; `localStorage` on web) | `lib/store.dart` |
| Images | `cached_network_image` ^4.0.6 on Android; `Image.network` with HTML fallback on web | `lib/widgets.dart` (`netImage`) |
| Network | `http` ^1.6.0 for MusicBrainz tracklists, rate-limited to 1 request per 1.1 s | `lib/details.dart` |
| Icons | `cupertino_icons` (declared, unused) and Material Icons | `pubspec.yaml` |
| Lints and tests | `flutter_lints`, 445 lines of widget and logic tests | `analysis_options.yaml`, `test/app_test.dart` |
| Other languages | Python build tools for the album library; Kotlin/C++ platform stubs (untouched Flutter templates) | `tool/*.py`, `android/`, `windows/` |

There are **no** animation, font, SVG, icon or state-management packages. State is a single `ChangeNotifier` (`Store`) that screens listen to with `ListenableBuilder`.

### 2.2 Build and release

- **Android:** every push to `main` runs `flutter analyze`, `flutter test`, builds a release APK and publishes it at a fixed "latest" download link (`.github/workflows/build-android.yml`). Bailey installs it on their phone.
- **Web:** every push to `main` publishes to GitHub Pages at `/music-app/` (`.github/workflows/deploy-web.yml`).
- **Library data:** separate workflows rebuild or patch `assets/catalogue.json` (`build-library.yml`, `patch-library.yml`).
- The cloud container used by Claude cannot download the Android SDK, so Android builds only happen in GitHub Actions. Visual checks are done on a web build.

### 2.3 Project structure

```
lib/
  main.dart               App start: loads data, builds the theme (1 line), caps width at 600 px
  nav.dart                All routes, the tab shell and tab bar, Android back handling, open*() helpers
  screens.dart            Re-exports screens; holds appVersion = '0.8'

  -- Screens --
  search_screen.dart      Discover / Search (also "pick an album" mode), Genre page, Artist page, AlbumRow
  charts.dart             Chart page (Popular, Top rated, Hardest, decades) and chart chip list
  album_screen.dart       Album page, track rows, release facts
  song_screen.dart        Song page
  expedition_screens.dart Expeditions list, Continue card, expedition tile, trail page, create/edit page
  you_screen.dart         You tab, Your Range picker, About page
  profile_screen.dart     (misnamed) Your Range skyline drawing only
  library_screen.dart     SliverAlbumGrid, the grid used by most lists

  -- Shared UI --
  widgets.dart            Cover, AlbumCard, badges, AlbumGrid, ExpeditionCover, ArtistCard, ArtistAvatar, netImage
  page_parts.dart         RatingStats, ArtistButton, track rating sheet, ReviewSection, RatingBar
  difficulty.dart         Difficulty levels (name, icon, text), DifficultyTag pill, DifficultySquare, explanation message
  chart.dart              "Rating spread" mountain chart (custom painted)
  sorting.dart            Sort options and the SortButton menu
  actions.dart            Listen later toggle, pin to Range, clear rating, Undo messages

  -- Data and logic (do not change in the redesign) --
  models.dart             Album
  store.dart              Everything saved on the device (ratings, lists, reviews, expeditions)
  catalogue.dart          Bundled album library, search, genres, artists
  details.dart            Tracklist, date, label from MusicBrainz, cached
  expeditions.dart        Built-in expeditions (3), progress, locking, difficulty lookup
assets/catalogue.json     Album library (2.2 MB)
android/, web/, windows/  Platform shells (mostly untouched templates)
```

**Data and UI separation is decent**: screens call `Store`, `Catalogue` and `DetailsLoader` but contain no business rules of their own apart from small display decisions (for example which artist releases count as "less known" in `ArtistScreen`, `lib/search_screen.dart`). This is what lets the redesign leave behaviour alone.

### 2.4 Styling and theming system

- **Observed:** the entire theme is `ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true)` in `lib/main.dart`. Material generates every colour from that one seed. No `TextTheme`, component themes, fonts or `ThemeExtension`s. No dark theme.
- **Observed:** widgets mostly use theme roles correctly (`colorScheme.primary`, `onSurfaceVariant`, `textTheme.titleMedium`), which is good. Hard-coded exceptions: `Colors.red.shade600` (like heart, chart flag), `Colors.white` and `Colors.black87` (artist card fade, chart snow), `Colors.white70`, and four raw `fontSize` values (`lib/widgets.dart` badges, `lib/profile_screen.dart` Range badge, `lib/chart.dart` axis labels).
- **Problem:** spacing, radii, sizes and durations are all literal numbers scattered through the files (66 `EdgeInsets`, 13 radius values).

### 2.5 Component libraries

Only Flutter's Material widgets. Custom shared components are listed in section 5.2. Custom drawings use `CustomPainter` in three places: `_MountainPainter` (`lib/chart.dart`), `_SkylinePainter` and dashed boxes (`lib/profile_screen.dart`), `_TrailPainter` (`lib/expedition_screens.dart`).

### 2.6 Animation capabilities

- **Observed:** nothing custom. Only motion is what Material widgets do by default: ink ripples, slider thumb, snack bar slide, bottom sheet slide, dialog fade, tab indicator pill, page transition. Image fades are deliberately set to `Duration.zero` (`lib/widgets.dart`, `netImage`).
- **Available without new packages:** implicit animations (`AnimatedContainer`, `AnimatedSwitcher`, `AnimatedOpacity`, `TweenAnimationBuilder`), `Hero` shared-element transitions, explicit `AnimationController`s, custom page transitions through go_router's `CustomTransitionPage`, and animating the existing `CustomPainter` drawings.
- **Candidate packages (need Bailey's approval):** `animations` (official Flutter team package: shared axis, fade through, container transform), `flutter_animate` (concise chained effects), `rive` or `lottie` (designer-made vector animations; heavier, only for a few hero moments). See section 6.4.

### 2.7 Platform constraints

| Constraint | Detail | Source |
|---|---|---|
| Android first | Release APK only; no iOS project in the repo | `android/` |
| Web is a real target | Used on Bailey's PC. App is capped to 600 px wide and centred; hover states exist only here | `lib/main.dart`, `_Hover` in `lib/widgets.dart` |
| Android back gesture | Edge swipe goes back; the rating bar has 20 px side padding so the slider thumb is not under the gesture edge | `lib/page_parts.dart` (`RatingBar`) |
| Edge-to-edge | Android 15+ draws behind the status and navigation bars by default; only the rating bar uses `SafeArea` explicitly (Scaffold/AppBar/NavigationBar handle the rest) | `lib/page_parts.dart` |
| Covers come from the internet | Cover Art Archive; may be slow or missing; the art itself cannot be redesigned | `lib/models.dart`, `lib/widgets.dart` |
| Offline | Catalogue is bundled, but tracklists need the network the first time | `lib/details.dart` |
| No dark mode | Only a light theme exists; Android system dark mode is ignored | `lib/main.dart` |
| Splash and launcher | Default Flutter launcher icon in every `mipmap-*` folder; plain white launch background | `android/app/src/main/res/` |
| App name | "Music App" (Android label, `MaterialApp.title`), "music_app" (web title and manifest), web theme colour `#0175C2` (Flutter blue) | `AndroidManifest.xml`, `lib/main.dart`, `web/index.html`, `web/manifest.json` |

### 2.8 Opportunities: performance, maintainability, reuse

**Performance**

- **Observed:** Discover rebuilds all 12 genre rows on any store change (rating, bookmark), and each row filters the full 10,000-album list (`Catalogue.inGenre`, `lib/catalogue.dart`; `_genreRows`, `lib/search_screen.dart`). `chartChips()` scans every album on each build (`lib/charts.dart`). Not visibly slow today, but animations amplify the cost of rebuilds. **Recommendation:** cache genre lists and chart chips once after loading; listen to the store only where ratings are shown.
- **Observed:** the 2.2 MB catalogue is parsed on the main thread before the first frame (`lib/main.dart`, `Catalogue.load`), behind a white splash. **Recommendation:** a branded native splash (cheap) and optionally parse in a background isolate.
- **Observed:** `shouldRepaint` always returns true for the skyline and trail painters. Cheap now, but they will repaint every frame during any animation. Minor fix during the motion phase.
- **Good:** covers are decoded at small sizes (`memCacheWidth` 250 or 500) and cached on disk.

**Maintainability**

- `profile_screen.dart` contains only the Your Range skyline; `search_screen.dart` also contains the Genre and Artist pages. **Recommendation:** rename and split during the redesign (no behaviour change) so each screen has its own file.
- Two private `_Fact` widgets with the same name and different purposes (`album_screen.dart`, `expedition_screens.dart`).
- The "unrated slider" styling is written twice (`RatingBar` in `page_parts.dart`, expedition rating in `expedition_screens.dart`); the slider exists three times (also the track sheet).
- Album "pick mode" (adding albums to a custom expedition) uses `Navigator.push` outside go_router (`search_screen.dart`, `expedition_screens.dart`). It works, but these pages will not get the router's custom transitions or web addresses.
- `README.md`, web manifest and `<meta description>` still say "A new Flutter project".

**Reuse**

- Section headers ("Tracklist", genre titles, "Studio albums (9)"), empty-state messages, error-with-retry rows and sliders are all re-typed per screen. Each should become one shared component.

---

## 3. Screen inventory

Fourteen routed screens, plus two overlays that act like screens (track rating sheet, review dialog). Web addresses use `#/` hash URLs.

### 3.1 Discover (tab 1, opens first)

- **File:** `lib/search_screen.dart` (`DiscoverScreen` wraps `SearchScreen`)
- **Route:** `/discover`
- **Purpose:** search the library, browse by genre, open charts.
- **Layout (top to bottom):**
  - App bar title "Discover" with a pinned search bar (60 px area) under it.
  - One sideways row of chips (48 px tall): chart chips (Popular, Top rated, Hardest, then one per decade 1950s to 2020s), a "Rated by me" filter chip, then 12 genre filter chips.
  - Browsing (no search): "Artists" heading + sideways row of wide artist cards (220×110), then 12 genre sections, each a heading with "See all" and a sideways row of 20 album cards (row height 214, card width 130).
  - Searching or filtering: "Artists" row (if matches), "Albums (N)" heading with Sort button, then a 3-across grid.
- **Actions:** type to search (results update per keystroke), clear (×), tap chart chip, toggle genre / Rated by me, open artist, open genre ("See all"), open album, bookmark album (tap icon or long-press card), change sort.
- **Gestures:** horizontal scrolling rows inside a vertical page; long-press on a card toggles Listen later.
- **In and out:** tab bar. Re-tapping Discover scrolls to top; a second tap clears the search (`nav.dart`, `_reselected`).
- **Usability problems:**
  - Chips row mixes three kinds of thing (navigation to charts, a filter, genre filters) in one strip that looks the same; 23 chips, most off-screen. Decade chips push genres far to the right.
  - Selecting a genre chip hides all other genre chips (only the chosen one stays), which is unusual.
  - Featured artists row shows before genres but is not personalised in a visible way.
  - 12 genre rows × 20 cards makes a long page; no visual difference between rows.
  - Search bar is at the top: out of comfortable thumb reach on tall phones (but the convention is strong).
- **Must preserve:** as-you-type search over the bundled library, artists row in results, genre filter, "Rated by me", sort with tap-again-to-reverse, chart entry points, re-tap behaviour.

### 3.2 Chart page

- **File:** `lib/charts.dart` (`ChartScreen`)
- **Route:** `/{tab}/chart/:kind` (`popular`, `top`, `hardest`, `1990` …)
- **Layout:** app bar title, one-line grey note explaining the data source, numbered 3-across grid (up to 200 albums).
- **Actions:** open album, bookmark.
- **Problems:** the rank number is a small badge on the cover, competing with the bookmark and rating badges; charts look identical to search results; "Top rated" and "Hardest" are thin until accounts and AI difficulty exist (the note explains this).
- **Preserve:** ranking order, explanatory note.

### 3.3 Genre page

- **File:** `lib/search_screen.dart` (`GenreScreen`)
- **Route:** `/{tab}/genre/:name`
- **Layout:** title, Sort in the app bar; in A-to-Z sort, a sideways letter index (36×36 targets) appears under the app bar; 3-across grid.
- **Problems:** the letter index is horizontal and partly off-screen, unlike the familiar vertical side index; sort sits top-right (hard to reach).
- **Preserve:** popularity default, A-Z jump index, pick mode.

### 3.4 Artist page

- **File:** `lib/search_screen.dart` (`ArtistScreen`)
- **Route:** `/{tab}/artist/:name`
- **Layout:** app bar with 32 px round avatar and name, Sort on the right. "Studio albums (N)" in a bigger grid (max 200 px wide cards, 2 across on phones), then sections per other type (EP, Mixtape, Live …) in a smaller grid (112 px, about 3 to 4 across), then a collapsed "Less-known releases (N)" with Show/Hide.
- **Problems:** no artist header (no picture, count or summary); avatar is a placeholder (the most popular album cover cropped to a circle); grids with three different card sizes on one page; the large 2-across studio cards have a lot of empty space below them (fixed aspect ratio).
- **Preserve:** studio-first grouping, oldest-first default, hidden minor releases, pick mode.

### 3.5 Album page (most important screen)

- **File:** `lib/album_screen.dart` (`AlbumScreen`), rating bar in `lib/page_parts.dart`
- **Route:** `/{tab}/album/:id` (`?exp=` when opened from an expedition)
- **Layout:**
  - Empty app bar (back arrow only).
  - Header row: 116 px cover | title (titleLarge bold), "Album · 12 tracks", artist chip | stats column 64 px wide (ratings count, yours, average).
  - Row: difficulty square (96 px wide, if any) + genre chip (larger) and subgenre chips (compact).
  - Row: "Listen later" and "Add to Your Range" text buttons.
  - Divider, "Tracklist": loading spinner, error with "Try again", empty text, or track rows (number, title, length · avg, and a "Rate" outlined button or a filled score button, 56×44).
  - Divider, "Rating spread" mountain chart (170 px tall) with a temporary "Test" button.
  - Divider, facts: Release date, Duration, Record label.
  - Divider, Reviews section.
  - **Fixed at the bottom:** rating bar (number on the left 72×60, slider filling the rest), with "Next: [album]" under it after rating an expedition album. Tab bar under that.
- **Actions:** rate (drag or tap slider; saves on release), clear (tap number, Undo), open artist, tap difficulty for explanation, Listen later, add to/remove from Your Range (dialog when full), open song, rate track (sheet), swipe rated track to clear, write/edit review, like, comment, report, retry tracklist, next expedition stop.
- **Problems:**
  - The header crams three columns into 360 to 412 px: long titles wrap to three lines next to the cover; artist names truncate ("Florence + the Ma…"); the stats column shows "0 ratings / – yours / – average", which is mostly empty until accounts exist and duplicates the rating bar.
  - Genre chips look like buttons but do nothing when tapped (plain `Chip`, `lib/album_screen.dart`).
  - Twelve "Rate" outlined buttons in the tracklist are the loudest thing on the page and compete with the album rating.
  - The rating bar plus the tab bar take about 150 px of the bottom of the screen on every album and song page.
  - "Test" button on the chart is a developer tool visible to users.
  - No hero area: the cover (the most emotional element) is 116 px.
- **Preserve:** fixed rating bar in the same place, unrated "–" state, first touch sets value, save on release, tap number to clear with Undo, Next stop shortcut, track ratings and swipe-to-clear, tracklist retry, all facts and review functions.

### 3.6 Song page

- **File:** `lib/song_screen.dart`
- **Route:** `/{tab}/album/:id/song/:tid`
- **Layout:** like the album page, smaller: 84 px **round** cover (the only vinyl reference in the app) with a music-note badge, title with a "Song" label, underlined link "Track N on [album]", length, artist chip, stats column; then rating spread chart and reviews. Same fixed rating bar.
- **Problems:** the round cover is a nice idea but small; underlined link style appears nowhere else.
- **Preserve:** separate song ratings, link back to album, reviews.

### 3.7 Track rating sheet (overlay)

- **File:** `lib/page_parts.dart` (`showRatingSheet`)
- **Layout:** modal bottom sheet: track title, big number, slider, "Remove rating" text button.
- **Behaviour:** saves and closes on release.
- **Problems:** a second, different rating control (sheet) from the album's fixed bar; the unrated slider here is not greyed like the album bar.

### 3.8 Expeditions list (tab 2)

- **File:** `lib/expedition_screens.dart` (`ExpeditionListScreen`, `ContinueCard`, `ExpeditionTile`)
- **Route:** `/expeditions`
- **Layout:** app bar "Expeditions" with + (new) on the right. "Continue" card (primary-container tint, 64 px cover, "Continue: [expedition]", album title, "Stop 2 of 5 · artist", chevron). Then one large tile per built-in expedition (3 today): stacked covers (104 px), name (titleLarge), 3-line blurb, facts (albums, In order, your average, your rating), progress bar with "1 of 5" / "Complete". Then "Your expeditions" with user-made tiles.
- **Problems:** this is the flagship feature but looks like a settings list of cards; the Continue card's bright mint tint (`primaryContainer`) is the loudest colour in the app; no difference between official and user expeditions except the heading; no sense of difficulty or length of the journey on the tile.
- **Preserve:** Continue card logic (most recently active, unfinished), progress, In order flag, + to create.

### 3.9 Expedition trail page

- **File:** `lib/expedition_screens.dart` (`ExpeditionScreen`, `JourneyTrail`, `_TrailPainter`)
- **Route:** `/expeditions/trail/:eid`
- **Layout:** app bar with name and ⋮ menu (Reset progress; Edit and Delete for own expeditions). Blurb, progress bar, "Your average so far". A **sideways-scrolling trail**: album cards (120 px) zig-zag up and down, joined by a solid line (travelled) and dashed line (ahead); the final stop is bigger (156 px) and vertically centred; the next stop is highlighted with a mint background and "Next stop" caption; locked stops are 40 percent opacity with a lock. It opens scrolled to the next stop. Below: "Rate this expedition" with its own slider.
- **Actions:** open album (with expedition context), tap locked stop (message "Rate album N first"), Reset (Undo), Edit, Delete (Undo), rate the expedition.
- **Problems:** the trail is the strongest identity element but is drawn with plain straight lines on a blank background; the highlight uses the same mint as other things; the expedition rating slider sits at the bottom of the scroll, not in the fixed bar position used elsewhere; ~50 percent of the screen below the trail is empty on tall phones.
- **Preserve:** sideways trail, zig-zag, solid vs dashed line, bigger final stop, auto-scroll to next stop, lock rules, Undo for reset and delete, expedition rating separate from album ratings.

### 3.10 Create / edit expedition

- **File:** `lib/expedition_screens.dart` (`CreateExpeditionScreen`)
- **Routes:** `/expeditions/new`, `/expeditions/trail/:eid/edit`
- **Layout:** Save in the app bar (disabled until a name and 2 albums). Outlined text fields for name and description, "Listen in order" switch, album list with drag handles and × remove, "Sort by year", "Add album" outlined button that opens Discover in pick mode.
- **Problems:** Save is top-right (far from the thumb, and the disabled state gives no reason); no feedback when saved (page just closes); removing an album has no Undo (inconsistent with the rest of the app); the empty state text mentions dragging before there is anything to drag.
- **Preserve:** validation rules, reorder, sort by year, pick flow.

### 3.11 You (tab 3)

- **File:** `lib/you_screen.dart` (`YouScreen`), skyline in `lib/profile_screen.dart`
- **Route:** `/you`
- **Layout:** app bar "You". Nickname (headlineMedium bold, pencil to edit in place), "@username" placeholder. "Your Range" heading, help line, the **skyline** (230 px tall: five triangles, each with a 54 px cover on top; height from difficulty; rating badge bottom-left; "?" badge when the album has no difficulty; empty slots are dashed boxes over dashed triangles), second help line. Segmented button: Rated (N) / Listen later (N) / Reviews (N). Help text ("Swipe an album sideways…") + Sort. Grid or review list. "About this app" row at the bottom.
- **Actions:** edit nickname, tap empty slot (picker), tap peak (album), long-press peak (remove, no Undo, no visible hint other than the help text), switch section, sort, swipe to clear rating, open About.
- **Problems:** two lines of instructions around the skyline are needed because the interactions are not discoverable; long-press removal has no Undo (inconsistent); "@username" is a fake placeholder; the segmented control squeezes three labels with counts into 360 px; About is the only way to settings-like information.
- **Preserve:** nickname editing in place, Your Range rules (5 slots, height from difficulty, rating badges, empty dashed slots), the three lists, swipe to clear with Undo.

### 3.12 Your Range picker

- **File:** `lib/you_screen.dart` (`RangePickerScreen`)
- **Route:** `/you/range/:slot`
- **Layout:** title "Add to Your Range", search bar for rated albums, grid of rated albums highest first. Tap picks and returns.
- **Preserve:** highest-first, search, moving an album between slots.

### 3.13 About

- **File:** `lib/you_screen.dart` (`AboutScreen`)
- **Route:** `/you/about`
- **Layout:** long text page: difficulty levels (list with icons), ratings, expeditions, Listen later and Your Range, charts, data sources, version.
- **Problems:** wall of text; says "about 9,000" albums while the library has 10,054 (content bug, not a design issue).

### 3.14 Missing page

- **File:** `lib/nav.dart` (`_Missing`)
- Plain "Couldn't find this album/song." with a back arrow. Needs a designed error state.

### 3.15 Dialogs and messages (not routes)

| Element | File | Use |
|---|---|---|
| Review editor (AlertDialog) | `lib/page_parts.dart` | Write/edit review (Cancel / Post) |
| Comment editor (AlertDialog) | `lib/page_parts.dart` | Add comment |
| Report reasons (SimpleDialog) | `lib/page_parts.dart` | 4 reasons |
| "Your Range is full" (SimpleDialog) | `lib/actions.dart` | Choose album to replace |
| Snack bars with Undo | `lib/actions.dart`, `lib/expedition_screens.dart` | Rating removed, Listen later, Progress reset, Expedition deleted |
| Information snack bars | `lib/difficulty.dart`, `lib/expedition_screens.dart`, `lib/page_parts.dart` | Difficulty explanation (4 s), locked stop, duplicate album, reported |

---

## 4. Navigation and user-flow map

### 4.1 Structure

```
App
└── Tab shell (bottom NavigationBar, always visible)          lib/nav.dart
    ├── Discover  /discover
    │   ├── album/:id ──► song/:tid
    │   ├── artist/:name
    │   ├── genre/:name
    │   └── chart/:kind
    ├── Expeditions  /expeditions
    │   ├── trail/:eid ──► edit
    │   ├── new ──► [Discover in pick mode ► Artist/Genre pick] (outside router)
    │   └── album/:id, artist, genre, chart (shared pages, kept inside this tab)
    └── You  /you
        ├── range/:slot
        ├── about
        └── album/:id, artist, genre, chart (shared pages)
```

- Each tab keeps its own history (switching tabs and back returns you where you were).
- Album, song, artist, genre and chart pages open **inside the current tab**.
- Android back: pops pages first; on the first page of Expeditions or You it goes to Discover; on Discover it exits (`HomeShell`, `lib/nav.dart`).
- Web: every page has a URL, browser back goes back one page.
- Re-tapping the current tab: return to its first page; if already there, scroll to top; on Discover a further tap clears search.

### 4.2 Key flows and tap counts (today)

| Flow | Path | Taps |
|---|---|---|
| Rate an album found by search | Discover → type → tap card → drag slider | 2 taps + typing + 1 drag |
| Rate the next expedition album | Expeditions → Continue card → drag | 2 + drag |
| Rate the next stop after rating | (on album) "Next: …" → drag | 1 + drag |
| Clear a rating | Tap the number in the rating bar (Undo available) | 1 |
| Save for later | Tap bookmark on any card | 1 |
| Rate a track | Album → "Rate" on track → drag in sheet (auto-closes) | 2 + drag |
| Add to Your Range | Album → "Add to Your Range" (dialog if full) | 1–2 |
| Start your own expedition | Expeditions → + → name → Add album ×N (each: search + tap) → Save | 4 + 2 per album |
| Find a decade chart | Discover → scroll chip row → tap decade | 1–2 + scroll |

**Observation:** the core loop is already short. The redesign should not add taps to any of these; designs should be checked against this table.

### 4.3 Navigation problems

- The tab icon for Expeditions (`Icons.hiking`) has no separate selected/filled version, unlike the other two, so its selected state relies on the pill only (`lib/nav.dart`).
- Album, song, artist pages have an empty app bar (back arrow only), which wastes 56 px.
- Charts are reached only through a chip in a long scrolling strip.
- Pick mode and the review/comment dialogs are the only places that leave the router; they will not share the new transitions unless moved into it.

---

## 5. Layout and component audit

### 5.1 Global layout

| Item | Observed value | Source | Problem / note |
|---|---|---|---|
| Max app width | 600 px, centred, `surfaceContainerLow` either side | `lib/main.dart` | On PC the side areas are empty flat colour; fine as a phone frame, but nothing adapts to tablets or wide screens |
| Page side padding | 10, 12, 16 or 20 px depending on the page | grids 10 (`library_screen.dart`, `widgets.dart`), chips 12, album/song 16, You 20 | **Inconsistent.** Edges of text and cards do not line up between screens or even within You (20 px header, 16 px sort row, 10 px grid) |
| Section heading spacing | 10/6, 12/0, 12/2, 20/8 | various | No vertical rhythm |
| Dividers | `Divider(height: 24 or 32)` | `album_screen.dart`, `song_screen.dart` | Heavy use of lines to separate sections |
| App bar | Material default 64 px; Discover adds 60 px for search | `search_screen.dart` | Empty app bars on detail pages |
| Bottom navigation | Material 3 `NavigationBar`, default height 80 px plus system inset | `lib/nav.dart` | Tall; labels always shown |
| Fixed rating bar | About 72 px plus "Next" row (44 px) plus safe area, `surfaceContainer` background | `lib/page_parts.dart` | With the tab bar, about 150–200 px of fixed chrome at the bottom of album pages; two stacked grey blocks |
| Safe areas | Handled by Scaffold, AppBar, NavigationBar; explicit `SafeArea` only in the rating bar | | OK today; check with edge-to-edge and gesture navigation when the bars are restyled |

### 5.2 Shared components

| Component | File | Sizes today | Used on | Notes |
|---|---|---|---|---|
| `Cover` | `widgets.dart` | Fills width or fixed; radius default 8 | Everywhere | Placeholder is a grey box with a disc icon; no fade-in |
| `AlbumCard` | `widgets.dart` | Card padding 6, cover + 6 + title (2 lines, bodyMedium w600) + 2 + artist (bodySmall) + optional difficulty pill + caption; radius 12 | All grids, rows, trail | Overlays: number (top-left), type (bottom-left, 10 px text), rating (bottom-right), bookmark (top-right, 18 px icon in a 26 px circle, 44 px tap area), lock (centre). **Up to 5 overlays on a ~110 px cover.** Long-press = Listen later |
| `_Badge` | `widgets.dart` | 12 px bold (10 px small), radius 10, 92 % opacity | Card overlays | Rating badge uses primary colour; number and type badges use surface colour |
| Grid (`albumGridDelegate`) | `widgets.dart` | Max card width 140, aspect 0.56, gaps 4 | Search, charts, You, genre | 3 across at 360–412 px. Fixed aspect means cards without difficulty have empty space; large text overflows |
| Artist grids | `search_screen.dart` | Big: max 200, aspect 0.66, gap 6. Small: max 112, aspect 0.56, gap 2 | Artist page | Three grid sizes in the app |
| `AlbumRow` | `search_screen.dart` | Height 214, card width 130 | Discover genre rows | Fixed height |
| `ArtistCard` | `widgets.dart` | 220 × 110, image cropped, black fade, white name | Discover | Only `Card` with default elevation/shadow apart from reviews |
| `ArtistAvatar` / `ArtistButton` | `widgets.dart`, `page_parts.dart` | 24–32 px circle inside a compact ActionChip | Album, song, artist pages | Compact chip is under 48 px tall |
| `DifficultyTag` | `difficulty.dart` | Outlined pill radius 20; small: 12 px icon, labelSmall | Cards | Tappable via `GestureDetector` with no button semantics, about 18–20 px tall |
| `DifficultySquare` | `difficulty.dart` | 96 px wide, outlined, radius 10, 26 px icon | Album page | Pushes the genre chips sideways |
| `RatingBar` | `page_parts.dart` | Number area 72×60; slider 21 steps (0–10 by 0.5) | Album, song | Good pattern; slider is stock Material; unrated = grey track and thumb at 0 with "–" |
| `RatingStats` | `page_parts.dart` | 64 px column, titleLarge numbers | Album, song | Mostly dashes and zeros until accounts |
| `MountainChart` | `chart.dart` | 170 px tall custom painting, 11 peaks, snow cap and red flag on the highest | Album, song | Strong identity element; "Test" button must go |
| `RangeSkyline` | `profile_screen.dart` | 230 px tall, 54 px covers | You | Strong identity element |
| `JourneyTrail` | `expedition_screens.dart` | Stops 120 px (final 156), step 140, zig 64, fixed text space 96 | Trail page | Fixed text space will clip with large text |
| `ExpeditionCover` | `widgets.dart` | 3 covers offset 7 px, radius 6, 1.5 px surface border | Expedition tiles | |
| `ContinueCard`, `ExpeditionTile` | `expedition_screens.dart` | Card radius default (12), elevation 0, padding 12/14 | Expeditions | Tinted fills instead of elevation |
| `SortButton` | `sorting.dart` | Min 44×44, icon + current order label, popup menu | Search, genre, artist, You | Good: always names the current order |
| `ReviewSection` | `page_parts.dart` | Card with default elevation | Album, song | Like/comment/report icons 18–20 px; report uses compact density on comments |
| `SliverAlbumGrid` | `library_screen.dart` | Padding 10/4/10/16 | Most lists | Optional numbering and swipe-to-clear |
| Chips | Material `ActionChip` / `FilterChip` / `Chip` | Default 32 px tall (48 px tap area by default), compact ones shrink-wrapped | Discover, album page | Genre chips on the album page are not tappable but look identical to tappable chips elsewhere |

### 5.3 Cover sizes in use

116 (album page), 84 round (song), 64 (Continue), 54 (Range), 44 (lists, edit page), 104 stacked (expedition tile), 120/156 (trail), plus grid widths of about 110–130 (3-across), about 170 (artist big grid) and about 85 (artist small grid). **Recommendation:** reduce to a scale of 4–5 named sizes (for example XS 44, S 64, M grid, L 120–160, XL hero).

### 5.4 Touch targets

| Control | Size | Status | File |
|---|---|---|---|
| Card bookmark | 44×44 tap area | OK (Material guideline is 48) | `widgets.dart` |
| Track Rate button | 56×44 | OK-ish | `album_screen.dart` |
| Sort button | ≥44×44 | OK-ish | `sorting.dart` |
| Rating number (clear) | 72×60 | Good | `page_parts.dart` |
| Next stop button | min 44 high | OK-ish | `album_screen.dart` |
| Difficulty pill on cards | about 18–20 px tall | **Too small** | `difficulty.dart`, `widgets.dart` |
| Subgenre chips (not tappable) | shrink-wrapped | n/a but look tappable | `album_screen.dart` |
| Artist chip | compact density | Below 48 | `page_parts.dart` |
| A–Z letter buttons | 36×36 | **Too small** | `search_screen.dart` |
| Comment report flag | compact, 16 px icon | **Too small** | `page_parts.dart` |
| Song page "Track N on …" link | text height only | **Too small** | `song_screen.dart` |
| Range peaks | 54×54 | OK | `profile_screen.dart` |

### 5.5 Typography

All text uses Roboto via Material's default `TextTheme`. Styles in use: displaySmall (1), headlineMedium (2), headlineSmall (1), titleLarge (4), titleMedium (13), titleSmall (3), bodyMedium (5), bodySmall (17), labelLarge (2), labelMedium (4), labelSmall (10), plus raw sizes 10, 11 and 12 px. With Material 3 defaults that is 36, 28, 24, 22, 16, 14, 14, 12, 14, 12, 11 px.

- **Problem:** 11 theme styles plus 3 raw sizes is too many for an app this size; section headings use titleMedium (16 px, regular weight), which is barely bigger than body text, so hierarchy is weak. Card titles are bodyMedium w600 and artist names bodySmall grey: fine, but the 11 px labelSmall is used for meaningful text (difficulty, facts, chart notes, "tap to clear").
- **Recommendation:** define about 7 named roles (display, title-large, title, body, body-small, label, caption-numeric) and a separate numeric style for scores (tabular figures), since numbers are central to the app.

### 5.6 Density, whitespace and thumb reach

- Album page and Discover are dense; Expedition trail and You are sparse with large empty areas on tall phones.
- **Frequent controls at the bottom (good):** tab bar, rating bar, Next stop, snack bar Undo.
- **Frequent controls at the top (harder to reach one-handed):** search bar, Sort (on genre and artist pages it is in the top-right corner), + new expedition, ⋮ expedition menu, Save on the edit page, segmented control on You (upper-middle).
- **Recommendation for ChatGPT:** keep rating and primary actions in the bottom third; treat top-right corners as places for rare actions only.

### 5.7 Responsiveness

- Everything is designed for 360–412 px and capped at 600 px. Grids adapt their column count by maximum card width, so the 600 px web view shows 4–5 columns.
- No layout uses `MediaQuery` or breakpoints; no tablet or landscape design. Fixed pixel heights (`AlbumRow` 214, `ArtistCard` 110, trail text space 96, skyline 230, chart 170, grid aspect ratios) do not grow with the user's font size.
- **Recommendation:** designs should specify behaviour at 360 px (small Android), 412 px (typical) and 600 px (web cap), and at 130 percent and 200 percent system text size.

---

## 6. Interaction and animation audit

### 6.1 How the app responds today

| Interaction | Response today | Source |
|---|---|---|
| Tap card / list row / chip / button | Material ink ripple; cards highlight with a ripple clipped to radius 12 | Material defaults |
| Hover (web) | Bookmark circle gets more opaque; ripple hover tint | `_Hover`, `widgets.dart` |
| Long-press album card | Toggles Listen later + snack bar with Undo (no visual hint beforehand, no haptic) | `widgets.dart`, `actions.dart` |
| Long-press Range peak | Removes it instantly, **no Undo**, no haptic | `profile_screen.dart` |
| Swipe rated album (You → Rated) | Card slides away, rating cleared, Undo | `library_screen.dart` |
| Swipe rated track | Background "Clear rating" shows; snaps back; rating cleared with Undo | `album_screen.dart` |
| Drag rating slider | Value label bubble, number updates live, saves on release; no haptic per step; no confirmation beyond the number staying | `page_parts.dart` |
| Tap rating number | Clears, snack bar "Rating removed · Undo" (3 s) | `actions.dart` |
| Rate track | Bottom sheet slides up; releases → saves and closes | `page_parts.dart` |
| Open / close pages | Flutter's stock page transition for the platform (no custom transition set); tab switches are instant (indexed stack, no animation) | `lib/nav.dart` |
| Select tab | Material 3 pill indicator animates | `NavigationBar` |
| Search typing | Results replace instantly each keystroke | `search_screen.dart` |
| Loading tracklist | Centered spinner inside the page | `album_screen.dart` |
| Tracklist failure | "Couldn't load the tracklist." + "Try again" text button | `album_screen.dart` |
| Cover loading/failure | Grey square with a disc icon; image pops in without fade | `widgets.dart` |
| Successful actions | Snack bars for list changes; nothing for rating saved, expedition saved, review posted, Range pinned | various |
| Expedition stop completed | Progress bar number changes; nothing celebrates finishing a stop or an expedition ("Complete!" text only) | `expedition_screens.dart` |
| Locked stop tap | Snack bar "Rate album N first to unlock this one." | `expedition_screens.dart` |
| Form submission (new expedition) | Save enabled/disabled; page closes on save | `expedition_screens.dart` |
| Difficulty tap | 4-second snack bar with the description | `difficulty.dart` |

### 6.2 Component states: coverage

| State | Covered today | Missing |
|---|---|---|
| Default | Yes | |
| Pressed | Ripple only | No scale or depth response on cards; custom `GestureDetector`s (difficulty pill, Range peaks, rating number) give **no pressed feedback at all** |
| Hover / focus | Material defaults on web; bookmark only | No visible keyboard focus design |
| Selected | Filter chips, segmented button, tab pill, next-stop highlight | Selected genre is shown by hiding the others |
| Disabled | Save button, artist chip when unknown, reported flag | Disabled Save gives no reason |
| Loading | Tracklist spinner; app start = white screen | No skeletons; no loading state for covers other than the grey box |
| Success | Snack bars for list changes | No feedback for rating saved, pinned, expedition saved/completed |
| Error | Tracklist retry; "Couldn't find this album" page | Generic; no illustration or guidance |
| Empty | Text messages (Rated, Listen later, Reviews, search, chart, Range dashed slots) | Plain centred text; only one empty state has an action button |
| Locked (app-specific) | 40 % opacity + lock icon | Low contrast; not announced to screen readers |
| Unrated (app-specific) | Grey slider, "–" | Good, keep |

### 6.3 Opportunities for purposeful motion

Ranked by usefulness (each is a recommendation, not a decision):

1. **Cover to album page (shared element / Hero).** The tapped cover grows into the album header. Strong sense of place, cheap in Flutter (`Hero`), works with go_router.
2. **Rating feedback.** Number ticks or springs as the slider moves; a light haptic per half step; a short confirmation when saved (for example the number settles with a small scale-down, the bar's accent fills). This is the most frequent action in the app and currently has no "saved" signal.
3. **Expedition progress.** Trail line draws forward to the next stop after rating; a small flag or summit moment when an expedition is completed. This is the feature's emotional payoff.
4. **Cover fade-in** (150–200 ms) instead of the current pop.
5. **Tab switches:** a short fade-through between tabs (currently instant).
6. **Listen later bookmark:** icon fill animation on toggle.
7. **Your Range:** peaks rise to their height when the You tab appears or a slot changes.
8. **Mountain chart:** peaks grow from the ground when the chart scrolls into view.
9. **Loading:** skeleton shimmer for the tracklist instead of a spinner; branded splash instead of white.
10. **Snack bars / Undo:** consistent style; keep the default slide.

Avoid: parallax and scroll-linked effects on the grids (performance on cheap phones, little usability value), long page transitions (over 300 ms), animations that delay the slider or the first touch.

### 6.4 Animation technology recommendation for Flutter

| Need | Tool | New dependency? |
|---|---|---|
| Small state changes (colour, size, opacity, icon swap) | Implicit animations: `AnimatedContainer`, `AnimatedSwitcher`, `AnimatedScale`, `TweenAnimationBuilder` | No |
| Cover → album | `Hero` | No |
| Page and tab transitions | go_router `CustomTransitionPage` + transitions from the official `animations` package (shared axis, fade through) | `animations` (official, small) |
| Trail drawing, chart and skyline growth | `AnimationController` driving the existing `CustomPainter`s | No |
| Haptics | `HapticFeedback.selectionClick` / `lightImpact` | No |
| Rich illustrated moments (expedition complete, empty states) | `rive` or `lottie`, only if ChatGPT designs animated illustrations | Yes, heavier; decide later |
| Chaining many small effects | `flutter_animate` | Optional; convenience only |

**Reduced motion:** Android "Remove animations" is exposed as `MediaQuery.disableAnimationsOf(context)`. The motion tokens (section 9) should return zero or near-zero durations when it is on, and Hero/page transitions should fall back to a plain fade. Nothing checks this today.

---

## 7. Accessibility and usability observations

| Area | Observed | Problem | Recommendation |
|---|---|---|---|
| Touch targets | Key controls fixed to 44 px in v0.8 | Several below 44–48 (section 5.4) | Minimum 48×48 tap area everywhere (visual can be smaller) |
| Text size | Many 11–12 px labels; raw 10 px type badge | Hard to read; meaningful info (difficulty, facts) in the smallest size | Smallest text 12 px, ideally 13+ for meaningful info |
| Text scaling | Fixed heights, fixed grid aspect ratios, `FittedBox` shrinking the rating number | Large system fonts will clip titles or overflow rows, especially the trail and genre rows | Design cards and rows to grow with text; test at 130 % and 200 % |
| Colour contrast | Body text on surface about 8.9:1 (good); outline grey used for "tap to clear" about 4.3:1 at 11 px (fails AA for small text); white text on artist card fade depends on the cover; locked cards at 40 % opacity | Some small grey text fails WCAG AA; locked state relies on fading | Keep body ≥4.5:1, small labels ≥4.5:1, icons ≥3:1. Brand pair `#172C2B` on `#F3F0E7` is **12.9:1**, excellent |
| Colour as only signal | Rating badge vs number badge differ by colour; dashed vs solid trail line; next stop is a tint | Partly relies on colour | Pair colour with shape, text or icon |
| Screen reader | One `Semantics` label (card bookmark). Skyline, trail, chart are `CustomPaint` with no description; rating badges read as bare numbers; difficulty pill and peaks are `GestureDetector`s with no button role; slider has no label ("Rating") | TalkBack users cannot use Your Range or the trail meaningfully | Add semantic labels to every custom component; treat this as part of each component's spec |
| Reduced motion | Not checked | | Respect it via motion tokens (section 6.4) |
| Hidden gestures | Long-press for Listen later (also has a button: OK), long-press to remove a Range peak (**only** way, no Undo), swipe to clear | Undiscoverable, and the Range removal breaks the app's Undo rule | Every gesture needs a visible alternative and Undo |
| Consistency | Three different sliders; two rating confirmation styles; genre chips look tappable but are not; one underlined link style | Learnability | One rating control style, one chip style per meaning |
| One-handed use | Rating at the bottom (good); search, sort, create and save at the top | Reach on tall phones | Bottom-third placement for frequent actions |
| Navigation efficiency | Core flows are 1–3 taps (section 4.2) | Charts hidden in a chip strip | Keep or improve tap counts |
| Error prevention and recovery | Undo for most destructive actions; no confirmation pop-ups (Bailey's rule) | Exceptions: Range long-press, removing an album in the edit page, Range-full dialog (a pop-up) | Bring these in line |
| Focus and keyboard (web) | Material defaults | No designed focus ring | Specify a focus style |

---

## 8. Existing assets and styling inventory

### 8.1 Colours

Generated by Material 3 from `Colors.teal` (light scheme only). Approximate values measured in the v0.8 visual audit:

| Role | Approx. hex | Used for |
|---|---|---|
| primary | `#006A60` | Rating badges, slider, progress bars, trail line, chart rock, text buttons, bookmark icon |
| onPrimary | `#FFFFFF` | Text on rating badges |
| primaryContainer | mint, about `#9EF2E4` | Continue card, next-stop highlight |
| secondaryContainer | pale grey-green | Expedition tiles (55 % opacity), Range peaks, "Song" label |
| surface | about `#F4FBF9` | Page background |
| surfaceContainer / Low / Highest | pale greys | Rating bar, web side margins, cover placeholders |
| onSurfaceVariant | about `#3F4947` | Grey secondary text, icons |
| outline / outlineVariant | about `#6F7977` / light grey | Unrated slider, dividers, difficulty pill border, dashed lines |
| Hard-coded | `Colors.red.shade600` (like, chart flag), white (snow), black 87 % (artist fade), white 70 % | |

**Brand colours supplied by Bailey (`#172C2B` deep forest green, `#F3F0E7` warm off-white) are not used anywhere yet.** Contrast between them is 12.9:1.

### 8.2 Typography

Roboto (system default on Android, bundled by Flutter on web). No custom fonts in `pubspec.yaml`. See 5.5 for sizes.

### 8.3 Icons

Material Icons (filled/outlined), 37 distinct icons. Identity-related ones: `hiking` (Expeditions tab), `explore` (Discover), `cabin` (Base Camp), `park` (Foothills, a tree), `terrain` (High Altitude), `flag` (Summit), `landscape` (Your Range), `album` (cover placeholder, album count). No custom icons. Icon sizes in use: 12, 14, 16, 18, 20, 24 (default), 26, 30 px.

**Note:** the four difficulty icons are generic Material glyphs that do not form a set (a cabin, a tree, a mountain, a flag). Custom difficulty glyphs are a natural first asset for ChatGPT.

### 8.4 Illustrations, backgrounds, textures, logos

- **None.** No image assets apart from `assets/catalogue.json` (data).
- Launcher icon: the default Flutter logo (`android/app/src/main/res/mipmap-*/ic_launcher.png`, `web/icons/`, `web/favicon.png`).
- Splash: plain white (`android/app/src/main/res/drawable/launch_background.xml`).
- Web theme colour `#0175C2` (`web/manifest.json`).
- Drawn (code-generated) identity art: rating spread mountain chart, Your Range skyline, expedition trail line, stacked expedition covers, round "record" cover on the song page. These are vector drawings in code and should stay in code (restyled), not be replaced by images.

### 8.5 Album artwork presentation

- Square covers from the Cover Art Archive, 250 px (small) or 500 px (large) versions; decoded at 250 or 500 px.
- Corner radius 8 (cards), 10 (album page), 6 (Range, Continue, stacked), 4 (lists), 42 (round on song page).
- No shadow, border or frame on covers (except a 1.5 px surface border on stacked covers).
- Placeholder: grey square with a disc icon (also shown for failed loads).
- About 1 in 5 covers were wrong at one point (data issue, being fixed separately); designs must look fine with any cover, including very light, very dark and busy ones.

### 8.6 Shadows, borders, radii

- **Shadows:** almost none by design (Bailey's earlier rule "no shadows"). Defaults remain on `ArtistCard` and review `Card`; search bar elevation explicitly 0; other cards elevation 0.
- **Borders:** outlined chips, difficulty pill/square (outlineVariant, 1 px), outlined text fields, outlined "Rate" buttons.
- **Radii in use:** 4, 6, 8, 10, 12, 20, plus Material defaults (chips 8, cards 12, buttons full pill, sheets 28). No scale.

---

## 9. Proposed design system architecture

### 9.1 Principles

1. **One source of truth in code.** Every colour, size, radius, duration and text style is a named token. Screens never type raw numbers or colours.
2. **Build on Material 3's theme system** rather than replacing it. Flutter widgets already read `ThemeData`; feeding it our tokens restyles buttons, chips, sliders, sheets, snack bars and the tab bar with little code.
3. **Tokens first, then components, then screens.**
4. **Dark mode ready** even if it ships later: define colours by role (surface, text, accent), not by name (green, cream), so a dark set can be added without touching screens.

### 9.2 Token layers

| Layer | Example | Purpose |
|---|---|---|
| Primitive (palette) | `forest900 = #172C2B`, `paper50 = #F3F0E7` | Raw values chosen by ChatGPT; never used directly in screens |
| Semantic (role) | `colors.surface`, `colors.textPrimary`, `colors.accent`, `colors.ratingFill`, `colors.difficultySummit`, `colors.locked` | What screens and components use |
| Component | `albumCard.radius`, `ratingBar.height`, `badge.paddingH` | Only where a component needs its own named value |

### 9.3 What each token set should contain

| Set | Contents ChatGPT should specify |
|---|---|
| **Colour** | Full light palette; semantic roles for surfaces (page, raised, sunken, overlay), text (primary, secondary, disabled, on-accent), accent and its container, borders, success, warning, error, rating, each difficulty level, locked, trail travelled/ahead, chart, scrim. Optional dark set. Contrast targets per pair |
| **Typography** | Font families (display, text, numeric), about 7 roles with size, weight, line height, letter spacing; tabular figures for scores; truncation rules |
| **Spacing** | A 4 px base scale, for example 4, 8, 12, 16, 24, 32, 48. One page gutter value (for example 16), one section gap, one card gap |
| **Sizing** | Cover sizes (4–5 named), icon sizes (16, 20, 24, plus large), min touch target 48, bar heights (app bar, tab bar, rating bar) |
| **Radii** | 3–4 steps, for example 4 (small), 8 (cover), 16 (card), full (pill) |
| **Elevation and shadow** | Whether shadows exist at all (Bailey previously preferred none); if not, define the alternative (tonal surfaces, 1 px borders) |
| **Motion** | 3–4 durations (for example 100 ms micro, 200 ms standard, 300 ms page, 500 ms celebration) and 2–3 easing curves (standard, emphasised, spring for rating). Reduced-motion variants |
| **Icons** | Style (outlined/rounded/filled, stroke weight), grid size (24 px with 2 px padding), custom set list |
| **Responsive** | Breakpoints (for example compact < 600, medium 600–840), max content width, columns per breakpoint, minimum text scale support (200 %) |
| **States** | For each interactive component: default, pressed, hover, focus, selected, disabled, loading, success, error, empty; define opacity/overlay rules once (for example pressed = 10 % overlay of text colour) |

### 9.4 How it should look in the codebase (proposal)

```
lib/design/
  tokens/
    palette.dart        Primitive colours (ChatGPT's hex values)
    colors.dart         Semantic colour roles, light and (later) dark, as a ThemeExtension
    typography.dart     Text roles -> TextTheme + a numeric style
    spacing.dart        Space scale and gutters (const doubles)
    sizes.dart          Cover sizes, icon sizes, touch target, bar heights
    radii.dart          Radius scale
    motion.dart         Durations and curves; returns zero when reduced motion is on
  theme.dart            Builds ThemeData from tokens: ColorScheme, TextTheme, and component
                        themes (NavigationBar, Slider, Chip, Buttons, SnackBar, BottomSheet,
                        AppBar, Card, SegmentedButton, Dialog, SearchBar, ProgressIndicator)
  components/           Reusable widgets built only from tokens:
    album_card.dart, cover.dart, badge.dart, rating_bar.dart, rating_slider.dart,
    difficulty_tag.dart, section_header.dart, empty_state.dart, error_state.dart,
    skeleton.dart, chip.dart (one per meaning), app_button.dart, expedition_tile.dart,
    trail.dart, skyline.dart, mountain_chart.dart, undo_snackbar.dart
assets/
  fonts/  icons/  illustrations/  brand/
design/
  APP_AUDIT.md          this document
  tokens.json           (optional) ChatGPT's tokens in a machine-readable form
  specs/                one Markdown spec per screen and component
  mockups/              reference images only, never shipped in the app
```

- **Access pattern:** `context.colors.accent`, `context.space.m`, `AppMotion.standard` through a small extension on `BuildContext`. Material widgets pick up the theme automatically.
- **Source of truth for ChatGPT's output:** a `design/tokens.json` file (or a table in a spec) that Claude converts to Dart by hand. A code generator is not worth it at this size.
- **Guardrail:** after the migration, a simple test or lint check can search `lib/` (outside `lib/design/`) for `Colors.`, `Color(0x`, `fontSize:` and `BorderRadius.circular(` with literals, to stop drift.

### 9.5 Reusable components to define (priority order)

1. Cover (with sizes, radius, placeholder, failed state, fade-in)
2. Album card (with a reduced overlay set; see open question 12.3)
3. Rating control (bar, slider, number, unrated, saving/saved, clear) used for albums, songs, tracks and expeditions
4. Difficulty tag, square/large form and the four glyphs
5. Badge (rating, rank, type)
6. Section header (title, count, optional action)
7. Chips (filter, navigation, info: three visibly different kinds)
8. Buttons (primary, secondary, text, icon) with all states
9. Empty, error, loading (skeleton) states
10. Expedition tile, Continue card, trail stop
11. Bottom navigation and app bar styles
12. Snack bar / Undo message, bottom sheet, dialog

---

## 10. Recommended asset integration workflow

### 10.1 What should be code vs image

| Build in code (never an image) | Supply as an asset |
|---|---|
| Every button, chip, card, badge, bar, slider, tab bar, list row, text | App icon (adaptive Android icon: foreground and background layers) |
| Rating spread mountain chart, Your Range skyline, expedition trail line (they show live data) | Logo / wordmark (SVG) |
| Progress bars, skeletons, dividers, gradients, simple textures made from shapes | Custom icon set, especially the 4 difficulty glyphs and the tab icons (SVG) |
| Layout, spacing, states | Illustrations for empty states, errors, onboarding, expedition complete (SVG, or Rive/Lottie if animated) |
| Album covers (they come from the internet) | Optional subtle textures (paper grain, topographic contour lines) as small tiling PNG/WebP, or better, as SVG |
| | Fonts (TTF/OTF files with licences) |
| | Splash image (SVG source; exported PNG) |
| | Expedition hero artwork, if each official expedition gets its own picture (WebP) |

**Mockups are references, not assets.** ChatGPT's screen images guide Claude's implementation; they are stored in `design/mockups/` and never placed inside the app. Text, buttons and layout in a mockup are always rebuilt in code.

### 10.2 Formats and resolutions

| Asset | Format | Size / notes |
|---|---|---|
| Icons | SVG, single colour, 24×24 viewBox, no embedded text, strokes converted to paths, no fills set to fixed colours (so code can tint them) | Rendering SVG needs a new package (`flutter_svg` or `vector_graphics`); alternatively convert icons to an icon font. Needs Bailey's approval |
| Illustrations | SVG preferred (few colours, flat shapes from the token palette); PNG/WebP only for painterly art | Raster: supply 1x, 2x, 3x (e.g. 240, 480, 720 px wide for a 240 px slot) in `2.0x/` and `3.0x/` folders |
| Textures | Tileable WebP or PNG, 256–512 px, under 50 KB | Must not reduce text contrast |
| App icon | 1024×1024 master; Android adaptive: 432×432 foreground (safe zone: central 264 px circle) and background layer; monochrome layer for Android 13+ themed icons | Generated into `mipmap-*` folders with `flutter_launcher_icons` (dev tool, needs approval) or by hand |
| Splash | Centred mark on a solid brand colour; Android 12+ shows only an icon in a circle | `flutter_native_splash` (dev tool) or by hand |
| Web | 192 and 512 px icons, maskable versions, favicon, theme colour | `web/` folder |
| Fonts | TTF/OTF, only the weights used, with licence files (OFL preferred) | Bundled in `assets/fonts/`, not downloaded at runtime (works offline and avoids flashes) |
| Animations | Rive (`.riv`) or Lottie (`.json`), under 100 KB each | Only if approved |

**Transparency:** all icons, logo and illustrations with transparent backgrounds; app icon foreground transparent, background solid.

### 10.3 Naming and folders

```
assets/
  brand/          logo_full.svg, logo_mark.svg, wordmark.svg
  icons/          ic_difficulty_base_camp.svg, ic_difficulty_foothills.svg,
                  ic_difficulty_high_altitude.svg, ic_difficulty_summit.svg,
                  ic_tab_discover.svg, ic_tab_discover_selected.svg, ...
  illustrations/  il_empty_rated.svg, il_empty_listen_later.svg, il_error_offline.svg,
                  il_expedition_complete.svg
  textures/       tx_paper_grain.webp, tx_contours.svg
  fonts/          <Family>-Regular.ttf, <Family>-SemiBold.ttf, OFL.txt
design/
  mockups/        <screen>_<state>_v<N>.png   e.g. album_unrated_v1.png
  specs/          <screen>.md, <component>.md
```

Rules: lowercase `snake_case`, a type prefix (`ic_`, `il_`, `tx_`), state suffixes (`_selected`, `_disabled`), version numbers only on mockups (assets are replaced in place and tracked by git).

### 10.4 Handover loop (per asset batch)

1. ChatGPT produces the asset plus a one-line spec (where it's used, size, colour token).
2. Bailey approves and drops the files into the project folder (`music-app/design-assets/…`) or attaches them in the thread.
3. Claude checks them (format, size, transparency, viewBox, contrast against the palette), optimises (SVG cleanup, WebP compression), places them in `assets/`, registers them in `pubspec.yaml`, and wires them into components.
4. Claude posts a web-build screenshot at 360 and 412 px for comparison with the mockup.

### 10.5 Loading and performance

- Bundle all UI assets (no network loading). Total target for new assets under 1 MB.
- Album covers: keep `cached_network_image`, add a short fade-in, keep decode sizes. A per-cover colour placeholder would need colour data the catalogue does not have, so a neutral, on-brand placeholder is the realistic option.
- Pre-cache the few illustrations used on first screens.

---

## 11. Phased implementation recommendations

The order below follows the actual architecture: because most widgets already read the Material theme, **tokens and the theme give the biggest visible change for the least risk**, then the handful of shared components cascade to every screen. Each phase ships as its own numbered version (as Bailey prefers) so the APK can be tried on the phone between phases.

| # | Phase | Who | What happens | Size | Depends on |
|---|---|---|---|---|---|
| 0 | **Audit** | Claude | This document | Done | |
| 1 | **Identity decisions** | ChatGPT + Bailey | App name (and whether the tab stays "Expeditions"), palette (light, dark later?), fonts, icon style, shadows yes/no, motion personality (calm vs playful), card overlay rules | Small | 0 |
| 2 | **Design system spec** | ChatGPT | Tokens (section 9.3) as a table or `tokens.json`; component specs with all states for the 12 components in 9.5 | Medium | 1 |
| 3 | **Tokens + theme in code** | Claude | `lib/design/` tokens, `ThemeData` with component themes, fonts bundled. Replace the hard-coded colours and font sizes. No layout changes | Medium | 2 |
| 4 | **Brand basics** | ChatGPT assets, Claude integration | App icon, splash, app name, web manifest/title/favicon | Small | 1 |
| 5 | **Shared components** | Claude | Rebuild Cover, AlbumCard, badges, Rating control, Difficulty tag + glyphs, section header, chips, empty/error/skeleton states, snack bar. Most screens change here automatically | Large | 2, 3 |
| 6 | **Screen designs** | ChatGPT | Screen-by-screen mockups with states (default, loading, empty, error, large text), in the order of phase 7 | Large (spread over time) | 2 |
| 7 | **Screens, one per release** | Claude | Suggested order by usage and impact: **(a) Album page** (rating, the core loop), **(b) Discover + search + chart + genre**, **(c) Expeditions list + trail** (flagship), **(d) You + Your Range**, **(e) Artist page**, **(f) Song page + track sheet**, **(g) Create/edit expedition, About, Missing page, dialogs** | Large | 5, 6 |
| 8 | **Motion** | ChatGPT specs, Claude builds | Motion tokens, page/tab transitions, Hero covers, rating feedback and haptics, trail and skyline animation, reduced-motion handling | Medium | 5, 7a–c |
| 9 | **Comparison** | Claude + Bailey | Screenshots at 360/412/600 px and at 200 % text, side by side with mockups, after each screen | Ongoing | 7 |
| 10 | **Accessibility and performance pass** | Claude | Semantics labels on custom drawings, touch targets, contrast check, rebuild/caching fixes from 2.8, test with TalkBack and large fonts | Medium | 7 |
| 11 | **Polish** | All | Empty-state illustrations, expedition-complete moment, micro-interactions | Medium | 8 |
| 12 | **Release** | Bailey | v1.0 visual release | | |

**Why this order differs slightly from the brief:** motion (brief step 5) is specified after the core screens because transitions depend on the final layout (a Hero needs both ends designed). Brand basics move early because they are independent, small and very visible.

**Rules during implementation**

- No changes to `store.dart`, `catalogue.dart`, `details.dart`, `expeditions.dart`, `models.dart` or saved data formats, except tiny read-only helpers if a design needs them (each one flagged).
- Each phase keeps all tests green; widget tests that look for exact texts (for example "Rate", "tap to clear") will be updated only where Bailey approves a wording change.
- Screens are migrated one at a time; old and new styles coexist briefly through the shared theme, which keeps the app usable at every release.

---

## 12. Technical risks, constraints and unresolved questions

### 12.1 Risks and constraints

| Risk | Impact | Mitigation |
|---|---|---|
| **Large system font sizes** break fixed-height cards, rows and the trail | Clipped titles, overflow stripes | Designs must specify growth behaviour; Claude will replace fixed heights with measured ones |
| **Album covers are unpredictable** (any colour, sometimes wrong or missing) | Overlays and text on covers may be unreadable; a palette that clashes with covers | Keep text off covers where possible; overlays on a solid scrim; neutral, recessive UI colours so the art leads |
| **Cover art licensing:** covers must be shown as they are | Cannot tint, crop heavily, or stylise covers | Treat covers as untouchable content; frame them, don't alter them |
| **New packages** (SVG, animations, fonts tooling, icons) | Bigger app, more to maintain | Each one listed for approval; prefer official/popular packages; fonts and icons bundled locally |
| **Android-only builds in CI**; Claude checks visuals on the web build | Small differences between web and Android (text rendering, shadows, haptics absent on web) | Bailey checks each APK on the phone; Claude flags Android-only behaviours |
| **Mixed navigation** (pick mode and dialogs outside go_router) | Custom transitions won't apply there | Move pick mode into routes during phase 7g (behaviour unchanged) |
| **Performance on low-end phones** with animation + 10k-album lists | Jank | Fix rebuild hot spots (2.8) before adding motion; keep animations to transforms/opacity |
| **Future backend (accounts, shared ratings, reviews)** | Some screens (stats column, reviews, Top rated) will change meaning | Design these areas for both "no data yet" and "real data" states now |
| **Tests depend on texts and widget types** | Redesign may break tests | Update tests deliberately alongside each screen |
| **Mockup-to-code fidelity** | Image-generated mockups often contain impossible details (inconsistent spacing, fake text rendering, effects that don't exist in Flutter) | ChatGPT should express designs as token-based specs plus mockups; Claude flags anything inefficient rather than silently changing it |
| **Earlier preferences** | Bailey's earlier rules were "plain, no shadows, no dark theme, no fancy animations, features first". This brief signals that polish is now in scope | Treat those rules as defaults to revisit in phase 1, not as constraints |

### 12.2 Feasibility notes for ChatGPT (what's easy, what's costly)

- **Easy in Flutter:** any colour/type/spacing/radius change; rounded or pill shapes; tonal surfaces; gradients; blur behind bars (`BackdropFilter`, moderate cost); Hero transitions; animated numbers; custom-drawn charts and lines; haptics; bottom sheets; skeleton loaders.
- **Moderate:** custom tab bar shapes; drag-to-rate on cards; trail with curved paths, terrain or contour backgrounds (custom painting); per-screen custom transitions; dark mode (easy once tokens exist).
- **Costly or risky:** colours extracted from each cover at runtime (needs image processing per cover; slow on 10k albums); 3D or parallax effects on scrolling grids; heavy blur on long lists; video backgrounds; illustration-heavy screens that must reflow at 200 % text; anything that hides the rating bar or moves it per screen.

### 12.3 Unresolved questions (for Bailey, informed by ChatGPT)

1. **Name.** Is the app called "Expeditions"? If so, should the second tab keep the same name (it would read "Expeditions › Expeditions"), or be renamed (for example "Trails", "Journeys")? An earlier visual audit suggested "Ascent" as an app name; is that still on the table?
2. **Palette.** Brand pair `#172C2B` / `#F3F0E7` vs the earlier "Alpine light" suggestion (`#1F2A30`, `#F7F7F2`, `#3A7CA5`, `#E8743B`). Does the app need a bright accent for ratings and progress beyond the forest green?
3. **Dark mode.** At launch, later, or never? (Tokens make "later" cheap.)
4. **Shadows and depth.** Keep the flat no-shadow style or introduce soft elevation?
5. **Card overlays.** Which of rank, type, rating, bookmark, lock should stay on the cover? (Suggestion: rating and lock on the cover; rank, type and bookmark moved below or into a long-press menu.)
6. **Vinyl theme.** How far should vinyl imagery go (round song covers today; record-shaped loaders, grooves)? It should not compete with the mountain theme.
7. **Motion personality.** Calm and quick, or playful with springs and celebrations? Haptics on rating: yes/no?
8. **Rating control.** Keep the 0–10 slider in the fixed bottom bar exactly as is, or allow a new visual (for example a mountain-height or ring control) as long as it keeps one-touch-to-set and save-on-release?
9. **Stats column** on album/song pages (ratings / yours / average): keep, hide until accounts, or redesign?
10. **Track "Rate" buttons:** keep visible per track or make track rating quieter?
11. **Expedition pictures:** keep stacked covers, or commission artwork per official expedition?
12. **New dependencies:** approve in principle `animations`, an SVG package, and icon/splash generators?
13. **Tablet and landscape:** out of scope for v1.0?
14. **Charts entry point:** keep as chips, or give charts a more visible place on Discover?

---

## 13. Appendix A: Brief for ChatGPT (what to design first)

To begin, ChatGPT needs:

1. **This document**, especially sections 3 (screens), 5 (components), 8 (current styling) and Appendix B (constraints).
2. **The v0.8 screenshots** (`music-app/aesthetic-audit-v0.8/`, 7 sheets) as the "before" state. Remember the gradient squares stand for real covers.
3. **Bailey's answers** to the questions in 12.3, at least name, palette direction, dark mode and motion personality.
4. **Platform facts:** Flutter, Material 3 base, Android phones 360–412 px wide (design at 412×915 and check at 360×800), web capped at 600 px, Roboto replaceable by any bundled open-licence font, icons as SVG.

**Requested first deliverables from ChatGPT (in order):**

1. A visual direction with 2–3 options (moodboard, palette, type pairing, icon style sample, one album card and one album page in each).
2. After Bailey picks one: the token tables (section 9.3) with exact values.
3. Component specs with every state (section 9.5 list), sized in px against the token scale.
4. The album page (unrated, rated, loading tracklist, failed tracklist, long title, from-expedition with Next stop, 200 % text), then the other screens in the phase 7 order.
5. The four difficulty glyphs and three tab icons as SVG.

**Format that makes implementation fastest:** for each screen, a mockup image plus a short spec listing components used, token names (not raw hex), spacing values, states, and any motion (trigger, duration token, curve token).

## 14. Appendix B: Hard constraints checklist for designs

Designs should keep (unless Bailey explicitly changes them):

- [ ] Three tabs: Discover (opens first), Expeditions, You. Tab bar visible on every page.
- [ ] Album and song pages: rating control fixed at the bottom in the same place; unrated shows "–" (not "Rate" and not a number); first touch sets the value; saves on release; one tap to clear with Undo; "Next: [album]" after rating an expedition album.
- [ ] Ratings 0–10 in half steps; one overall score; no sub-scores.
- [ ] Difficulty shown as one of four words with an icon, never as a number, and always tappable for an explanation.
- [ ] Undo messages instead of confirmation pop-ups.
- [ ] Albums as portrait cards with square covers, title (max 2 lines) and artist, about three across on a phone; the user's rating visible on the cover.
- [ ] Listen later reachable in one tap from any album card.
- [ ] Expedition trail scrolls sideways, zig-zags, shows travelled vs ahead, has a bigger final stop, and opens at the next stop. "In order" expeditions show locked stops.
- [ ] Continue card at the top of Expeditions.
- [ ] Your Range: five slots drawn as a skyline, height from difficulty, ratings on covers, empty slots visible.
- [ ] Re-tapping a tab scrolls up / returns to its first page; Android back behaviour as in section 4.1.
- [ ] Sort button always names the current order; tapping the same option reverses it.
- [ ] No extra tabs, no extra confirmation steps, no added taps on the flows in section 4.2.
