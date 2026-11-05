import 'package:flutter/material.dart';

import 'tokens/app_colors.dart';
import 'tokens/app_type.dart';
import 'tokens/spacing.dart';

/// The Expeditions brand theme: dark forest green, warm off-white, flat
/// surfaces and no shadows. Built only from the design tokens.
abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark);

  /// Material's colour roles, filled from the semantic tokens so screens that
  /// use `Theme.of(context).colorScheme` get brand colours without changes.
  static ColorScheme colorScheme(AppColors c) => ColorScheme(
    brightness: Brightness.dark,
    // Highest-priority actions are cream with dark text.
    primary: c.primaryButtonFill,
    onPrimary: c.primaryButtonText,
    primaryContainer: c.surfaceSelected,
    onPrimaryContainer: c.textPrimary,
    // Ratings, progress and success.
    secondary: c.ratingFill,
    onSecondary: c.textOnLight,
    secondaryContainer: c.surfaceSelected,
    onSecondaryContainer: c.textPrimary,
    tertiary: c.textSecondary,
    onTertiary: c.textOnLight,
    tertiaryContainer: c.surfaceRaised,
    onTertiaryContainer: c.textPrimary,
    error: c.error,
    onError: c.textOnLight,
    errorContainer: c.surfaceRaised,
    onErrorContainer: c.error,
    surface: c.page,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceDim: c.chrome,
    surfaceBright: c.surfaceSelected,
    surfaceContainerLowest: c.chrome,
    surfaceContainerLow: c.chrome,
    surfaceContainer: c.surfaceRaised,
    surfaceContainerHigh: c.surfaceRaised,
    surfaceContainerHighest: c.surfaceSelected,
    outline: c.lineFunctional,
    outlineVariant: c.lineDecorative,
    shadow: Colors.transparent,
    scrim: c.chrome,
    inverseSurface: c.textPrimary,
    onInverseSurface: c.textOnLight,
    inversePrimary: c.page,
    surfaceTint: Colors.transparent,
  );

  static ThemeData _build(AppColors c) {
    final scheme = colorScheme(c);
    final text = AppType.textTheme().apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);
    const stadium = StadiumBorder();
    final cardShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.card));
    final functionalLine = BorderSide(color: c.lineFunctional);

    // Shared button parts: full 48 px tap areas, pill shape, no shadow.
    final buttonText = WidgetStatePropertyAll(text.labelLarge);
    const noElevation = WidgetStatePropertyAll<double>(0);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      textTheme: text,
      primaryTextTheme: text,
      fontFamily: AppType.ui,
      scaffoldBackgroundColor: c.page,
      canvasColor: c.page,
      dividerColor: c.lineDecorative,
      disabledColor: c.disabledForeground,
      focusColor: c.focusRing.withValues(alpha: 0.12),
      hoverColor: c.textPrimary.withValues(alpha: 0.04),
      highlightColor: c.textPrimary.withValues(alpha: 0.08),
      splashColor: c.textPrimary.withValues(alpha: 0.08),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      extensions: [c],

      appBarTheme: AppBarTheme(
        backgroundColor: c.page,
        foregroundColor: c.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: AppSizes.appBarHeight,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: c.textPrimary, size: AppIconSizes.standard),
        actionsIconTheme: IconThemeData(color: c.textPrimary, size: AppIconSizes.standard),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.chrome,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.bottomNavHeight,
        indicatorColor: c.surfaceSelected,
        indicatorShape: stadium,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: AppSizes.tabIcon,
            color: s.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppType.caption.copyWith(
            color: s.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: cardShape,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceRaised,
        selectedColor: c.surfaceSelected,
        disabledColor: c.surfaceSunken,
        checkmarkColor: c.textPrimary,
        deleteIconColor: c.textSecondary,
        iconTheme: IconThemeData(color: c.textPrimary, size: AppIconSizes.small + 2),
        labelStyle: text.titleSmall?.copyWith(color: c.textPrimary),
        secondaryLabelStyle: text.titleSmall?.copyWith(color: c.textPrimary),
        side: functionalLine,
        shape: stadium,
        elevation: 0,
        pressElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.surfaceSelected : c.primaryButtonFill,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.disabledForeground : c.primaryButtonText,
          ),
          overlayColor: WidgetStatePropertyAll(c.primaryButtonText.withValues(alpha: 0.08)),
          minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.primaryButtonHeight)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpace.xl)),
          shape: const WidgetStatePropertyAll(stadium),
          textStyle: buttonText,
          elevation: noElevation,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.disabledForeground : c.textPrimary,
          ),
          overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.08)),
          side: WidgetStateProperty.resolveWith(
            (s) => BorderSide(
              color: s.contains(WidgetState.focused) ? c.focusRing : c.secondaryButtonBorder,
              width: s.contains(WidgetState.focused) ? AppSizes.indicatorBorderWidth : 1,
            ),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.secondaryButtonHeight)),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: AppSpace.lg)),
          shape: const WidgetStatePropertyAll(stadium),
          textStyle: buttonText,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.disabledForeground : c.textPrimary,
          ),
          overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.08)),
          minimumSize: const WidgetStatePropertyAll(Size(48, AppSizes.touchMin)),
          shape: const WidgetStatePropertyAll(stadium),
          textStyle: buttonText,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.disabledForeground : c.textPrimary,
          ),
          overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.08)),
          minimumSize: const WidgetStatePropertyAll(Size(64, AppSizes.secondaryButtonHeight)),
          shape: const WidgetStatePropertyAll(stadium),
          textStyle: buttonText,
          elevation: noElevation,
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? c.disabledForeground : c.textPrimary,
          ),
          overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.08)),
          minimumSize: const WidgetStatePropertyAll(Size.square(AppSizes.touchMin)),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primaryButtonFill,
        foregroundColor: c.primaryButtonText,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: stadium,
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.surfaceSelected : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? c.textPrimary : c.textSecondary,
          ),
          side: WidgetStatePropertyAll(functionalLine),
          minimumSize: const WidgetStatePropertyAll(Size(48, AppSizes.touchMin)),
          textStyle: WidgetStatePropertyAll(text.titleSmall),
          overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.08)),
        ),
      ),

      sliderTheme: SliderThemeData(
        activeTrackColor: c.ratingFill,
        inactiveTrackColor: c.ratingTrack,
        thumbColor: c.ratingFill,
        overlayColor: c.ratingFill.withValues(alpha: 0.12),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
        valueIndicatorColor: c.chrome,
        valueIndicatorTextStyle: AppType.scoreSmall.copyWith(color: c.textPrimary),
        disabledActiveTrackColor: c.lineDecorative,
        disabledInactiveTrackColor: c.surfaceSelected,
        disabledThumbColor: c.lineFunctional,
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.progressFill,
        linearTrackColor: c.progressTrack,
        circularTrackColor: Colors.transparent,
        linearMinHeight: AppSizes.progressTrackHeight,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.chrome,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.textPrimary),
        actionTextColor: c.ratingFill,
        disabledActionTextColor: c.disabledForeground,
        closeIconColor: c.textSecondary,
        elevation: 0,
        shape: Border(top: BorderSide(color: c.lineDecorative)),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surfaceRaised,
        modalBackgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: c.textTertiary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.xl)),
        titleTextStyle: text.titleLarge,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.textSecondary),
        barrierColor: c.chrome.withValues(alpha: 0.72),
      ),

      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: noElevation,
        overlayColor: WidgetStatePropertyAll(c.textPrimary.withValues(alpha: 0.04)),
        side: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.focused)
              ? BorderSide(color: c.focusRing, width: AppSizes.indicatorBorderWidth)
              : functionalLine,
        ),
        shape: const WidgetStatePropertyAll(stadium),
        constraints: const BoxConstraints(minHeight: 52, maxWidth: double.infinity),
        textStyle: WidgetStatePropertyAll(text.bodyLarge?.copyWith(color: c.textPrimary)),
        hintStyle: WidgetStatePropertyAll(text.bodyLarge?.copyWith(color: c.textTertiary)),
      ),

      searchViewTheme: SearchViewThemeData(
        backgroundColor: c.page,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        dividerColor: c.lineDecorative,
        headerTextStyle: text.bodyLarge,
        headerHintStyle: text.bodyLarge?.copyWith(color: c.textTertiary),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        hintStyle: text.bodyLarge?.copyWith(color: c.textTertiary),
        labelStyle: text.bodyLarge?.copyWith(color: c.textSecondary),
        floatingLabelStyle: text.bodySmall?.copyWith(color: c.textPrimary),
        helperStyle: text.bodySmall?.copyWith(color: c.textSecondary),
        errorStyle: text.bodySmall?.copyWith(color: c.error),
        iconColor: c.textSecondary,
        prefixIconColor: c.textSecondary,
        suffixIconColor: c.textSecondary,
        // Borders are left to each field (some are outlined, some underlined);
        // their colours come from the colour scheme.
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.textPrimary,
        selectionColor: c.ratingFill.withValues(alpha: 0.35),
        selectionHandleColor: c.ratingFill,
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: c.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        textStyle: text.bodyMedium,
        labelTextStyle: WidgetStatePropertyAll(text.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: c.lineDecorative),
        ),
      ),

      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(c.surfaceRaised),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: noElevation,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
              side: BorderSide(color: c.lineDecorative),
            ),
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.textSecondary,
        textColor: c.textPrimary,
        titleTextStyle: text.bodyLarge,
        subtitleTextStyle: text.bodySmall?.copyWith(color: c.textSecondary),
        selectedColor: c.textPrimary,
        selectedTileColor: c.surfaceSelected,
      ),

      dividerTheme: DividerThemeData(color: c.lineDecorative, thickness: 1),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.textPrimary,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        textStyle: AppType.caption.copyWith(color: c.textOnLight),
      ),

      iconTheme: IconThemeData(color: c.textPrimary, size: AppIconSizes.standard),
    );
  }
}
