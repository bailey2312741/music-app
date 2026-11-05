import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/motion.dart';
import '../tokens/spacing.dart';

/// A text-only genre pill. Width follows the name; the tap area is at least
/// 48 px tall. Selected genres are filled cream with dark text.
///
/// States: default (outlined), pressed (tonal), selected (filled),
/// disabled (dimmed, when [onPressed] is null) and keyboard focus (2 px ring).
class GenreButton extends StatefulWidget {
  final String genre;
  final bool selected;
  final VoidCallback? onPressed;
  const GenreButton(this.genre, {super.key, this.selected = false, this.onPressed});

  @override
  State<GenreButton> createState() => _GenreButtonState();
}

class _GenreButtonState extends State<GenreButton> {
  bool _focused = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = widget.onPressed != null;
    final selected = widget.selected;
    final fill = selected
        ? (enabled ? c.primaryButtonFill : c.surfaceSelected)
        : _pressed
        ? c.surfaceSelected
        : Colors.transparent;
    final ink = selected
        ? (enabled ? c.primaryButtonText : c.disabledForeground)
        : enabled
        ? c.textPrimary
        : c.disabledForeground;
    final edge = !enabled
        ? c.lineDecorative
        : selected
        ? c.primaryButtonFill
        : c.lineFunctional;
    final fade = AppMotion.press.resolve(context);

    // The pill shows the name in capitals; screen readers get it as written.
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: widget.genre,
        child: InkWell(
          onTap: widget.onPressed,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          onFocusChange: (v) => setState(() => _focused = v),
          customBorder: const StadiumBorder(),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
            child: Align(
              widthFactor: 1,
              // Focus ring: 2 px cream line with a 2 px gap around the pill.
              child: AnimatedContainer(
                duration: fade.duration,
                curve: fade.curve,
                padding: const EdgeInsets.all(AppSizes.indicatorBorderWidth),
                decoration: ShapeDecoration(
                  shape: StadiumBorder(
                    side: BorderSide(
                      color: _focused ? c.focusRing : Colors.transparent,
                      width: AppSizes.indicatorBorderWidth,
                    ),
                  ),
                ),
                child: AnimatedContainer(
                  duration: fade.duration,
                  curve: fade.curve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.lg,
                    vertical: AppSpace.sm - 1,
                  ),
                  decoration: ShapeDecoration(
                    color: fill,
                    shape: StadiumBorder(side: BorderSide(color: edge)),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      widget.genre.toUpperCase(),
                      style: AppType.label.copyWith(color: ink),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
