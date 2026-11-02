import 'package:flutter/material.dart';

import 'actions.dart';
import 'catalogue.dart';
import 'chart.dart';
import 'details.dart';
import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'page_parts.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

class AlbumScreen extends StatefulWidget {
  final Store store;
  final Album album;

  /// Set when opened from an expedition, so the rating bar can offer the next stop.
  final String? expeditionId;
  const AlbumScreen({super.key, required this.store, required this.album, this.expeditionId});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late final Album _album = Catalogue.byId(widget.album.id) ?? widget.album;
  AlbumDetails? _details;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _details = DetailsLoader.cached(_album.id);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _details == null;
      _failed = false;
    });
    try {
      final d = await DetailsLoader.load(_album);
      if (mounted) setState(() => _details = d);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final a = _album;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tracks = _details?.tracks ?? const <Track>[];

    return Scaffold(
      appBar: AppBar(),
      // The rating bar stays at the bottom while the page scrolls.
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) => RatingBar(
          saved: store.ratingOf(a.id),
          onSave: (v) => store.rate(a, v),
          onClear: () => clearRating(context, store, a),
          next: _nextButton(context),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final saved = store.ratingOf(a.id);
          final difficulty = difficultyOf(store, a.id);
          final type = (a.type == null || a.type == 'Studio') ? 'Album' : a.type!;
          final n = tracks.isNotEmpty ? tracks.length : a.trackCount;
          final kind = [type, if (n != null) '$n ${n == 1 ? 'track' : 'tracks'}'].join(' · ');
          final total = _details?.totalMs;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // Cover on the left, details beside it, ratings on the right.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 116, child: Cover(album: a, radius: 10)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          kind,
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
                    count: store.ratingCount(a.id),
                    yours: saved,
                    average: store.averageOf(a.id),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Difficulty, then the main genre larger with subgenres smaller.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (difficulty != null) ...[
                    DifficultySquare(
                      difficulty,
                      onTap: () => explainDifficulty(context, difficulty),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (a.genre != null)
                          Chip(label: Text(a.genre!, style: theme.textTheme.titleSmall)),
                        for (final t in a.subgenres)
                          Chip(
                            label: Text(t, style: theme.textTheme.labelSmall),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => toggleListenLater(context, store, a),
                    icon: Icon(
                      store.isListenLater(a.id) ? Icons.bookmark : Icons.bookmark_add_outlined,
                    ),
                    label: Text(store.isListenLater(a.id) ? 'Saved for later' : 'Listen later'),
                  ),
                  TextButton.icon(
                    onPressed: () => pinToRange(context, store, a),
                    icon: Icon(store.isPinned(a.id) ? Icons.landscape : Icons.landscape_outlined),
                    label: Text(store.isPinned(a.id) ? 'In Your Range' : 'Add to Your Range'),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text('Tracklist', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_failed)
                Row(
                  children: [
                    const Expanded(child: Text("Couldn't load the tracklist.")),
                    TextButton(onPressed: _load, child: const Text('Try again')),
                  ],
                )
              else if (tracks.isEmpty)
                Text('No tracklist for this album yet.', style: theme.textTheme.bodySmall)
              else
                for (final t in tracks) _TrackRow(store: store, album: a, track: t),
              const Divider(height: 32),
              MountainChart(counts: ratingBuckets([?saved])),
              const Divider(height: 32),
              _Fact('Release date', switch (a.date ?? _details?.date) {
                final d? => fmtDate(d),
                null => a.year,
              }),
              _Fact('Duration', total == null ? null : fmtDuration(total)),
              _Fact('Record label', _details?.label),
              const Divider(height: 32),
              ReviewSection(store: store, subject: 'album:${a.id}'),
            ],
          );
        },
      ),
    );
  }
}

extension on _AlbumScreenState {
  /// After rating an expedition album: a shortcut to the next stop.
  Widget? _nextButton(BuildContext context) {
    final id = widget.expeditionId;
    if (id == null) return null;
    final e = allExpeditions(widget.store).where((x) => x.id == id).firstOrNull;
    if (e == null) return null;
    final here = e.stops.where((s) => albumFor(widget.store, s)?.id == _album.id).firstOrNull;
    if (here == null || !isDone(widget.store, e, here)) return null;
    final i = nextStop(widget.store, e);
    final next = i == null ? null : albumFor(widget.store, e.stops[i]);
    if (next == null || next.id == _album.id) return null;
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        style: TextButton.styleFrom(minimumSize: const Size(44, 44)),
        onPressed: () => replaceWithAlbum(context, next, id),
        icon: const Icon(Icons.arrow_forward),
        label: Text('Next: ${next.title}', overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Store store;
  final Album album;
  final Track track;
  const _TrackRow({required this.store, required this.album, required this.track});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mine = store.trackRatingOf(track.id);
    final avg = store.trackAverageOf(track.id);
    final sub = [
      if (track.ms != null) fmtLength(track.ms!),
      'avg ${avg == null ? '–' : fmt(avg)}',
    ].join(' · ');
    final row = InkWell(
      onTap: () => openSong(context, store, album, track),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                track.number,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(track.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(
                    sub,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Tap to rate the track right from the list.
            mine == null
                ? OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(56, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _rate(context),
                    child: const Text('Rate'),
                  )
                : FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(56, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onPressed: () => _rate(context),
                    child: Text(fmt(mine), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
          ],
        ),
      ),
    );
    if (mine == null) return row;
    // Swipe a rated track sideways to clear its rating.
    return Dismissible(
      key: ValueKey('track-${track.id}'),
      confirmDismiss: (_) async {
        clearTrackRating(context, store, track);
        return false;
      },
      background: Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: const Text('Clear rating'),
      ),
      child: row,
    );
  }

  void _rate(BuildContext context) => showRatingSheet(
    context,
    title: track.title,
    current: store.trackRatingOf(track.id),
    onSave: (v) => store.rateTrack(track, v),
  );
}

class _Fact extends StatelessWidget {
  final String label;
  final String? value;
  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value ?? 'Unknown', style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
