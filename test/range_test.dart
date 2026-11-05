import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/album_screen.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/details.dart';
import 'package:music_app/difficulty.dart';
import 'package:music_app/models.dart';
import 'package:music_app/nav.dart';
import 'package:music_app/profile_screen.dart';
import 'package:music_app/store.dart';
import 'package:music_app/you_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_fonts.dart';

// Real built-in expedition albums, so their stages come from the app's data.
const _summit = Album(id: 'su', title: 'Spiritual Unity', artist: 'Albert Ayler Trio');
const _high = Album(id: 'ha', title: 'Out to Lunch!', artist: 'Eric Dolphy');
const _foot = Album(id: 'fo', title: 'Chill Out', artist: 'The KLF');
const _base = Album(id: 'bc', title: 'Kind of Blue', artist: 'Miles Davis');
const _none = Album(id: 'ok', title: 'OK Computer', artist: 'Radiohead'); // no stage
const _all = [_summit, _high, _foot, _base, _none];

Future<Store> _store({List<String?> range = const [null, null, null, null, null]}) async {
  SharedPreferences.setMockInitialValues({
    'range': jsonEncode(range),
    for (final a in _all) 'details2:${a.id}': jsonEncode(const AlbumDetails(tracks: []).toJson()),
  });
  Catalogue.use(_all);
  final store = await Store.load();
  var r = 6.0;
  for (final a in _all) {
    await store.rate(a, r += 0.5);
  }
  return store;
}

