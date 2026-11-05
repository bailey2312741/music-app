import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';

import 'actions.dart';
import 'design/design.dart';
import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

/// What a Range slot holds, as far as the mountain is concerned.
enum PeakKind { empty, unassigned, baseCamp, foothills, highAltitude, summit }

/// Shapes and heights of the Your Range mountains (design system 4.8).
///
/// Heights are measured from the shared baseline to the apex and come only
/// from the album's listening stage, never from its rating.
abstract final class RangeGeometry {
  /// Room above the tallest apex for its 48 px cover.
  static const coverRoom = 52.0;
  static const summitHeight = 156.0;

  /// The solid ground strip under every peak.
  static const groundHeight = 14.0;

  /// The mountain canvas, from the top of a Summit cover to the ground.
  static const canvasHeight = coverRoom + summitHeight + groundHeight;
  static const baseline = coverRoom + summitHeight;

  static PeakKind kindOf(Album? album, Difficulty? stage) => album == null
      ? PeakKind.empty
      : switch (stage) {
          null => PeakKind.unassigned,
          Difficulty.baseCamp => PeakKind.baseCamp,
          Difficulty.foothills => PeakKind.foothills,
          Difficulty.highAltitude => PeakKind.highAltitude,
          Difficulty.summit => PeakKind.summit,
        };

  /// Apex height above the baseline. Unassigned is a neutral placeholder
  /// height, not a rank; an empty slot is a low faint outline.
  static double height(PeakKind k) => switch (k) {
    PeakKind.baseCamp => 80,
    PeakKind.foothills => 102,
    PeakKind.highAltitude => 130,
    PeakKind.summit => summitHeight,
    PeakKind.unassigned => 98,
    PeakKind.empty => 64,
  };

  /// Half the width of a peak's base, for slots [slot] wide. Neighbouring
  /// peaks overlap so the five read as one connected range.
  static double halfBase(PeakKind k, double slot) => switch (k) {
    PeakKind.baseCamp => slot * 0.95,
    PeakKind.foothills => slot * 0.9,
    PeakKind.highAltitude => slot * 0.82,
    PeakKind.summit => slot * 0.86,
    PeakKind.unassigned => slot * 0.7,
    PeakKind.empty => slot * 0.6,
  };

  /// The outline of one peak with its apex at x = [x], standing on [base].
  /// Each stage has its own silhouette, not just its own height.
  static Path silhouette(PeakKind k, double x, double base, double slot) {
    final h = height(k);
    final b = halfBase(k, slot);
    final top = base - h;
    final p = Path()..moveTo(x - b, base);
    switch (k) {
      case PeakKind.baseCamp:
        // Broad low ridge with a short flat top.
        p
          ..lineTo(x - b * 0.5, base - h * 0.62)
          ..lineTo(x - b * 0.14, top)
          ..lineTo(x + b * 0.12, top + 2)
          ..lineTo(x + b * 0.45, base - h * 0.7)
          ..lineTo(x + b * 0.62, base - h * 0.55);
      case PeakKind.foothills:
        // Rolling, rounded ridge with a strong right shoulder.
        p
          ..quadraticBezierTo(x - b * 0.55, base - h * 0.55, x - b * 0.3, base - h * 0.88)
          ..quadraticBezierTo(x, top - 8, x + b * 0.28, base - h * 0.86)
          ..lineTo(x + b * 0.52, base - h * 0.62)
          ..quadraticBezierTo(x + b * 0.7, base - h * 0.58, x + b * 0.8, base - h * 0.4);
      case PeakKind.highAltitude:
        // Steep split face with a jagged second tooth.
        p
          ..lineTo(x - b * 0.62, base - h * 0.38)
          ..lineTo(x - b * 0.5, base - h * 0.34)
          ..lineTo(x - b * 0.3, base - h * 0.72)
          ..lineTo(x - b * 0.2, base - h * 0.66)
          ..lineTo(x, top)
          ..lineTo(x + b * 0.2, base - h * 0.76)
          ..lineTo(x + b * 0.34, base - h * 0.84)
          ..lineTo(x + b * 0.52, base - h * 0.5)
          ..lineTo(x + b * 0.7, base - h * 0.32);
      case PeakKind.summit:
        // One isolated tall pinnacle rising from two stepped ledges.
        p
          ..lineTo(x - b * 0.66, base - h * 0.2)
          ..lineTo(x - b * 0.46, base - h * 0.23)
          ..lineTo(x - b * 0.36, base - h * 0.48)
          ..lineTo(x - b * 0.24, base - h * 0.52)
          ..lineTo(x - b * 0.08, base - h * 0.94)
          ..lineTo(x, top)
          ..lineTo(x + b * 0.08, base - h * 0.95)
          ..lineTo(x + b * 0.24, base - h * 0.6)
          ..lineTo(x + b * 0.32, base - h * 0.4)
          ..lineTo(x + b * 0.48, base - h * 0.37)
          ..lineTo(x + b * 0.64, base - h * 0.16);
      case PeakKind.unassigned:
      case PeakKind.empty:
        // Plain neutral triangle: no stage shape implied.
        p.lineTo(x, top);
    }
    return p
      ..lineTo(x + b, base)
      ..close();
  }

