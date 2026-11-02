import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

/// "Your Range": the pinned albums drawn as a mountain skyline. Each cover sits
/// on top of a peak whose height comes from the album's difficulty.
class RangeSkyline extends StatelessWidget {
  final Store store;
  const RangeSkyline({super.key, required this.store});

  static const _height = 230.0;
  static const _coverSize = 54.0;

  /// Peak height as a share of the available height. No difficulty = base height.
  static double peakShare(Difficulty? d) => switch (d) {
    null => 0.25,
    Difficulty.baseCamp => 0.32,
    Difficulty.foothills => 0.5,
    Difficulty.highAltitude => 0.7,
    Difficulty.summit => 0.9,
  };

  @override
  Widget build(BuildContext context) {
    final range = store.range;
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final slot = w / Store.rangeSize;
        final usable = _height - _coverSize - 8;
        final peaks = <_Peak>[
          for (var i = 0; i < range.length; i++)
            _Peak(
              x: slot * (i + 0.5),
              topY:
                  _height -
                  usable * (range[i] == null ? 0.45 : peakShare(difficultyOf(store, range[i]!.id))),
              empty: range[i] == null,
            ),
        ];
        return SizedBox(
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkylinePainter(
                    peaks: peaks,
                    halfBase: slot * 0.75,
                    fill: scheme.secondaryContainer,
                    line: scheme.outline,
                  ),
                ),
              ),
              for (var i = 0; i < range.length; i++)
                Positioned(
                  left: peaks[i].x - _coverSize / 2,
                  top: peaks[i].topY - _coverSize - 4,
                  child: _PeakTop(
                    album: range[i],
                    noDifficulty: range[i] != null && difficultyOf(store, range[i]!.id) == null,
                    rating: range[i] == null ? null : store.ratingOf(range[i]!.id),
                    // An empty slot opens a list of your rated albums to pick from.
                    onTap: range[i] == null
                        ? () => context.push('/you/range/$i')
                        : () => openAlbum(context, store, range[i]!),
                    onLongPress: range[i] == null ? null : () => store.unpin(range[i]!.id),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Peak {
  final double x, topY;
  final bool empty;
  const _Peak({required this.x, required this.topY, required this.empty});
}

class _PeakTop extends StatelessWidget {
  final Album? album;
  final bool noDifficulty;
  final double? rating;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  const _PeakTop({
    required this.album,
    required this.noDifficulty,
    required this.rating,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = RangeSkyline._coverSize;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: album == null
          ? SizedBox(
              width: size,
              height: size,
              child: CustomPaint(painter: _DashedBoxPainter(scheme.outline)),
            )
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Cover(album: album!, size: size, radius: 6),
                if (rating != null)
                  Positioned(
                    left: -6,
                    bottom: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fmt(rating!),
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (noDifficulty)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: scheme.surface,
                      child: Text('?', style: TextStyle(color: scheme.onSurface, fontSize: 12)),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _SkylinePainter extends CustomPainter {
  final List<_Peak> peaks;
  final double halfBase;
  final Color fill, line;
  _SkylinePainter({
    required this.peaks,
    required this.halfBase,
    required this.fill,
    required this.line,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final ground = size.height;
    final fillPaint = Paint()..color = fill;
    final edge = Paint()
      ..color = line
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    // Filled peaks first, back to front, then outlines on top.
    for (final p in peaks.where((p) => !p.empty)) {
      final path = Path()
        ..moveTo(p.x - halfBase, ground)
        ..lineTo(p.x, p.topY)
        ..lineTo(p.x + halfBase, ground)
        ..close();
      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, edge);
    }
    for (final p in peaks.where((p) => p.empty)) {
      _dashed(canvas, Offset(p.x - halfBase * 0.8, ground), Offset(p.x, p.topY), edge);
      _dashed(canvas, Offset(p.x, p.topY), Offset(p.x + halfBase * 0.8, ground), edge);
    }
    canvas.drawLine(Offset(0, ground), Offset(size.width, ground), edge);
  }

  @override
  bool shouldRepaint(_SkylinePainter old) => true;
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

/// Exposed for the expedition trail.
void drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint) => _dashed(canvas, a, b, paint);
