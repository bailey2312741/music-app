import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/details.dart';
import 'package:music_app/models.dart';
import 'package:music_app/nav.dart';
import 'package:music_app/search_screen.dart';
import 'package:music_app/store.dart';
import 'package:music_app/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_fonts.dart';

const _albums = [
  Album(id: 'r1', title: 'OK Computer', artist: 'Radiohead', year: '1997', genre: 'Rock'),
  Album(id: 'r2', title: 'Kid A', artist: 'Radiohead', year: '2000', genre: 'Electronic'),
  Album(id: 'r3', title: 'In Rainbows', artist: 'Radiohead', year: '2007', genre: 'Rock'),
  Album(id: 'b1', title: 'Abbey Road', artist: 'The Beatles', year: '1969', genre: 'Rock'),
  Album(id: 'k1', title: 'Kind of Blue', artist: 'Miles Davis', year: '1959', genre: 'Jazz'),
  Album(id: 'p1', title: 'Thriller', artist: 'Michael Jackson', year: '1982', genre: 'Pop'),
  Album(
    id: 'x1',
    title: 'Radio Hits',
    artist: 'Radio Head Tribute Band',
    year: '2010',
    genre: 'Pop',
  ),
];

Future<Store> _store() async {
  SharedPreferences.setMockInitialValues({
    // Saved tracklists, so album pages don't go to the internet.
    for (final a in _albums)
      'details2:${a.id}': jsonEncode(const AlbumDetails(tracks: []).toJson()),
  });
  Catalogue.use(_albums, featured: ['Radiohead', 'The Beatles', 'Miles Davis']);
  return Store.load();
}

Future<void> _open(WidgetTester t, Store store, {double width = 412, double textScale = 1}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 2400);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: page!,
      ),
      home: SearchScreen(store: store),
    ),
  );
  await t.pumpAndSettle();
}

Finder _genre(String name) => find.widgetWithText(GenreButton, name.toUpperCase());

/// Scrolls the genre strip to [name] and taps it, as a person would.
Future<void> _tapGenre(WidgetTester t, String name) async {
  await t.ensureVisible(_genre(name));
  await t.pumpAndSettle();
  await t.tap(_genre(name));
}

void main() {
  testWidgets('browsing: charts and decades in their own rows, every genre', (t) async {
    final store = await _store();
    await _open(t, store);
    expect(find.text('Charts'), findsOneWidget);
    for (final chart in ['Popular', 'Top rated', 'Hardest']) {
      expect(find.widgetWithText(OutlinedButton, chart), findsOneWidget);
    }
    expect(find.text('By decade'), findsOneWidget);
    for (final d in ['1950s', '1960s', '1980s', '1990s', '2000s', '2010s']) {
      expect(find.widgetWithText(OutlinedButton, d), findsOneWidget);
    }
    // Charts and decades are different rows.
    expect(t.getRect(find.text('1950s')).top, greaterThan(t.getRect(find.text('Popular')).bottom));
    expect(find.byType(GenreButton), findsNWidgets(Catalogue.families.length));
    expect(find.text('Rated by me'), findsOneWidget);
    expect(find.text('Featured artists'), findsOneWidget);
    expect(find.byType(ArtistCard), findsNWidgets(3));
    expect(find.bySemanticsLabel('See all Rock'), findsOneWidget);
    // No search button besides the field itself.
    expect(find.byType(SearchBar), findsOneWidget);
    expect(find.widgetWithIcon(IconButton, Icons.search), findsNothing);
  });

  testWidgets('search: artists then albums, each with the right count', (t) async {
    final store = await _store();
    await _open(t, store);
    await t.enterText(find.byType(TextField), 'radiohead');
    await t.pumpAndSettle();
    expect(find.text('Charts'), findsNothing);
    expect(find.textContaining('Artists', findRichText: true), findsOneWidget);
    expect(find.text('Artist · 3 albums'), findsOneWidget);
    final albums = Catalogue.search('radiohead');
    expect(find.text('Albums  ${albums.length}', findRichText: true), findsOneWidget);
    expect(find.byType(AlbumCard), findsNWidgets(albums.length));
    expect(find.text('Best match'), findsOneWidget);
    // Clear button empties the field and brings the charts back.
    await t.tap(find.byTooltip('Clear search'));
    await t.pumpAndSettle();
    expect(find.text('Charts'), findsOneWidget);
  });

  testWidgets('long artist lists show three, then all on request', (t) async {
    final store = await _store();
    await _open(t, store);
    await t.enterText(find.byType(TextField), 'a'); // all five artists
    await t.pumpAndSettle();
    final all = Catalogue.searchArtists('a');
    expect(all, hasLength(5));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    await t.tap(find.text('Show all 5 artists'));
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(5));
    expect(find.text('Show all 5 artists'), findsNothing);
  });

  testWidgets('a selected genre keeps every other genre in reach', (t) async {
    final store = await _store();
    await _open(t, store);
    await _tapGenre(t, 'Jazz');
    await t.pumpAndSettle();
    expect(find.byType(GenreButton), findsNWidgets(Catalogue.families.length));
    expect(t.widget<GenreButton>(_genre('Jazz')).selected, isTrue);
    expect(find.text('Albums  1', findRichText: true), findsOneWidget);
    expect(find.text('Kind of Blue'), findsOneWidget);
    // Straight to another genre, no clearing first.
    await _tapGenre(t, 'Pop');
    await t.pumpAndSettle();
    expect(find.text('Albums  2', findRichText: true), findsOneWidget);
    // Tap again to clear.
    await _tapGenre(t, 'Pop');
    await t.pumpAndSettle();
    expect(find.text('Charts'), findsOneWidget);
  });

  testWidgets('Rated by me filters to your rated albums', (t) async {
    final store = await _store();
    await store.rate(Catalogue.byId('r1')!, 9);
    await store.rate(Catalogue.byId('k1')!, 8);
    await _open(t, store);
    await t.tap(find.text('Rated by me'));
    await t.pumpAndSettle();
    expect(find.text('Albums  2', findRichText: true), findsOneWidget);
    await t.enterText(find.byType(TextField), 'radiohead');
    await t.pumpAndSettle();
    expect(find.text('Albums  1', findRichText: true), findsOneWidget);
    expect(find.text('OK Computer'), findsOneWidget);
  });

  testWidgets('the search is still there after visiting an album', (t) async {
    final store = await _store();
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(412, 2400);
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp.router(routerConfig: buildRouter(store)));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'radiohead');
    await t.pumpAndSettle();
    await t.tap(find.text('Kid A').last);
    await t.pumpAndSettle();
    expect(find.byType(SearchBar), findsNothing);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('radiohead'), findsOneWidget);
    expect(find.text('Artist · 3 albums'), findsOneWidget);
  });

  for (final width in [360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('Discover fits at $width wide, ${scale * 100}% text', (t) async {
        await loadBrandFonts();
        final store = await _store();
        await store.rate(Catalogue.byId('r1')!, 9.5);
        await _open(t, store, width: width, textScale: scale);
        expect(t.takeException(), isNull);
        // The search field is at least 52 tall and grows with the text.
        expect(
          t.getSize(find.byType(SearchBar)).height,
          greaterThanOrEqualTo(AppSizes.searchFieldHeight),
        );
        await t.enterText(find.byType(TextField), 'radiohead');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await _tapGenre(t, 'Rock');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
}
