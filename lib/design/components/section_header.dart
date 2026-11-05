import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/spacing.dart';

/// A section title (Outfit 20) on the 16 px gutter, with an optional count and
/// an optional trailing action such as "See all" or a Sort button.
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  const SectionHeader(
    this.title, {
    super.key,
    this.count,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.xs, AppSpace.xs),
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: padding,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
        // Title left, action right; with large text the action drops onto
        // its own line instead of squeezing the title.
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSizes.touchMin),
                child: Align(
                  alignment: Alignment.centerLeft,
                  widthFactor: 1,
                  heightFactor: 1,
                  child: Semantics(
                    header: true,
                    child: Text.rich(
                      TextSpan(
                        text: title,
                        children: [
                          if (count != null)
                            TextSpan(
                              text: '  $count',
                              style: AppType.bodySmall.copyWith(color: c.textTertiary),
                            ),
                        ],
                      ),
                      style: AppType.sectionTitle.copyWith(color: c.textPrimary),
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
