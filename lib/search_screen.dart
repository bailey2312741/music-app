import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'actions.dart';
import 'catalogue.dart';
import 'expeditions.dart';
import 'models.dart';
import 'screens.dart';
import 'sorting.dart';
import 'store.dart';
import 'widgets.dart';

/// How many albums each genre row shows before "See all".
const _rowLength = 20;

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

  /// Opens a page; in pick mode, an album picked there is passed back up.
  Future<void> _push(Widget page) async {
    final picked = await Navigator.of(context).push<Album>(MaterialPageRoute(builder: (_) => page));
    if (picked != null && mounted) Navigator.of(context).pop(picked);
  }

  void _openArtist(String name) =>
      _push(ArtistScreen(store: widget.store, artist: name, pickMode: widget.pickMode));

  void _openGenre(String genre) =>
      _push(GenreScreen(store: widget.store, genre: genre, pickMode: widget.pickMode));

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final browsing = _text.trim().isEmpty && _genre == null;

    return Scaffold(
      appBar: widget.pickMode
          ? AppBar(title: const Text('Add an album'))
          : AppBar(title: const Text('Search'), actions: cornerActions(store)),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final artists = _genre != null
              ? const <String>[]
              : browsing
              ? Catalogue.featuredArtists([for (final r in store.ratedAlbums) r.album.artist])
              : Catalogue.searchArtists(_text);
          return CustomScrollView(
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
              // Genre filter: tap a main genre to show only that genre, tap again to clear.
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    children: [
                      for (final g in _genre == null ? Catalogue.families : [_genre!])
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
                _heading(context, 'Artists'),
                SliverToBoxAdapter(
                  child: _ArtistRow(artists: artists, onTap: _openArtist),
                ),
              ],
              if (browsing) ..._genreRows(context) else ..._results(context),
            ],
          );
        },
      ),
    );
  }

  /// Browse: one sideways row per main genre, most popular first.
  List<Widget> _genreRows(BuildContext context) => [
    for (final g in Catalogue.families) ...[
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
          child: Row(
            children: [
              Expanded(child: Text(g, style: Theme.of(context).textTheme.titleMedium)),
              TextButton(onPressed: () => _openGenre(g), child: const Text('See all')),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: AlbumRow(
          albums: Catalogue.inGenre(g).take(_rowLength).toList(),
          store: widget.store,
          onTap: _tapAlbum,
        ),
      ),
    ],
    const SliverToBoxAdapter(child: SizedBox(height: 16)),
  ];

  /// Search results (or one genre) as a grid.
  List<Widget> _results(BuildContext context) {
    final found = Catalogue.search(_text, genre: _genre);
    final albums = _sort == null ? found : _sort!.apply(found, widget.store);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Albums (${albums.length})',
                  style: Theme.of(context).textTheme.titleSmall,
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
              'No albums match. The library has the ${Catalogue.albums.length} most '
              'popular albums for now.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      SliverAlbumGrid(albums: albums, store: widget.store, onTap: _tapAlbum),
    ];
  }
}

Widget _heading(BuildContext context, String text) => SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  ),
);

/// A sideways row of artist cards.
class _ArtistRow extends StatelessWidget {
  final List<String> artists;
  final void Function(String) onTap;
  const _ArtistRow({required this.artists, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 110,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) => ArtistCard(
        artist: artists[i],
        image: Catalogue.artistImage(artists[i]),
        albumCount: Catalogue.byArtist(artists[i]).length,
        onTap: () => onTap(artists[i]),
      ),
    ),
  );
}

/// A sideways row of album cards, the same size as in the grids.
class AlbumRow extends StatelessWidget {
  final List<Album> albums;
  final Store store;
  final void Function(Album) onTap;
  const AlbumRow({super.key, required this.albums, required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 214,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      itemCount: albums.length,
      itemExtent: 130,
      itemBuilder: (context, i) {
        final a = albums[i];
        return AlbumCard(
          album: a,
          rating: store.ratingOf(a.id),
          difficulty: difficultyOf(store, a.id),
          listenLater: store.isListenLater(a.id),
          onListenLater: () => toggleListenLater(context, store, a),
          onTap: () => onTap(a),
        );
      },
    ),
  );
}

/// Every album in one genre: most popular first, or A to Z with a letter
/// index to jump through the list.
class GenreScreen extends StatefulWidget {
  final Store store;
  final String genre;
  final bool pickMode;
  const GenreScreen({super.key, required this.store, required this.genre, this.pickMode = false});

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  SortOrder? _sort;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  static String _letter(Album a) {
    final n = Catalogue.norm(a.title); // same order as the A to Z sort
    final c = n.isEmpty ? '#' : n[0].toUpperCase();
    return RegExp('[A-Z]').hasMatch(c) ? c : '#';
  }

