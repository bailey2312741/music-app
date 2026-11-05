import 'package:flutter/material.dart';

import 'design/design.dart';

/// Listening difficulty. Shown to users as a word plus an icon only,
/// never as a number, so it can't be confused with the quality rating.
enum Difficulty {
  baseCamp(
    'Base Camp',
    'base_camp',
    'Easy to get into. Familiar song shapes and sounds that reward a first listen.',
  ),
  foothills(
    'Foothills',
    'foothills',
    'Takes a little adjusting: some unusual sounds, length or structure, but an open way in.',
  ),
  highAltitude(
    'High Altitude',
    'high_altitude',
    'Demanding. Unconventional sound or structure that usually needs a few listens.',
  ),
  summit(
    'Summit',
    'summit',
    'The hardest climb. Abrasive, very long or very abstract records for when you are ready.',
  );

  final String label;

  /// Drawing in assets/icons/stages/ (see StageIcon).
  final String icon;
  final String description;
  const Difficulty(this.label, this.icon, this.description);
}

/// Difficulty as a pill: stage drawing + word. Shows nothing when unknown.
class DifficultyTag extends StatelessWidget {
  final Difficulty? difficulty;
  final bool small;
  const DifficultyTag(this.difficulty, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final d = difficulty;
    if (d == null) return const SizedBox.shrink();
    return StageBadge(name: d.icon, label: d.label, small: small);
  }
}

/// Difficulty as a small info square: the detailed stage drawing, with the
/// level name underneath. Tapping it calls [onTap] (the album page then shows
/// what the level means).
class DifficultySquare extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback? onTap;
  const DifficultySquare(this.difficulty, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MergeSemantics(
      child: Semantics(
        button: onTap != null,
        label: 'Listening stage: ${difficulty.label}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Container(
            // 96 wide normally; wider with large text so words never break.
            constraints: const BoxConstraints(minWidth: 96),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm + 2, horizontal: AppSpace.sm),
            decoration: BoxDecoration(
              border: Border.all(color: c.lineFunctional),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Column(
              children: [
                StageIcon(difficulty.icon, size: 44),
                const SizedBox(height: AppSpace.sm - 2),
                ExcludeSemantics(
                  child: Text(
                    difficulty.label.toUpperCase(),
                    style: AppType.label.copyWith(color: c.textPrimary, letterSpacing: 0.4),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows what a difficulty level means as a short line at the bottom of the screen.
void explainDifficulty(BuildContext context, Difficulty d) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(content: Text('${d.label}: ${d.description}'), duration: const Duration(seconds: 4)),
  );
}
