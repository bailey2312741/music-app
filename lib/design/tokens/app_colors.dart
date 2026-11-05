import 'package:flutter/material.dart';

import 'palette.dart';

/// Semantic colour roles (`semantic` in design/design_tokens_v1.json).
///
/// Read them in a widget with `AppColors.of(context)`. Only the dark brand
/// theme exists in v1; a light theme would be a second instance of this class.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color page;
  final Color chrome;
  final Color surfaceRaised;
  final Color surfaceSelected;
  final Color surfaceSunken;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textOnLight;
  final Color primaryButtonFill;
  final Color primaryButtonText;
  final Color secondaryButtonBorder;
  final Color lineDecorative;
  final Color lineFunctional;
  final Color focusRing;
  final Color ratingFill;
  final Color ratingTrack;
  final Color progressFill;
  final Color progressTrack;
  final Color success;
  final Color warning;
  final Color error;
  final Color disabledForeground;
  final Color bookmarkActive;
  final Color lockedText;
  final Color snowCap;
  final Color mountainLit;
  final Color mountainShadow;
  final Color mountainBase;
  final Color unscoredOutline;

  const AppColors({
    required this.page,
    required this.chrome,
    required this.surfaceRaised,
    required this.surfaceSelected,
    required this.surfaceSunken,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textOnLight,
    required this.primaryButtonFill,
    required this.primaryButtonText,
    required this.secondaryButtonBorder,
    required this.lineDecorative,
    required this.lineFunctional,
    required this.focusRing,
    required this.ratingFill,
    required this.ratingTrack,
    required this.progressFill,
    required this.progressTrack,
    required this.success,
    required this.warning,
    required this.error,
    required this.disabledForeground,
    required this.bookmarkActive,
    required this.lockedText,
    required this.snowCap,
    required this.mountainLit,
    required this.mountainShadow,
    required this.mountainBase,
    required this.unscoredOutline,
  });

  /// The v1 dark forest-green brand theme.
  static const dark = AppColors(
    page: Palette.forest800,
    chrome: Palette.forest900,
    surfaceRaised: Palette.forest700,
    surfaceSelected: Palette.forest650,
    surfaceSunken: Palette.forest900,
    textPrimary: Palette.paper50,
    textSecondary: Palette.paper200,
    textTertiary: Palette.paper300,
    textOnLight: Palette.forest900,
    primaryButtonFill: Palette.paper50,
    primaryButtonText: Palette.forest900,
    secondaryButtonBorder: Palette.borderFunctional,
    lineDecorative: Palette.borderSubtle,
    lineFunctional: Palette.borderFunctional,
    focusRing: Palette.paper50,
    ratingFill: Palette.mint200,
    ratingTrack: Palette.forest650,
    progressFill: Palette.mint200,
    progressTrack: Palette.forest650,
    success: Palette.mint200,
    warning: Palette.amber200,
    error: Palette.coral200,
    disabledForeground: Palette.paper300,
    bookmarkActive: Palette.paper50,
    lockedText: Palette.paper200,
    snowCap: Palette.paper50,
    mountainLit: Palette.borderFunctional,
    mountainShadow: Palette.forest650,
    mountainBase: Palette.forest700,
    unscoredOutline: Palette.paper300,
  );

  /// The semantic colours of the current theme (the dark theme if none is set).
  static AppColors of(BuildContext context) => Theme.of(context).extension<AppColors>() ?? dark;

  /// Every role by its token name, for tests that compare against the JSON.
  Map<String, Color> get byName => {
    'page': page,
    'chrome': chrome,
    'surfaceRaised': surfaceRaised,
    'surfaceSelected': surfaceSelected,
    'surfaceSunken': surfaceSunken,
    'textPrimary': textPrimary,
    'textSecondary': textSecondary,
    'textTertiary': textTertiary,
    'textOnLight': textOnLight,
    'primaryButtonFill': primaryButtonFill,
    'primaryButtonText': primaryButtonText,
    'secondaryButtonBorder': secondaryButtonBorder,
    'lineDecorative': lineDecorative,
    'lineFunctional': lineFunctional,
    'focusRing': focusRing,
    'ratingFill': ratingFill,
    'ratingTrack': ratingTrack,
    'progressFill': progressFill,
    'progressTrack': progressTrack,
    'success': success,
    'warning': warning,
    'error': error,
    'disabledForeground': disabledForeground,
    'bookmarkActive': bookmarkActive,
    'lockedText': lockedText,
    'snowCap': snowCap,
    'mountainLit': mountainLit,
    'mountainShadow': mountainShadow,
    'mountainBase': mountainBase,
    'unscoredOutline': unscoredOutline,
  };

  @override
  AppColors copyWith({
    Color? page,
    Color? chrome,
    Color? surfaceRaised,
    Color? surfaceSelected,
    Color? surfaceSunken,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textOnLight,
    Color? primaryButtonFill,
    Color? primaryButtonText,
    Color? secondaryButtonBorder,
    Color? lineDecorative,
    Color? lineFunctional,
    Color? focusRing,
    Color? ratingFill,
    Color? ratingTrack,
    Color? progressFill,
    Color? progressTrack,
    Color? success,
    Color? warning,
    Color? error,
    Color? disabledForeground,
    Color? bookmarkActive,
    Color? lockedText,
    Color? snowCap,
    Color? mountainLit,
    Color? mountainShadow,
    Color? mountainBase,
    Color? unscoredOutline,
  }) => AppColors(
    page: page ?? this.page,
    chrome: chrome ?? this.chrome,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceSelected: surfaceSelected ?? this.surfaceSelected,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textOnLight: textOnLight ?? this.textOnLight,
    primaryButtonFill: primaryButtonFill ?? this.primaryButtonFill,
    primaryButtonText: primaryButtonText ?? this.primaryButtonText,
    secondaryButtonBorder: secondaryButtonBorder ?? this.secondaryButtonBorder,
    lineDecorative: lineDecorative ?? this.lineDecorative,
    lineFunctional: lineFunctional ?? this.lineFunctional,
    focusRing: focusRing ?? this.focusRing,
    ratingFill: ratingFill ?? this.ratingFill,
    ratingTrack: ratingTrack ?? this.ratingTrack,
    progressFill: progressFill ?? this.progressFill,
    progressTrack: progressTrack ?? this.progressTrack,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    error: error ?? this.error,
    disabledForeground: disabledForeground ?? this.disabledForeground,
    bookmarkActive: bookmarkActive ?? this.bookmarkActive,
    lockedText: lockedText ?? this.lockedText,
    snowCap: snowCap ?? this.snowCap,
    mountainLit: mountainLit ?? this.mountainLit,
    mountainShadow: mountainShadow ?? this.mountainShadow,
    mountainBase: mountainBase ?? this.mountainBase,
    unscoredOutline: unscoredOutline ?? this.unscoredOutline,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      page: l(page, other.page),
      chrome: l(chrome, other.chrome),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSelected: l(surfaceSelected, other.surfaceSelected),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      textOnLight: l(textOnLight, other.textOnLight),
      primaryButtonFill: l(primaryButtonFill, other.primaryButtonFill),
      primaryButtonText: l(primaryButtonText, other.primaryButtonText),
      secondaryButtonBorder: l(secondaryButtonBorder, other.secondaryButtonBorder),
      lineDecorative: l(lineDecorative, other.lineDecorative),
      lineFunctional: l(lineFunctional, other.lineFunctional),
      focusRing: l(focusRing, other.focusRing),
      ratingFill: l(ratingFill, other.ratingFill),
      ratingTrack: l(ratingTrack, other.ratingTrack),
      progressFill: l(progressFill, other.progressFill),
      progressTrack: l(progressTrack, other.progressTrack),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      disabledForeground: l(disabledForeground, other.disabledForeground),
      bookmarkActive: l(bookmarkActive, other.bookmarkActive),
      lockedText: l(lockedText, other.lockedText),
      snowCap: l(snowCap, other.snowCap),
      mountainLit: l(mountainLit, other.mountainLit),
      mountainShadow: l(mountainShadow, other.mountainShadow),
      mountainBase: l(mountainBase, other.mountainBase),
      unscoredOutline: l(unscoredOutline, other.unscoredOutline),
    );
  }
}
