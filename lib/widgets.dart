import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'design/design.dart';
import 'difficulty.dart';
import 'models.dart';

/// Formats a rating without a trailing ".0".
String fmt(double v) => formatScore(v);

/// A picture from the internet. On the phone it's saved after the first load,
/// so it shows instantly next time; [decodeWidth] keeps small pictures small in memory.
///
/// The [placeholder] shows until the picture arrives, then the picture fades
/// in over it (instantly when the system asks for reduced motion).
Widget netImage(
  String url, {
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  int? decodeWidth,
}) => _NetImage(url, placeholder, fit, alignment, decodeWidth);

class _NetImage extends StatelessWidget {
  final String url;
  final Widget placeholder;
  final BoxFit fit;
  final Alignment alignment;
  final int? decodeWidth;
  const _NetImage(this.url, this.placeholder, this.fit, this.alignment, this.decodeWidth);

  @override
  Widget build(BuildContext context) {
    final reveal = AppMotion.coverReveal.resolve(context);
    if (kIsWeb) {
      // The browser keeps its own copy. Fall back to a plain <img> if the cover
      // host blocks cross-origin requests, so covers still show.
      return Stack(
        fit: StackFit.expand,
        children: [
          placeholder,
          Image.network(
            url,
            fit: fit,
            alignment: alignment,
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            frameBuilder: (_, child, frame, wasSynchronouslyLoaded) => wasSynchronouslyLoaded
                ? child
                : AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: reveal.duration,
                    curve: reveal.curve,
                    child: child,
                  ),
          ),
        ],
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      alignment: alignment,
      memCacheWidth: decodeWidth,
      fadeInDuration: reveal.duration,
      fadeInCurve: reveal.curve,
      fadeOutDuration: Duration.zero,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

/// Square album cover with an on-brand placeholder while loading or when missing.
class Cover extends StatelessWidget {
  final Album album;
  final double? size; // null = fill the available width
  final double radius;
  final bool large;
  const Cover({
    super.key,
    required this.album,
    this.size,
    this.radius = AppRadii.cover,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    const placeholder = CoverPlaceholder();
    final url = album.coverUrl(large: large);
    return SizedBox(
      width: size,
      height: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: url.isEmpty
              ? placeholder
              : netImage(url, placeholder: placeholder, decodeWidth: large ? 500 : 250),
        ),
      ),
    );
  }
}

/// Portrait album card: square cover on top, title and artist below.
///
/// Only two things sit on the artwork: the Listen-later bookmark (top right)
/// and the user's rating (bottom right). A position number goes before the
/// title, and a release type other than Studio goes after the artist. The
/// card's height comes from [AlbumCardMetrics], so a grid never clips it.
class AlbumCard extends StatelessWidget {
  final Album album;
  final double? rating;
  final String? caption; // e.g. "Next stop"
  final bool highlight;
  final int? number; // chart position or expedition stop
  final Difficulty? difficulty;
  final bool locked; // greyed out with a lock until the stop before is rated
  final VoidCallback? onTap;

  /// Whether the album is on the listen-later list. Null hides the button.
  final bool? listenLater;
  final VoidCallback? onListenLater;

  const AlbumCard({
    super.key,
    required this.album,
    this.rating,
    this.caption,
    this.highlight = false,
    this.number,
    this.difficulty,
    this.locked = false,
    this.onTap,
    this.listenLater,
    this.onListenLater,
  });

  /// What a screen reader says for the card.
  String get semanticLabel {
    final parts = [
      if (number != null) 'Number $number',
      album.title,
      album.artist,
      if (album.type != null && album.type != 'Studio') album.type!,
      rating == null ? 'not rated' : 'your rating ${formatScore(rating!)} out of 10',
      if (difficulty != null) 'listening stage ${difficulty!.label}',
      if (locked) 'locked until the stop before is rated',
      ?caption,
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final type = album.type != null && album.type != 'Studio' ? album.type : null;
    final title = Text.rich(
      TextSpan(
        children: [
          if (number != null) ...[
            // The title already scales this badge with the text size, so the
            // badge itself must not scale again.
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: MediaQuery.withNoTextScaling(child: RankBadge(number!)),
            ),
            const TextSpan(text: ' '),
          ],
          TextSpan(text: album.title),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppType.cardTitle.copyWith(color: c.textPrimary),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Cover(album: album),
            if (locked)
              Positioned.fill(
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: c.chrome, shape: BoxShape.circle),
                    child: Icon(Icons.lock, size: AppIconSizes.regular, color: c.lockedText),
                  ),
                ),
              ),
            if (rating != null)
              Positioned(
                right: AppSpace.sm - 2,
                bottom: AppSpace.sm - 2,
                child: RatingBadge(rating!),
              ),
          ],
        ),
        const SizedBox(height: AlbumCardMetrics.coverGap),
        ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: AppSpace.xxs),
              Text(
                type == null ? album.artist : '${album.artist} · $type',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodySmall.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
        if (difficulty != null) ...[const SizedBox(height: AppSpace.xs), _StageRow(difficulty!)],
        if (caption != null) ...[
          const SizedBox(height: AppSpace.xxs),
          ExcludeSemantics(
            child: Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.caption.copyWith(color: c.success, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
    return Material(
      color: highlight ? c.surfaceSelected : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Stack(
        children: [
          Semantics(
            button: true,
            label: semanticLabel,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.card),
              onTap: onTap,
              // On phones, press and hold to add to Listen later.
              onLongPress: onListenLater,
              child: Padding(
                padding: EdgeInsets.all(highlight ? AppSpace.sm - 2 : 0),
                // Locked albums stay visible but dimmed, with a lock on the cover.
                child: Opacity(opacity: locked ? 0.45 : 1, child: content),
              ),
            ),
          ),
          if (listenLater != null && !locked)
            Positioned(
              right: highlight ? AppSpace.sm - 2 : 0,
              top: highlight ? AppSpace.sm - 2 : 0,
              child: BookmarkButton(saved: listenLater!, onPressed: onListenLater),
            ),
        ],
      ),
    );
  }
}

/// The small stage tag on a card. Tapping it explains the stage.
class _StageRow extends StatelessWidget {
  final Difficulty difficulty;
  const _StageRow(this.difficulty);

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Semantics(
      button: true,
      label: 'Listening stage ${difficulty.label}. What does this mean?',
      excludeSemantics: true,
      onTap: () => explainDifficulty(context, difficulty),
      child: InkWell(
        onTap: () => explainDifficulty(context, difficulty),
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AlbumCardMetrics.stageRowMin),
          child: Align(
            widthFactor: 1,
            alignment: Alignment.centerLeft,
            child: DifficultyTag(difficulty, small: true),
          ),
        ),
      ),
    ),
  );
}

