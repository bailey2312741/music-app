import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/spacing.dart';

/// One of the four listening-stage drawings in assets/icons/stages/.
///
/// [name] is the file stem, e.g. `base_camp`. At 40 px and up the detailed
/// version is used, below that the simplified one. The drawing is decorative:
/// put the stage name in text next to it (or pass [semanticLabel]).
class StageIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final String? semanticLabel;
  const StageIcon(
    this.name, {
    super.key,
    this.size = AppIconSizes.standard,
    this.color,
    this.semanticLabel,
  });

  /// Sizes at or above this use the detailed drawing.
  static const largeFrom = 40.0;

  static String asset(String name, {required bool large}) =>
      'assets/icons/stages/${name}_${large ? 'large' : 'compact'}.svg';

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    asset(name, large: size >= largeFrom),
    width: size,
    height: size,
    colorFilter: ColorFilter.mode(color ?? AppColors.of(context).textPrimary, BlendMode.srcIn),
    semanticsLabel: semanticLabel,
    excludeFromSemantics: semanticLabel == null,
  );
}

/// A listening stage as a pill: compact drawing + stage name.
///
/// With [onTap] the pill is a button whose tap area is at least 48 px tall,
/// even though the visible pill is smaller.
class StageBadge extends StatelessWidget {
  final String name; // asset stem
  final String label; // "High Altitude"
  final bool small;
  final VoidCallback? onTap;
  const StageBadge({
    super.key,
    required this.name,
    required this.label,
    this.small = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final iconSize = small ? AppIconSizes.small : AppIconSizes.regular;
    final text = small
        ? AppType.caption.copyWith(fontWeight: FontWeight.w600, color: c.textSecondary)
        : AppType.label.copyWith(color: c.textPrimary);
    final pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? AppSpace.xs : AppSpace.md,
        vertical: small ? AppSpace.xxs : AppSpace.xs,
      ),
      decoration: ShapeDecoration(
        shape: StadiumBorder(side: BorderSide(color: small ? c.lineDecorative : c.lineFunctional)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StageIcon(name, size: iconSize, color: small ? c.textSecondary : c.textPrimary),
          SizedBox(width: small ? AppSpace.xs - 1 : AppSpace.sm - 2),
          Flexible(
            child: Text(
              small ? label : label.toUpperCase(),
              style: text,
              overflow: TextOverflow.ellipsis,
              semanticsLabel: 'Listening stage: $label',
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
          child: Align(widthFactor: 1, child: pill),
        ),
      ),
    );
  }
}
