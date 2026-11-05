import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/actions.dart';
import 'package:music_app/album_screen.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/charts.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/details.dart';
import 'package:music_app/expeditions.dart';
import 'package:music_app/models.dart';
import 'package:music_app/nav.dart';
import 'package:music_app/search_screen.dart';
import 'package:music_app/song_screen.dart';
import 'package:music_app/store.dart';
import 'package:music_app/widgets.dart';
import 'package:music_app/you_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_fonts.dart';

// Spiritual Unity (Summit) and Kind of Blue (Base Camp) are built-in
// expedition albums, so Hardest has real stages to rank.
const _albums = [
  Album(
    id: 'su',
    title: 'Spiritual Unity',
    artist: 'Albert Ayler Trio',
    year: '1965',
    genre: 'Jazz',
    popularity: 50,
  ),
  Album(
    id: 'kb',
    title: 'Kind of Blue',
    artist: 'Miles Davis',
    year: '1959',
    genre: 'Jazz',
    popularity: 900,
  ),
  Album(
    id: 'bb',
    title: 'Bitches Brew',
    artist: 'Miles Davis',
    year: '1970',
    genre: 'Jazz',
    popularity: 700,
  ),
  Album(
    id: 'ia',
    title: 'In a Silent Way',
    artist: 'Miles Davis',
    year: '1969',
    genre: 'Jazz',
    popularity: 500,
  ),
  Album(
    id: 'ms',
    title: 'Miles Smiles',
    artist: 'Miles Davis',
    year: '1967',
    genre: 'Jazz',
    popularity: 300,
  ),
  Album(
    id: 'lv',
    title: 'Live at the Plugged Nickel',
    artist: 'Miles Davis',
    year: '1995',
    genre: 'Jazz',
    type: 'Live',
    popularity: 200,
  ),
  Album(
    id: 'ok',
    title: 'OK Computer',
    artist: 'Radiohead',
    year: '1997',
    genre: 'Rock',
    popularity: 1000,
  ),
  Album(
    id: 'ab',
    title: 'Abbey Road',
    artist: 'The Beatles',
    year: '1969',
    genre: 'Rock',
    popularity: 800,
  ),
];

const _track = Track(
  id: 'so-what',
  number: '1',
  title: 'So What (a long song title that has to wrap onto another line)',
  ms: 562000,
  albumId: 'kb',
);

Future<Store> _store() async {
  SharedPreferences.setMockInitialValues({
    for (final a in _albums)
      'details2:${a.id}': jsonEncode(
        AlbumDetails(tracks: a.id == 'kb' ? const [_track] : const []).toJson(),
      ),
  });
  Catalogue.use(_albums, featured: ['Miles Davis']);
  return Store.load();
}

Future<void> _pump(WidgetTester t, Widget home, {double width = 412, double scale = 1}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 2000);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
        child: page!,
      ),
      home: home,
    ),
  );
  await t.pumpAndSettle();
}

Future<void> _app(WidgetTester t, Store store, String location) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(412, 2000);
  addTearDown(t.view.reset);
  final router = buildRouter(store);
  await t.pumpWidget(MaterialApp.router(theme: AppTheme.dark(), routerConfig: router));
  router.go(location);
  await t.pumpAndSettle();
}

Finder _card(String title) => find.ancestor(
  of: find.textContaining(title, findRichText: true),
  matching: find.byType(AlbumCard),
);

