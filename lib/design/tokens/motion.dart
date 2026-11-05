import 'package:flutter/widgets.dart';

/// One motion token: how long, and with what easing.
@immutable
class MotionToken {
  final Duration duration;
  final Curve curve;
  const MotionToken(this.duration, this.curve);

  /// This token, or an instant one when the user asked the system to reduce
  /// motion (Android "Remove animations", or the browser equivalent).
  MotionToken resolve(BuildContext context) => AppMotion.reduced(context) ? AppMotion.none : this;
}

/// Motion tokens from design/design_tokens_v1.json (`primitives.motion`).
///
/// Use `AppMotion.fade.resolve(context)` so reduced-motion is always honoured.
abstract final class AppMotion {
  static const none = MotionToken(Duration.zero, Curves.linear);
  static const press = MotionToken(Duration(milliseconds: 100), Curves.easeOutCubic);
  static const ratingValue = MotionToken(Duration(milliseconds: 120), Curves.easeOutCubic);
  static const fade = MotionToken(Duration(milliseconds: 180), Curves.easeOutCubic);
  static const coverReveal = MotionToken(Duration(milliseconds: 200), Curves.easeInOut);
  static const hero = MotionToken(Duration(milliseconds: 240), Curves.easeInOutCubic);
  static const screen = MotionToken(Duration(milliseconds: 280), Curves.easeOutCubic);
  static const trail = MotionToken(Duration(milliseconds: 400), Curves.easeInOutCubic);
  static const rangePeak = MotionToken(Duration(milliseconds: 400), Curves.easeInOutCubic);
  static const completeMoment = MotionToken(Duration(milliseconds: 500), Curves.easeOutCubic);

  /// Pressed buttons shrink to this scale (unless motion is reduced).
  static const pressScale = 0.98;

  /// Whether the user asked for reduced motion.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// The press scale, or 1 (no shrink) when motion is reduced.
  static double pressScaleFor(BuildContext context) => reduced(context) ? 1 : pressScale;
}
