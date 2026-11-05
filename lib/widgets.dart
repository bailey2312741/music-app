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
  final String? caption; // e.g. "Final stop"

  /// Read out by screen readers only, for a label drawn elsewhere.
  final String? semanticNote;
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
    this.semanticNote,
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
      ?semanticNote,
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
            CoverHero(
              albumId: album.id,
              source: context,
              child: Cover(album: album),
            ),
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
              onTap: onTap == null
                  ? null
                  : () {
                      CoverHero.claim(context);
                      onTap!();
                    },
              // On phones, press and hold to add to Listen later.
              onLongPress: onListenLater,
              child: Padding(
                padding: EdgeInsets.all(highlight ? AppSpace.sm - 2 : 0),
                // Locked albums stay visible but dimmed, with a lock on the cover.
                // A stop that unlocks brightens over 180 ms.
                child: AnimatedOpacity(
                  opacity: locked ? 0.45 : 1,
                  duration: AppMotion.fade.resolve(context).duration,
                  curve: AppMotion.fade.curve,
                  child: content,
                ),
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

/// Artist card: a round picture with the name and album count underneath.
/// Round, so artists read differently from the square album cards.
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

  static const picture = AppCoverSizes.md;

  /// Card width: wider with large text so names wrap between words.
  static double widthFor(TextScaler scaler) => scaler.scale(10) >= 15 ? AppCoverSizes.lg : picture;

  /// Height of a card at this text size: picture, two name lines, count line.
  static double heightFor(TextScaler scaler) {
    double line(double size, double height) => scaler.scale(size) / size * height;
    return picture + AppSpace.sm + 2 * line(15, 20) + AppSpace.xxs + line(13, 19) + AppSpace.xs;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final albums = '$albumCount ${albumCount == 1 ? 'album' : 'albums'}';
    return SizedBox(
      width: widthFor(MediaQuery.textScalerOf(context)),
      child: Semantics(
        button: true,
        label: '$artist, $albums',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Column(
            children: [
              ArtistAvatar(image: image, size: picture),
              const SizedBox(height: AppSpace.sm),
              Text(
                artist,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppType.cardTitle.copyWith(color: c.textPrimary),
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                albums,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.bodySmall.copyWith(color: c.textSecondary),
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
            : netImage(url, placeholder: placeholder, decodeWidth: size > 60 ? 250 : 120),
      ),
    );
  }
}
