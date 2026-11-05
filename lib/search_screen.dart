import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'actions.dart';
import 'catalogue.dart';
import 'charts.dart';
import 'design/design.dart';
import 'library_screen.dart';
import 'models.dart';
import 'nav.dart';
import 'sorting.dart';
import 'store.dart';
import 'widgets.dart';

/// How many albums each genre row shows before "See all".
const _rowLength = 20;

/// The Discover tab (opens first): search, charts and genres.
class DiscoverScreen extends StatelessWidget {
  final Store store;
  const DiscoverScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) => SearchScreen(store: store);
}

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
  bool _ratedOnly = false;
  SortOrder? _sort;
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (!widget.pickMode) tabReselects[0].addListener(_reselected);
  }

  @override
  void dispose() {
    if (!widget.pickMode) tabReselects[0].removeListener(_reselected);
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Tapping Discover while on it: scroll to the top, then (second tap) clear the search.
  void _reselected() {
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.jumpTo(0);
    } else {
      _clear();
    }
  }

  void _clear() => setState(() {
    _search.clear();
    _text = '';
    _genre = null;
    _ratedOnly = false;
    _sort = null;
  });

  void _tapAlbum(Album a) =>
      widget.pickMode ? Navigator.of(context).pop(a) : openAlbum(context, widget.store, a);

  /// Opens a page; in pick mode, an album picked there is passed back up.
  Future<void> _push(Widget page) async {
    final picked = await Navigator.of(context).push<Album>(MaterialPageRoute(builder: (_) => page));
    if (picked != null && mounted) Navigator.of(context).pop(picked);
  }

  void _openArtist(String name) => widget.pickMode
      ? _push(ArtistScreen(store: widget.store, artist: name, pickMode: true))
      : openArtist(context, name);

  void _openGenre(String genre) => widget.pickMode
      ? _push(GenreScreen(store: widget.store, genre: genre, pickMode: true))
      : openGenre(context, genre);

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final browsing = _text.trim().isEmpty && _genre == null && !_ratedOnly;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Add an album' : 'Discover'),
        // The search bar stays pinned at the top while the page scrolls.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: SearchBar(
              controller: _search,
              hintText: 'Album, artist or genre',
              leading: const Icon(Icons.search),
              trailing: [
                if (_text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                    onPressed: () => setState(() {
                      _search.clear();
                      _text = '';
                    }),
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _text = v),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final artists = _genre != null || _ratedOnly
              ? const <String>[]
              : browsing
              ? Catalogue.featuredArtists([for (final r in store.ratedAlbums) r.album.artist])
              : Catalogue.searchArtists(_text);
          return CustomScrollView(
            controller: _scroll,
            slivers: [
              // Charts, then "Rated by me", then the main genres (tap again to clear).
              SliverToBoxAdapter(
                child: SizedBox(
                  // Grows with the phone's text size so labels never clip.
                  height: 52 + MediaQuery.textScalerOf(context).scale(16) - 16,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    children: [
                      if (!widget.pickMode)
                        for (final (kind, label) in chartChips())
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              avatar: const Icon(Icons.leaderboard_outlined, size: 16),
                              label: Text(label),
                              onPressed: () => openChart(context, kind),
                            ),
                          ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: const Text('Rated by me'),
                          selected: _ratedOnly,
                          onSelected: (on) => setState(() => _ratedOnly = on),
                        ),
                      ),
                      for (final g in _genre == null ? Catalogue.families : [_genre!])
                        Padding(
                          padding: const EdgeInsets.only(right: 2),
                          child: GenreButton(
                            g,
                            selected: g == _genre,
                            onPressed: () => setState(() => _genre = g == _genre ? null : g),
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
        child: SectionHeader(
          g,
          trailing: TextButton(
            onPressed: () => _openGenre(g),
            child: Text('See all', semanticsLabel: 'See all $g'),
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
    var found = Catalogue.search(_text, genre: _genre);
    if (_ratedOnly) {
      found = found.where((a) => widget.store.ratingOf(a.id) != null).toList();
    }
    final albums = _sort == null ? found : _sort!.apply(found, widget.store);
    return [
      SliverToBoxAdapter(
        child: SectionHeader(
          'Albums',
          count: albums.length,
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.xs, 0),
          trailing: SortButton(
            value: _sort,
            defaultLabel: _text.trim().isEmpty ? 'Most popular' : 'Best match',
            onChanged: (v) => setState(() => _sort = v),
          ),
        ),
      ),
      if (albums.isEmpty)
        SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.search_off,
            message: _ratedOnly
                ? 'None of your rated albums match.'
                : 'No albums match. The library has the ${Catalogue.albums.length} most '
                      'popular albums for now.',
          ),
        ),
      SliverAlbumGrid(albums: albums, store: widget.store, onTap: _tapAlbum),
    ];
  }
}

Widget _heading(BuildContext context, String text) => SliverToBoxAdapter(
  child: SectionHeader(
    text,
    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, 0),
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
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

  /// Card width in a row: a little under the grid's, so the next card peeks in.
  static const cardWidth = 116.0;

  @override
  Widget build(BuildContext context) {
    final staged = stagesById(store);
    final stages = [for (final a in albums) staged[a.id]];
    final metrics = AlbumCardMetrics(
      textScaler: MediaQuery.textScalerOf(context),
      withStage: stages.any((d) => d != null),
    );
    return SizedBox(
      height: metrics.cardHeight(cardWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.gridPageGutter),
        itemCount: albums.length,
        separatorBuilder: (_, _) => const SizedBox(width: AlbumCardMetrics.gap),
        itemBuilder: (context, i) {
          final a = albums[i];
          return SizedBox(
            width: cardWidth,
            child: AlbumCard(
              album: a,
              rating: store.ratingOf(a.id),
              difficulty: stages[i],
              listenLater: store.isListenLater(a.id),
              onListenLater: () => toggleListenLater(context, store, a),
              onTap: () => onTap(a),
            ),
          );
        },
      ),
    );
  }
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
  void _jumpTo(int index, double width, AlbumCardMetrics metrics) {
    final layout = metrics.delegate().getLayout(
      SliverConstraints(
        axisDirection: AxisDirection.down,
        growthDirection: GrowthDirection.forward,
        userScrollDirection: ScrollDirection.idle,
        scrollOffset: 0,
        precedingScrollExtent: 0,
        overlap: 0,
        remainingPaintExtent: 0,
        crossAxisExtent: width - 2 * AppSizes.gridPageGutter,
        crossAxisDirection: AxisDirection.right,
        viewportMainAxisExtent: 0,
        remainingCacheExtent: 0,
        cacheOrigin: 0,
      ),
    ) as SliverGridRegularTileLayout;
    final offset =
        SliverAlbumGrid.topPadding + (index ~/ layout.crossAxisCount) * layout.mainAxisStride;
    _scroll.jumpTo(offset.clamp(0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final all = Catalogue.inGenre(widget.genre);
    final albums = _sort == null ? all : _sort!.apply(all, widget.store);
    final az = _sort?.by == SortBy.alphabetical;
    final staged = stagesById(widget.store);
    // Same sizes as the grid below, so a letter jumps to the right row.
    final metrics = AlbumCardMetrics(
      textScaler: MediaQuery.textScalerOf(context),
      withStage: albums.any((a) => staged[a.id] != null),
    );
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
        actions: [
          SortButton(
            value: _sort,
            defaultLabel: 'Most popular',
            onChanged: (v) => setState(() => _sort = v),
          ),
        ],
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
                            onPressed: () => _jumpTo(e.value, box.maxWidth, metrics),
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

/// Studio albums show bigger (two across on a phone), other releases smaller.
const _bigCard = 200.0;
const _smallCard = 112.0;

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

    Widget header(String text, int count, {Widget? trailing}) => SliverToBoxAdapter(
      child: SectionHeader(text, count: count, trailing: trailing),
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
        actions: [
          SortButton(
            value: _sort,
            defaultLabel: 'Oldest first',
            onChanged: (v) => setState(() => _sort = v),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) => CustomScrollView(
          slivers: [
            if (studio.isNotEmpty) ...[
              header('Studio albums', studio.length),
              SliverAlbumGrid(
                albums: studio,
                store: widget.store,
                onTap: onTap,
                maxCardWidth: _bigCard,
              ),
            ],
            for (final t in types) ...[
              header(plural(t, others[t]!.length), others[t]!.length),
              SliverAlbumGrid(
                albums: others[t]!,
                store: widget.store,
                onTap: onTap,
                maxCardWidth: _smallCard,
              ),
            ],
            if (hidden.isNotEmpty) ...[
              header(
                'Less-known releases',
                hidden.length,
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
                  maxCardWidth: _smallCard,
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
