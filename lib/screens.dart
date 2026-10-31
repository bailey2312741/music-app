import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'musicbrainz.dart';
import 'store.dart';
import 'widgets.dart';

export 'widgets.dart' show fmt;

const appVersion = '0.3';

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
            'The highlighted card is your next stop.',
          ),
          para(
            'Expeditions marked "In order" unlock one album at a time: rate an album to open '
            'the next. Others can be taken in any order.',
          ),
          para(
            'Make your own with "New expedition" on the Expeditions tab. They are saved on '
            'this device only for now.',
          ),
          para('An album counts as done once you rate it, wherever you rate it from.'),
          heading('Where the data comes from'),
          para(
            'Album details come from MusicBrainz and covers from the Cover Art Archive, '
            'both free and community-run. Search leaves out singles, compilations and live albums.',
          ),
          const SizedBox(height: 16),
          Text('Version $appVersion', style: theme.textTheme.bodySmall),
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
              difficulty: difficultyOf(store, rated[i].album.id),
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

  /// When true, tapping an album returns it instead of opening it.
  final bool pickMode;
  const SearchScreen({super.key, required this.store, this.pickMode = false});

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
      appBar: widget.pickMode
          ? AppBar(title: const Text('Add an album'))
          : AppBar(title: const Text('Search'), actions: const [InfoButton()]),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Expeditions'), actions: const [InfoButton()]),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New expedition'),
        onPressed: () =>
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => CreateExpeditionScreen(store: store))),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final custom = store.customExpeditions;
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
            children: [
              for (final e in builtInExpeditions) _ExpeditionTile(store: store, expedition: e),
              if (custom.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
                  child: Text('Your expeditions', style: Theme.of(context).textTheme.titleMedium),
                ),
              for (final e in custom) _ExpeditionTile(store: store, expedition: e),
            ],
          );
        },
      ),
    );
  }
}

class _ExpeditionTile extends StatelessWidget {
  final Store store;
  final Expedition expedition;
  const _ExpeditionTile({required this.store, required this.expedition});

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    final theme = Theme.of(context);
    final done = ratedCount(store, e);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ExpeditionScreen(store: store, expedition: e),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExpeditionCover(albums: [for (final s in e.stops) albumFor(store, s)]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name, style: theme.textTheme.titleMedium),
                    if (e.blurb.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        e.blurb,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (e.inOrder) ...[
                          Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text('In order', style: theme.textTheme.labelSmall),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: LinearProgressIndicator(
                            value: done / e.stops.length,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('$done of ${e.stops.length}', style: theme.textTheme.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpeditionScreen extends StatelessWidget {
  final Store store;
  final Expedition expedition;
  const ExpeditionScreen({super.key, required this.store, required this.expedition});

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete this expedition?'),
        content: const Text('Your album ratings are kept.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await store.deleteExpedition(expedition.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = expedition;
    return Scaffold(
      appBar: AppBar(
        title: Text(e.name),
        actions: [
          if (e.custom)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete expedition',
              onPressed: () => _delete(context),
            ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([store, StopResolver.failed, StopResolver.running]),
        builder: (context, _) {
          final done = ratedCount(store, e);
          final open = unlockedCount(store, e);
          final next = nextStop(store, e);

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (e.blurb.isNotEmpty) Text(e.blurb),
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
                  final album = albumFor(store, stop);
                  final locked = i >= open;
                  final failed = StopResolver.failed.value.contains(stop.key);
                  return AlbumCard(
                    // Until the stop is found, show its title and artist with a blank cover.
                    album: album ?? Album(id: '', title: stop.title, artist: stop.artist),
                    number: i + 1,
                    difficulty: stop.difficulty,
                    rating: album == null ? null : store.ratingOf(album.id),
                    locked: locked,
                    highlight: i == next,
                    caption: locked
                        ? null
                        : album == null
                        ? (failed ? 'Tap to retry' : 'Loading…')
                        : (i == next ? 'Next stop' : null),
                    onTap: locked
                        ? () => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Rate album $open first to unlock this one.'),
                              duration: const Duration(seconds: 2),
                            ),
                          )
                        : album == null
                        ? (StopResolver.running.value ? null : () => StopResolver.resolveAll(store))
                        : () => openAlbum(context, store, album),
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

// ---------------------------------------------------------------- Create expedition

class CreateExpeditionScreen extends StatefulWidget {
  final Store store;
  const CreateExpeditionScreen({super.key, required this.store});

  @override
  State<CreateExpeditionScreen> createState() => _CreateExpeditionScreenState();
}

class _CreateExpeditionScreenState extends State<CreateExpeditionScreen> {
  final _name = TextEditingController();
  final _blurb = TextEditingController();
  final List<Album> _albums = [];
  bool _inOrder = false;

  bool get _canSave => _name.text.trim().isNotEmpty && _albums.length >= 2;

  Future<void> _addAlbum() async {
    final album = await Navigator.of(context).push<Album>(
      MaterialPageRoute(builder: (_) => SearchScreen(store: widget.store, pickMode: true)),
    );
    if (album == null || !mounted) return;
    if (_albums.any((a) => a.id == album.id)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('That album is already in this expedition.')));
      return;
    }
    setState(() => _albums.add(album));
  }

  void _sortByYear() =>
      setState(() => _albums.sort((a, b) => (a.year ?? '9999').compareTo(b.year ?? '9999')));

  Future<void> _save() async {
    await widget.store.saveExpedition(
      Expedition(
        DateTime.now().millisecondsSinceEpoch.toString(),
        _name.text.trim(),
        _blurb.text.trim(),
        [for (final a in _albums) ExpeditionStop.ofAlbum(a)],
        inOrder: _inOrder,
        custom: true,
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _name.dispose();
    _blurb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('New expedition'),
        actions: [TextButton(onPressed: _canSave ? _save : null, child: const Text('Save'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _blurb,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Listen in order'),
            subtitle: const Text('Each album unlocks after you rate the one before it.'),
            value: _inOrder,
            onChanged: (v) => setState(() => _inOrder = v),
          ),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text('Albums (${_albums.length})', style: theme.textTheme.titleMedium),
              ),
              if (_albums.length > 1)
                TextButton.icon(
                  onPressed: _sortByYear,
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort by year'),
                ),
            ],
          ),
          if (_albums.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Add at least two albums. Drag to reorder.'),
            ),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            onReorderItem: (from, to) => setState(() => _albums.insert(to, _albums.removeAt(from))),
            children: [
              for (var i = 0; i < _albums.length; i++)
                ListTile(
                  key: ValueKey(_albums[i].id),
                  contentPadding: EdgeInsets.zero,
                  leading: Cover(album: _albums[i], size: 44, radius: 4),
                  title: Text(
                    '${i + 1}. ${_albums[i].title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [_albums[i].artist, _albums[i].year].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Remove',
                        onPressed: () => setState(() => _albums.removeAt(i)),
                      ),
                      ReorderableDragStartListener(index: i, child: const Icon(Icons.drag_handle)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _addAlbum,
            icon: const Icon(Icons.add),
            label: const Text('Add album'),
          ),
        ],
      ),
    );
  }
}
