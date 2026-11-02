import 'package:flutter/material.dart';

import 'actions.dart';
import 'expeditions.dart';
import 'models.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

/// Album cards in a grid inside a scroll view, with ratings, difficulty and
/// the listen-later bookmark. Tapping opens the album unless [onTap] is given.
/// [numbered] shows each album's place (charts); [swipeToClear] lets you swipe
/// a card sideways to remove its rating, with Undo.
class SliverAlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final Store store;
  final void Function(Album)? onTap;
  final SliverGridDelegate delegate;
  final bool numbered;
  final bool swipeToClear;
  const SliverAlbumGrid({
    super.key,
    required this.albums,
    required this.store,
    this.onTap,
    this.delegate = albumGridDelegate,
    this.numbered = false,
    this.swipeToClear = false,
  });

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
    sliver: SliverGrid.builder(
      gridDelegate: delegate,
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final a = albums[i];
        final card = AlbumCard(
          album: a,
          number: numbered ? i + 1 : null,
          rating: store.ratingOf(a.id),
          difficulty: difficultyOf(store, a.id),
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