  /// Where the snow line starts below the apex; null for no snow.
  static double? snowDepth(PeakKind k) => switch (k) {
    PeakKind.summit => 30,
    PeakKind.highAltitude => 24,
    PeakKind.foothills => 12,
    _ => null,
  };
}

/// "Your Range": the pinned albums drawn as a connected mountain skyline. Each
/// cover sits on its peak; the peak's height and shape come from the album's
/// listening stage. Below each peak, its stage in words.
class RangeSkyline extends StatelessWidget {
  final Store store;

  /// When true, tapping a cover removes it (the visible alternative to
  /// pressing and holding).
  final bool editing;
  const RangeSkyline({super.key, required this.store, this.editing = false});

  static const coverSize = AppSizes.rangeCover;

  Future<void> _remove(BuildContext context, Album album, int slot) async {
    final messenger = ScaffoldMessenger.of(context);
    await store.unpin(album.id);
    showUndoOn(messenger, 'Removed from Your Range', () async {
      if (store.range[slot] == null) {
        await store.pin(album, slot: slot);
      } else if (!store.rangeFull) {
        await store.pin(album);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final range = store.range;
    final stages = [for (final a in range) a == null ? null : difficultyOf(store, a.id)];
    final kinds = [
      for (var i = 0; i < range.length; i++) RangeGeometry.kindOf(range[i], stages[i]),
    ];
    final c = AppColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final slot = box.maxWidth / Store.rangeSize;
        final xs = [for (var i = 0; i < range.length; i++) slot * (i + 0.5)];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: RangeGeometry.canvasHeight,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: CustomPaint(
                        painter: RangePainter(
                          kinds: kinds,
                          xs: xs,
                          slot: slot,
                          colors: RangeColors.of(c),
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < range.length; i++)
                    Positioned(
                      left: xs[i] - coverSize / 2,
                      top:
                          RangeGeometry.baseline -
                          RangeGeometry.height(kinds[i]) -
                          coverSize +
                          AppSpace.xs,
                      child: _PeakTop(
                        slot: i,
                        album: range[i],
                        stage: stages[i],
                        rating: range[i] == null ? null : store.ratingOf(range[i]!.id),
                        editing: editing,
                        // An empty slot opens a list of your rated albums to pick from.
                        onTap: range[i] == null
                            ? () => context.push('/you/range/$i')
                            : editing
                            ? () => _remove(context, range[i]!, i)
                            : () => openAlbum(context, store, range[i]!),
                        onRemove: range[i] == null ? null : () => _remove(context, range[i]!, i),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            // Stage under each peak. With large text the names would break
            // mid-word in a fifth of the width, so they become a list instead;
            // the peaks themselves never change size with text.
            ExcludeSemantics(
              child: MediaQuery.textScalerOf(context).scale(10) >= 15
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < range.length; i++)
                          _StageLabel(kind: kinds[i], stage: stages[i], number: i + 1),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < range.length; i++)
                          Expanded(
                            child: _StageLabel(kind: kinds[i], stage: stages[i]),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// The stage name (and icon) under a peak.
class _StageLabel extends StatelessWidget {
  final PeakKind kind;
  final Difficulty? stage;

  /// Set for the list layout: "1  Summit" in a row instead of a column.
  final int? number;
  const _StageLabel({required this.kind, required this.stage, this.number});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = stage;
    final (Widget icon, String text, Color color) = switch (kind) {
      PeakKind.empty => (
        Icon(Icons.add, size: AppIconSizes.small, color: c.textTertiary),
        'Empty',
        c.textTertiary,
      ),
      PeakKind.unassigned => (
        Icon(Icons.help_outline, size: AppIconSizes.small, color: c.unscoredOutline),
        'Not assigned',
        c.textSecondary,
      ),
      _ => (
        StageIcon(s!.icon, size: AppIconSizes.regular, color: c.textPrimary),
        s.label,
        c.textPrimary,
      ),
    };
    final style = AppType.caption.copyWith(color: color, fontWeight: FontWeight.w600);
    if (number != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxs),
        child: Row(
          children: [
            SizedBox(
              width: AppSpace.xl,
              child: Text('$number', style: style),
            ),
            icon,
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(text, style: style)),
          ],
        ),
      );
    }
    return Column(
      children: [
        icon,
        const SizedBox(height: AppSpace.xxs),
        Text(text, textAlign: TextAlign.center, style: style),
      ],
    );
  }
}

/// The colours the mountains are painted in.
@immutable
class RangeColors {
  final Color lit, shadow, ground, snow, unscored, faint;
  const RangeColors({
    required this.lit,
    required this.shadow,
    required this.ground,
    required this.snow,
    required this.unscored,
    required this.faint,
  });

  factory RangeColors.of(AppColors c) => RangeColors(
    lit: c.mountainLit,
    shadow: c.mountainShadow,
    ground: c.mountainBase,
    snow: c.snowCap,
    unscored: c.unscoredOutline,
    faint: c.lineDecorative,
  );

  @override
  bool operator ==(Object other) =>
      other is RangeColors &&
      other.lit == lit &&
      other.shadow == shadow &&
      other.ground == ground &&
      other.snow == snow &&
      other.unscored == unscored &&
      other.faint == faint;

  @override
  int get hashCode => Object.hash(lit, shadow, ground, snow, unscored, faint);
}

/// Paints the five peaks, tallest at the back, on a shared ground strip.
class RangePainter extends CustomPainter {
  final List<PeakKind> kinds;
  final List<double> xs;
  final double slot;
  final RangeColors colors;
  RangePainter({required this.kinds, required this.xs, required this.slot, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    const base = RangeGeometry.baseline;
    final order = [for (var i = 0; i < kinds.length; i++) i]
      ..sort((a, b) => RangeGeometry.height(kinds[b]).compareTo(RangeGeometry.height(kinds[a])));
    for (final i in order) {
      final k = kinds[i];
      final x = xs[i];
      final path = RangeGeometry.silhouette(k, x, base, slot);
      if (k == PeakKind.empty) {
        // A faint dotted position, no stage implied.
        _dashedPath(
          canvas,
          path,
          Paint()
            ..color = colors.faint
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
        continue;
      }
      if (k == PeakKind.unassigned) {
        // Neutral: ground-coloured body, dashed light outline.
        canvas.drawPath(path, Paint()..color = colors.ground);
        _dashedPath(
          canvas,
          path,
          Paint()
            ..color = colors.unscored
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
        );
        continue;
      }
      final h = RangeGeometry.height(k);
      final b = RangeGeometry.halfBase(k, slot);
      final top = base - h;
      canvas.save();
      canvas.clipPath(path);
      // Lit face everywhere, then the shaded face right of the ridge line.
      canvas.drawRect(Rect.fromLTWH(x - b, top - 10, b * 2, h + 10), Paint()..color = colors.lit);
      final shade = Path()
        ..moveTo(x, top - 10)
        ..lineTo(x + b * 0.12, base)
        ..lineTo(x + b + 1, base)
        ..lineTo(x + b + 1, top - 10)
        ..close();
      canvas.drawPath(shade, Paint()..color = colors.shadow);
      // Snow cap with a jagged lower edge.
      final depth = RangeGeometry.snowDepth(k);
      if (depth != null) {
        final y = top + depth;
        final w = b * 0.6;
        final snow = Path()..moveTo(x - w, top - 10);
        const teeth = 6;
        for (var t = 0; t <= teeth; t++) {
          snow.lineTo(x - w + 2 * w * t / teeth, y + (t.isOdd ? 6 : -2));
        }
        snow
          ..lineTo(x + w, top - 10)
          ..close();
        canvas.drawPath(snow, Paint()..color = colors.snow.withValues(alpha: 0.9));
      }
      canvas.restore();
      // A defined ridge line along the silhouette.
      canvas.drawPath(
        path,
        Paint()
          ..color = colors.shadow
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
    // Shared ground.
    canvas.drawRect(
      Rect.fromLTWH(0, base, size.width, RangeGeometry.groundHeight),
      Paint()..color = colors.ground,
    );
    canvas.drawLine(
      const Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = colors.lit
        ..strokeWidth = 1.5,
    );
  }

  /// Draws [path] as a dashed line.
  static void _dashedPath(Canvas canvas, Path path, Paint paint) {
    for (final m in path.computeMetrics()) {
      for (var t = 0.0; t < m.length; t += 10) {
        canvas.drawPath(m.extractPath(t, math.min(t + 5, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(RangePainter old) =>
      old.slot != slot || old.colors != colors || !_same(old.kinds, kinds) || !_same(old.xs, xs);

  static bool _same<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The 48 px target on top of a peak: the album's cover with its rating, or a
/// dashed add slot.
class _PeakTop extends StatelessWidget {
  final int slot;
  final Album? album;
  final Difficulty? stage;
  final double? rating;
  final bool editing;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _PeakTop({
    required this.slot,
    required this.album,
    required this.stage,
    required this.rating,
    required this.editing,
    required this.onTap,
    this.onRemove,
  });

  String get _label {
    final a = album;
    if (a == null) return 'Your Range slot ${slot + 1}, empty. Add an album';
    return [
      'Your Range slot ${slot + 1}: ${a.title}, ${a.artist}',
      rating == null ? 'not rated' : 'your rating ${formatScore(rating!)}',
      stage == null ? 'listening stage not assigned' : 'listening stage ${stage!.label}',
      if (editing) 'Tap to remove',
    ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    const size = RangeSkyline.coverSize;
    final a = album;
    final Widget face;
    if (a == null) {
      face = CustomPaint(
        painter: _DashedBoxPainter(c.lineFunctional),
        child: Center(child: Icon(Icons.add, color: c.textSecondary)),
      );
    } else {
      face = Stack(
        children: [
          Cover(album: a, size: size, radius: AppRadii.xs),
          if (rating != null)
            Positioned(
              right: AppSpace.xxs,
              bottom: AppSpace.xxs,
              child: MediaQuery.withNoTextScaling(child: RatingBadge(rating!)),
            ),
          if (stage == null)
            Positioned(
              left: AppSpace.xxs,
              top: AppSpace.xxs,
              child: SizedBox.square(
                dimension: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.chrome,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.unscoredOutline),
                  ),
                  child: Center(
                    child: MediaQuery.withNoTextScaling(
                      child: Text(
                        '?',
                        style: AppType.caption.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          if (editing)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.page.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Icon(Icons.close, color: c.textPrimary),
              ),
            ),
        ],
      );
    }
    return Semantics(
      button: true,
      label: _label,
      excludeSemantics: true,
      customSemanticsActions: onRemove == null || editing
          ? null
          : {const CustomSemanticsAction(label: 'Remove from Your Range'): onRemove!},
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          onLongPress: onRemove,
          borderRadius: BorderRadius.circular(AppRadii.xs),
          child: SizedBox.square(dimension: size, child: face),
        ),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  final Color color;
  _DashedBoxPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    _dashed(canvas, Offset.zero, Offset(s.width, 0), p);
    _dashed(canvas, Offset(s.width, 0), Offset(s.width, s.height), p);
    _dashed(canvas, Offset(s.width, s.height), Offset(0, s.height), p);
    _dashed(canvas, Offset(0, s.height), Offset.zero, p);
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color;
}

/// Draws a dashed straight line from [a] to [b].
void _dashed(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 6, double gap = 5}) {
  final d = b - a;
  final len = d.distance;
  if (len == 0) return;
  final dir = d / len;
  for (var t = 0.0; t < len; t += dash + gap) {
    canvas.drawLine(a + dir * t, a + dir * math.min(t + dash, len), paint);
  }
}

/// Exposed for the expedition trail.
void drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) => _dashed(canvas, a, b, paint);
