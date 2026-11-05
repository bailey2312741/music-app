import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'actions.dart';
import 'catalogue.dart';
import 'chart.dart';
import 'design/design.dart';
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
    final c = AppColors.of(context);
    final tracks = _details?.tracks ?? const <Track>[];

    return Scaffold(
      appBar: AppBar(),
      // The one rating slider: fixed at the bottom while the page scrolls.
      bottomNavigationBar: ListenableBuilder(
        listenable: store,
        builder: (context, _) => RatingBar(
          saved: store.ratingOf(a.id),
          noun: 'album',
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
          final total = _details?.totalMs;
          final year = a.year ?? (a.date ?? _details?.date)?.split('-').first;
          final meta = [
            type,
            ?year,
            if (n != null) '$n ${n == 1 ? 'track' : 'tracks'}',
            if (total != null) _minutes(total),
          ].join(' · ');

          return LayoutBuilder(
            builder: (context, box) {
              final cover = math.min(
                (0.56 * box.maxWidth).clamp(200.0, 220.0),
                box.maxWidth - 2 * AppSpace.gutter,
              );
              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  AppSpace.xs,
                  AppSpace.gutter,
                  AppSpace.xxl,
                ),
                children: [
                  // ---- Header: cover, title, artist, details, stage.
                  Center(
                    child: Semantics(
                      container: true,
                      image: true,
                      label: 'Cover of ${a.title}',
                      child: Cover(album: a, size: cover, large: true),
                    ),
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Semantics(
                    header: true,
                    child: Text(
                      a.title,
                      textAlign: TextAlign.center,
                      style: AppType.screenTitle.copyWith(color: c.textPrimary),
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxs),
                  Center(
                    child: ArtistButton(store: store, artist: a.artist),
                  ),
                  Text(
                    meta,
                    textAlign: TextAlign.center,
                    style: AppType.bodySmall.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Center(
                    child: difficulty == null
                        ? const _StageNotAssigned()
                        : StageBadge(
                            name: difficulty.icon,
                            label: difficulty.label,
                            onTap: () => explainDifficulty(context, difficulty),
                          ),
                  ),
                  const SizedBox(height: AppSpace.md),
                  // ---- Listen later and Your Range.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _ToggleAction(
                          on: store.isListenLater(a.id),
                          onIcon: Icons.bookmark,
                          offIcon: Icons.bookmark_add_outlined,
                          onLabel: 'Saved for later',
                          offLabel: 'Listen later',
                          onPressed: () => toggleListenLater(context, store, a),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: _ToggleAction(
                          on: store.isPinned(a.id),
                          onIcon: Icons.landscape,
                          offIcon: Icons.landscape_outlined,
                          onLabel: 'In Your Range',
                          offLabel: 'Add to Your Range',
                          onPressed: () => pinToRange(context, store, a),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                  // ---- Ratings and genres, quieter than the header.
                  _AlbumStats(
                    count: store.ratingCount(a.id),
                    yours: saved,
                    average: store.averageOf(a.id),
                  ),
                  if (a.genre != null || a.subgenres.isNotEmpty) ...[
                    const SizedBox(height: AppSpace.md),
                    _Genres(main: a.genre, subgenres: a.subgenres),
                  ],
                  // ---- Tracklist.
                  const SizedBox(height: AppSpace.section),
                  SectionHeader(
                    'Tracklist',
                    count: tracks.isEmpty ? null : tracks.length,
                    padding: EdgeInsets.zero,
                  ),
                  if (_loading)
                    const LoadingPlaceholder(rows: 5, label: 'Loading the tracklist')
                  else if (_failed)
                    ErrorState(message: "Couldn't load the tracklist.", onRetry: _load)
                  else if (tracks.isEmpty)
                    Text(
                      'No tracklist for this album yet.',
                      style: AppType.bodySmall.copyWith(color: c.textSecondary),
                    )
                  else
                    for (final t in tracks) _TrackRow(store: store, album: a, track: t),
                  // ---- Rating spread, album info, reviews.
                  const SizedBox(height: AppSpace.section),
                  MountainChart(counts: ratingBuckets([?saved])),
                  const SizedBox(height: AppSpace.section),
                  const SectionHeader('Album info', padding: EdgeInsets.zero),
                  _Fact('Release date', switch (a.date ?? _details?.date) {
                    final d? => fmtDate(d),
                    null => a.year,
                  }),
                  _Fact('Duration', total == null ? null : fmtDuration(total)),
                  _Fact('Record label', _details?.label),
                  const SizedBox(height: AppSpace.section),
                  ReviewSection(store: store, subject: 'album:${a.id}'),
                ],
              );
            },
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
        style: TextButton.styleFrom(minimumSize: const Size(AppSizes.touchMin, AppSizes.touchMin)),
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
    final c = AppColors.of(context);
    final mine = store.trackRatingOf(track.id);
    final avg = store.trackAverageOf(track.id);
    final sub = [
      if (track.ms != null) fmtLength(track.ms!),
      'avg ${avg == null ? '–' : formatScore(avg)}',
    ].join(' · ');
    final row = InkWell(
      onTap: () => openSong(context, store, album, track),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
        child: Row(
          children: [
            // Track number as printed on the release ("3", or "A1" for side A).
            ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.textScalerOf(context).scale(32)),
              child: Text(
                track.number,
                style: AppType.bodySmall.copyWith(
                  color: c.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.body.copyWith(color: c.textPrimary),
                  ),
                  Text(sub, style: AppType.caption.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            // One tap opens the rating sheet. Quiet text until rated.
            _TrackRateButton(title: track.title, rating: mine, onPressed: () => _rate(context)),
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
        color: c.surfaceRaised,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        child: Text('Clear rating', style: AppType.body.copyWith(color: c.textPrimary)),
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

/// The per-track rating control: a quiet "Rate" when unrated, the score in a
/// small tonal pill once rated. Always a 48 × 48 tap area.
class _TrackRateButton extends StatelessWidget {
  final String title;
  final double? rating;
  final VoidCallback onPressed;
  const _TrackRateButton({required this.title, required this.rating, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final r = rating;
    return Semantics(
      container: true,
      button: true,
      label: r == null ? 'Rate $title' : 'Your rating for $title: ${formatScore(r)}. Change',
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        customBorder: const StadiumBorder(),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.touchMin,
            minHeight: AppSizes.touchMin,
          ),
          child: Center(
            widthFactor: 1,
            child: r == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                    child: Text('Rate', style: AppType.label.copyWith(color: c.textSecondary)),
                  )
                : Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.sm,
                      vertical: AppSpace.xxs,
                    ),
                    decoration: ShapeDecoration(
                      color: c.surfaceSelected,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      formatScore(r),
                      textAlign: TextAlign.center,
                      style: AppType.scoreSmall.copyWith(color: c.textPrimary, fontSize: 13),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Listen later / Your Range: outlined when off, filled tonal with a filled
/// icon and changed wording when on.
class _ToggleAction extends StatelessWidget {
  final bool on;
  final IconData onIcon, offIcon;
  final String onLabel, offLabel;
  final VoidCallback onPressed;
  const _ToggleAction({
    required this.on,
    required this.onIcon,
    required this.offIcon,
    required this.onLabel,
    required this.offLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return MergeSemantics(
      child: Semantics(
        toggled: on,
        child: OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            backgroundColor: on ? c.surfaceSelected : Colors.transparent,
            side: BorderSide(color: on ? c.surfaceSelected : c.secondaryButtonBorder),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
          ),
          onPressed: onPressed,
          icon: Icon(on ? onIcon : offIcon, size: AppIconSizes.regular),
          label: Text(on ? onLabel : offLabel, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

/// Number of ratings, yours and the average in one quiet row.
class _AlbumStats extends StatelessWidget {
  final int count;
  final double? yours, average;
  const _AlbumStats({required this.count, this.yours, this.average});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget cell(String value, String label, String spoken, {bool empty = false}) => Expanded(
      child: Semantics(
        container: true,
        label: spoken,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.xs),
          child: Column(
            children: [
              Text(
                value,
                style: AppType.score.copyWith(
                  fontSize: 18,
                  color: empty ? c.textTertiary : c.textPrimary,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
    Widget rule() => Container(width: 1, height: 28, color: c.lineDecorative);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: c.lineDecorative),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          cell(
            '$count',
            count == 1 ? 'rating' : 'ratings',
            '$count ${count == 1 ? 'rating' : 'ratings'}',
          ),
          rule(),
          cell(
            yours == null ? '–' : formatScore(yours!),
            'yours',
            yours == null ? 'You have not rated it' : 'Your rating ${formatScore(yours!)}',
            empty: yours == null,
          ),
          rule(),
          cell(
            average == null ? '–' : formatScore(average!),
            'average',
            average == null ? 'No average yet' : 'Average ${formatScore(average!)}',
            empty: average == null,
          ),
        ],
      ),
    );
  }
}

/// Main genre and subgenres as plain information (not buttons): a filled
/// tonal label with no outline, main genre brighter.
class _Genres extends StatelessWidget {
  final String? main;
  final List<String> subgenres;
  const _Genres({required this.main, required this.subgenres});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget tag(String text, {bool primary = false}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs + 1),
      decoration: BoxDecoration(
        color: primary ? c.surfaceSelected : c.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.full),
      ),
      child: Text(
        text,
        style: AppType.bodySmall.copyWith(
          color: primary ? c.textPrimary : c.textSecondary,
          fontWeight: primary ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
    return Semantics(
      container: true,
      label: 'Genres: ${[?main, ...subgenres].join(', ')}',
      excludeSemantics: true,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpace.sm - 2,
        runSpacing: AppSpace.sm - 2,
        children: [if (main != null) tag(main!, primary: true), for (final g in subgenres) tag(g)],
      ),
    );
  }
}

/// Shown instead of a stage badge when the album has no listening stage yet.
/// Informational only, so it is not a button.
class _StageNotAssigned extends StatelessWidget {
  const _StageNotAssigned();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      container: true,
      label: 'Listening stage not assigned',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
        decoration: ShapeDecoration(
          shape: StadiumBorder(side: BorderSide(color: c.unscoredOutline)),
        ),
        child: Text('Stage not assigned', style: AppType.caption.copyWith(color: c.textSecondary)),
      ),
    );
  }
}

/// One line of album info: label on the left, value on the right.
class _Fact extends StatelessWidget {
  final String label;
  final String? value;
  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm - 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: AppType.body.copyWith(color: c.textSecondary)),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            flex: 3,
            child: Text(value ?? 'Unknown', style: AppType.body.copyWith(color: c.textPrimary)),
          ),
        ],
      ),
    );
  }
}

/// Album length for the details line: "46 min", "1 hr 12 min".
String _minutes(int ms) {
  final m = (ms / 60000).round();
  return m >= 60 ? '${m ~/ 60} hr ${m % 60} min' : '$m min';
}
