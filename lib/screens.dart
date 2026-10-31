import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'musicbrainz.dart';
import 'store.dart';

/// Two tabs: the expedition and search.
class HomeShell extends StatefulWidget {
  final Store store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: [
        ExpeditionScreen(store: widget.store, expedition: ambientExpedition),
        SearchScreen(store: widget.store),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.hiking), label: 'Expedition'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Search

class SearchScreen extends StatefulWidget {
  final Store store;
  const SearchScreen({super.key, required this.store});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Album> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search(String text) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await MusicBrainz.search(text);
      setState(() => _results = r);
    } catch (e) {
      setState(() => _error = 'Search failed. Check your connection and try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Album or artist',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onSubmitted: _search,
          ),
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
        Expanded(
          child: ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) => ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, i) => AlbumTile(store: widget.store, album: _results[i]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// One album row, used in search results.
class AlbumTile extends StatelessWidget {
  final Store store;
  final Album album;
  const AlbumTile({super.key, required this.store, required this.album});

  @override
  Widget build(BuildContext context) {
    final rating = store.ratingOf(album.id);
    final subtitle = [album.artist, album.year, if (album.type == 'EP') 'EP']
        .whereType<String>()
        .join(' · ');
    return ListTile(
      leading: Cover(album: album, size: 48),
      title: Text(album.title),
      subtitle: Text(subtitle),
      trailing: rating == null ? null : RatingText(rating),
      onTap: () => openAlbum(context, store, album),
    );
  }
}

// ---------------------------------------------------------------- Album

void openAlbum(BuildContext context, Store store, Album album) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => AlbumScreen(store: store, album: album),
  ));
}

class AlbumScreen extends StatefulWidget {
  final Store store;
  final Album album;
  const AlbumScreen({super.key, required this.store, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late double _draft = widget.store.ratingOf(widget.album.id) ?? 5;

  @override
  Widget build(BuildContext context) {
    final a = widget.album;
    final saved = widget.store.ratingOf(a.id);
    final difficulty = difficultyOf(widget.store, a.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Album')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(child: Cover(album: a, size: 200)),
        const SizedBox(height: 16),
        Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
        Text([a.artist, a.year].whereType<String>().join(' · ')),
        const SizedBox(height: 8),
        DifficultyTag(difficulty),
        const Divider(height: 32),
        Text(saved == null ? 'Your rating' : 'Your rating: ${fmt(saved)} / 10',
            style: Theme.of(context).textTheme.titleMedium),
        Row(children: [
          Expanded(
            child: Slider(
              value: _draft,
              min: 0,
              max: 10,
              divisions: 20,
              label: fmt(_draft),
              onChanged: (v) => setState(() => _draft = v),
            ),
          ),
          SizedBox(width: 40, child: Text(fmt(_draft), textAlign: TextAlign.end)),
        ]),
        Row(children: [
          FilledButton(
            onPressed: () async {
              await widget.store.rate(a.id, _draft);
              if (context.mounted) setState(() {});
            },
            child: Text(saved == null ? 'Save rating' : 'Update rating'),
          ),
          const SizedBox(width: 12),
          if (saved != null)
            TextButton(
              onPressed: () async {
                await widget.store.rate(a.id, null);
                if (context.mounted) setState(() {});
              },
              child: const Text('Remove'),
            ),
        ]),
      ]),
    );
  }
}

// ---------------------------------------------------------------- Expedition

class ExpeditionScreen extends StatefulWidget {
  final Store store;
  final Expedition expedition;
  const ExpeditionScreen({super.key, required this.store, required this.expedition});

  @override
  State<ExpeditionScreen> createState() => _ExpeditionScreenState();
}

class _ExpeditionScreenState extends State<ExpeditionScreen> {
  final Set<String> _failed = {};
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _resolveStops();
  }

  /// Looks up each stop on MusicBrainz once, then remembers it.
  Future<void> _resolveStops() async {
    if (_resolving) return;
    setState(() {
      _resolving = true;
      _failed.clear();
    });
    for (final s in widget.expedition.stops) {
      if (widget.store.resolvedStop(s.key) != null) continue;
      try {
        final album = await MusicBrainz.find(s.title, s.artist);
        if (album == null) {
          _failed.add(s.key);
        } else {
          await widget.store.saveResolvedStop(s.key, album);
        }
      } catch (_) {
        _failed.add(s.key);
      }
      if (mounted) setState(() {});
    }
    if (mounted) setState(() => _resolving = false);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.expedition;
    return Scaffold(
      appBar: AppBar(title: const Text('Expedition')),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final albums = e.stops.map((s) => widget.store.resolvedStop(s.key)).toList();
          bool isDone(int i) => albums[i] != null && widget.store.ratingOf(albums[i]!.id) != null;
          final done = List.generate(e.stops.length, isDone).where((d) => d).length;
          final next = List.generate(e.stops.length, (i) => i).where((i) => !isDone(i)).firstOrNull;

          return ListView(padding: const EdgeInsets.all(16), children: [
            Text(e.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(e.blurb),
            const SizedBox(height: 16),
            Text(done == e.stops.length ? 'Expedition complete!' : '$done of ${e.stops.length} rated'),
            const SizedBox(height: 6),
            LinearProgressIndicator(value: done / e.stops.length),
            const SizedBox(height: 16),
            for (var i = 0; i < e.stops.length; i++)
              _StopTile(
                number: i + 1,
                stop: e.stops[i],
                album: albums[i],
                rating: albums[i] == null ? null : widget.store.ratingOf(albums[i]!.id),
                isNext: i == next,
                failed: _failed.contains(e.stops[i].key),
                onTap: albums[i] == null
                    ? (_resolving ? null : _resolveStops)
                    : () => openAlbum(context, widget.store, albums[i]!),
              ),
          ]);
        },
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  final int number;
  final ExpeditionStop stop;
  final Album? album;
  final double? rating;
  final bool isNext;
  final bool failed;
  final VoidCallback? onTap;

  const _StopTile({
    required this.number,
    required this.stop,
    required this.album,
    required this.rating,
    required this.isNext,
    required this.failed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = album == null
        ? (failed ? 'Couldn\'t load. Tap to retry.' : 'Loading…')
        : null;
    return Card(
      color: isNext ? scheme.primaryContainer : null,
      child: ListTile(
        leading: rating != null
            ? const Icon(Icons.check_circle)
            : CircleAvatar(radius: 14, child: Text('$number')),
        title: Text(stop.title),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text([stop.artist, album?.year].whereType<String>().join(' · ')),
          const SizedBox(height: 4),
          if (isNext) const Text('Next stop', style: TextStyle(fontWeight: FontWeight.bold)),
          if (status != null) Text(status),
          DifficultyTag(stop.difficulty),
        ]),
        trailing: rating == null ? null : RatingText(rating!),
        onTap: onTap,
      ),
    );
  }
}

// ---------------------------------------------------------------- Shared bits

String fmt(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

class RatingText extends StatelessWidget {
  final double rating;
  const RatingText(this.rating, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(fmt(rating), style: Theme.of(context).textTheme.titleMedium);
}

class Cover extends StatelessWidget {
  final Album album;
  final double size;
  const Cover({super.key, required this.album, required this.size});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(Icons.album, size: size / 2),
    );
    return Image.network(
      album.coverUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => placeholder,
      loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
    );
  }
}
