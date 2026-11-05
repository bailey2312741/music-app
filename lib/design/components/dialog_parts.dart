import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_type.dart';
import '../tokens/spacing.dart';

/// One choice in a list dialog (report reasons, which Range slot to replace):
/// at least 48 tall, full width, with an optional picture and second line.
class DialogChoice extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;
  const DialogChoice({
    super.key,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: leading == null ? AppSizes.touchMin : 64),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.sm),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AppSpace.md)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppType.body.copyWith(color: c.textPrimary)),
                    if (subtitle != null)
                      Text(subtitle!, style: AppType.bodySmall.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The secondary "Cancel" at the end of a list dialog, right-aligned like the
/// actions of every other dialog.
class DialogCancel extends StatelessWidget {
  const DialogCancel({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.sm, AppSpace.lg, 0),
    child: Align(
      alignment: Alignment.centerRight,
      child: TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
    ),
  );
}
