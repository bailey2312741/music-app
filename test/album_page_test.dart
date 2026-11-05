import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/album_screen.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/details.dart';
import 'package:music_app/models.dart';
import 'package:music_app/page_parts.dart';
import 'package:music_app/store.dart';
import 'package:music_app/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_fonts.dart';

// Kind of Blue is a built-in expedition stop (Base Camp); Blue has no stage.
const _staged = Album(
  id: 'k1',
  title: 'Kind of Blue',
  artist: 'Miles Davis',
  year: '1959',
  genre: 'Jazz',
  subgenres: ['Modal Jazz', 'Cool Jazz'],
);
const _plain = Album(id: 'j1', title: 'Blue', artist: 'Joni Mitchell', year: '1971', genre: 'Folk');

const _details = AlbumDetails(
  date: '1959-08-17',
  label: 'Columbia',
  tracks: [
    Track(id: 't1', number: 'A1', title: 'So What', ms: 562000, albumId: 'k1'),
    Track(id: 't2', number: 'A2', title: 'Freddie Freeloader', ms: 586000, albumId: 'k1'),
    Track(id: 't3', number: 'B1', title: 'Blue in Green', ms: 337000, albumId: 'k1'),
  ],
);

Future<Store> _store() async {
  SharedPreferences.setMockInitialValues({
    // Saved tracklists, so the page doesn't go to the internet.
    'details2:k1': jsonEncode(_details.toJson()),
    'details2:j1': jsonEncode(const AlbumDetails(tracks: []).toJson()),
  });
  Catalogue.use(const [_staged, _plain]);
  return Store.load();
}

Future<void> _open(WidgetTester t, Store store, Album album, {double textScale = 1}) async {
  // A tall phone, so the whole page is built without scrolling.
  if (t.view.physicalSize.height < 2000) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(412, 2600);
    addTearDown(t.view.reset);
  }
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: page!,
      ),
      home: AlbumScreen(key: ValueKey(album.id), store: store, album: album),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('one rating slider, fixed at the bottom; no Test button', (t) async {
    final store = await _store();
    await _open(t, store, _staged);
    expect(find.byType(Slider), findsOneWidget);
    expect(
      find.descendant(of: find.byType(RatingBar), matching: find.byType(Slider)),
      findsOneWidget,
    );
    // The bar stays put while the page scrolls.
    final before = t.getRect(find.byType(RatingBar));
    await t.drag(find.byType(ListView), const Offset(0, -600));
    await t.pumpAndSettle();
    expect(t.getRect(find.byType(RatingBar)), before);
    expect(find.text('Test'), findsNothing);
  });

  testWidgets('header: title, artist, details, stage badge from the real data', (t) async {
    final store = await _store();
    await _open(t, store, _staged);
    expect(find.text('Kind of Blue'), findsOneWidget);
    expect(find.text('Miles Davis'), findsOneWidget);
    expect(find.text('Album · 1959 · 3 tracks · 25 min'), findsOneWidget);
    expect(find.text('BASE CAMP'), findsOneWidget);
    expect(find.text('Stage not assigned'), findsNothing);
    expect(find.text('Listen later'), findsOneWidget);
    expect(find.text('Add to Your Range'), findsOneWidget);
    // Genres are information, not buttons.
    expect(find.bySemanticsLabel('Genres: Jazz, Modal Jazz, Cool Jazz'), findsOneWidget);

    await _open(t, store, _plain);
    expect(find.text('Stage not assigned'), findsOneWidget);
    expect(find.text('BASE CAMP'), findsNothing);
  });

  testWidgets('Listen later and Your Range show their on state', (t) async {
    final store = await _store();
    await _open(t, store, _staged);
    await t.tap(find.text('Listen later'));
    await t.pumpAndSettle();
    expect(store.isListenLater('k1'), isTrue);
    expect(find.text('Saved for later'), findsOneWidget);
    await t.tap(find.text('Add to Your Range'));
    await t.pumpAndSettle();
    expect(store.isPinned('k1'), isTrue);
    expect(find.text('In Your Range'), findsOneWidget);
  });

  testWidgets('tracklist keeps side labels and one-tap rating', (t) async {
    final store = await _store();
    await _open(t, store, _staged);
    expect(find.text('A1'), findsOneWidget);
    expect(find.text('B1'), findsOneWidget);
    expect(find.text('9:22 · avg –'), findsOneWidget);
    // One tap on Rate opens the sheet; letting go of the slider saves.
    await t.tap(find.bySemanticsLabel('Rate So What'));
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await t.drag(
      find.descendant(of: find.byType(BottomSheet), matching: find.byType(Slider)),
      const Offset(1000, 0),
    );
    await t.pumpAndSettle();
    expect(store.trackRatingOf('t1'), 10);
    expect(find.bySemanticsLabel('Your rating for So What: 10. Change'), findsOneWidget);
  });

  testWidgets('rating spread: empty state, then the real rating', (t) async {
    final store = await _store();
    await _open(t, store, _staged);
    expect(find.textContaining('No ratings yet'), findsOneWidget);
    await store.rate(_staged, 8.5);
    await t.pumpAndSettle();
    expect(find.textContaining('No ratings yet'), findsNothing);
    expect(find.bySemanticsLabel('Rating spread, 1 rating: 1 at 9'), findsOneWidget);
  });

  for (final width in [360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('album page fits at $width wide, ${scale * 100}% text', (t) async {
        await loadBrandFonts();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 2600);
        addTearDown(t.view.reset);
        final store = await _store();
        await store.rate(_staged, 9);
        await _open(t, store, _staged, textScale: scale);
        // The artwork is 200-220 wide on phones, never wider than the page.
        final cover = t.getSize(find.byType(Cover).first).width;
        expect(cover, inInclusiveRange(200, 220));
        // Scroll to the end so every section is built and laid out.
        await t.drag(find.byType(ListView), const Offset(0, -8000));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
}
