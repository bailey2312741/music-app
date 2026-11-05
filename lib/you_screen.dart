import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'catalogue.dart';
import 'design/design.dart';
import 'details.dart';
import 'difficulty.dart';
import 'library_screen.dart';
import 'models.dart';
import 'nav.dart';
import 'profile_screen.dart';
import 'screens.dart' show appVersion;
import 'sorting.dart';
import 'store.dart';
import 'widgets.dart';

enum _Section { rated, later, reviews }

/// The You tab: nickname, Your Range, then your rated albums, Listen later
/// and reviews, with a link to the About page at the bottom.
class YouScreen extends StatefulWidget {
  final Store store;
  const YouScreen({super.key, required this.store});

  @override
  State<YouScreen> createState() => _YouScreenState();
}

class _YouScreenState extends State<YouScreen> {
  _Section _section = _Section.rated;
  SortOrder? _sort;
  bool _editingName = false;
  final _scroll = ScrollController();
  late final _name = TextEditingController(text: widget.store.nickname);

  @override
  void initState() {
    super.initState();
    tabReselects[2].addListener(_toTop);
  }

  @override
  void dispose() {
    tabReselects[2].removeListener(_toTop);
    _scroll.dispose();
    _name.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _saveName() async {
    await widget.store.setNickname(_name.text);
    setState(() => _editingName = false);
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final rated = [for (final r in store.ratedAlbums) r.album];
          final later = store.listenLater;
          final reviews = store.reviews;
          final shown = _section == _Section.later ? later : rated;
          final albums = _sort == null ? shown : _sort!.apply(shown, store);
          return CustomScrollView(
            controller: _scroll,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                sliver: SliverList.list(
                  children: [
                    _nickname(context),
                    // Real, unique usernames need online accounts, so this is a placeholder.
                    Text('@username', style: muted),
                    const SizedBox(height: 20),
                    const SectionHeader('Your Range', padding: EdgeInsets.zero),
                    Text('Up to five favourites. Harder albums stand taller.', style: muted),
                    const SizedBox(height: 12),
                    RangeSkyline(store: store),
                    const SizedBox(height: 8),
                    Text(
                      'Tap an empty slot to add one of your rated albums. '
                      'Press and hold a peak to remove it.',
                      style: muted,
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<_Section>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: _Section.rated,
                          label: Text('Rated (${rated.length})'),
                        ),
                        ButtonSegment(
                          value: _Section.later,
                          label: Text('Listen later (${later.length})'),
                        ),
                        ButtonSegment(
                          value: _Section.reviews,
                          label: Text('Reviews (${reviews.length})'),
                        ),
                      ],
                      selected: {_section},
                      onSelectionChanged: (v) => setState(() {
                        _section = v.first;
                        _sort = null;
                      }),
                    ),
                  ],
                ),
              ),
              if (_section != _Section.reviews) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _section == _Section.rated
                                ? 'Swipe an album sideways to clear its rating.'
                                : '',
                            style: muted,
                          ),
                        ),
                        SortButton(
                          value: _sort,
                          defaultLabel: _section == _Section.rated
                              ? 'Recently rated'
                              : 'Recently saved',
                          onChanged: (v) => setState(() => _sort = v),
                        ),
                      ],
                    ),
                  ),
                ),
                if (albums.isEmpty) SliverToBoxAdapter(child: _empty(context)),
                SliverAlbumGrid(
                  albums: albums,
                  store: store,
                  swipeToClear: _section == _Section.rated,
                ),
              ] else ...[
                if (reviews.isEmpty)
                  const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.rate_review_outlined,
                      message: 'Reviews you write on album and song pages show up here.',
                    ),
                  ),
                SliverList.list(
                  children: [for (final (subject, r) in reviews) _reviewTile(context, subject, r)],
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 24),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About this app'),
                    subtitle: Text('How it works · version $appVersion'),
                    onTap: () => context.push('/you/about'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _nickname(BuildContext context) {
    final theme = Theme.of(context);
    final store = widget.store;
    if (_editingName) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _name,
              autofocus: true,
              maxLength: 30,
              decoration: const InputDecoration(hintText: 'What should we call you?'),
              onSubmitted: (_) => _saveName(),
            ),
          ),
          TextButton(onPressed: _saveName, child: const Text('Save')),
        ],
      );
    }
    return Row(
      children: [
        Flexible(
          child: Text(
            store.nickname.isEmpty ? 'Your nickname' : store.nickname,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: store.nickname.isEmpty ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: 'Edit nickname',
          color: theme.colorScheme.onSurfaceVariant,
          onPressed: () => setState(() {
            _name.text = store.nickname;
            _editingName = true;
          }),
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) => EmptyState(
    icon: _section == _Section.later ? Icons.bookmark_border : Icons.album_outlined,
    message: _section == _Section.later
        ? 'Tap the bookmark on any album card to save it here.'
        : 'Albums you rate will show up here.',
    action: _section == _Section.rated
        ? OutlinedButton(onPressed: () => context.go('/discover'), child: const Text('Find albums'))
        : null,
  );

  Widget _reviewTile(BuildContext context, String subject, Review r) {
    final store = widget.store;
    final id = subject.substring(subject.indexOf(':') + 1);
    final Album? album;
    final Track? track;
    if (subject.startsWith('track:')) {
      track = store.trackInfo(id);
      album = track == null
          ? null
          : (Catalogue.byId(track.albumId) ?? store.albumById(track.albumId));
    } else {
      track = null;
      album = Catalogue.byId(id) ?? store.albumById(id);
    }
    final title =
        track?.title ?? album?.title ?? (subject.startsWith('track:') ? 'A song' : 'An album');
    return AlbumListTile(
      cover: album == null
          ? ColoredBox(
              color: AppColors.of(context).surfaceSunken,
              child: Icon(Icons.rate_review_outlined, color: AppColors.of(context).textTertiary),
            )
          : Cover(album: album),
      title: title,
      subtitle: r.text,
      subtitleLines: 2,
      onTap: album == null
          ? null
          : () => track != null
                ? openSong(context, store, album!, track)
                : openAlbum(context, store, album!),
    );
  }
}

/// Picks one of your rated albums for an empty Your Range slot, highest rated first.
class RangePickerScreen extends StatefulWidget {
  final Store store;
  final int slot;
  const RangePickerScreen({super.key, required this.store, required this.slot});

  @override
  State<RangePickerScreen> createState() => _RangePickerScreenState();
}

class _RangePickerScreenState extends State<RangePickerScreen> {
  String _text = '';

  Future<void> _pick(Album a) async {
    final store = widget.store;
    await store.unpin(a.id); // moving it from another slot
    await store.pin(a, slot: widget.slot.clamp(0, Store.rangeSize - 1));
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final q = Catalogue.norm(_text);
    final rated = [
      for (final r in store.ratedAlbums)
        if (q.isEmpty ||
            Catalogue.norm(r.album.title).contains(q) ||
            Catalogue.norm(r.album.artist).contains(q))
          r.album,
    ]..sort((a, b) => store.ratingOf(b.id)!.compareTo(store.ratingOf(a.id)!));
    return Scaffold(
      appBar: AppBar(title: const Text('Add to Your Range')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: SearchBar(
                hintText: 'Search your rated albums',
                leading: const Icon(Icons.search),
                elevation: const WidgetStatePropertyAll(0),
                onChanged: (v) => setState(() => _text = v),
              ),
            ),
          ),
          if (rated.isEmpty)
            SliverToBoxAdapter(
              child: EmptyState(
                icon: store.ratedAlbums.isEmpty ? Icons.album_outlined : Icons.search_off,
                message: store.ratedAlbums.isEmpty
                    ? 'Rate an album first, then add it here.'
                    : 'None of your rated albums match.',
              ),
            ),
          SliverAlbumGrid(albums: rated, store: store, onTap: _pick),
        ],
      ),
    );
  }
}

