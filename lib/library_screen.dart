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

  @override
  Widget build(BuildContext context) {
    final staged = stagesById(store);
    final stages = [for (final a in albums) staged[a.id]];
    final metrics = AlbumCardMetrics(
      maxCardWidth: maxCardWidth,
      textScaler: MediaQuery.textScalerOf(context),
      withStage: stages.any((d) => d != null),
    );
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.gridPageGutter,
        topPadding,
        AppSizes.gridPageGutter,
        AppSpace.lg,
      ),
      sliver: SliverGrid.builder(
        gridDelegate: metrics.delegate(),
        itemCount: albums.length,
        itemBuilder: (context, i) {
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
        },
      ),
    );
  }
}
