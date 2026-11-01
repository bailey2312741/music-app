import 'package:flutter/material.dart';

import 'catalogue.dart';
import 'models.dart';
import 'screens.dart';
import 'sorting.dart';
import 'store.dart';
import 'widgets.dart';

class SearchScreen extends StatefulWidget {
  final Store store;

  /// When true, tapping an album returns it instead of opening it.
  final bool pickMode;
  const SearchScreen({super.key, required this.store, this.pickMode = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _text = '';
  String? _genre;
  SortOrder? _sort;

  void _tapAlbum(Album a) =>
      widget.pickMode ? Navigator.of(context).pop(a) : openAlbum(context, widget.store, a);

  Future<void> _openArtist(String name) async {
    final picked = await Navigator.of(context).push<Album>(
      MaterialPageRoute(
        builder: (_) => ArtistScreen(store: widget.store, artist: name, pickMode: widget.pickMode),
      ),
    );
    if (picked != null && mounted) Navigator.of(context).pop(picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final store = widget.store;
    final browsing = _text.trim().isEmpty && _genre == null;
    final artists = _genre != null
        ? const <String>[]
        : browsing
        ? Catalogue.artists
        : Catalogue.searchArtists(_text);
    final found = Catalogue.search(_text, genre: _genre);
    final albums = _sort == null ? found : _sort!.apply(found, store);

    return Scaffold(
      appBar: widget.pickMode
          ? AppBar(title: const Text('Add an album'))
          : AppBar(title: const Text('Search'), actions: cornerActions(store)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: SearchBar(
                  hintText: 'Album, artist or genre',
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (v) => setState(() => _text = v),
                ),
              ),
            ),
            // Genre filter: tap a tag to show only that genre, tap again to clear.
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  children: [
                    for (final g in Catalogue.genres.take(_genre == null ? 10 : 99))
                      if (_genre == null || g == _genre)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(g),
                            selected: g == _genre,
                            onSelected: (on) => setState(() => _genre = on ? g : null),
                          ),
                        ),
                  ],
                ),
              ),
            ),
            if (artists.isNotEmpty) ...[
              _heading(context, browsing ? 'Artists (${artists.length})' : 'Artists'),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: artists.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final own = Catalogue.byArtist(artists[i]);
                      return ArtistCard(
                        artist: artists[i],
                        image: own.where((a) => a.cover != null).lastOrNull ?? own.lastOrNull,
                        albumCount: own.length,
                        onTap: () => _openArtist(artists[i]),
                      );
                    },
                  ),
                ),
              ),
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        browsing ? 'All albums (${albums.length})' : 'Albums (${albums.length})',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    SortButton(value: _sort, onChanged: (v) => setState(() => _sort = v)),
                  ],
                ),
              ),
            ),
            if (albums.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No albums match. The album list is a short test list for now.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
            SliverAlbumGrid(albums: albums, store: store, onTap: _tapAlbum),
          ],
        ),
      ),
    );
  }
}

Widget _heading(BuildContext context, String text) => SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  ),
);

/// One artist's albums, oldest first.
class ArtistScreen extends StatefulWidget {
  final Store store;
  final String artist;

  /// When true (adding to an expedition), tapping an album returns it.
  final bool pickMode;
  const ArtistScreen({super.key, required this.store, required this.artist, this.pickMode = false});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  SortOrder? _sort;

  @override
  Widget build(BuildContext context) {
    final own = Catalogue.byArtist(widget.artist);
    final albums = _sort == null ? own : _sort!.apply(own, widget.store);
    return Scaffold(
      appBar: AppBar(title: Text(widget.artist)),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${albums.length} ${albums.length == 1 ? 'album' : 'albums'}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    SortButton(value: _sort, onChanged: (v) => setState(() => _sort = v)),
                  ],
                ),
              ),
            ),
            SliverAlbumGrid(
              albums: albums,
              store: widget.store,
              onTap: widget.pickMode ? (a) => Navigator.of(context).pop(a) : null,
            ),
          ],
        ),
      ),
    );
  }
}
