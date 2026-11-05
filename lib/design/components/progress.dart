import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/spacing.dart';

/// Expedition progress: one equal segment per stop, rated stops filled mint.
class SegmentedProgress extends StatelessWidget {
  final int done;
  final int total;
  final String? semanticLabel;
  const SegmentedProgress({super.key, required this.done, required this.total, this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: semanticLabel ?? '$done of $total albums rated',
      excludeSemantics: true,
      child: SizedBox(
        height: AppSizes.progressTrackHeight,
        child: Row(
          // Stretch, or the empty segments get no height and the bar vanishes.
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < total; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: i < done ? c.progressFill : c.progressTrack,
                    borderRadius: BorderRadius.circular(AppSizes.progressTrackHeight / 2),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
