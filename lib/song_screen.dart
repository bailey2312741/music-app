import 'package:flutter/material.dart';

import 'actions.dart';
import 'chart.dart';
import 'details.dart';
import 'models.dart';
import 'nav.dart';
import 'page_parts.dart';
import 'store.dart';
import 'widgets.dart';

/// A single song. Laid out like the album page, but with a "Song" label, a
/// smaller cover with a note on it, and a link back to its album.
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) => RatingBar(
          saved: store.trackRatingOf(t.id),
          onSave: (v) => store.rateTrack(t, v),
          onClear: () => clearTrackRating(context, store, t),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final saved = store.trackRatingOf(t.id);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 84,
                    child: Stack(
                      children: [
                        Cover(album: a, radius: 42), // round, like a record
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: CircleAvatar(
                            radius: 13,
                            backgroundColor: scheme.primary,
                            child: Icon(Icons.music_note, size: 16, color: scheme.onPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: t.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                ),
                              ),
                              const WidgetSpan(child: SizedBox(width: 8)),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: scheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Song',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onSecondaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () => openAlbum(context, store, a),
                          child: Text(
                            'Track ${t.number} on ${a.title}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.primary,
                              decoration: TextDecoration.underline,
                              decorationColor: scheme.primary,
                            ),
                          ),
                        ),
                        if (t.ms != null)
                          Text(
                            fmtLength(t.ms!),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 6),
                        ArtistButton(store: store, artist: a.artist),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  RatingStats(
                    count: store.trackRatingCount(t.id),
                    yours: saved,
                    average: store.trackAverageOf(t.id),
                  ),
                ],
              ),
              const Divider(height: 32),
              MountainChart(counts: ratingBuckets([?saved])),
              const Divider(height: 32),
              ReviewSection(store: store, subject: 'track:${t.id}'),
            ],
          );
        },
      ),
    );
  }
}
