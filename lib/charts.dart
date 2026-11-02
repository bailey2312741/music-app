import 'package:flutter/material.dart';

import 'catalogue.dart';
import 'expeditions.dart';
import 'library_screen.dart';
import 'models.dart';
import 'store.dart';

/// The chart chips on Discover, in order: (key, label).
List<(String, String)> chartChips() {
  final decades = <int>{};
  for (final a in Catalogue.albums) {
    final y = int.tryParse(a.year ?? '');
    if (y != null && y >= 1950) decades.add(y ~/ 10 * 10);
  }
  return [
    ('popular', 'Popular'),
    ('top', 'Top rated'),
    ('hardest', 'Hardest'),
    for (final d in decades.toList()..sort()) ('$d', '${d}s'),
  ];
}

/// A ranked list: Popular, Top rated, Hardest, or one decade.
class ChartScreen extends StatelessWidget {
  final Store store;
  final String kind;
  const ChartScreen({super.key, required this.store, required this.kind});

  static const _size = 200;

  (String, String?, List<Album>) _chart() {
    switch (kind) {
      case 'popular':
        return ('Popular', 'Most played on ListenBrainz.', Catalogue.albums.take(_size).toList());
      case 'top':
        final rated = [for (final r in store.ratedAlbums) r.album]
          ..sort((a, b) => store.ratingOf(b.id)!.compareTo(store.ratingOf(a.id)!));
        return (
          'Top rated',
          'Only your own ratings for now. Everyone\'s ratings arrive with accounts.',
          rated,
        );
      case 'hardest':
        final hard = Catalogue.albums.where((a) => difficultyOf(store, a.id) != null).toList()
          ..sort(
            (a, b) => difficultyOf(store, b.id)!.index.compareTo(difficultyOf(store, a.id)!.index),
          );
        return (
          'Hardest',
          'Only expedition albums have a difficulty so far (${hard.length} albums).',
          hard,
        );
      default:
        final d = int.tryParse(kind) ?? 0;
        final list = Catalogue.albums
            .where((a) {
              final y = int.tryParse(a.year ?? '');
              return y != null && y >= d && y < d + 10;
            })
            .take(_size)
            .toList();
        return ('${d}s', 'Most played albums released in the ${d}s.', list);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final (title, note, albums) = _chart();
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: CustomScrollView(
            slivers: [
              if (note != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(note, style: Theme.of(context).textTheme.bodySmall),
                  ),
                ),
              if (albums.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Nothing here yet.', textAlign: TextAlign.center),
                  ),
                ),
              SliverAlbumGrid(albums: albums, store: store, numbered: true),
            ],
          ),
        );
      },
    );
  }
}
