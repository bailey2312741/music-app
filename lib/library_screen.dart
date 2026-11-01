import 'package:flutter/material.dart';

import 'actions.dart';
import 'expeditions.dart';
import 'models.dart';
import 'screens.dart';
import 'sorting.dart';
import 'store.dart';
import 'widgets.dart';

/// The Ratings tab: albums you've rated, and your Listen later list.
class LibraryScreen extends StatefulWidget {
  final Store store;
  const LibraryScreen({super.key, required this.store});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _showListenLater = false;
  SortOrder? _sort;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Your albums'), actions: cornerActions(store)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final rated = [for (final r in store.ratedAlbums) r.album];
          final later = store.listenLater;
          final shown = _showListenLater ? later : rated;
          final albums = _sort == null ? shown : _sort!.apply(shown, store);
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: SegmentedButton<bool>(
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(value: false, label: Text('Rated (${rated.length})')),
                            ButtonSegment(
                              value: true,
                              label: Text('Listen later (${later.length})'),
                            ),
                          ],
                          selected: {_showListenLater},
                          onSelectionChanged: (v) => setState(() => _showListenLater = v.first),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SortButton(value: _sort, onChanged: (v) => setState(() => _sort = v)),
                  ),
                ),
              ),
              if (albums.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      _showListenLater
                          ? 'Tap the bookmark on any album to save it for later.'
                          : 'Albums you rate will show up here.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SliverAlbumGrid(albums: albums, store: store),
            ],
          );
        },
      ),
    );
  }
}

/// Album cards in a grid inside a scroll view, with ratings, difficulty and
/// the listen-later button. Tapping opens the album unless [onTap] is given.
class SliverAlbumGrid extends StatelessWidget {
  final List<Album> albums;
  final Store store;
  final void Function(Album)? onTap;
  final SliverGridDelegate delegate;
  const SliverAlbumGrid({
    super.key,
    required this.albums,
    required this.store,
    this.onTap,
    this.delegate = albumGridDelegate,
  });

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
    sliver: SliverGrid.builder(
      gridDelegate: delegate,
      itemCount: albums.length,
      itemBuilder: (context, i) {
        final a = albums[i];
        return AlbumCard(
          album: a,
          rating: store.ratingOf(a.id),
          difficulty: difficultyOf(store, a.id),
          listenLater: store.isListenLater(a.id),
          onListenLater: () => toggleListenLater(context, store, a),
          onTap: () => onTap != null ? onTap!(a) : openAlbum(context, store, a),
        );
      },
    ),
  );
}
