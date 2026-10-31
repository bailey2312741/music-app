import 'package:flutter/material.dart';

/// Listening difficulty. Shown to users as a word plus an icon only,
/// never as a number, so it can't be confused with the quality rating.
enum Difficulty {
  baseCamp('Base Camp', Icons.cabin),
  foothills('Foothills', Icons.forest),
  highAltitude('High Altitude', Icons.terrain),
  summit('Summit', Icons.flag);

  final String label;
  final IconData icon;
  const Difficulty(this.label, this.icon);
}

/// Shows a difficulty as icon + word. Shows nothing when there is none.
class DifficultyTag extends StatelessWidget {
  final Difficulty? difficulty;
  const DifficultyTag(this.difficulty, {super.key});

  @override
  Widget build(BuildContext context) {
    final d = difficulty;
    if (d == null) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(d.icon, size: 18),
      const SizedBox(width: 4),
      Text(d.label),
    ]);
  }
}
