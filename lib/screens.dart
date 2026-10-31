import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'musicbrainz.dart';
import 'store.dart';
import 'widgets.dart';

export 'widgets.dart' show fmt;

/// Three tabs: Ratings, Search (opens first) and Expeditions.
class HomeShell extends StatefulWidget {
  final Store store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          RatingsScreen(store: widget.store),
          SearchScreen(store: widget.store),
          ExpeditionListScreen(store: widget.store),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.star_outline),
            selectedIcon: Icon(Icons.star),
            label: 'Ratings',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.hiking), label: 'Expeditions'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Info

/// App-bar button that opens the temporary info page.
class InfoButton extends StatelessWidget {
  const InfoButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.info_outline),
    tooltip: 'How it works',
    onPressed: () =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const InfoScreen())),
  );
}

/// Temporary reference page: difficulty levels and how the app works.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 8),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    );
    Widget para(String text) =>
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text));

    return Scaffold(
      appBar: AppBar(title: const Text('How it works')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          heading('Difficulty levels'),
          para(
            'How much effort an album takes to get into, from easiest to hardest. '
            'It says nothing about how good the album is.',
          ),
          for (final d in Difficulty.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(d.icon),
              title: Text(d.label),
              subtitle: Text(d.description),
            ),
          para(
            'Albums without enough information show no difficulty. '
            'For now the levels are set by hand on expedition albums only; '
            'AI scoring comes later.',
          ),
          heading('Ratings'),
          para(
            'Rate any album from 0 to 10 in half steps. Your rating is about quality, '
            'kept completely separate from difficulty.',
          ),
          para(
            'Ratings are saved on this device only for now. The phone app and the web '
            'version keep separate ratings.',
          ),
          heading('Expeditions'),
          para(
            'A short journey through a handful of albums in a suggested order. '
            'The highlighted card is your next stop, but you can go in any order.',
          ),
          para('An album counts as done once you rate it, wherever you rate it from.'),
          heading('Where the data comes from'),
          para(
            'Album details come from MusicBrainz and covers from the Cover Art Archive, '
            'both free and community-run. Search leaves out singles, compilations and live albums.',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Ratings

class RatingsScreen extends StatelessWidget {
  final Store store;
  const RatingsScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your ratings'), actions: const [InfoButton()]),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final rated = store.ratedAlbums;
          if (rated.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Albums you rate will show up here.', textAlign: TextAlign.center),
              ),
            );
          }
          return AlbumGrid(
            itemCount: rated.length,
            itemBuilder: (context, i) => AlbumCard(
              album: rated[i].album,
              rating: rated[i].rating,
              onTap: () => openAlbum(context, store, rated[i].album),
            ),
          );
        },
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
      appBar: AppBar(title: const Text('Search'), actions: const [InfoButton()]),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: SearchBar(
              hintText: 'Album or artist',
              leading: const Icon(Icons.search),
              textInputAction: TextInputAction.search,
              elevation: const WidgetStatePropertyAll(0),
              onSubmitted: _search,
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) => AlbumGrid(
                itemCount: _results.length,
                itemBuilder: (context, i) => AlbumCard(
                  album: _results[i],
                  rating: widget.store.ratingOf(_results[i].id),
                  onTap: () => openAlbum(context, widget.store, _results[i]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Album

void openAlbum(BuildContext context, Store store, Album album) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AlbumScreen(store: store, album: album),
    ),
  );
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

  Future<void> _save(double? score) async {
    await widget.store.rate(widget.album, score);
    if (!mounted) return;
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(score == null ? 'Rating removed' : 'Rated ${fmt(score)} / 10'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.album;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final saved = widget.store.ratingOf(a.id);
    final difficulty = difficultyOf(widget.store, a.id);
    final meta = [a.year, a.type].whereType<String>().join(' · ');

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Cover(album: a, radius: 12),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            a.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(a.artist, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          if (meta.isNotEmpty)
            Text(
              meta,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          if (difficulty != null) ...[
            const SizedBox(height: 12),
            Center(child: DifficultyTag(difficulty)),
          ],
          const SizedBox(height: 20),
          const Divider(height: 32),
          Padding(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Text(
                  saved == null ? 'Your rating' : 'Your rating · saved',
                  style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
                Text(fmt(_draft), style: theme.textTheme.headlineLarge),
                Slider(
                  value: _draft,
                  min: 0,
                  max: 10,
                  divisions: 20,
                  label: fmt(_draft),
                  onChanged: (v) => setState(() => _draft = v),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: saved == _draft ? null : () => _save(_draft),
                    child: Text(saved == null ? 'Save rating' : 'Update rating'),
                  ),
                ),
                if (saved != null)
                  TextButton(onPressed: () => _save(null), child: const Text('Remove rating')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Expeditions

class ExpeditionListScreen extends StatelessWidget {
  final Store store;
  const ExpeditionListScreen({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Expeditions'), actions: const [InfoButton()]),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(12),
          children: [
            for (final e in expeditions)
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpeditionScreen(store: store, expedition: e),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(e.name, style: theme.textTheme.titleLarge)),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(e.blurb),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: ratedCount(store, e) / e.stops.length,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('${ratedCount(store, e)} of ${e.stops.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
      appBar: AppBar(title: Text(e.name)),
      body: ListenableBuilder(
        listenable: widget.store,
        builder: (context, _) {
          final albums = e.stops.map((s) => widget.store.resolvedStop(s.key)).toList();
          double? ratingAt(int i) =>
              albums[i] == null ? null : widget.store.ratingOf(albums[i]!.id);
          final done = ratedCount(widget.store, e);
          final next = List.generate(
            e.stops.length,
            (i) => i,
          ).where((i) => ratingAt(i) == null).firstOrNull;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.blurb),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: done / e.stops.length,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          done == e.stops.length ? 'Complete!' : '$done of ${e.stops.length} rated',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AlbumGrid(
                shrinkWrap: true,
                itemCount: e.stops.length,
                itemBuilder: (context, i) {
                  final stop = e.stops[i];
                  final album = albums[i];
                  final failed = _failed.contains(stop.key);
                  return AlbumCard(
                    // Until the stop is found, show its title and artist with a blank cover.
                    album: album ?? Album(id: '', title: stop.title, artist: stop.artist),
                    number: i + 1,
                    difficulty: stop.difficulty,
                    rating: ratingAt(i),
                    highlight: i == next,
                    caption: album == null
                        ? (failed ? 'Tap to retry' : 'Loading…')
                        : (i == next ? 'Next stop' : null),
                    onTap: album == null
                        ? (_resolving ? null : _resolveStops)
                        : () => openAlbum(context, widget.store, album),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
