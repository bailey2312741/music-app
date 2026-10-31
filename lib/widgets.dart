import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'models.dart';

/// Formats a rating without a trailing ".0".
String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Square album cover with a placeholder while loading or when missing.
class Cover extends StatelessWidget {
  final Album album;
  final double? size; // null = fill the available width
  final double radius;
  const Cover({super.key, required this.album, this.size, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.album,
        size: (size ?? 100) / 2.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            album.coverUrl,
            fit: BoxFit.cover,
            // On the web, fall back to a plain <img> if the cover host blocks
            // cross-origin requests, so covers still show.
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (_, _, _) => placeholder,
            loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
          ),
        ),
      ),
    );
  }
}

/// Portrait album card: square cover on top, title and artist below.
/// Shows the user's rating as a badge on the cover, or a tick when [done].
class AlbumCard extends StatelessWidget {
  final Album album;
  final double? rating;
  final String? caption; // e.g. "Next stop"
  final bool highlight;
  final int? number; // position in an expedition
  final Difficulty? difficulty;
  final VoidCallback? onTap;

  const AlbumCard({
    super.key,
    required this.album,
    this.rating,
    this.caption,
    this.highlight = false,
    this.number,
    this.difficulty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: highlight ? scheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Cover(album: album),
                  if (number != null)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: _Badge('$number', scheme.surface, scheme.onSurface),
                    ),
                  if (rating != null)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: _Badge(fmt(rating!), scheme.primary, scheme.onPrimary),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                album.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                album.artist,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
              if (difficulty != null) ...[
                const SizedBox(height: 4),
                DifficultyTag(difficulty, small: true),
              ],
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Badge(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: bg.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
    ),
  );
}

/// Grid of album cards, about three across on a phone.
class AlbumGrid extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final bool shrinkWrap;
  const AlbumGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    shrinkWrap: shrinkWrap,
    physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 140,
      childAspectRatio: 0.56,
      crossAxisSpacing: 4,
      mainAxisSpacing: 4,
    ),
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );
}
