import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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

class _JourneyTrailState extends State<JourneyTrail> with TickerProviderStateMixin {
  ScrollController? _scroll;

  /// The travelled path grows towards the next stop after a rating is saved
  /// (400 ms). It follows saved progress only, never the slider while it is
  /// being dragged, and starts when the trail is on screen again.
  late final _travel = AnimationController(vsync: this, duration: AppMotion.trail.duration)
    ..value = 1;
  late final _travelT = CurvedAnimation(parent: _travel, curve: AppMotion.trail.curve);
  late int _current = _currentStop();
  double _from = 0;

  /// The final stop's check mark pops in once when the expedition completes.
  late final _complete = AnimationController(
    vsync: this,
    duration: AppMotion.completeMoment.duration,
    value: 1,
  );
  late bool _wasComplete = nextStop(store, widget.expedition) == null;

  /// Whether a finger is on the trail; then it never scrolls by itself.
  bool _touching = false;

  Store get store => widget.store;

  int _currentStop() => nextStop(store, widget.expedition) ?? widget.expedition.stops.length - 1;

  double get _travelled => _from + (_current - _from) * _travelT.value;

  @override
  void didUpdateWidget(JourneyTrail old) {
    super.didUpdateWidget(old);
    final current = _currentStop();
    final complete = nextStop(store, widget.expedition) == null;
    final reduced = AppMotion.reduced(context);
    if (current != _current) {
      _from = _travelled;
      _current = current;
      if (reduced) {
        _travel.value = 1;
      } else {
        _travel.forward(from: 0);
        _revealCurrent = true;
      }
    }
    if (complete && !_wasComplete && !reduced) _complete.forward(from: 0);
    _wasComplete = complete;
  }

  /// Set when progress moved, so the next layout can bring the new stop into
  /// view if it is off screen.
  bool _revealCurrent = false;

  void _reveal(double left, double size, double viewport) {
    _revealCurrent = false;
    final scroll = _scroll;
    if (scroll == null || !scroll.hasClients || _touching) return;
    final pos = scroll.position;
    if (left >= pos.pixels && left + size <= pos.pixels + viewport) return; // already visible
    final target = (left + size / 2 - viewport / 2).clamp(0.0, pos.maxScrollExtent);
    scroll.animateTo(target, duration: AppMotion.trail.duration, curve: AppMotion.trail.curve);
  }

  @override
  void dispose() {
    _travel.dispose();
    _complete.dispose();
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

        if (_revealCurrent) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _reveal(lefts[current], sizes[current], box.maxWidth),
          );
        }
        final motion = AppMotion.trail.resolve(context);

        return Listener(
          onPointerDown: (_) => _touching = true,
          onPointerUp: (_) => _touching = false,
          onPointerCancel: (_) => _touching = false,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    // Only the path repaints while it grows.
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _travelT,
                        builder: (context, _) => CustomPaint(
                          painter: _TrailPainter(
                            points: centres,
                            travelled: _travelled,
                            color: AppColors.of(context).progressFill,
                            faded: AppColors.of(context).lineFunctional,
                          ),
                        ),
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
                  // The next stop's label sits on its cover, where it's seen
                  // first, and travels along with the path to the new stop.
                  if (next != null)
                    AnimatedPositioned(
                      duration: motion.duration,
                      curve: motion.curve,
                      left: lefts[next] + AppSpace.md,
                      top: tops[next] + AppSpace.md,
                      child: const _NextStopLabel(),
                    ),
                  // Expedition complete: a check on the final stop.
                  if (next == null)
                    Positioned(
                      left: lefts[n - 1] + sizes[n - 1] - AppSizes.touchMin + AppSpace.xs,
                      top: tops[n - 1] + sizes[n - 1] - AppSizes.touchMin + AppSpace.xs,
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _complete,
                          curve: AppMotion.completeMoment.curve,
                        ),
                        child: const _CompleteMark(),
                      ),
                    ),
                ],
              ),
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

/// The check on the final stop of a completed expedition.
class _CompleteMark extends StatelessWidget {
  const _CompleteMark();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Semantics(
      label: 'Expedition complete',
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: c.success,
          shape: BoxShape.circle,
          border: Border.all(color: c.page, width: AppSizes.indicatorBorderWidth),
        ),
        child: Icon(Icons.check, size: AppIconSizes.regular, color: c.page),
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

