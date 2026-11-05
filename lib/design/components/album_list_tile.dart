import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/spacing.dart';

/// An album (or song) as a list row: small square cover, title and a second
/// line, optional trailing widget. At least 72 px tall; grows with text size.
class AlbumListTile extends StatelessWidget {
  final Widget cover;
  final String title;
  final String? subtitle;
  final int subtitleLines;
  final Widget? trailing;
  final VoidCallback? onTap;
  const AlbumListTile({
    super.key,
    required this.cover,
    required this.title,
    this.subtitle,
    this.subtitleLines = 1,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
          child: Row(
            children: [
              SizedBox.square(dimension: 56, child: cover),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle.copyWith(color: c.textPrimary),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        subtitle!,
                        maxLines: subtitleLines,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.bodySmall.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: AppSpace.sm), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
