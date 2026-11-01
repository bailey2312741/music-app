import 'package:flutter/material.dart';

import 'difficulty.dart';
import 'expedition_screens.dart';
import 'library_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'store.dart';

export 'album_screen.dart';
export 'expedition_screens.dart';
export 'library_screen.dart';
export 'profile_screen.dart';
export 'search_screen.dart';
export 'widgets.dart' show fmt;

const appVersion = '0.7';

/// Three tabs: Ratings, Search (opens first) and Expeditions.
/// Profile and info open from buttons in the top corner.
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
          LibraryScreen(store: widget.store),
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

/// The buttons in the top corner of each tab: info and profile.
List<Widget> cornerActions(Store store) => [const InfoButton(), ProfileButton(store: store)];

class ProfileButton extends StatelessWidget {
  final Store store;
  const ProfileButton({super.key, required this.store});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.account_circle_outlined),
    tooltip: 'Profile',
    onPressed: () =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProfileScreen(store: store))),
  );
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
          para(
            'Rate the expedition itself at the bottom of its page, separately from its albums. '
            '"Reset progress" starts it over without deleting your album ratings.',
          ),
          heading('Listen later and Your Range'),
          para(
            'Tap the bookmark on an album card (or press and hold on a phone) to save it to '
            'Listen later, found on the Ratings tab.',
          ),
          para(
            'Your Range, on your profile, shows up to five favourite albums as mountain peaks. '
            'Taller peaks are harder albums.',
          ),
          heading('Where the data comes from'),
          para(
            'The library has about 10,000 of the most listened-to albums (popularity from '
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