  /// How far along the stops the solid path reaches: 2 means up to stop 3;
  /// 2.5 means halfway from stop 3 to stop 4 (while it grows).
  final double travelled;
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
      final reach = travelled - i; // 1 or more: the whole segment is travelled
      if (reach >= 1) {
        canvas.drawLine(points[i], points[i + 1], solid);
        continue;
      }
      drawDashedLine(canvas, points[i], points[i + 1], dashed);
      if (reach > 0) {
        canvas.drawLine(points[i], Offset.lerp(points[i], points[i + 1], reach)!, solid);
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.travelled != travelled ||
      old.color != color ||
      old.faded != faded ||
      old.points.length != points.length ||
      [for (var i = 0; i < points.length; i++) old.points[i] != points[i]].any((d) => d);
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

  /// The name error shows only once the name has been typed in and cleared.
  bool _nameTouched = false;

  static const _minAlbums = 2;

  bool get _canSave => _name.text.trim().isNotEmpty && _albums.length >= _minAlbums;

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

  /// Moves the album at [from] one place up or down (keyboard and screen
  /// reader alternative to dragging).
  void _move(int from, int to) {
    if (to < 0 || to >= _albums.length) return;
    setState(() => _albums.insert(to, _albums.removeAt(from)));
  }

  @override
  void dispose() {
    _name.dispose();
    _blurb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final nameMissing = _name.text.trim().isEmpty;
    final needed = math.max(0, _minAlbums - _albums.length);
    final missing = [
      if (nameMissing) 'a name',
      if (needed > 0) needed == 1 ? 'one more album' : '$needed more albums',
    ];
    return Scaffold(
      appBar: AppBar(),
      // Save sits at the bottom, always in the same place, and says what it
      // still needs while it can't be pressed.
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: c.chrome,
          border: Border(top: BorderSide(color: c.lineDecorative)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              AppSpace.md,
              AppSpace.gutter,
              AppSpace.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (missing.isNotEmpty) ...[
                  Text(
                    'To save, add ${missing.join(' and ')}.',
                    textAlign: TextAlign.center,
                    style: AppType.bodySmall.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: Text(widget.editing == null ? 'Save expedition' : 'Save changes'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          AppSpace.xs,
          AppSpace.gutter,
          AppSpace.xxl,
        ),
        children: [
          PageHeader(
            widget.editing == null ? 'New expedition' : 'Edit expedition',
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
          ),
          const SizedBox(height: AppSpace.sm),
          TextField(
            controller: _name,
            style: AppType.sectionTitle.copyWith(color: c.textPrimary),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'e.g. Into the Ambient',
              border: const OutlineInputBorder(),
              errorText: _nameTouched && nameMissing ? 'Give your expedition a name.' : null,
            ),
            onChanged: (_) => setState(() => _nameTouched = true),
          ),
          const SizedBox(height: AppSpace.lg),
          TextField(
            controller: _blurb,
            minLines: 2,
            maxLines: 5,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Description',
              helperText: 'Optional',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Listen in order', style: AppType.cardTitle.copyWith(color: c.textPrimary)),
            subtitle: const Text('Each album unlocks after you rate the one before it.'),
            value: _inOrder,
            onChanged: (v) => setState(() => _inOrder = v),
          ),
          const SizedBox(height: AppSpace.sm),
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
          Text(
            needed > 0
                ? 'Add at least $_minAlbums albums. Drag the handle to change the order.'
                : 'Drag the handle to change the order.',
            style: AppType.bodySmall.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpace.sm),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            // The lifted row: a flat raised surface, no shadow.
            proxyDecorator: (child, _, _) => Material(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadii.card),
              child: child,
            ),
            onReorderItem: (from, to) => setState(() => _albums.insert(to, _albums.removeAt(from))),
            children: [
              for (var i = 0; i < _albums.length; i++)
                _StopRow(
                  key: ValueKey(_albums[i].id),
                  album: _albums[i],
                  index: i,
                  count: _albums.length,
                  onRemove: () => setState(() => _albums.removeAt(i)),
                  onMove: (to) => _move(i, to),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
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

/// One album in the expedition editor: position, cover, title, artist and
/// year, a remove button and a drag handle. Arrow keys on the focused handle
/// (or the screen reader's actions) move it up and down too.
class _StopRow extends StatelessWidget {
  final Album album;
  final int index;
  final int count;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;
  const _StopRow({
    super.key,
    required this.album,
    required this.index,
    required this.count,
    required this.onRemove,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final details = [album.artist, ?album.year].join(' · ');
    return Semantics(
      customSemanticsActions: {
        if (index > 0) const CustomSemanticsAction(label: 'Move up'): () => onMove(index - 1),
        if (index < count - 1)
          const CustomSemanticsAction(label: 'Move down'): () => onMove(index + 1),
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 72),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
          child: Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minWidth: MediaQuery.textScalerOf(context).scale(24)),
                child: Text(
                  '${index + 1}',
                  semanticsLabel: 'Stop ${index + 1} of $count',
                  style: AppType.bodySmall.copyWith(
                    color: c.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              ExcludeSemantics(child: Cover(album: album, size: 56)),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.cardTitle.copyWith(color: c.textPrimary),
                    ),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.bodySmall.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove ${album.title}',
                onPressed: onRemove,
              ),
              _DragHandle(index: index, count: count, title: album.title, onMove: onMove),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 48 px drag handle that can also take keyboard focus: Up and Down arrows
/// move the album.
class _DragHandle extends StatefulWidget {
  final int index;
  final int count;
  final String title;
  final ValueChanged<int> onMove;
  const _DragHandle({
    required this.index,
    required this.count,
    required this.title,
    required this.onMove,
  });

  @override
  State<_DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<_DragHandle> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final to = switch (event.logicalKey) {
          LogicalKeyboardKey.arrowUp => widget.index - 1,
          LogicalKeyboardKey.arrowDown => widget.index + 1,
          _ => null,
        };
        if (to == null || to < 0 || to >= widget.count) return KeyEventResult.ignored;
        widget.onMove(to);
        // Keep the focus on this album's handle after it moves.
        WidgetsBinding.instance.addPostFrameCallback((_) => node.requestFocus());
        return KeyEventResult.handled;
      },
      child: Semantics(
        container: true,
        label: 'Reorder ${widget.title}',
        hint: 'Drag, or use the up and down arrow keys',
        child: ReorderableDragStartListener(
          index: widget.index,
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Container(
              width: AppSizes.touchMin,
              height: AppSizes.touchMin,
              decoration: _focused
                  ? BoxDecoration(
                      border: Border.all(color: c.focusRing, width: AppSizes.indicatorBorderWidth),
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    )
                  : null,
              child: Icon(Icons.drag_handle, color: c.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
