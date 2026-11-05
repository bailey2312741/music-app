import 'package:flutter/material.dart';

/// Type roles from design/design_tokens_v1.json (`typography.roles`).
///
/// Outfit (display) and Inter (UI) are bundled in assets/fonts/ under the SIL
/// Open Font License. Styles here carry no colour: the theme adds it.
abstract final class AppType {
  static const display = 'Outfit';
  static const ui = 'Inter';

  /// Flutter wants line height as a multiple of font size.
  static TextStyle _role(
    String family,
    double size,
    double lineHeight,
    FontWeight weight,
    double letterSpacing, {
    bool tabular = false,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: letterSpacing,
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
  );

  /// Rare hero headline. Outfit 32/38 800.
  static final displayRole = _role(display, 32, 38, FontWeight.w800, -0.4);

  /// Discover, Expeditions, You. Outfit 28/34 700.
  static final screenTitle = _role(display, 28, 34, FontWeight.w700, -0.35);

  /// Tracklist, Your Range, genre sections. Outfit 20/26 700.
  static final sectionTitle = _role(display, 20, 26, FontWeight.w700, -0.15);

  /// Album and expedition names. Inter 15/20 600.
  static final cardTitle = _role(ui, 15, 20, FontWeight.w600, -0.1);

  /// Main UI body. Inter 15/22 400.
  static final body = _role(ui, 15, 22, FontWeight.w400, 0);

  /// Artist and helpful metadata. Inter 13/19 400.
  static final bodySmall = _role(ui, 13, 19, FontWeight.w400, 0);

  /// Uppercase stage/section tags only: pass upper-case text, Flutter can't
  /// transform case from a style. Inter 12/16 600, +0.8 tracking.
  static final label = _role(ui, 12, 16, FontWeight.w600, 0.8);

  /// Short ancillary text. Inter 12/17 400.
  static final caption = _role(ui, 12, 17, FontWeight.w400, 0.05);

  /// Main rating value, tabular digits. Inter 24/29 700.
  static final score = _role(ui, 24, 29, FontWeight.w700, -0.5, tabular: true);

  /// Card score badges, tabular digits. Inter 12/16 700.
  static final scoreSmall = _role(ui, 12, 16, FontWeight.w700, 0, tabular: true);

  /// Material's text roles mapped onto the design roles, so existing screens
  /// that use `Theme.of(context).textTheme` pick up the new type unchanged.
  ///
  /// Roles the spec doesn't name reuse the nearest design role; see the PR
  /// notes for the mapping.
  static TextTheme textTheme() => TextTheme(
    displayLarge: displayRole,
    displayMedium: displayRole,
    displaySmall: displayRole,
    headlineLarge: screenTitle,
    headlineMedium: screenTitle,
    // Only used for the big number in the rating bar today.
    headlineSmall: score,
    // App bar titles, album and expedition names on their pages.
    titleLarge: sectionTitle,
    titleMedium: cardTitle,
    titleSmall: bodySmall.copyWith(fontWeight: FontWeight.w600),
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: bodySmall,
    // Button text.
    labelLarge: cardTitle.copyWith(letterSpacing: 0),
    labelMedium: caption.copyWith(fontWeight: FontWeight.w600, height: 16 / 12),
    labelSmall: caption,
  );
}
