import 'dart:math';

import 'package:flutter/material.dart';

import 'design/design.dart';

/// Ratings 0 to 10 grouped into whole numbers (8.5 counts as 9).
List<int> ratingBuckets(Iterable<double> ratings) {
  final counts = List<int>.filled(11, 0);
  for (final r in ratings) {
    counts[(r + 0.0001).round().clamp(0, 10)]++;
  }
  return counts;
}

/// The rating spread drawn as a mountain range: one peak per score, as tall as
/// the number of ratings it got. The highest peak has snow and a flag. With no
/// ratings yet it shows a short empty message instead of an empty chart.
class MountainChart extends StatelessWidget {
  final List<int> counts; // 11 values, for scores 0..10

  /// With no ratings, a single line instead of the larger empty message.
  final bool compactEmpty;
  const MountainChart({super.key, required this.counts, this.compactEmpty = false});

  /// What a screen reader hears: the real counts, highest first.
  String get semanticLabel {
    final total = counts.fold<int>(0, (a, b) => a + b);
    final scores = [
      for (var i = 10; i >= 0; i--)
        if (counts[i] > 0) '${counts[i]} at $i',
    ];
    return 'Rating spread, $total ${total == 1 ? 'rating' : 'ratings'}: ${scores.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final total = counts.fold<int>(0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader('Rating spread', count: total == 0 ? null : total, padding: EdgeInsets.zero),
        if (total == 0 && compactEmpty)
          Text(
            'No ratings yet. Use the bar at the bottom to add yours.',
            style: AppType.bodySmall.copyWith(color: c.textSecondary),
          )
        else if (total == 0)
          const EmptyState(
            icon: Icons.landscape_outlined,
            message: 'No ratings yet. Use the bar at the bottom to add yours.',
          )
        else
          Semantics(
            container: true,
            label: semanticLabel,
            excludeSemantics: true,
            child: SizedBox(
              height: 170,
              child: ClipRect(
                child: CustomPaint(
                  painter: _MountainPainter(
                    counts,
                    shadow: c.mountainShadow,
                    rock: c.mountainLit,
                    snow: c.snowCap,
                    text: c.textSecondary,
                    flag: c.warning,
                    ground: c.lineDecorative,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MountainPainter extends CustomPainter {
  final List<int> counts;
  final Color shadow, rock, snow, text, flag, ground;
  _MountainPainter(
    this.counts, {
    required this.shadow,
    required this.rock,
    required this.snow,
    required this.text,
    required this.flag,
    required this.ground,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const labelSpace = 18.0, top = 34.0; // room for scores below and the flag above
    final base = size.height - labelSpace;
    final step = size.width / 11;
    final maxCount = counts.reduce(max);
    double x(int i) => step * (i + 0.5);

    // Peaks, tallest drawn first so smaller ones sit in front of them.
    final order = [for (var i = 0; i < 11; i++) i]..sort((a, b) => counts[b].compareTo(counts[a]));
    final highest = maxCount == 0 ? -1 : order.first;
    for (final i in order) {
      if (counts[i] == 0) continue;
      final h = (base - top) * counts[i] / maxCount;
      final peak = Offset(x(i), base - h);
      final half = step * 0.55 + h * 0.35; // taller peaks have wider bases
      final shade = 0.35 + 0.65 * counts[i] / maxCount;
      canvas.drawPath(
        Path()
          ..moveTo(peak.dx - half, base)
          ..lineTo(peak.dx, peak.dy)
          ..lineTo(peak.dx + half, base)
          ..close(),
        // Small peaks sit back in shadow; the more ratings, the more light.
        Paint()..color = Color.lerp(shadow, rock, shade)!,
      );
      if (i == highest) {
        // Snow cap: the top quarter, with a jagged lower edge.
        final capH = h * 0.26, capW = half * 0.26;
        final y = peak.dy + capH;
        canvas.drawPath(
          Path()
            ..moveTo(peak.dx, peak.dy)
            ..lineTo(peak.dx + capW, y)
            ..lineTo(peak.dx + capW * 0.45, y - capH * 0.18)
            ..lineTo(peak.dx + capW * 0.1, y + capH * 0.12)
            ..lineTo(peak.dx - capW * 0.35, y - capH * 0.2)
            ..lineTo(peak.dx - capW, y)
            ..close(),
          Paint()..color = snow,
        );
        // Flag on the summit.
        final poleTop = peak.translate(0, -28);
        canvas.drawLine(
          peak,
          poleTop,
          Paint()
            ..color = text
            ..strokeWidth = 1.5,
        );
        canvas.drawPath(
          Path()
            ..moveTo(poleTop.dx, poleTop.dy)
            ..lineTo(poleTop.dx + 16, poleTop.dy + 5)
            ..lineTo(poleTop.dx, poleTop.dy + 10)
            ..close(),
          Paint()..color = flag,
        );
      }
    }

    canvas.drawLine(
      Offset(0, base),
      Offset(size.width, base),
      Paint()
        ..color = ground
        ..strokeWidth = 1,
    );
    for (var i = 0; i <= 10; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: '$i',
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: i == highest ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x(i) - tp.width / 2, base + 3));
    }
  }

  @override
  bool shouldRepaint(_MountainPainter old) =>
      old.counts != counts || old.rock != rock || old.shadow != shadow;
}
