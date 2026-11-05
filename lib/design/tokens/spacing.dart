/// Sizes from design/design_tokens_v1.json, in Flutter logical pixels.
library;

/// Spacing scale: 0, 2, 4, 8, 12, 16, 24, 32, 40, 48.
abstract final class AppSpace {
  static const double zero = 0;
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  /// Standard page gutter.
  static const double gutter = lg;

  /// Between sections.
  static const double section = xl;
}

/// Corner radii. Cards 12, square covers 8, sheets 24 (top), pills [full].
abstract final class AppRadii {
  static const double none = 0;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const double cover = sm;
  static const double card = md;
  static const double sheet = xl;
}

/// Icon sizes. Visible icons can be small, but the tap area is always [touchTarget].
abstract final class AppIconSizes {
  static const double small = 16;
  static const double regular = 20;
  static const double standard = 24;
  static const double large = 32;
  static const double stageLarge = 64;
  static const double strokeWidth = 1.8;
  static const double viewBox = 24;
  static const double touchTarget = 48;
}

/// Named album cover sizes. Grid covers are fluid and always square.
abstract final class AppCoverSizes {
  static const double xs = 44;
  static const double sm = 64;
  static const double md = 112;
  static const double lg = 160;
  static const double xl = 224;
  static const double heroMin = 200;
  static const double heroMax = 240;

  /// Album page cover: min(240, max(200, 0.56 × viewport width)).
  static double hero(double viewportWidth) =>
      (0.56 * viewportWidth).clamp(heroMin, heroMax).toDouble();
}

/// Fixed sizes of chrome and components.
abstract final class AppSizes {
  static const double touchMin = 48;
  static const double primaryButtonHeight = 52;
  static const double secondaryButtonHeight = 48;
  static const double appBarHeight = 56;
  static const double searchFieldHeight = 52;
  static const double bottomNavHeight = 72; // plus the system gesture inset
  static const double ratingBarHeight = 72;
  static const double expeditionNextRowHeight = 40;
  static const double albumCardGap = 12;
  static const double gridPageGutter = 16;
  static const double sectionGap = 24;
  static const double groupGap = 12;
  static const double tabIcon = 24;
  static const double ratingValueWidth = 68;
  static const double rangeCanvasHeight = 260;
  static const double rangeCover = 48;
  static const double rangeSlotGap = 2;
  static const double progressTrackHeight = 6;
  static const double indicatorBorderWidth = 2;
}

/// Layout breakpoints and the app's maximum width on the web.
abstract final class AppBreakpoints {
  static const double compactMax = 479;
  static const double mediumMin = 480;
  static const double webMaxWidth = 600;
}
