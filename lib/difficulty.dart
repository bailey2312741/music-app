import 'package:flutter/material.dart';

/// Listening difficulty. Shown to users as a word plus an icon only,
/// never as a number, so it can't be confused with the quality rating.
enum Difficulty {
  baseCamp(
    'Base Camp',
    Icons.cabin,
    'Easy to get into. Familiar song shapes and sounds that reward a first listen.',
  ),
  foothills(
    'Foothills',
    Icons.park,
    'Takes a little adjusting: some unusual sounds, length or structure, but an open way in.',
  ),
  highAltitude(
    'High Altitude',
    Icons.terrain,
    'Demanding. Unconventional sound or structure that usually needs a few listens.',
  ),
  summit(
    'Summit',
    Icons.flag,
    'The hardest climb. Abrasive, very long or very abstract records for when you are ready.',
  );

  final String label;
  final IconData icon;
  final String description;
  const Difficulty(this.label, this.icon, this.description);
}

/// Difficulty as a small outlined pill: icon + word. Shows nothing when unknown.
class DifficultyTag extends StatelessWidget {
  final Difficulty? difficulty;
  final bool small;
  const DifficultyTag(this.difficulty, {super.key, this.small = false});

  @override
  Widget build(BuildContext context) {
    final d = difficulty;
    if (d == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final style =
        (small ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelLarge)
            ?.copyWith(color: scheme.onSurfaceVariant);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 6 : 10, vertical: small ? 2 : 4),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(d.icon, size: small ? 12 : 16, color: scheme.onSurfaceVariant),
          SizedBox(width: small ? 3 : 5),
          Flexible(
            child: Text(d.label, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

/// Difficulty as a small info square: the symbol, with the level name underneath.
/// Tapping it calls [onTap] (the album page then shows what the level means).
class DifficultySquare extends StatelessWidget {
  final Difficulty difficulty;
  final VoidCallback? onTap;
  const DifficultySquare(this.difficulty, {super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 96,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(difficulty.icon, size: 26, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(difficulty.label, style: theme.textTheme.labelMedium, textAlign: TextAlign.center),
          ],
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
