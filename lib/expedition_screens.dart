import 'dart:math' as math;

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
          final next = ContinueCard.maybe(store);
          return ListView(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.section,
            ),
            children: [
              if (next != null) ...[const _Heading('Continue your journey'), next],
              _Heading(next == null ? 'Expeditions' : 'All expeditions'),
              for (final e in builtInExpeditions) ExpeditionTile(store: store, expedition: e),
              if (custom.isNotEmpty) ...[
                _Heading('Your expeditions', count: custom.length),
                for (final e in custom) ExpeditionTile(store: store, expedition: e),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A section title on the Expeditions page.
class _Heading extends StatelessWidget {
  final String text;
  final int? count;
  const _Heading(this.text, {this.count});

  @override
  Widget build(BuildContext context) => SectionHeader(
    text,
    count: count,
    padding: const EdgeInsets.only(top: AppSpace.sm, bottom: AppSpace.xs),
  );
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
    final where = 'Stop ${stop + 1} of ${expedition.stops.length} · ${expedition.name}';
    return Semantics(
      button: true,
      label:
          'Continue ${expedition.name}: ${album.title} by ${album.artist}, '
          'stop ${stop + 1} of ${expedition.stops.length}',
      excludeSemantics: true,
      child: Card(
        elevation: 0,
        color: c.surfaceSelected,
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: c.lineFunctional),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openAlbum(context, store, album, expeditionId: expedition.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Cover(album: album, size: _coverSize),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONTINUE', style: AppType.label.copyWith(color: c.success)),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        album.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.sectionTitle.copyWith(color: c.textPrimary),
                      ),
                      Text(
                        album.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        where,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.bodySmall.copyWith(color: c.textTertiary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Icon(Icons.chevron_right, color: c.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cover size on the Continue card and the expedition cards.
const _coverSize = 88.0;

/// An expedition card: the next album's cover (or the stacked covers once
/// finished), name, short description, facts and progress.
class ExpeditionTile extends StatelessWidget {
  final Store store;
  final Expedition expedition;
  const ExpeditionTile({super.key, required this.store, required this.expedition});

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    final c = AppColors.of(context);
    final total = e.stops.length;
    final done = ratedCount(store, e);
    final complete = done == total;
    final average = expeditionAverage(store, e);
    final own = store.expeditionRating(e.id);
    final next = nextStop(store, e);
    final nextAlbum = next == null ? null : albumFor(store, e.stops[next]);
    final status = complete ? 'Complete' : '$done of $total';
    return Semantics(
      button: true,
      label: [
        e.name,
        '$total albums',
        if (e.inOrder) 'in order',
        complete ? 'complete' : '$done of $total rated',
        if (nextAlbum != null) 'next: ${nextAlbum.title} by ${nextAlbum.artist}',
        if (average != null) 'your average ${average.toStringAsFixed(1)}',
        if (own != null) 'expedition rated ${formatScore(own)}',
      ].join(', '),
      excludeSemantics: true,
      child: Card(
        elevation: 0,
        color: c.surfaceRaised,
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openExpedition(context, e.id),
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Next album to listen to; finished (or unknown) shows the stack.
                    nextAlbum != null
                        ? Cover(album: nextAlbum, size: _coverSize)
                        : ExpeditionCover(
                            albums: [for (final s in e.stops) albumFor(store, s)],
                            size: _coverSize - 14,
                          ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.sectionTitle.copyWith(color: c.textPrimary),
                          ),
                          if (e.blurb.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.xxs),
                            Text(
                              e.blurb,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.bodySmall.copyWith(color: c.textSecondary),
                            ),
                          ],
                          const SizedBox(height: AppSpace.sm),
                          Wrap(
                            spacing: AppSpace.md,
                            runSpacing: AppSpace.xs,
                            children: [
                              _Fact(Icons.album_outlined, '$total albums'),
                              if (e.inOrder) const _Fact(Icons.lock_outline, 'In order'),
                              if (average != null)
                                _Fact(Icons.star_outline, 'Avg ${average.toStringAsFixed(1)}'),
                              if (own != null)
                                _Fact(Icons.flag_outlined, 'Rated ${formatScore(own)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedProgress(done: done, total: total),
                    ),
                    const SizedBox(width: AppSpace.md),
                    if (complete) ...[
                      Icon(Icons.check_circle, size: AppIconSizes.small, color: c.success),
                      const SizedBox(width: AppSpace.xs),
                    ],
                    Text(
                      status,
                      style: AppType.caption.copyWith(
                        color: complete ? c.success : c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        Flexible(
          child: Text(text, style: AppType.caption.copyWith(color: c.textSecondary)),
        ),
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
            padding: const EdgeInsets.only(bottom: AppSpace.section),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.blurb.isNotEmpty) ...[
                      Text(e.blurb, style: AppType.body.copyWith(color: c.textSecondary)),
                      const SizedBox(height: AppSpace.md),
                    ],
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
                            style: AppType.bodySmall.copyWith(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (average != null) ...[
                      const SizedBox(height: AppSpace.sm),
                      Text.rich(
                        TextSpan(
                          text: 'Your average so far: ',
                          children: [
                            TextSpan(
                              text: average.toStringAsFixed(1),
                              style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        style: AppType.bodySmall.copyWith(color: c.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              JourneyTrail(store: store, expedition: e),
              const SizedBox(height: AppSpace.lg),
              // The expedition's own rating, in its own panel so it reads as
              // separate from the album ratings on the trail.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.surfaceRaised,
                    borderRadius: BorderRadius.circular(AppRadii.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.lg,
                      AppSpace.lg,
                      AppSpace.lg,
                      AppSpace.sm,
                    ),
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
                        const SizedBox(height: AppSpace.md),
                        ExcludeSemantics(child: ScoreText(own, scale: 1.33)),
                        if (own == null)
                          ExcludeSemantics(
                            child: Text(
                              'Not rated yet',
                              style: AppType.caption.copyWith(color: c.textTertiary),
                            ),
                          ),
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

  /// Cover sizes: every stop, and the bigger final stop.
  static const cover = 120.0;
  static const finalCover = 152.0;

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
        // Title, artist, stage and caption under each cover; grows with text size.
        final metrics = AlbumCardMetrics(
          textScaler: MediaQuery.textScalerOf(context),
          withStage: true,
          withCaption: true,
        );
        // With large text, wider stops so titles wrap between words.
        final card = metrics.largeText ? AppCoverSizes.lg : JourneyTrail.cover;
        final last = metrics.largeText ? AppCoverSizes.lg + 32 : JourneyTrail.finalCover;
        final textSpace = metrics.cardHeight(card) - card;
        const zig = 56.0; // how far the lower stops sit below the upper ones
        final step = card + AppSpace.xxl; // room for the path between stops
        const pad = AppSpace.sm;
        // Tall enough for a lower stop and its text, and no taller.
        final height = math.max(pad + zig + card + textSpace, last + textSpace) + pad;

        final lefts = <double>[], tops = <double>[], sizes = <double>[];
        for (var i = 0; i < n; i++) {
          final isLast = i == n - 1;
          final size = isLast ? last : card;
          lefts.add(AppSpace.gutter + i * step + (isLast ? AppSpace.sm : 0));
          tops.add(isLast ? (height - last - textSpace) / 2 : pad + (i.isOdd ? zig : 0));
          sizes.add(size);
        }
        final width = lefts.last + last + AppSpace.gutter;
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
                // The next stop's label sits on its cover, where it's seen first.
                if (next != null)
                  Positioned(
                    left: lefts[next] + AppSpace.md,
                    top: tops[next] + AppSpace.md,
                    child: const _NextStopLabel(),
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
        caption: locked || i == next ? null : (i == e.stops.length - 1 ? 'Final stop' : null),
        semanticNote: i == next ? 'Next stop' : null,
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

/// "Next stop" pill on the highlighted stop's cover.
class _NextStopLabel extends StatelessWidget {
  const _NextStopLabel();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    // A short tag on the artwork: grows with text size, but only a little,
    // so it never hides the cover. The card itself also says "Next stop".
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: DecoratedBox(
        decoration: ShapeDecoration(color: c.success, shape: const StadiumBorder()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xxs),
          child: ExcludeSemantics(
            child: Text('NEXT STOP', style: AppType.label.copyWith(color: c.page)),
          ),
        ),
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
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final dashed = Paint()
      ..color = faded
      ..strokeWidth = 3
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
