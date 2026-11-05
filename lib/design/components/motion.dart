import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/motion.dart';

/// The one page transition: a short fade with a slight slide in from the
/// right (280 ms, easeOutCubic). With reduced motion it is a plain cut.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Duration get transitionDuration => AppMotion.screen.duration;

  @override
  Duration get reverseTransitionDuration => AppMotion.screen.duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduced(context)) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.screen.curve,
      reverseCurve: AppMotion.screen.curve.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// Small, meaningful vibrations. Nothing on the web or desktop, and never
/// more than one tick per [_minGap] while a slider is dragged quickly.
abstract final class AppHaptics {
  static const _minGap = Duration(milliseconds: 45);
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// A rating slider moved to another half point.
  static void step() {
    if (!_supported) return;
    final now = DateTime.now();
    if (now.difference(_last) < _minGap) return;
    _last = now;
    HapticFeedback.selectionClick();
  }

  /// A rating was saved, or an expedition stop was completed.
  static void commit() {
    if (!_supported) return;
    _last = DateTime.now();
    HapticFeedback.lightImpact();
  }
}

/// Which album card was just tapped. Only that card's cover takes part in the
/// shared-cover (Hero) flight, so an album shown in several rows never
/// produces duplicate Hero tags.
final ValueNotifier<Object?> _heroSource = ValueNotifier<Object?>(null);

/// The album cover flying between a card and the album page.
///
/// On a card ([source] set to something unique to that card, such as its
/// BuildContext), the Hero only flies after [CoverHero.claim] was called with
/// the same source. On the album page ([source] null) it always can. Reduced
/// motion turns the flight off.
class CoverHero extends StatelessWidget {
  final String albumId;
  final Object? source;
  final Widget child;
  const CoverHero({super.key, required this.albumId, required this.child, this.source});

  /// Marks [source] as the card being opened.
  static void claim(Object source) => _heroSource.value = source;

  static String tagFor(String albumId) => 'album-cover:$albumId';

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    Widget hero(bool enabled) => HeroMode(
      enabled: enabled && !reduced,
      child: Hero(
        tag: tagFor(albumId),
        // The card's cover flies in both directions: it is already loaded,
        // so the artwork never flashes to a placeholder mid-flight.
        flightShuttleBuilder: (_, _, direction, fromContext, toContext) {
          final card = direction == HeroFlightDirection.push ? fromContext : toContext;
          return (card.widget as Hero).child;
        },
        child: child,
      ),
    );
    if (source == null) return hero(true);
    return ValueListenableBuilder<Object?>(
      valueListenable: _heroSource,
      builder: (_, active, _) => hero(identical(active, source)),
    );
  }
}
