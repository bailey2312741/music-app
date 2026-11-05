import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';

/// What a cover shows while loading or when there is no artwork: a recessed
/// green square with a simple record drawn in quiet lines.
class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ColoredBox(
      color: c.surfaceSunken,
      child: CustomPaint(
        painter: _RecordPainter(grooves: c.lineDecorative, label: c.surfaceSelected),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RecordPainter extends CustomPainter {
  final Color grooves, label;
  const _RecordPainter({required this.grooves, required this.label});

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = math.min(size.width, size.height) * 0.3;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = grooves
      ..strokeWidth = math.max(1, r * 0.045);
    canvas.drawCircle(centre, r, line);
    canvas.drawCircle(centre, r * 0.72, line);
    canvas.drawCircle(centre, r * 0.36, Paint()..color = label);
    canvas.drawCircle(centre, math.max(1, r * 0.07), Paint()..color = grooves);
  }

  @override
  bool shouldRepaint(_RecordPainter old) => old.grooves != grooves || old.label != label;
}
