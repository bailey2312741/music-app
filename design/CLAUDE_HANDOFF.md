# Claude Code handoff — Expeditions Design System v1.0

This package is the **approved design direction and baseline technical specification**, not an instruction to recreate a mockup image literally. Source documents already in your project: `design/APP_AUDIT.md`, `design/CONCEPT_BOARD_REVIEW.md`, seven v0.8 contact sheets and the five canonical Expeditions brand reference images.

Read **`DESIGN_SYSTEM_V1.md`** first, and then **`design_tokens_v1.json`**. The Markdown document defines interaction rules and precedence; JSON provides exact machine-readable tokens. If a mockup disagrees with these files or with the existing app's core functionality, the functional contract in the spec takes precedence. Flag contradictions and propose a resolution rather than silently changing behaviour.

## Immediate task: foundation-only implementation

Create a feature branch (not `main`) and implement **Phase A: token and theme foundation only** in the current Flutter repository. Do not redesign every screen or add generated backgrounds and fake album artwork.

1. Reconfirm the current app version, Flutter configuration, current source locations and catalogue/stage coverage. The review reported 15 of 9,120 staged; verify the actual current values.
2. Add a sensible `lib/design/` structure with primitive/semantic colours, typography roles, spacing, radii, cover/icon sizes, motion tokens and reduced-motion helpers. Where practical implement a typed `ThemeExtension` for semantic colours.
3. Implement a dark forest-green `ThemeData` and Material 3 component themes (AppBar, NavigationBar, Card, Chip, buttons, Slider, SnackBar, BottomSheet, Dialog, Search/SearchBar, SegmentedButton, progress indicator) using the semantic tokens. Preserve current behaviours.
4. Prepare **Outfit** display and **Inter** UI type integration after confirming legal font sources and obtaining the required open licences. Do not include unlicensed fonts; if acquisition is blocked, implement the theme with temporary system fallbacks, and report the blocker clearly. Do not ask ChatGPT to export or share font binary files.
5. Do not add an SVG or animation dependency yet. `flutter_svg`, `animations` and launcher/splash build tooling require explicit approval. Stage glyphs, launcher artwork and screen layouts are separate deliverables, unless there are already suitable source SVGs in the project.
6. Keep UI test selectors / button functionality, navigator stacks, persistent data, rating logic, routes, album image loading, and `Undo` identical. No changes to the data/model/store files unless a separately documented critical compatibility fix is required.
7. Run available lint/analyze/tests and produce comparative web screenshots (360, 412, 600dp, plus 130% and 200% text scale). Verify all functionality remains intact and the brand palette reads clearly.
8. Report changed files, any token deviations, contrast checks, runtime/package constraints, analysis/test results, Android-only validation still necessary, and any decisions requiring product-owner approval.

## Explicitly NOT in Phase A

- No big Album page restructure, new Discover Featured carousel, genre tile replacement, expanded backend, difficulty assignment or data-model redesign.
- No generated landscape images, mockups shipped as assets, invented playable controls or invented album ratings/stages.
- No removal of existing track-rating buttons, zig-zag expedition trail, current 3-column Rated grid, charts/sort/filters or fixed rating dock.
- No merging into `main` until reviewed and approved.

## Next separate implementation tickets after the foundation

**Phase B:** Export/trace and verify canonical logo, four genuinely distinct large+compact stage icons, tab pairs and genre icon set, with source SVG consistency checks and explicit `flutter_svg` dependency approval if needed.

**Phase C:** Refactor and restyle `Cover`, album cards, rating bar/slider, badges, chips, tabs and state views using components. Preserve actions and one-tap rules. App should remain functional after each commit.

**Phase D:** Detailed Album page from ChatGPT's future screen-specific specification; thereafter Discover, Expeditions list+zig-zag trail, You+Your Range, and remaining screens. Deliver matching screenshots before progressing.

**Phase E:** Code-drawn, responsive five-peak Range geometry; page/Hero/rating/trail animations; reduced-motion handling and Android APK acceptance tests.

## Nonnegotiable acceptance

- All existing tests pass (or any test edits are limited to approved styling/widget selectors).
- No silent functionality loss, no increase in tap counts for core actions.
- 48×48 minimum action targets, readable text at 200%, TalkBack/focus support.
- Real album covers and real rating/stage data only; the UI must support unscored albums explicitly.
- The album rating remains a 0–10 half-step slider with `–` for unrated and Undo on clear.
- New styling is driven from a single semantic source of truth.

**Finish Phase A and present its screenshots and test results for review. Do not automatically continue to the next phases.**