  /// Scrolls the grid so the album at [index] is at the top.
  void _jumpTo(int index, double width) {
    final layout = albumGridDelegate.getLayout(
      SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0,
        precedingScrollExtent: 0,
        overlap: 0,
        remainingPaintExtent: 0,
        crossAxisExtent: width - 20, // grid side padding
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 0,
        remainingCacheExtent: 0,
        cacheOrigin: 0,
      ),
    ) as SliverGridRegularTileLayout;
    final offset = 4 + (index ~/ layout.crossAxisCount) * layout.mainAxisStride;
    _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final all = Catalogue.inGenre(widget.genre);
    final albums = _sort == null ? all : _sort!.apply(all, widget.store);
    final az = _sort?.by == SortBy.alphabetical;
    // First position of each letter (A to Z order, or Z to A when reversed).
    final firstOf = <String, int>{};
    if (az) {
      for (var i = 0; i < albums.length; i++) {
        firstOf.putIfAbsent(_letter(albums[i]), () => i);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.genre),
        actions: [SortButton(value: _sort, onChanged: (v) => setState(() => _sort = v))],
        bottom: az
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: LayoutBuilder(
                  builder: (context, box) => SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      children: [
                        for (final e in firstOf.entries)
                          TextButton(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _jumpTo(e.value, box.maxWidth),
                            child: Text(e.key),
                          ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) => CustomScrollView(
          controller: _scroll,
          slivers: [
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

/// One artist's albums: studio albums first, oldest to newest and shown
/// bigger, then every other kind of release below, smaller.
class ArtistScreen extends StatefulWidget {
  final Store store;
  final String artist;

  /// When true (adding to an expedition), tapping an album returns it.
  final bool pickMode;
  const ArtistScreen({super.key, required this.store, required this.artist, this.pickMode = false});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

/// Order of the sections below the studio albums.
const _otherTypes = ['EP', 'Mixtape', 'Live', 'Soundtrack', 'Remix', 'Compilation'];

const _bigGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 200,
  childAspectRatio: 0.66,
  crossAxisSpacing: 6,
  mainAxisSpacing: 6,
);

const _smallGrid = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 112,
  childAspectRatio: 0.56,
  crossAxisSpacing: 2,
  mainAxisSpacing: 2,
);

class _ArtistScreenState extends State<ArtistScreen> {
  SortOrder? _sort;
  bool _showMinor = false;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final all = Catalogue.byArtist(widget.artist); // oldest first
    // Releases far less played than the artist's best known album (often
    // regional editions or archive releases) are tucked away at the bottom.
    // Albums from Bailey's sheet (no play count) and rated ones always show.
    final top = all.fold<int>(0, (m, a) => a.popularity > m ? a.popularity : m);
    bool minor(Album a) =>
        a.popularity > 0 && a.popularity < top * 0.01 && store.ratingOf(a.id) == null;
    final own = all.where((a) => !minor(a)).toList();
    final hidden = all.where(minor).toList();
    final albums = _sort == null ? own : _sort!.apply(own, store);
    bool isStudio(Album a) => a.type == null || a.type == 'Studio';
    final studio = albums.where(isStudio).toList();
    final others = <String, List<Album>>{};
    for (final a in albums.where((a) => !isStudio(a))) {
      (others[a.type!] ??= []).add(a);
    }
    final types = others.keys.toList()
      ..sort((a, b) {
        int i(String t) => _otherTypes.contains(t) ? _otherTypes.indexOf(t) : 99;
        return i(a).compareTo(i(b));
      });
    final onTap = widget.pickMode ? (Album a) => Navigator.of(context).pop(a) : null;
    final theme = Theme.of(context);

    Widget header(String text, {Widget? trailing}) => SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 2),
        child: Row(
          children: [
            Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
            ?trailing,
          ],
        ),
      ),
    );

    String plural(String type, int n) => switch (type) {
      'Live' => 'Live albums',
      'Remix' => 'Remix albums',
      _ => n == 1 ? type : '${type}s',
    };

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ArtistAvatar(image: Catalogue.artistImage(widget.artist), size: 32),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.artist, overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [SortButton(value: _sort, onChanged: (v) => setState(() => _sort = v))],
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) => CustomScrollView(
          slivers: [
            if (studio.isNotEmpty) ...[
              header('Studio albums (${studio.length})'),
              SliverAlbumGrid(
                albums: studio,
                store: widget.store,
                onTap: onTap,
                delegate: _bigGrid,
              ),
            ],
            for (final t in types) ...[
              header('${plural(t, others[t]!.length)} (${others[t]!.length})'),
              SliverAlbumGrid(
                albums: others[t]!,
                store: widget.store,
                onTap: onTap,
                delegate: _smallGrid,
              ),
            ],
            if (hidden.isNotEmpty) ...[
              header(
                'Less-known releases (${hidden.length})',
                trailing: TextButton(
                  onPressed: () => setState(() => _showMinor = !_showMinor),
                  child: Text(_showMinor ? 'Hide' : 'Show'),
                ),
              ),
              if (_showMinor)
                SliverAlbumGrid(
                  albums: _sort == null ? hidden : _sort!.apply(hidden, store),
                  store: store,
                  onTap: onTap,
                  delegate: _smallGrid,
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
