import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/spacing.dart';

/// The compact top of a browse page (artist, genre, chart): the page name in
/// Outfit, an optional picture before it and an optional line of real detail
/// under it. Long names wrap instead of being cut off.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Space around the header; pages that already pad their content pass
  /// their own.
  final EdgeInsetsGeometry padding;
  const PageHeader(
    this.title, {
    super.key,
    this.subtitle,
    this.leading,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpace.gutter,
      AppSpace.xs,
      AppSpace.gutter,
      AppSpace.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: AppType.screenTitle.copyWith(color: c.textPrimary)),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.xs),
          Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.textSecondary)),
        ],
      ],
    );
    return Padding(
      padding: padding,
      child: leading == null
          ? SizedBox(width: double.infinity, child: text)
          : Row(
              children: [
                leading!,
                const SizedBox(width: AppSpace.md),
                Expanded(child: text),
              ],
            ),
    );
  }
}
