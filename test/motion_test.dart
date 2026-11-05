import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/album_screen.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/details.dart';
import 'package:music_app/expedition_screens.dart';
import 'package:music_app/expeditions.dart';
import 'package:music_app/models.dart';
import 'package:music_app/nav.dart';
import 'package:music_app/page_parts.dart';
import 'package:music_app/profile_screen.dart';
import 'package:music_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Spiritual Unity is a Summit album, Kind of Blue Base Camp, OK Computer has
// no stage.
const _summit = Album(id: 'su', title: 'Spiritual Unity', artist: 'Albert Ayler Trio');
const _base = Album(id: 'bc', title: 'Kind of Blue', artist: 'Miles Davis', genre: 'Jazz');
const _none = Album(id: 'ok', title: 'OK Computer', artist: 'Radiohead', genre: 'Rock');
const _all = [_summit, _base, _none];

Future<Store> _store() async {
  SharedPreferences.setMockInitialValues({
    for (final a in _all) 'details2:${a.id}': jsonEncode(const AlbumDetails(tracks: []).toJson()),
  });
  Catalogue.use(_all);
  return Store.load();
}

Future<void> _pump(WidgetTester t, Widget child, {bool reduced = false}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(412, 1400);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      builder: (context, page) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: page!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
  await t.pumpAndSettle();
}

List<double> _peaks(WidgetTester t) {
  final paint = t.widget<CustomPaint>(
    find.byWidgetPredicate((w) => w is CustomPaint && w.painter is RangePainter),
  );
  return (paint.painter! as RangePainter).heights;
}

Widget _range(Store store) => ListenableBuilder(
  listenable: store,
  builder: (_, _) => RangeSkyline(store: store),
);

void main() {
  testWidgets('a pinned album rises from its empty slot to its stage height', (t) async {
    final store = await _store();
    await _pump(t, _range(store));
    expect(_peaks(t)[0], 64); // empty
    await store.pin(_summit, slot: 0);
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    final mid = _peaks(t)[0];
    expect(mid, greaterThan(64));
    expect(mid, lessThan(156));
    await t.pumpAndSettle();
    expect(_peaks(t)[0], 156); // Summit
    // A new rating never moves a peak.
    await store.rate(_summit, 3);
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(_peaks(t)[0], 156);
    // Removing sinks it back to the empty slot; Undo raises it again.
    await store.unpin('su');
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    expect(_peaks(t)[0], inExclusiveRange(64, 156));
    await t.pumpAndSettle();
    expect(_peaks(t)[0], 64);
    expect(store.range[0], isNull);
  });

  testWidgets('reduced motion: peaks change at once', (t) async {
    final store = await _store();
    await _pump(t, _range(store), reduced: true);
    await store.pin(_base, slot: 2);
    await t.pump();
    expect(_peaks(t)[2], 80); // Base Camp, no growth animation
  });

  testWidgets('saved progress moves the Next Stop label along the trail', (t) async {
    final store = await _store();
    final e = Expedition('mine', 'Three', '', [
      for (final a in _all) ExpeditionStop.ofAlbum(a),
    ], custom: true);
    await store.saveExpedition(e);
    await _pump(
      t,
      ListenableBuilder(
        listenable: store,
        builder: (_, _) => JourneyTrail(store: store, expedition: e),
      ),
    );
    double label() => t.getTopLeft(find.text('NEXT STOP')).dx;
    final before = label();
    await store.rate(_summit, 8);
    await t.pump();
    await t.pump(const Duration(milliseconds: 200));
    final mid = label();
    await t.pumpAndSettle();
    final after = label();
    expect(mid, greaterThan(before));
    expect(after, greaterThan(mid));
    // Completing the last stops shows the check on the final stop.
    await store.rate(_base, 7);
    await store.rate(_none, 6);
    await t.pumpAndSettle();
    expect(find.text('NEXT STOP'), findsNothing);
    expect(find.bySemanticsLabel('Expedition complete'), findsOneWidget);
  });

  testWidgets('album cover flies from the tapped card, with no duplicate tags', (t) async {
    final store = await _store();
    await store.rate(_base, 9); // shows in "Rated by me" as well as Jazz
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(412, 2400);
    addTearDown(t.view.reset);
    final router = buildRouter(store);
    await t.pumpWidget(MaterialApp.router(theme: AppTheme.dark(), routerConfig: router));
    router.go('/discover/genre/Jazz');
    await t.pumpAndSettle();
    await t.tap(find.text('Kind of Blue').first);
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    expect(t.takeException(), isNull);
    await t.pumpAndSettle();
    expect(find.byType(AlbumScreen), findsOneWidget);
    expect(find.byType(Hero), findsWidgets);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.byType(AlbumScreen), findsNothing);
  });

  testWidgets('rating haptics: a tick per step, one on save, none when idle', (t) async {
    final calls = <String>[];
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (c) async {
      if (c.method == 'HapticFeedback.vibrate') calls.add(c.arguments as String);
      return null;
    });
    addTearDown(
      () =>
          t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );
    double? saved;
    await _pump(
      t,
      StatefulBuilder(
        builder: (context, set) =>
            RatingBar(saved: saved, onSave: (v) async => set(() => saved = v), onClear: () {}),
      ),
    );
    await t.drag(find.byType(Slider), const Offset(200, 0));
    await t.pumpAndSettle();
    expect(saved, isNotNull);
    expect(calls.where((c) => c == 'HapticFeedbackType.lightImpact'), hasLength(1));
    expect(calls.where((c) => c == 'HapticFeedbackType.selectionClick'), isNotEmpty);
  });
}
