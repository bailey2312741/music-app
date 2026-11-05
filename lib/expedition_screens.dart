import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'actions.dart';
import 'design/design.dart';
import 'expeditions.dart';
import 'models.dart';
import 'nav.dart';
import 'profile_screen.dart' show drawDashedLine;
import 'search_screen.dart';
import 'store.dart';
import 'widgets.dart';

class ExpeditionListScreen extends StatefulWidget {
  final Store store;
  const ExpeditionListScreen({super.key, required this.store});

  @override
  State<ExpeditionListScreen> createState() => _ExpeditionListScreenState();
}

class _ExpeditionListScreenState extends State<ExpeditionListScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    tabReselects[1].addListener(_toTop);
  }

  @override
  void dispose() {
    tabReselects[1].removeListener(_toTop);
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expeditions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New expedition',
            onPressed: () => context.push('/expeditions/new'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final custom = store.customExpeditions;
          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.xl),
            children: [
              ?ContinueCard.maybe(store),
              for (final e in builtInExpeditions) ExpeditionTile(store: store, expedition: e),
              if (custom.isNotEmpty)
                SectionHeader(
                  'Your expeditions',
                  count: custom.length,
                  padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xs),
                ),
              for (final e in custom) ExpeditionTile(store: store, expedition: e),
            ],
          );
        },
      ),
    );
  }
}

/// "Continue": the next album of the expedition you were last on. Tapping it
/// opens the album with the rating bar ready.
class ContinueCard extends StatelessWidget {
  final Store store;
  final Expedition expedition;
  final Album album;
  final int stop;
  const ContinueCard._(this.store, this.expedition, this.album, this.stop);

