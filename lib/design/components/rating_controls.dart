import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import 'badges.dart';

/// A score in the score type: "–" when unrated (not the same as 0), "9", "9.5".
class ScoreText extends StatelessWidget {
  final double? value;
  final double scale; // 1 = the 24 px rating-bar size
  const ScoreText(this.value, {super.key, this.scale = 1});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final v = value;
    return Text(
      v == null ? '–' : formatScore(v),
      style: AppType.score.copyWith(
        fontSize: AppType.score.fontSize! * scale,
        color: v == null ? c.textTertiary : c.textPrimary,
      ),
    );
  }
}

/// The 0 to 10 half-step slider used for albums, songs and expeditions.
///
/// Unrated ([value] null): a neutral grey-green track with the thumb parked at
/// the left, and the first touch picks a value. Saving happens in
/// [onChangeEnd], when the finger lifts.
class RatingSlider extends StatelessWidget {
  final double? value;
  final String noun; // "album", "song", "expedition"
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  const RatingSlider({
    super.key,
    required this.value,
    required this.noun,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final unrated = value == null;
    final theme = SliderTheme.of(context);
    return SliderTheme(
      data: unrated
          ? theme.copyWith(
              activeTrackColor: c.lineDecorative,
              inactiveTrackColor: c.lineDecorative,
              thumbColor: c.lineFunctional,
            )
          : theme,
      child: Semantics(
        label: 'Your $noun rating, 0 to 10 in steps of 0.5',
        child: Slider(
          value: value ?? 0,
          min: 0,
          max: 10,
          divisions: 20,
          label: unrated ? null : formatScore(value!),
          semanticFormatterCallback: (v) => unrated ? 'Not rated' : '${formatScore(v)} out of 10',
          onChangeStart: onChangeStart,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ),
    );
  }
}
