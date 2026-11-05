import 'dart:math' as math;

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
  bool _allArtists = false;
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
    _allArtists = false;
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

  /// Search results show this many artists until "Show all" is tapped.
  static const _artistPreview = 3;

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final browsing = _text.trim().isEmpty && _genre == null && !_ratedOnly;
    final scaler = MediaQuery.textScalerOf(context);
    // The 52 px field grows with the phone's text size so the text never clips.
    final fieldHeight = math.max(AppSizes.searchFieldHeight, scaler.scale(22) + 30);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pickMode ? 'Add an album' : 'Discover'),
        // The search field stays pinned at the top while the page scrolls.
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(fieldHeight + AppSpace.sm),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
            child: SearchBar(
              controller: _search,
              hintText: 'Search albums, artists or genres',
              leading: const Icon(Icons.search),
              trailing: [
                if (_text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                    onPressed: () => setState(() {
                      _search.clear();
                      _text = '';
                      _allArtists = false;
                    }),
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() {
                _text = v;
                _allArtists = false;
              }),
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
              SliverToBoxAdapter(child: _filters()),
              if (browsing) ...[
                if (!widget.pickMode) ..._charts(context),
                if (artists.isNotEmpty) ...[
                  SliverToBoxAdapter(child: _header('Featured artists')),
                  SliverToBoxAdapter(
                    child: _ArtistRow(artists: artists, onTap: _openArtist),
                  ),
                ],
                ..._genreRows(context),
              ] else ...[
                if (artists.isNotEmpty) ..._artistResults(artists),
                ..._results(context),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.lg)),
            ],
          );
        },
      ),
    );
  }

  /// "Rated by me" and the main genres, under the search field in every
  /// state, so a filter stays where it was tapped. Tap a genre again to clear.
  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: Row(
      children: [
        FilterChip(
          label: const Text('Rated by me'),
          selected: _ratedOnly,
          onSelected: (on) => setState(() => _ratedOnly = on),
        ),
        const SizedBox(width: AppSpace.sm),
        for (final g in Catalogue.families) ...[
          GenreButton(
            g,
            selected: g == _genre,
            onPressed: () => setState(() => _genre = g == _genre ? null : g),
          ),
          const SizedBox(width: AppSpace.xs),
        ],
      ],
    ),
  );

  /// The three charts, then one button per decade.
  List<Widget> _charts(BuildContext context) {
    final decades = chartChips().where((c) => int.tryParse(c.$1) != null);
    return [
      SliverToBoxAdapter(child: _header('Charts')),
      const SliverToBoxAdapter(child: _ChartButtons()),
      SliverToBoxAdapter(child: _header('By decade')),
      SliverToBoxAdapter(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Row(
            children: [
              for (final (kind, label) in decades) ...[
                OutlinedButton(
                  onPressed: () => openChart(context, kind),
                  child: Text(label, semanticsLabel: 'The $label chart'),
                ),
                const SizedBox(width: AppSpace.sm),
              ],
            ],
          ),
        ),
      ),
    ];
  }

  /// Browse: one sideways row per main genre, most popular first.
  List<Widget> _genreRows(BuildContext context) => [
    for (final g in Catalogue.families) ...[
      SliverToBoxAdapter(
        child: _header(
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
  ];

  /// Artists matching the search, as list rows: the first few, then all.
  List<Widget> _artistResults(List<String> artists) {
    final shown = _allArtists ? artists : artists.take(_artistPreview).toList();
    return [
      SliverToBoxAdapter(child: _header('Artists', count: artists.length)),
      SliverList.builder(
        itemCount: shown.length,
        itemBuilder: (context, i) => _ArtistTile(artist: shown[i], onTap: _openArtist),
      ),
      if (shown.length < artists.length)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _allArtists = true),
                child: Text('Show all ${artists.length} artists'),
              ),
            ),
          ),
        ),
    ];
  }

  /// Search results (or one genre, or your rated albums) as a grid.
  List<Widget> _results(BuildContext context) {
    var found = Catalogue.search(_text, genre: _genre);
    if (_ratedOnly) {
      found = found.where((a) => widget.store.ratingOf(a.id) != null).toList();
    }
    final albums = _sort == null ? found : _sort!.apply(found, widget.store);
    return [
      SliverToBoxAdapter(
        child: _header(
          'Albums',
          count: albums.length,
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

/// Every Discover section heading: the same gutter and spacing everywhere.
/// A trailing button brings its own padding, so the right edge is tighter.
Widget _header(String text, {int? count, Widget? trailing}) => SectionHeader(
  text,
  count: count,
  trailing: trailing,
  padding: EdgeInsets.fromLTRB(
    AppSpace.gutter,
    AppSpace.md,
    trailing == null ? AppSpace.gutter : AppSpace.xs,
    0,
  ),
);

/// Popular, Top rated and Hardest: one even row, icon above label, when all
/// three fit; otherwise ordinary buttons that wrap (very large text).
class _ChartButtons extends StatelessWidget {
  const _ChartButtons();

  static const _charts = [
    ('popular', 'Popular', Icons.trending_up),
    ('top', 'Top rated', Icons.star_outline),
    ('hardest', 'Hardest', Icons.landscape_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelLarge;
    final scaler = MediaQuery.textScalerOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: LayoutBuilder(
        builder: (context, box) {
          // The widest label decides: every button gets a third of the row.
          var widest = 0.0;
          for (final c in _charts) {
            final painter = TextPainter(
              text: TextSpan(text: c.$2, style: style),
              textScaler: scaler,
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            widest = math.max(widest, painter.width);
          }
          final third = (box.maxWidth - 2 * AppSpace.sm) / 3;
          if (widest + 2 * AppSpace.md + 2 <= third) {
            return Row(
              children: [
                for (final (i, c) in _charts.indexed) ...[
                  if (i > 0) const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.md,
                          vertical: AppSpace.sm,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.card),
                        ),
                      ),
                      onPressed: () => openChart(context, c.$1),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(c.$3, size: AppIconSizes.regular),
                          const SizedBox(height: AppSpace.xs),
                          Text(c.$2, maxLines: 1, softWrap: false),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            );
          }
          return Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final c in _charts)
                OutlinedButton.icon(
                  icon: Icon(c.$3, size: AppIconSizes.regular),
                  label: Text(c.$2),
                  onPressed: () => openChart(context, c.$1),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// A sideways row of artist cards; as tall as its cards, at any text size.
class _ArtistRow extends StatelessWidget {
  final List<String> artists;
  final void Function(String) onTap;
  const _ArtistRow({required this.artists, required this.onTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: ArtistCard.heightFor(MediaQuery.textScalerOf(context)),
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      itemCount: artists.length,
      separatorBuilder: (_, _) => const SizedBox(width: AlbumCardMetrics.gap),
      itemBuilder: (context, i) => ArtistCard(
        artist: artists[i],
        image: Catalogue.artistImage(artists[i]),
        albumCount: Catalogue.byArtist(artists[i]).length,
        onTap: () => onTap(artists[i]),
      ),
    ),
  );
}

/// One artist in search results: picture, name and album count.
class _ArtistTile extends StatelessWidget {
  final String artist;
  final void Function(String) onTap;
  const _ArtistTile({required this.artist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final n = Catalogue.byArtist(artist).length;
    return AlbumListTile(
      cover: ArtistAvatar(image: Catalogue.artistImage(artist), size: 56),
      title: artist,
      subtitle: 'Artist · $n ${n == 1 ? 'album' : 'albums'}',
      trailing: Icon(Icons.chevron_right, color: AppColors.of(context).textSecondary),
      onTap: () => onTap(artist),
    );
  }
}

/// A sideways row of album cards, the same size as in the grids.
class AlbumRow extends StatelessWidget {
  final List<Album> albums;
  final Store store;
  final void Function(Album) onTap;
  const AlbumRow({super.key, required this.albums, required this.store, required this.onTap});

  /// Card width in a row: a little under the grid's, so the next card peeks
  /// in. Wider with large text, so titles wrap between words, not inside them.
  static double cardWidthFor(TextScaler scaler) =>
      AlbumCardMetrics(textScaler: scaler).largeText ? AppCoverSizes.lg : 116.0;

  @override
  Widget build(BuildContext context) {
    final staged = stagesById(store);
    final stages = [for (final a in albums) staged[a.id]];
    final metrics = AlbumCardMetrics(
      textScaler: MediaQuery.textScalerOf(context),
      withStage: stages.any((d) => d != null),
    );
    final cardWidth = cardWidthFor(MediaQuery.textScalerOf(context));
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
  final _headerKey = GlobalKey();

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
    final header = _headerKey.currentContext?.size?.height ?? 0;
    final offset =
        header +
        SliverAlbumGrid.topPadding +
        (index ~/ layout.crossAxisCount) * layout.mainAxisStride;
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
    final c = AppColors.of(context);
    // The letter strip stays 48 tall, or grows with large text.
    final stripHeight = math.max(
      AppSizes.touchMin,
      MediaQuery.textScalerOf(context).scale(AppType.cardTitle.fontSize!) + AppSpace.xl,
    );
    return Scaffold(
      appBar: AppBar(
        actions: [
          SortButton(
            value: _sort,
            defaultLabel: 'Most popular',
            onChanged: (v) => setState(() => _sort = v),
          ),
        ],
        bottom: az
            ? PreferredSize(
                preferredSize: Size.fromHeight(stripHeight),
                child: LayoutBuilder(
                  builder: (context, box) => Semantics(
                    label: 'Jump to letter',
                    container: true,
                    child: SizedBox(
                      height: stripHeight,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                        children: [
                          for (final e in firstOf.entries)
                            TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(AppSizes.touchMin, AppSizes.touchMin),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                                foregroundColor: c.textPrimary,
                                textStyle: AppType.cardTitle,
                              ),
                              onPressed: () => _jumpTo(e.value, box.maxWidth, metrics),
                              child: Text(e.key, semanticsLabel: 'Jump to ${e.key}'),
                            ),
                        ],
                      ),
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
            SliverToBoxAdapter(
              child: PageHeader(
                widget.genre,
                key: _headerKey,
                subtitle: albums.length == 1 ? '1 album' : '${albums.length} albums',
              ),
            ),
            if (albums.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.album_outlined,
                  message: 'No albums in this genre yet.',
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

/// One artist's albums: studio albums first, oldest to newest, then every
/// other kind of release in its own section below.
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
    final image = Catalogue.artistImage(widget.artist);

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
            SliverToBoxAdapter(
              child: PageHeader(
                widget.artist,
                leading: image == null
                    ? null
                    : ExcludeSemantics(
                        child: ArtistAvatar(image: image, size: AppCoverSizes.sm),
                      ),
              ),
            ),
            if (studio.isNotEmpty) ...[
              header('Studio albums', studio.length),
              SliverAlbumGrid(albums: studio, store: widget.store, onTap: onTap),
            ],
            for (final t in types) ...[
              header(plural(t, others[t]!.length), others[t]!.length),
              SliverAlbumGrid(albums: others[t]!, store: widget.store, onTap: onTap),
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
                ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AppSpace.section)),
          ],
        ),
      ),
    );
  }
}
