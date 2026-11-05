import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/expedition_screens.dart';
import 'package:music_app/expeditions.dart';
import 'package:music_app/models.dart';
import 'package:music_app/store.dart';
import 'package:music_app/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_fonts.dart';

/// Every built-in stop as a catalogue album, so covers and progress resolve.
List<Album> _albums() => [
  for (final e in builtInExpeditions)
    for (final (i, s) in e.stops.indexed)
      Album(id: '${e.id}$i', title: s.title, artist: s.artist, year: '1990', genre: 'Rock'),
];

/// Into the Ambient: stop 1 rated (most recently). Golden Age Hip-Hop: all
/// rated, and the expedition itself rated. Jazz (in order): stops 1 and 2.
Future<Store> _store() async {
  SharedPreferences.setMockInitialValues({});
  Catalogue.use(_albums());
  final store = await Store.load();
  for (var i = 0; i < 5; i++) {
    await store.rate(Catalogue.byId('hiphop$i')!, 7 + i * 0.5);
  }
  await store.rate(Catalogue.byId('jazz0')!, 10);
  await store.rate(Catalogue.byId('jazz1')!, 6.5);
  await store.rate(Catalogue.byId('ambient0')!, 8.5);
  await store.rateExpedition('hiphop', 8.5);
  return store;
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

Expedition _byId(String id) => builtInExpeditions.firstWhere((e) => e.id == id);

void main() {
  testWidgets('Continue shows the real next album of the latest expedition', (t) async {
    final store = await _store();
    await _pump(t, ExpeditionListScreen(store: store));
    final card = find.byType(ContinueCard);
    expect(card, findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Chill Out')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('The KLF')), findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('Stop 2 of 5 · Into the Ambient')),
      findsOneWidget,
    );
    final cover = t.widget<Cover>(find.descendant(of: card, matching: find.byType(Cover)));
    expect(cover.album.id, 'ambient1');
  });

  testWidgets('expedition cards show the next album, or the stack when complete', (t) async {
    final store = await _store();
    await _pump(t, ExpeditionListScreen(store: store));
    Finder tile(String name) =>
        find.ancestor(of: find.text(name), matching: find.byType(ExpeditionTile));
    Cover coverOf(String name) =>
        t.widget<Cover>(find.descendant(of: tile(name), matching: find.byType(Cover)).first);

    expect(coverOf('Into the Ambient').album.id, 'ambient1');
    expect(coverOf('Jazz Breaks Free').album.id, 'jazz2');
    expect(
      find.descendant(of: tile('Golden Age Hip-Hop'), matching: find.byType(ExpeditionCover)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile('Golden Age Hip-Hop'), matching: find.text('Complete')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile('Golden Age Hip-Hop'), matching: find.text('Rated 8.5')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile('Jazz Breaks Free'), matching: find.text('In order')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile('Jazz Breaks Free'), matching: find.text('2 of 5')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: tile('Jazz Breaks Free'), matching: find.text('Avg 8.3')),
      findsOneWidget,
    );
  });

  testWidgets('the progress bar is actually drawn', (t) async {
    await _pump(
      t,
      const Center(child: SizedBox(width: 200, child: SegmentedProgress(done: 2, total: 5))),
    );
    final segments = find.descendant(
      of: find.byType(SegmentedProgress),
      matching: find.byType(DecoratedBox),
    );
    expect(segments, findsNWidgets(5));
    expect(t.getSize(segments.first).height, AppSizes.progressTrackHeight);
  });

  testWidgets('trail: sideways, zig-zag, next stop marked, final stop bigger', (t) async {
    final store = await _store();
    await _pump(t, ExpeditionScreen(store: store, expeditionId: 'ambient'));
    final trail = find.descendant(
      of: find.byType(JourneyTrail),
      matching: find.byType(SingleChildScrollView),
    );
    expect(t.widget<SingleChildScrollView>(trail).scrollDirection, Axis.horizontal);
    final cards = find.descendant(of: find.byType(JourneyTrail), matching: find.byType(AlbumCard));
    expect(cards, findsNWidgets(5));
    final rects = [for (var i = 0; i < 5; i++) t.getRect(cards.at(i))];
    expect(rects[1].top, greaterThan(rects[0].top)); // zig
    expect(rects[2].top, lessThan(rects[1].top)); // zag
    expect(rects[4].width, greaterThan(rects[0].width)); // final stop bigger
    // Stop 2 (Chill Out) is next: highlighted, labelled, and says so to screen readers.
    final next = t.widget<AlbumCard>(cards.at(1));
    expect(next.highlight, isTrue);
    expect(next.semanticLabel, contains('Next stop'));
    expect(find.text('NEXT STOP'), findsOneWidget);
    expect(t.getRect(find.text('NEXT STOP')).overlaps(rects[1]), isTrue);
    // Not in order: nothing is locked; ratings shown only where rated.
    expect([
      for (var i = 0; i < 5; i++) t.widget<AlbumCard>(cards.at(i)).locked,
    ], everyElement(false));
    expect(t.widget<AlbumCard>(cards.at(0)).rating, 8.5);
    expect(t.widget<AlbumCard>(cards.at(2)).rating, isNull);
    expect(find.text('Final stop'), findsOneWidget);
  });

  testWidgets('in-order trail locks only the stops its rules lock', (t) async {
    final store = await _store();
    await _pump(t, ExpeditionScreen(store: store, expeditionId: 'jazz'));
    final cards = find.descendant(of: find.byType(JourneyTrail), matching: find.byType(AlbumCard));
    final locked = [for (var i = 0; i < 5; i++) t.widget<AlbumCard>(cards.at(i)).locked];
    expect(unlockedCount(store, _byId('jazz')), 3);
    expect(locked, [false, false, false, true, true]);
    expect(t.widget<AlbumCard>(cards.at(2)).highlight, isTrue);
  });

  testWidgets('expedition rating: unrated is not zero, saves on release', (t) async {
    final store = await _store();
    await _pump(t, ExpeditionScreen(store: store, expeditionId: 'ambient'));
    expect(find.text('Not rated yet'), findsOneWidget);
    expect(store.expeditionRating('ambient'), isNull);
    final slider = find.byType(Slider);
    await t.ensureVisible(slider);
    await t.drag(slider, const Offset(-1000, 0));
    await t.pumpAndSettle();
    expect(store.expeditionRating('ambient'), 0);
    expect(find.text('Not rated yet'), findsNothing);
    // Album ratings untouched.
    expect(store.ratingOf('ambient0'), 8.5);
  });

  testWidgets('a completed expedition keeps its rating', (t) async {
    final store = await _store();
    await _pump(t, ExpeditionScreen(store: store, expeditionId: 'hiphop'));
    expect(find.text('Complete!'), findsOneWidget);
    expect(find.text('NEXT STOP'), findsNothing);
    expect(find.text('8.5'), findsWidgets);
    expect(find.text('Not rated yet'), findsNothing);
  });

  for (final width in [360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('Expeditions fit at $width wide, ${scale * 100}% text', (t) async {
        await loadBrandFonts();
        final store = await _store();
        await _pump(
          t,
          ExpeditionListScreen(store: store),
          width: width,
          scale: scale,
        );
        expect(t.takeException(), isNull);
        for (final id in ['ambient', 'jazz', 'hiphop']) {
          await _pump(
            t,
            ExpeditionScreen(key: ValueKey(id), store: store, expeditionId: id),
            width: width,
            scale: scale,
          );
          expect(t.takeException(), isNull);
          // Scroll the whole trail sideways, so every stop is laid out.
          await t.drag(
            find.descendant(
              of: find.byType(JourneyTrail),
              matching: find.byType(SingleChildScrollView),
            ),
            const Offset(-2000, 0),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
      });
    }
  }
}