  /// The started, unfinished expedition rated most recently; if none is
  /// started yet, the first one. Null when everything is done.
  static ContinueCard? maybe(Store store) {
    Expedition? best;
    var bestAt = -1;
    for (final e in allExpeditions(store)) {
      if (nextStop(store, e) == null) continue;
      var at = 0;
      for (final s in e.stops) {
        if (!isDone(store, e, s)) continue;
        final t = store.ratedAtOf(albumFor(store, s)!.id);
        if (t > at) at = t;
      }
      if (at > bestAt) {
        best = e;
        bestAt = at;
      }
    }
    if (best == null) return null;
    final i = nextStop(store, best)!;
    final album = albumFor(store, best.stops[i]);
    if (album == null) return null;
    return ContinueCard._(store, best, album, i);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Card(
      elevation: 0,
      color: c.surfaceSelected,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openAlbum(context, store, album, expeditionId: expedition.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Cover(album: album, size: AppCoverSizes.sm),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue: ${expedition.name}',
                      style: AppType.caption.copyWith(
                        color: c.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      album.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      'Stop ${stop + 1} of ${expedition.stops.length} · ${album.artist}',
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
    );
  }
}

/// A large expedition card: stacked covers, name, description, progress and averages.
/// Tinted and wider than album cards so the two never look alike.
class ExpeditionTile extends StatelessWidget {
  final Store store;
  final Expedition expedition;
  const ExpeditionTile({super.key, required this.store, required this.expedition});

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    final c = AppColors.of(context);
    final done = ratedCount(store, e);
    final average = expeditionAverage(store, e);
    final own = store.expeditionRating(e.id);
    return Card(
      elevation: 0,
      color: c.surfaceRaised,
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openExpedition(context, e.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExpeditionCover(albums: [for (final s in e.stops) albumFor(store, s)], size: 104),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.name, style: AppType.sectionTitle.copyWith(color: c.textPrimary)),
                        const SizedBox(height: AppSpace.xs),
                        if (e.blurb.isNotEmpty)
                          Text(
                            e.blurb,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.bodySmall.copyWith(color: c.textSecondary),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            _Fact(Icons.album_outlined, '${e.stops.length} albums'),
                            if (e.inOrder) const _Fact(Icons.lock_outline, 'In order'),
                            if (average != null)
                              _Fact(Icons.star_half, 'Your avg ${average.toStringAsFixed(1)}'),
                            if (own != null)
                              _Fact(Icons.flag_outlined, 'Rated ${formatScore(own)}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SegmentedProgress(done: done, total: e.stops.length),
                  ),
                  const SizedBox(width: AppSpace.md),
                  ExcludeSemantics(
                    child: Text(
                      done == e.stops.length ? 'Complete' : '$done of ${e.stops.length}',
                      style: AppType.caption.copyWith(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Fact(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSizes.small, color: c.textTertiary),
        const SizedBox(width: AppSpace.xs),
        Text(text, style: AppType.caption.copyWith(color: c.textSecondary)),
      ],
    );
  }
}

/// One expedition, drawn as a trail: albums are landmarks that zig-zag along
/// a sideways-scrolling path, joined by a line (solid where you've been, dashed ahead), with the
/// final album bigger and centred.
class ExpeditionScreen extends StatefulWidget {
  final Store store;
  final String expeditionId;
  const ExpeditionScreen({super.key, required this.store, required this.expeditionId});

  @override
  State<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends State<ExpeditionScreen> {
  double? _draft;

  Store get store => widget.store;

  Expedition? get _expedition =>
      allExpeditions(store).where((e) => e.id == widget.expeditionId).firstOrNull;

  /// Starts the expedition over (album ratings are kept), with Undo.
  Future<void> _reset(Expedition e) async {
    final messenger = ScaffoldMessenger.of(context);
    await store.resetProgress(e.id);
    setState(() => _draft = null);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    showUndo(context, 'Progress reset', () => store.undoReset(e.id));
  }

  /// Deletes one of your expeditions, with Undo.
  Future<void> _delete(Expedition e) async {
    final messenger = ScaffoldMessenger.of(context);
    context.pop();
    await store.deleteExpedition(e.id);
    showUndoOn(messenger, 'Expedition deleted', () => store.saveExpedition(e));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final e = _expedition;
        if (e == null) return const Scaffold();
        final c = AppColors.of(context);
        final done = ratedCount(store, e);
        final average = expeditionAverage(store, e);
        final own = _draft ?? store.expeditionRating(e.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(e.name),
            actions: [
              // A menu keeps Reset (and Delete) out of the way of normal taps.
              PopupMenuButton<String>(
                tooltip: 'More',
                onSelected: (v) => switch (v) {
                  'edit' => context.push('/expeditions/trail/${Uri.encodeComponent(e.id)}/edit'),
                  'delete' => _delete(e),
                  _ => _reset(e),
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'reset', child: Text('Reset progress')),
                  if (e.custom) const PopupMenuItem(value: 'edit', child: Text('Edit expedition')),
                  if (e.custom)
                    const PopupMenuItem(value: 'delete', child: Text('Delete expedition')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.blurb.isNotEmpty)
                      Text(e.blurb, style: AppType.body.copyWith(color: c.textSecondary)),
                    const SizedBox(height: AppSpace.md),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedProgress(done: done, total: e.stops.length),
                        ),
                        const SizedBox(width: AppSpace.md),
                        ExcludeSemantics(
                          child: Text(
                            done == e.stops.length
                                ? 'Complete!'
                                : '$done of ${e.stops.length} rated',
                            style: AppType.bodySmall.copyWith(color: c.textPrimary),
                          ),
                        ),
                      ],
                    ),
                    if (average != null) ...[
                      const SizedBox(height: AppSpace.sm - 2),
                      Text(
                        'Your average so far: ${average.toStringAsFixed(1)}',
                        style: AppType.bodySmall.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              JourneyTrail(store: store, expedition: e),
              const Divider(height: 32, indent: 16, endIndent: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Rate this expedition',
                        textAlign: TextAlign.center,
                        style: AppType.sectionTitle.copyWith(color: c.textPrimary),
                      ),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Text(
                      'How was the journey as a whole? Separate from your album ratings.',
                      textAlign: TextAlign.center,
                      style: AppType.bodySmall.copyWith(color: c.textSecondary),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    ExcludeSemantics(child: ScoreText(own, scale: 1.33)),
                    // Unrated: grey, thumb at the far left; the first touch sets the value.
                    RatingSlider(
                      value: own,
                      noun: 'expedition',
                      onChanged: (v) => setState(() => _draft = v),
                      onChangeEnd: (v) {
                        setState(() => _draft = v);
                        store.rateExpedition(e.id, v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The trail of stops, scrolling sideways. Stops zig-zag up and down; the
/// final stop is bigger and centred. The line is solid up to your current
/// stop, dashed after. It opens scrolled to your next stop.
class JourneyTrail extends StatefulWidget {
  final Store store;
  final Expedition expedition;
  const JourneyTrail({super.key, required this.store, required this.expedition});

  @override
  State<JourneyTrail> createState() => _JourneyTrailState();
}

class _JourneyTrailState extends State<JourneyTrail> {
  ScrollController? _scroll;

  Store get store => widget.store;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expedition;
    final n = e.stops.length;
    final open = unlockedCount(store, e);
    final next = nextStop(store, e);
    // Everything before the current stop counts as travelled.
    final current = next ?? n - 1;

    return LayoutBuilder(
      builder: (context, box) {
        const card = 120.0;
        const last = 156.0;
        // Title, artist, stage and caption under each cover; grows with text size.
        final metrics = AlbumCardMetrics(
          textScaler: MediaQuery.textScalerOf(context),
          withStage: true,
          withCaption: true,
        );
        final textSpace = metrics.cardHeight(card) - card;
        const zig = 64.0; // how far the lower stops sit below the upper ones
        const step = card + 20;
        final height = card + textSpace + zig + 24;

        final lefts = <double>[], tops = <double>[], sizes = <double>[];
        for (var i = 0; i < n; i++) {
          final isLast = i == n - 1;
          final size = isLast ? last : card;
          lefts.add(16 + i * step + (isLast ? 8 : 0));
          tops.add(isLast ? (height - last - textSpace) / 2 : 12 + (i.isOdd ? zig : 0));
          sizes.add(size);
        }
        final width = lefts.last + last + 16;
        final centres = [
          for (var i = 0; i < n; i++) Offset(lefts[i] + sizes[i] / 2, tops[i] + sizes[i] / 2),
        ];
        _scroll ??= ScrollController(
          initialScrollOffset: (lefts[current] + card / 2 - box.maxWidth / 2).clamp(
            0,
            (width - box.maxWidth).clamp(0, double.infinity),
          ),
        );

        return SingleChildScrollView(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrailPainter(
                      points: centres,
                      travelled: current,
                      color: AppColors.of(context).progressFill,
                      faded: AppColors.of(context).lineFunctional,
                    ),
                  ),
                ),
                for (var i = 0; i < n; i++)
                  Positioned(
                    left: lefts[i],
                    top: tops[i],
                    width: sizes[i],
                    child: _stop(context, e, i, open, next),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stop(BuildContext context, Expedition e, int i, int open, int? next) {
    final stop = e.stops[i];
    final album = albumFor(store, stop);
    final locked = i >= open;
    final shown = album ?? Album(id: '', title: stop.title, artist: stop.artist);
    return Material(
      color: AppColors.of(context).page,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: AlbumCard(
        album: shown,
        number: i + 1,
        difficulty: stop.difficulty ?? (album == null ? null : difficultyOf(store, album.id)),
        rating: album != null && isDone(store, e, stop) ? store.ratingOf(album.id) : null,
        locked: locked,
        highlight: i == next,
        caption: locked
            ? null
            : (i == next ? 'Next stop' : (i == e.stops.length - 1 ? 'Final stop' : null)),
        onTap: locked
            ? () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Rate album $open first to unlock this one.'),
                  duration: const Duration(seconds: 2),
                ),
              )
            : album == null
            ? null
            : () => openAlbum(context, store, album, expeditionId: e.id),
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  final List<Offset> points;
  final int travelled; // segments before this stop index are solid
  final Color color, faded;
  _TrailPainter({
    required this.points,
    required this.travelled,
    required this.color,
    required this.faded,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final solid = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dashed = Paint()
      ..color = faded
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i + 1 < points.length; i++) {
      if (i + 1 <= travelled) {
        canvas.drawLine(points[i], points[i + 1], solid);
      } else {
        drawDashedLine(canvas, points[i], points[i + 1], dashed);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) => true;
}

// ---------------------------------------------------------------- Create and edit

/// Makes a new expedition, or edits one of yours when [editing] is given.
class CreateExpeditionScreen extends StatefulWidget {
  final Store store;
  final Expedition? editing;
  const CreateExpeditionScreen({super.key, required this.store, this.editing});

  @override
  State<CreateExpeditionScreen> createState() => _CreateExpeditionScreenState();
}

class _CreateExpeditionScreenState extends State<CreateExpeditionScreen> {
  late final _name = TextEditingController(text: widget.editing?.name);
  late final _blurb = TextEditingController(text: widget.editing?.blurb);
  late final List<Album> _albums = [
    for (final s in widget.editing?.stops ?? const <ExpeditionStop>[]) ?s.album,
  ];
  late bool _inOrder = widget.editing?.inOrder ?? false;

  bool get _canSave => _name.text.trim().isNotEmpty && _albums.length >= 2;

  Future<void> _addAlbum() async {
    final album = await Navigator.of(context).push<Album>(
      MaterialPageRoute(builder: (_) => SearchScreen(store: widget.store, pickMode: true)),
    );
    if (album == null || !mounted) return;
    if (_albums.any((a) => a.id == album.id)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('That album is already in this expedition.')));
      return;
    }
    setState(() => _albums.add(album));
  }

  void _sortByYear() =>
      setState(() => _albums.sort((a, b) => (a.year ?? '9999').compareTo(b.year ?? '9999')));

  Future<void> _save() async {
    await widget.store.saveExpedition(
      Expedition(
        widget.editing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        _name.text.trim(),
        _blurb.text.trim(),
        [for (final a in _albums) ExpeditionStop.ofAlbum(a)],
        inOrder: _inOrder,
        custom: true,
      ),
    );
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _name.dispose();
    _blurb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editing == null ? 'New expedition' : 'Edit expedition'),
        actions: [TextButton(onPressed: _canSave ? _save : null, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _blurb,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Listen in order'),
            subtitle: const Text('Each album unlocks after you rate the one before it.'),
            value: _inOrder,
            onChanged: (v) => setState(() => _inOrder = v),
          ),
          const Divider(),
          SectionHeader(
            'Albums',
            count: _albums.length,
            padding: EdgeInsets.zero,
            trailing: _albums.length > 1
                ? TextButton.icon(
                    onPressed: _sortByYear,
                    icon: const Icon(Icons.sort, size: AppIconSizes.small),
                    label: const Text('Sort by year'),
                  )
                : null,
          ),
          if (_albums.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Add at least two albums. Drag to reorder.'),
            ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => setState(() => _albums.insert(to, _albums.removeAt(from))),
            children: [
              for (var i = 0; i < _albums.length; i++)
                ListTile(
                  key: ValueKey(_albums[i].id),
                  contentPadding: EdgeInsets.zero,
                  leading: Cover(album: _albums[i], size: AppCoverSizes.xs),
                  title: Text(
                    '${i + 1}. ${_albums[i].title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [_albums[i].artist, _albums[i].year].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove',
                        onPressed: () => setState(() => _albums.removeAt(i)),
                      ),
                      ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addAlbum,
            icon: const Icon(Icons.add),
            label: const Text('Add album'),
          ),
        ],
      ),
    );
  }
}
