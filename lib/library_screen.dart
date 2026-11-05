import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'actions.dart';
import 'difficulty.dart';
import 'design/design.dart';
import 'expeditions.dart';
import 'models.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

/// Every album with a listening stage, by album id. Same answer as
/// [difficultyOf], but worked out once for a whole list instead of per album.
Map<String, Difficulty?> stagesById(Store store) {
  final out = <String, Difficulty?>{};
  for (final e in builtInExpeditions) {
    for (final s in e.stops) {
      final a = albumFor(store, s);
      if (a != null) out.putIfAbsent(a.id, () => s.difficulty);
    }
  }
  return out;
}

/// Album cards in a grid inside a scroll view, with ratings, difficulty and
/// the listen-later bookmark. Tapping opens the album unless [onTap] is given.
/// [numbered] shows each album's place (charts); [swipeToClear] lets you swipe
/// a card sideways to remove its rating, with Undo.
class SliverAlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final Store store;
  final void Function(Album)? onTap;

  /// Widest a card may be before another column is added.
  final double maxCardWidth;
  final bool numbered;
  final bool swipeToClear;
  const SliverAlbumGrid({
    super.key,
    required this.albums,
    required this.store,
    this.onTap,
    this.maxCardWidth = AlbumCardMetrics.defaultMaxWidth,
    this.numbered = false,
    this.swipeToClear = false,
  });

  /// Top padding above the first row (used by screens that scroll to a row).
  static const topPadding = AppSpace.xs;

  /// Each row is only as tall as its own cards: a row with no stage tags
  /// doesn't keep room for one, so there are no big gaps between rows.
  static double _rowHeight(
    List<Difficulty?> stages,
    int row,
    int columns,
    double cardWidth,
    TextScaler scaler,
    double maxCardWidth,
  ) {
    final from = row * columns;
    final to = math.min(from + columns, stages.length);
    return AlbumCardMetrics(
      maxCardWidth: maxCardWidth,
      textScaler: scaler,
      withStage: stages.sublist(from, to).any((d) => d != null),
    ).cardHeight(cardWidth);
  }

  /// Distance from the top of the grid to the row holding [index], for a grid
  /// [width] wide (including its side padding).
  static double offsetOf(
    List<Album> albums,
    Store store,
    int index,
    double width,
    TextScaler scaler, {
    double maxCardWidth = AlbumCardMetrics.defaultMaxWidth,
  }) {
    final staged = stagesById(store);
    final stages = [for (final a in albums) staged[a.id]];
    final metrics = AlbumCardMetrics(maxCardWidth: maxCardWidth, textScaler: scaler);
    final inner = width - 2 * AppSizes.gridPageGutter;
    final n = metrics.columns(inner);
    final cw = metrics.cardWidth(inner);
    var y = topPadding;
    for (var r = 0; r < index ~/ n; r++) {
      y += _rowHeight(stages, r, n, cw, scaler, maxCardWidth) + AlbumCardMetrics.rowGap;
    }
    return y;
  }

  @override
  Widget build(BuildContext context) {
    final staged = stagesById(store);
    final stages = [for (final a in albums) staged[a.id]];
    final scaler = MediaQuery.textScalerOf(context);
    final metrics = AlbumCardMetrics(maxCardWidth: maxCardWidth, textScaler: scaler);

    Widget card(int i) {
      final a = albums[i];
      final card = AlbumCard(
        album: a,
        number: numbered ? i + 1 : null,
        rating: store.ratingOf(a.id),
        difficulty: stages[i],
        listenLater: store.isListenLater(a.id),
        onListenLater: () => toggleListenLater(context, store, a),
        onTap: () => onTap != null ? onTap!(a) : openAlbum(context, store, a),
      );
      if (!swipeToClear) return card;
      return Dismissible(
        key: ValueKey('rated-${a.id}'),
        onDismissed: (_) => clearRating(context, store, a),
        child: card,
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.gridPageGutter,
        topPadding,
        AppSizes.gridPageGutter,
        AppSpace.lg,
      ),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final n = metrics.columns(width);
          final cw = metrics.cardWidth(width);
          final rows = (albums.length + n - 1) ~/ n;
          return SliverList.builder(
            itemCount: rows,
            itemBuilder: (context, r) => Padding(
              padding: EdgeInsets.only(top: r == 0 ? 0 : AlbumCardMetrics.rowGap),
              child: SizedBox(
                height: _rowHeight(stages, r, n, cw, scaler, maxCardWidth),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = r * n; i < math.min(r * n + n, albums.length); i++) ...[
                      if (i > r * n) const SizedBox(width: AlbumCardMetrics.gap),
                      SizedBox(width: cw, child: card(i)),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