void main() {
  testWidgets('artist page: name as the heading, studio albums three across', (t) async {
    final store = await _store();
    await _pump(t, ArtistScreen(store: store, artist: 'Miles Davis'));
    final heading = find.descendant(
      of: find.byType(PageHeader),
      matching: find.text('Miles Davis'),
    );
    expect(heading, findsOneWidget);
    expect(t.widget<Text>(heading).style?.fontFamily, AppType.display);
    expect(find.textContaining('Studio albums', findRichText: true), findsOneWidget);
    expect(find.textContaining('Live albums', findRichText: true), findsOneWidget);
    // Oldest first: Kind of Blue, Miles Smiles, In a Silent Way, Bitches Brew.
    final tops = [
      for (final title in ['Kind of Blue', 'Miles Smiles', 'In a Silent Way'])
        t.getRect(_card(title)),
    ];
    expect(tops[0].top, tops[1].top);
    expect(tops[1].top, tops[2].top); // three across on a 412 px phone
    expect(t.getRect(_card('Bitches Brew')).top, greaterThan(tops[0].bottom));
    // Sort is kept, and bookmarking is one tap.
    expect(find.byTooltip('Sort'), findsOneWidget);
    await t.tap(find.descendant(of: _card('Kind of Blue'), matching: find.byType(BookmarkButton)));
    await t.pumpAndSettle();
    expect(store.isListenLater('kb'), isTrue);
  });

  testWidgets('genre page: heading with count, letter jump with 48 px targets', (t) async {
    final store = await _store();
    await _pump(t, GenreScreen(store: store, genre: 'Jazz'));
    expect(
      find.descendant(of: find.byType(PageHeader), matching: find.text('Jazz')),
      findsOneWidget,
    );
    expect(find.text('6 albums'), findsOneWidget);
    // Most popular first.
    expect(t.getRect(_card('Kind of Blue')).left, lessThan(t.getRect(_card('Bitches Brew')).left));
    await t.tap(find.byTooltip('Sort'));
    await t.pumpAndSettle();
    await t.tap(find.text('Alphabetical').last);
    await t.pumpAndSettle();
    final letter = find.bySemanticsLabel('Jump to S');
    expect(letter, findsOneWidget);
    final button = find.ancestor(of: find.text('S'), matching: find.byType(TextButton));
    expect(t.getSize(button).height, greaterThanOrEqualTo(48));
    expect(t.getSize(button).width, greaterThanOrEqualTo(48));
  });

  testWidgets('charts: real rank numbers beside titles, stage-only Hardest', (t) async {
    final store = await _store();
    await _pump(t, ChartScreen(store: store, kind: 'popular'));
    expect(
      find.descendant(of: find.byType(PageHeader), matching: find.text('Popular')),
      findsOneWidget,
    );
    final first = t.widget<AlbumCard>(find.byType(AlbumCard).first);
    expect(first.number, 1);
    expect(first.album.title, 'OK Computer');
    // The rank sits under the cover, not on it.
    final cover = t.getRect(
      find.descendant(of: _card('OK Computer'), matching: find.byType(Cover)),
    );
    final rank = t.getRect(
      find.descendant(of: _card('OK Computer'), matching: find.byType(RankBadge)),
    );
    expect(rank.top, greaterThanOrEqualTo(cover.bottom));

    await _pump(t, ChartScreen(key: const ValueKey('h'), store: store, kind: 'hardest'));
    final hardest = [for (final c in t.widgetList<AlbumCard>(find.byType(AlbumCard))) c.album.id];
    expect(hardest, ['su', 'kb']); // Summit before Base Camp; nothing unstaged

    await _pump(t, ChartScreen(key: const ValueKey('t'), store: store, kind: 'top'));
    expect(find.text('Rate an album and it appears here, highest first.'), findsOneWidget);
  });

  testWidgets('song page: title leads, album link opens the album, rating dock', (t) async {
    final store = await _store();
    await _app(t, store, '/discover/album/kb');
    await t.tap(find.text(_track.title));
    await t.pumpAndSettle();
    expect(find.byType(SongScreen), findsOneWidget);
    final title = find.text(_track.title);
    expect(t.widget<Text>(title).style?.fontFamily, AppType.display);
    expect(t.getSize(title).height, greaterThan(40)); // wrapped, not cut off
    expect(find.text('Track 1 · 9:22'), findsOneWidget);
    expect(find.text('Test'), findsNothing);
    expect(find.byType(Slider), findsOneWidget); // one slider: the dock
    expect(find.bySemanticsLabel('You have not rated it'), findsOneWidget);
    expect(find.text('No ratings yet. Use the bar at the bottom to add yours.'), findsOneWidget);
    // Rate with the dock, saved on release.
    await t.drag(find.byType(Slider), const Offset(1000, 0));
    await t.pumpAndSettle();
    expect(store.trackRatingOf('so-what'), 10);
    expect(find.bySemanticsLabel('Your rating 10'), findsOneWidget);
    // The album link is one obvious button.
    final link = find.bySemanticsLabel(RegExp('^From the album Kind of Blue'));
    expect(link, findsOneWidget);
    expect(t.getSize(link).height, greaterThanOrEqualTo(48));
    await t.tap(link);
    await t.pumpAndSettle();
    expect(find.byType(AlbumScreen), findsOneWidget);
  });

  testWidgets('reviews: write, edit and delete', (t) async {
    final store = await _store();
    await _pump(t, SongScreen(store: store, album: _albums[1], track: _track));
    await t.tap(find.text('Write a review'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'Lovely bass line.');
    await t.tap(find.text('Post'));
    await t.pumpAndSettle();
    expect(store.reviewOf('track:so-what')?.text, 'Lovely bass line.');
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    expect(find.text('Edit your review'), findsOneWidget);
    await t.tap(find.text('Delete'));
    await t.pumpAndSettle();
    expect(store.reviewOf('track:so-what'), isNull);
    expect(find.text('No reviews yet.'), findsOneWidget);
  });

  testWidgets('new expedition: save needs a name and two albums; data saved', (t) async {
    final store = await _store();
    await _app(t, store, '/expeditions/new');
    expect(find.text('New expedition'), findsOneWidget);
    FilledButton save() => t.widget<FilledButton>(find.byType(FilledButton));
    expect(save().onPressed, isNull);
    expect(find.text('To save, add a name and 2 more albums.'), findsOneWidget);
    // A name typed then cleared shows its error by the field.
    await t.enterText(find.widgetWithText(TextField, 'Name'), 'x');
    await t.enterText(find.widgetWithText(TextField, 'Name'), '');
    await t.pumpAndSettle();
    expect(find.text('Give your expedition a name.'), findsOneWidget);
    await t.enterText(find.widgetWithText(TextField, 'Name'), 'Miles');
    await t.enterText(find.widgetWithText(TextField, 'Description (optional)'), 'Two of his.');
    await t.pumpAndSettle();

    Future<void> pick(String title) async {
      await t.tap(find.text('Add album'));
      await t.pumpAndSettle();
      expect(find.text('Add an album'), findsOneWidget);
      await t.enterText(find.byType(TextField), title);
      await t.pumpAndSettle();
      await t.tap(_card(title));
      await t.pumpAndSettle();
    }

    await pick('Kind of Blue');
    await pick('Kind of Blue'); // duplicate: refused with a message
    expect(find.text('That album is already in this expedition.'), findsOneWidget);
    await pick('Bitches Brew');
    expect(save().onPressed, isNotNull);
    expect(find.textContaining('To save'), findsNothing);
    // Each row: remove button and drag handle, both 48 px.
    final remove = find.byTooltip('Remove Kind of Blue');
    expect(t.getSize(remove).height, greaterThanOrEqualTo(48));
    final handle = find.bySemanticsLabel('Reorder Kind of Blue');
    expect(t.getSize(handle).height, greaterThanOrEqualTo(48));
    // Keyboard: arrow down on the focused handle moves the album.
    Focus.of(t.element(find.byIcon(Icons.drag_handle).first)).requestFocus();
    await t.pump();
    await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await t.pumpAndSettle();
    // Let the "already in this expedition" message time out first.
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await t.tap(find.byType(FilledButton));
    await t.pumpAndSettle();
    final e = store.customExpeditions.single;
    expect(e.name, 'Miles');
    expect(e.blurb, 'Two of his.');
    expect([for (final s in e.stops) s.album?.id], ['bb', 'kb']);
  });

  testWidgets('edit expedition keeps every field and reorders by year', (t) async {
    final store = await _store();
    await store.saveExpedition(
      Expedition(
        'mine',
        'Late Miles',
        'Electric years.',
        [
          for (final id in ['bb', 'kb', 'ia']) ExpeditionStop.ofAlbum(Catalogue.byId(id)!),
        ],
        inOrder: true,
        custom: true,
      ),
    );
    await _app(t, store, '/expeditions/trail/mine/edit');
    expect(find.text('Edit expedition'), findsOneWidget);
    expect(find.text('Late Miles'), findsOneWidget);
    expect(find.text('Electric years.'), findsOneWidget);
    expect(t.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    expect(find.text('Miles Davis · 1970'), findsOneWidget);
    await t.tap(find.text('Sort by year'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Remove In a Silent Way'));
    await t.pumpAndSettle();
    await t.tap(find.text('Save changes'));
    await t.pumpAndSettle();
    final e = store.customExpeditions.single;
    expect(e.name, 'Late Miles');
    expect(e.inOrder, isTrue);
    expect([for (final s in e.stops) s.album?.id], ['kb', 'bb']);
  });

  testWidgets('Range full: every choice is a 48 px target, with Cancel', (t) async {
    final store = await _store();
    for (final id in ['su', 'kb', 'bb', 'ia', 'ms']) {
      await store.pin(Catalogue.byId(id)!);
    }
    await _pump(
      t,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => pinToRange(context, store, Catalogue.byId('ok')!),
              child: const Text('Pin'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('Pin'));
    await t.pumpAndSettle();
    expect(find.text('Your Range is full'), findsOneWidget);
    expect(find.byType(DialogChoice), findsNWidgets(5));
    for (final r in t.widgetList(find.byType(DialogChoice))) {
      expect(t.getSize(find.byWidget(r)).height, greaterThanOrEqualTo(48));
    }
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(store.isPinned('ok'), isFalse);
    await t.tap(find.text('Pin'));
    await t.pumpAndSettle();
    await t.tap(find.text('3. Bitches Brew'));
    await t.pumpAndSettle();
    expect(store.range[2]?.id, 'ok');
  });

  testWidgets('a missing album says so plainly', (t) async {
    final store = await _store();
    await _app(t, store, '/discover/album/nope');
    expect(find.text("Couldn't find this album"), findsOneWidget);
  });

  for (final width in [360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('D5 screens fit at $width wide, ${scale * 100}% text', (t) async {
        await loadBrandFonts();
        final store = await _store();
        await store.rate(Catalogue.byId('kb')!, 9);
        await store.rateTrack(_track, 8.5);
        await store.saveReview('track:so-what', 'Lovely bass line.');
        final pages = <Widget>[
          ArtistScreen(store: store, artist: 'Miles Davis'),
          GenreScreen(store: store, genre: 'Jazz'),
          ChartScreen(store: store, kind: 'popular'),
          ChartScreen(store: store, kind: 'top'),
          SongScreen(store: store, album: _albums[1], track: _track),
          const AboutScreen(),
          SearchScreen(store: store, pickMode: true),
        ];
        for (final (i, page) in pages.indexed) {
          await _pump(
            t,
            KeyedSubtree(key: ValueKey(i), child: page),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull, reason: '${page.runtimeType}');
        }
      });

      testWidgets('expedition form fits at $width wide, ${scale * 100}% text', (t) async {
        await loadBrandFonts();
        final store = await _store();
        await store.saveExpedition(
          Expedition(
            'mine',
            'A very long expedition name for checking wrapping',
            'Electric years.',
            [for (final a in _albums.take(5)) ExpeditionStop.ofAlbum(a)],
            custom: true,
          ),
        );
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 2000);
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final router = buildRouter(store);
        await t.pumpWidget(MaterialApp.router(theme: AppTheme.dark(), routerConfig: router));
        router.go('/expeditions/new');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        router.go('/expeditions/trail/mine/edit');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
}
