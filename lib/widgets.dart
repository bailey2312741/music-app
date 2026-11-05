import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'models.dart';

/// Formats a rating without a trailing ".0".
String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// A picture from the internet. On the phone it's saved after the first load,
/// so it shows instantly next time; [decodeWidth] keeps small pictures small in memory.
Widget netImage(
  String url, {
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
  Alignment alignment = Alignment.center,
  int? decodeWidth,
}) {
  if (kIsWeb) {
    // The browser keeps its own copy. Fall back to a plain <img> if the cover
    // host blocks cross-origin requests, so covers still show.
    return Image.network(
      url,
      fit: fit,
      alignment: alignment,
      webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    );
  }
  return CachedNetworkImage(
    imageUrl: url,
    fit: fit,
    alignment: alignment,
    memCacheWidth: decodeWidth,
    fadeInDuration: Duration.zero,
    fadeOutDuration: Duration.zero,
    placeholder: (_, _) => placeholder,
    errorWidget: (_, _, _) => placeholder,
  );
}

/// Square album cover with a placeholder while loading or when missing.
class Cover extends StatelessWidget {
  final Album album;
  final double? size; // null = fill the available width
  final double radius;
  final bool large;
  const Cover({super.key, required this.album, this.size, this.radius = 8, this.large = false});

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
          child: album.coverUrl(large: large).isEmpty
              ? placeholder
              : netImage(
                  album.coverUrl(large: large),
                  placeholder: placeholder,
                  decodeWidth: large ? 500 : 250,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return _Hover(
      builder: (context, hovered) => Material(
        color: highlight ? scheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          // On phones (no hover), press and hold to add to Listen later.
          onLongPress: onListenLater,
          child: Padding(
            padding: const EdgeInsets.all(6),
            // Locked albums stay visible but greyed out, with a lock on the cover.
            child: Opacity(
              opacity: locked ? 0.4 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Cover(album: album),
                      if (locked)
                        const Positioned.fill(child: Center(child: Icon(Icons.lock, size: 30))),
                      if (number != null)
                        Positioned(
                          left: 6,
                          top: 6,
                          child: _Badge('$number', scheme.surface, scheme.onSurface),
                        ),
                      // Anything other than a studio album says what it is (EP, Live...).
                      if (album.type != null && album.type != 'Studio')
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: _Badge(album.type!, scheme.surface, scheme.onSurface, small: true),
                        ),
                      if (rating != null)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: _Badge(fmt(rating!), scheme.primary, scheme.onPrimary),
                        ),
                      // Listen-later bookmark on every card. The visible circle is
                      // small, but the tap area is 44 px.
                      if (listenLater != null && !locked)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Semantics(
                            button: true,
                            label: listenLater! ? 'Remove from Listen later' : 'Listen later',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: onListenLater,
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: scheme.surface.withValues(
                                        alpha: hovered || listenLater! ? 0.92 : 0.75,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      listenLater! ? Icons.bookmark : Icons.bookmark_add_outlined,
                                      size: 18,
                                      color: scheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
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
                    GestureDetector(
                      onTap: () => explainDifficulty(context, difficulty!),
                      child: DifficultyTag(difficulty, small: true),
                    ),
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
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final bool small;
  const _Badge(this.text, this.bg, this.fg, {this.small = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: small ? 5 : 7, vertical: small ? 2 : 3),
    decoration: BoxDecoration(
      color: bg.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      text,
      style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: small ? 10 : 12),
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
    gridDelegate: albumGridDelegate,
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );
}

/// Shared layout for album grids: about three cards across on a phone.
const albumGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 140,
  // A little taller than v0.8 (0.56) so the brand fonts fit with a difficulty tag.
  childAspectRatio: 0.53,
  crossAxisSpacing: 4,
  mainAxisSpacing: 4,
);

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

/// Rebuilds its child with whether the mouse is over it (always false on touch).
class _Hover extends StatefulWidget {
  final Widget Function(BuildContext, bool hovered) builder;
  const _Hover({required this.builder});

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: widget.builder(context, _hovered),
  );
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