/// An expedition's picture: its first albums' covers stacked, first on top.
class ExpeditionCover extends StatelessWidget {
  final List<Album?> albums; // in expedition order
  final double size;
  const ExpeditionCover({super.key, required this.albums, this.size = 76});

  @override
  Widget build(BuildContext context) {
    const step = 7.0;
    final shown = albums.take(3).toList();
    final blank = const Album(id: '', title: '', artist: '');
    return SizedBox(
      width: size + step * 2,
      height: size + step * 2,
      child: Stack(
        children: [
          // Draw back to front so the first album ends up on top.
          for (var i = shown.length - 1; i >= 0; i--)
            Positioned(
              left: step * i,
              top: step * (2 - i),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 1.5),
                ),
                child: Cover(album: shown[i] ?? blank, size: size, radius: 6),
              ),
            ),
        ],
      ),
    );
  }
}

/// Wide artist card: one of their covers fills the card, name over the image.
/// Deliberately a different shape from the square album cards.
class ArtistCard extends StatelessWidget {
  final String artist;
  final Album? image; // the album whose cover to use
  final int albumCount;
  final VoidCallback? onTap;
  const ArtistCard({
    super.key,
    required this.artist,
    required this.image,
    required this.albumCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = image?.coverUrl() ?? '';
    return SizedBox(
      width: 220,
      height: 110,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (url.isNotEmpty)
                netImage(
                  url,
                  alignment: const Alignment(0, -0.2),
                  decodeWidth: 250,
                  placeholder: Container(color: theme.colorScheme.surfaceContainerHighest),
                )
              else
                Container(color: theme.colorScheme.surfaceContainerHighest),
              // Dark fade at the bottom so the name is readable on any image.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.35, 1],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$albumCount ${albumCount == 1 ? 'album' : 'albums'}',
                      style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                    ),
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

/// Round artist picture. For now it's the artist's most popular album cover.
class ArtistAvatar extends StatelessWidget {
  final Album? image;
  final double size;
  const ArtistAvatar({super.key, required this.image, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: scheme.surfaceContainerHighest,
      child: Icon(Icons.person, size: size * 0.6, color: scheme.onSurfaceVariant),
    );
    final url = image?.coverUrl() ?? '';
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? placeholder
            : netImage(url, placeholder: placeholder, decodeWidth: 120),
      ),
    );
  }
}
