import 'package:flutter/material.dart';

import 'actions.dart';
import 'chart.dart';
import 'design/design.dart';
import 'details.dart';
import 'models.dart';
import 'nav.dart';
import 'page_parts.dart';
import 'store.dart';
import 'widgets.dart';

/// A single song: the title first, then its artist, the album it comes from
/// (one tap opens it), your rating, the rating spread and reviews. Rated with
/// the same fixed bar as an album.
class SongScreen extends StatefulWidget {
  final Store store;
  final Album album;
  final Track track;
  const SongScreen({super.key, required this.store, required this.album, required this.track});

  @override
  State<SongScreen> createState() => _SongScreenState();
}

class _SongScreenState extends State<SongScreen> {
  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final t = widget.track;
    final a = widget.album;
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(),
      // The one rating slider: fixed at the bottom while the page scrolls.
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) => RatingBar(
          saved: store.trackRatingOf(t.id),
          onSave: (v) => store.rateTrack(t, v),
          onClear: () => clearTrackRating(context, store, t),
          noun: 'song',
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final saved = store.trackRatingOf(t.id);
          final meta = ['Track ${t.number}', if (t.ms != null) fmtLength(t.ms!)].join(' · ');
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.xs,
              AppSpace.gutter,
              AppSpace.xxl,
            ),
            children: [
              // ---- Header: the song's title leads; the record stands in for
              // song artwork.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: _SongArt(album: a)),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SONG',
                          semanticsLabel: 'Song',
                          style: AppType.label.copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: AppSpace.xxs),
                        Semantics(
                          header: true,
                          child: Text(
                            t.title,
                            style: AppType.screenTitle.copyWith(color: c.textPrimary),
                          ),
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Text(meta, style: AppType.bodySmall.copyWith(color: c.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: ArtistButton(store: store, artist: a.artist),
              ),
              const SizedBox(height: AppSpace.sm),
              // ---- The album it is on: a whole-row link.
              _AlbumLink(album: a, track: t, onTap: () => openAlbum(context, store, a)),
              const SizedBox(height: AppSpace.lg),
              RatingSummary(
                count: store.trackRatingCount(t.id),
                yours: saved,
                average: store.trackAverageOf(t.id),
              ),
              const SizedBox(height: AppSpace.section),
              MountainChart(counts: ratingBuckets([?saved]), compactEmpty: true),
              const SizedBox(height: AppSpace.section),
              ReviewSection(store: store, subject: 'track:${t.id}'),
            ],
          );
        },
      ),
    );
  }
}

/// The album cover shown round, like a record, with a small note on it.
class _SongArt extends StatelessWidget {
  final Album album;
  const _SongArt({required this.album});

  static const _size = 88.0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        children: [
          Cover(album: album, size: _size, radius: _size / 2),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.surfaceSelected,
                shape: BoxShape.circle,
                border: Border.all(color: c.page, width: 2),
              ),
              child: Icon(Icons.music_note, size: AppIconSizes.small, color: c.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// "From the album": small cover, album title and artist, and a chevron. The
/// whole row opens the album.
class _AlbumLink extends StatelessWidget {
  final Album album;
  final Track track;
  final VoidCallback onTap;
  const _AlbumLink({required this.album, required this.track, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      button: true,
      label: 'From the album ${album.title} by ${album.artist}, track ${track.number}. Open album',
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: c.lineDecorative),
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 72),
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.sm),
                child: Row(
                  children: [
                    Cover(album: album, size: 56),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'FROM THE ALBUM',
                            style: AppType.label.copyWith(color: c.textSecondary),
                          ),
                          const SizedBox(height: AppSpace.xxs),
                          Text(
                            album.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.cardTitle.copyWith(color: c.textPrimary),
                          ),
                          Text(
                            album.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySmall.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
