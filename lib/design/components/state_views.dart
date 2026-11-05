import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/spacing.dart';

/// Static low-contrast bars standing in for rows that are still loading.
/// No shimmer; screen readers hear "Loading".
class LoadingPlaceholder extends StatelessWidget {
  final int rows;
  final String label;
  const LoadingPlaceholder({super.key, this.rows = 4, this.label = 'Loading'});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget bar(double widthFactor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
      ),
    );
    return Semantics(
      label: label,
      liveRegion: true,
      excludeSemantics: true,
      child: Column(
        children: [
          for (var i = 0; i < rows; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
              child: bar(i.isEven ? 0.7 : 0.5),
            ),
        ],
      ),
    );
  }
}

/// A short message for an empty list, with an optional pictogram and action.
class EmptyState extends StatelessWidget {
  final IconData? icon;
  final String message;
  final String? title;
  final Widget? action;
  const EmptyState({super.key, required this.message, this.icon, this.title, this.action});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl, vertical: AppSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppIconSizes.large, color: c.textTertiary),
            const SizedBox(height: AppSpace.md),
          ],
          if (title != null) ...[
            Text(
              title!,
              textAlign: TextAlign.center,
              style: AppType.cardTitle.copyWith(color: c.textPrimary),
            ),
            const SizedBox(height: AppSpace.xs),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppType.body.copyWith(color: c.textSecondary),
          ),
          if (action != null) ...[const SizedBox(height: AppSpace.lg), action!],
        ],
      ),
    );
  }
}

/// Something failed: an error icon, what went wrong and a one-tap retry.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Icon(Icons.error_outline, size: AppIconSizes.regular, color: c.error),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(message, style: AppType.body.copyWith(color: c.textPrimary)),
        ),
        if (onRetry != null) TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