/// How the app works, the difficulty levels, and where the data comes from.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget heading(String text) => SectionHeader(
      text,
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.xxs),
    );
    Widget para(String text) =>
        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text));

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          heading('Difficulty levels'),
          para(
            'How much effort an album takes to get into, from easiest to hardest. '
            'It says nothing about how good the album is. Tap a difficulty on any album '
            'to see what it means.',
          ),
          for (final d in Difficulty.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: StageIcon(d.icon, size: 40),
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
            'Rate any album or song from 0 to 10 in half steps with the bar at the bottom of '
            'its page. It saves when you let go. Tap the big number to clear it, and '
            '"Undo" brings it back. In the Rated list you can also swipe an album sideways.',
          ),
          para(
            'Ratings are saved on this device only for now. The phone app and the web '
            'version keep separate ratings.',
          ),
          heading('Expeditions'),
          para(
            'A short journey through a handful of albums in a suggested order. '
            'The "Continue" card at the top of the Expeditions tab takes you to your next stop, '
            'and after rating, the bar offers the next album.',
          ),
          para(
            'Expeditions marked "In order" unlock one album at a time: rate an album to open '
            'the next. Clearing a rating never locks albums again.',
          ),
          para(
            'Make your own with the + at the top of the Expeditions tab. They are saved on '
            'this device only for now. "Reset progress" (in the menu on an expedition) starts '
            'it over without deleting your album ratings.',
          ),
          heading('Listen later and Your Range'),
          para('Tap the bookmark on any album card to save it to Listen later, on the You tab.'),
          para(
            'Your Range shows up to five favourite albums as mountain peaks. Taller peaks are '
            'harder albums. Tap an empty slot to pick one of your rated albums.',
          ),
          heading('Charts'),
          para(
            'Popular and the decade charts use ListenBrainz play counts. Top rated and Hardest '
            'only use your own ratings and the expedition albums until accounts arrive.',
          ),
          heading('Where the data comes from'),
          para(
            'The library has about 9,000 of the most listened-to albums (popularity from '
            'ListenBrainz), plus every album from Bailey\'s rankings. Album details come from '
            'MusicBrainz and covers from the Cover Art Archive. Genres outside Bailey\'s rankings '
            'are a first guess from MusicBrainz tags.',
          ),
          const SizedBox(height: 16),
          Text('Version $appVersion', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