Future<void> _pumpRange(WidgetTester t, Store store, {double width = 360}) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = Size(width, 900);
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: ListenableBuilder(
            listenable: store,
            builder: (_, _) => RangeSkyline(store: store),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

Finder _slot(int i) => find.bySemanticsLabel(RegExp('^Your Range slot ${i + 1}'));

void main() {
  test('peak height comes only from the listening stage', () {
    expect(RangeGeometry.kindOf(_base, Difficulty.baseCamp), PeakKind.baseCamp);
    expect(RangeGeometry.kindOf(_none, null), PeakKind.unassigned);
    expect(RangeGeometry.kindOf(null, null), PeakKind.empty);
    expect(RangeGeometry.height(PeakKind.baseCamp), 80);
    expect(RangeGeometry.height(PeakKind.foothills), 102);
    expect(RangeGeometry.height(PeakKind.highAltitude), 130);
    expect(RangeGeometry.height(PeakKind.summit), 156);
    expect(RangeGeometry.height(PeakKind.unassigned), 98);
    expect(RangeGeometry.baseline - RangeGeometry.height(PeakKind.summit), greaterThan(48));
  });

  testWidgets('covers sit on their peaks; ratings never move them', (t) async {
    final store = await _store(range: ['su', 'ha', 'ok', 'fo', 'bc']);
    await _pumpRange(t, store);
    final canvasTop = t.getTopLeft(find.byType(CustomPaint).first).dy;
    double coverBottom(int i) => t.getRect(_slot(i)).bottom - canvasTop;
    const kinds = [
      PeakKind.summit,
      PeakKind.highAltitude,
      PeakKind.unassigned,
      PeakKind.foothills,
      PeakKind.baseCamp,
    ];
    for (var i = 0; i < 5; i++) {
      expect(
        coverBottom(i),
        closeTo(RangeGeometry.baseline - RangeGeometry.height(kinds[i]) + AppSpace.xs, 0.01),
      );
    }
    // A different rating leaves the summit cover exactly where it was.
    final before = t.getRect(_slot(0));
    await store.rate(_summit, 0);
    await t.pumpAndSettle();
    expect(t.getRect(_slot(0)), before);
    // Five separate 48 px targets that don't overlap, inside a 360 px screen.
    final rects = [for (var i = 0; i < 5; i++) t.getRect(_slot(i))];
    for (final r in rects) {
      expect(r.width, closeTo(48, 0.01));
      expect(r.height, closeTo(48, 0.01));
      expect(r.left, greaterThanOrEqualTo(0));
      expect(r.right, lessThanOrEqualTo(360));
    }
    for (var i = 0; i + 1 < 5; i++) {
      expect(rects[i].overlaps(rects[i + 1]), isFalse);
    }
  });

  testWidgets('each peak is described for screen readers', (t) async {
    final store = await _store(range: ['su', null, 'ok', null, null]);
    await _pumpRange(t, store);
    expect(
      find.bySemanticsLabel(
        'Your Range slot 1: Spiritual Unity, Albert Ayler Trio, your rating 6.5, '
        'listening stage Summit',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Your Range slot 3: OK Computer, Radiohead, your rating 8.5, '
        'listening stage not assigned',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Your Range slot 2, empty. Add an album'), findsOneWidget);
    expect(find.text('Not assigned'), findsOneWidget);
    expect(find.text('Summit'), findsOneWidget);
    expect(find.text('Empty'), findsNWidgets(3));
    // Removing has a screen-reader action as well as press and hold.
    final node = t.getSemantics(_slot(0));
    expect(
      node.getSemanticsData().customSemanticsActionIds,
      contains(
        CustomSemanticsAction.getIdentifier(
          const CustomSemanticsAction(label: 'Remove from Your Range'),
        ),
      ),
    );
  });

  testWidgets('press and hold removes a peak; Undo puts it back in the same slot', (t) async {
    final store = await _store(range: ['su', 'ha', 'ok', 'fo', 'bc']);
    await _pumpRange(t, store);
    await t.longPress(_slot(2));
    await t.pumpAndSettle();
    expect(store.range[2], isNull);
    expect(find.text('Removed from Your Range'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(store.range.map((a) => a?.id), ['su', 'ha', 'ok', 'fo', 'bc']);
    // Saved, too.
    final again = await Store.load();
    expect(again.range.map((a) => a?.id), ['su', 'ha', 'ok', 'fo', 'bc']);
  });

  testWidgets('You tab: Edit removes with one tap; empty slots open the picker', (t) async {
    await loadBrandFonts();
    final store = await _store(range: ['su', null, null, null, 'bc']);
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(412, 1400);
    addTearDown(t.view.reset);
    final router = buildRouter(store);
    await t.pumpWidget(MaterialApp.router(theme: AppTheme.dark(), routerConfig: router));
    router.go('/you');
    await t.pumpAndSettle();
    expect(find.byType(YouScreen), findsOneWidget);
    // Occupied peak opens its album.
    await t.tap(_slot(0));
    await t.pumpAndSettle();
    expect(find.byType(AlbumScreen), findsOneWidget);
    expect(find.text('Spiritual Unity'), findsWidgets);
    router.go('/you');
    await t.pumpAndSettle();
    // Edit, then one tap removes.
    await t.tap(find.text('Edit'));
    await t.pumpAndSettle();
    await t.tap(_slot(4));
    await t.pumpAndSettle();
    expect(store.range[4], isNull);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(store.range[4]?.id, 'bc');
    await t.tap(find.text('Done'));
    await t.pumpAndSettle();
    // Empty slot: picker, rated albums highest first; one tap fills the slot.
    await t.tap(_slot(1));
    await t.pumpAndSettle();
    expect(find.byType(RangePickerScreen), findsOneWidget);
    expect(find.text('Add to Your Range'), findsOneWidget);
    await t.tap(find.text('OK Computer'));
    await t.pumpAndSettle();
    expect(store.range[1]?.id, 'ok');
    expect(find.byType(YouScreen), findsOneWidget);
  });

  for (final width in [360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('You tab fits at $width wide, ${scale * 100}% text', (t) async {
        await loadBrandFonts();
        final store = await _store(range: ['su', 'ha', 'ok', null, 'bc']);
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 1600);
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final router = buildRouter(store);
        await t.pumpWidget(MaterialApp.router(theme: AppTheme.dark(), routerConfig: router));
        router.go('/you');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        // The five-peak graphic keeps its height whatever the text size.
        expect(
          t.getSize(find.byType(CustomPaint).at(0)).height,
          greaterThanOrEqualTo(RangeGeometry.canvasHeight - 1),
        );
        router.go('/you/range/3');
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      });
    }
  }
}
