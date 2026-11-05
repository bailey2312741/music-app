import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

/// Formats a score: whole numbers without ".0" (9), halves with one place (9.5).
String formatScore(double v) =>
    v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// The user's rating as a small cream chip on a cover. Purely visual: the
/// card it sits on reads the rating out and handles taps.
class RatingBadge extends StatelessWidget {
  final double rating;
  const RatingBadge(this.rating, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minWidth: 24),
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm - 2, vertical: AppSpace.xxs),
          decoration: ShapeDecoration(color: c.primaryButtonFill, shape: const StadiumBorder()),
          child: Text(
            formatScore(rating),
            textAlign: TextAlign.center,
            style: AppType.scoreSmall.copyWith(color: c.primaryButtonText),
          ),
        ),
      ),
    );
  }
}

/// A position number (chart rank, expedition stop) shown before a title,
/// outside the artwork.
class RankBadge extends StatelessWidget {
  final int rank;
  const RankBadge(this.rank, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ExcludeSemantics(
      child: Container(
        constraints: const BoxConstraints(minWidth: 20),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs + 1),
        decoration: BoxDecoration(
          color: c.surfaceSelected,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: Text(
          '$rank',
          textAlign: TextAlign.center,
          style: AppType.scoreSmall.copyWith(color: c.textPrimary, height: 18 / 12),
        ),
      ),
    );
  }
}

/// The Listen-later bookmark on a cover: a 20 px icon on a small dark disc,
/// inside a 48 × 48 tap area in the top-right corner.
class BookmarkButton extends StatelessWidget {
  final bool saved;
  final VoidCallback? onPressed;
  const BookmarkButton({super.key, required this.saved, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      toggled: saved,
      label: 'Listen later',
      excludeSemantics: true,
      onTap: onPressed,
      child: InkResponse(
        onTap: onPressed,
        radius: 20,
        child: SizedBox.square(
          dimension: AppSizes.touchMin,
          child: Center(
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: c.chrome.withValues(alpha: 0.88),
                shape: BoxShape.circle,
              ),
              // The icon swaps with a quick scale, so the change is seen.
              child: AnimatedSwitcher(
                duration: AppMotion.press.resolve(context).duration,
                switchInCurve: AppMotion.press.curve,
                transitionBuilder: (child, a) => ScaleTransition(
                  scale: Tween(begin: 0.7, end: 1.0).animate(a),
                  child: FadeTransition(opacity: a, child: child),
                ),
                child: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                  key: ValueKey(saved),
                  size: AppIconSizes.regular,
                  color: c.bookmarkActive,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
