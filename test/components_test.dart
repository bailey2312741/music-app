import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/difficulty.dart';
import 'package:music_app/models.dart';
import 'package:music_app/page_parts.dart';
import 'package:music_app/widgets.dart';

import 'brand_fonts.dart';

Widget _app(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.dark(),
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
    child: page!,
  ),
  home: Scaffold(body: child),
);

/// [bar] fixed at the bottom of a page, like the album page's rating bar.
Widget _withBar(Widget bar, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.dark(),
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
    child: page!,
  ),
  home: Scaffold(body: const SizedBox(), bottomNavigationBar: bar),
);

const _long = Album(
  id: 'l1',
  title: 'The Rise and Fall of Ziggy Stardust and the Spiders from Mars',
  artist: 'David Bowie and an Unreasonably Long Band Name',
  type: 'Live',
);

const _short = Album(id: 's1', title: 'Blue', artist: 'Joni Mitchell');

void main() {
  group('album card sizes', () {
    test('about three cards across on phones, four at 600, two with big text', () {
      const m = AlbumCardMetrics();
      // Width inside the 16 px page gutters.
      expect(m.columns(360 - 32), 3);
      expect(m.columns(412 - 32), 3);
      expect(m.columns(600 - 32), 4);
      const big = AlbumCardMetrics(textScaler: TextScaler.linear(2));
      expect(big.columns(360 - 32), 2);
      expect(big.columns(600 - 32), 2);
      const medium = AlbumCardMetrics(textScaler: TextScaler.linear(1.3));
      expect(medium.columns(412 - 32), 3);
    });

    test('cards grow with text size and with a stage tag, never shrink the cover', () {
      const plain = AlbumCardMetrics();
      const staged = AlbumCardMetrics(withStage: true);
      const big = AlbumCardMetrics(withStage: true, textScaler: TextScaler.linear(2));
      expect(staged.cardHeight(100), greaterThan(plain.cardHeight(100)));
      expect(big.cardHeight(100), greaterThan(staged.cardHeight(100)));
      // The cover is always a square as wide as the card.
      expect(plain.cardHeight(100), greaterThan(100 + 2 * 20));
    });

    for (final width in [360.0, 412.0, 600.0]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('a grid of worst-case cards fits at $width wide, ${scale * 100}% text', (
          t,
        ) async {
          await loadBrandFonts();
          t.view.devicePixelRatio = 1;
          t.view.physicalSize = Size(width, 900);
          addTearDown(t.view.reset);
          final metrics = AlbumCardMetrics(
            textScaler: TextScaler.linear(scale),
            withStage: true,
            withCaption: true,
          );
          await t.pumpWidget(
            _app(
              textScale: scale,
              CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.gridPageGutter),
                    sliver: SliverGrid.builder(
                      gridDelegate: metrics.delegate(),
                      itemCount: 4,
                      itemBuilder: (_, i) => AlbumCard(
                        album: i.isEven ? _long : _short,
                        number: i == 0 ? 100 : null,
                        rating: i == 1 ? null : 9.5,
                        difficulty: Difficulty.values[i],
                        caption: 'Next stop',
                        highlight: i == 2,
                        locked: i == 3,
                        listenLater: i.isOdd,
                        onListenLater: () {},
                        onTap: () {},
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          // A card is exactly as tall as the grid cell it sits in.
          final cell = t.getSize(find.byType(AlbumCard).first);
          expect(cell.height, metrics.cardHeight(metrics.cardWidth(width - 32)));
        });
      }
    }
  });

  testWidgets('a card shows only the bookmark and the rating on the artwork', (t) async {
    var saved = 0, opened = 0;
    await t.pumpWidget(
      _app(
        SizedBox(
          width: 120,
          child: AlbumCard(
            album: _long,
            rating: 9.5,
            number: 3,
            listenLater: false,
            onListenLater: () => saved++,
            onTap: () => opened++,
          ),
        ),
      ),
    );
    // No cover URL: the record placeholder shows.
    expect(find.byType(CoverPlaceholder), findsOneWidget);
    expect(find.text('9.5'), findsOneWidget);
    // Release type moves under the title, next to the artist.
    expect(find.textContaining('· Live'), findsOneWidget);
    expect(t.getSize(find.byType(BookmarkButton)), const Size(48, 48));
    await t.tap(find.byType(BookmarkButton));
    expect((saved, opened), (1, 0));
    await t.tap(find.byType(CoverPlaceholder));
    expect((saved, opened), (1, 1));
    // Press and hold also saves for later.
    await t.longPress(find.byType(CoverPlaceholder));
    expect(saved, 2);

    final card = t.widget<AlbumCard>(find.byType(AlbumCard));
    expect(
      card.semanticLabel,
      'Number 3, The Rise and Fall of Ziggy Stardust and the Spiders from Mars, '
      'David Bowie and an Unreasonably Long Band Name, Live, your rating 9.5 out of 10',
    );
    expect(const AlbumCard(album: _short).semanticLabel, 'Blue, Joni Mitchell, not rated');
    expect(find.bySemanticsLabel('Listen later'), findsOneWidget);
  });

  testWidgets('rating badge and score text: halves, whole numbers, zero and unrated', (t) async {
    await t.pumpWidget(
      _app(
        const Column(
          children: [
            RatingBadge(10),
            RatingBadge(0),
            ScoreText(7.5),
            ScoreText(0),
            ScoreText(null),
          ],
        ),
      ),
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
    expect(find.text('7.5'), findsOneWidget);
    expect(find.text('–'), findsOneWidget);
  });

  group('rating bar', () {
    Future<(List<double>, List<int>)> pumpBar(WidgetTester t, {double? saved}) async {
      final saves = <double>[];
      final clears = <int>[];
      Widget bar(double? v) => _withBar(
        RatingBar(
          saved: v,
          onSave: (x) async => saves.add(x),
          onClear: () => clears.add(1),
          noun: 'song',
        ),
      );
      await t.pumpWidget(bar(saved));
      return (saves, clears);
    }

    testWidgets('unrated shows a dash; the first touch can set a real 0', (t) async {
      final (saves, clears) = await pumpBar(t);
      expect(find.text('–'), findsOneWidget);
      expect(find.text('tap to clear'), findsNothing);
      // Unrated: nothing to clear.
      await t.tap(find.text('–'));
      expect(clears, isEmpty);
      // Drag hard left: saves exactly 0 when the finger lifts.
      await t.drag(find.byType(Slider), const Offset(-1000, 0));
      await t.pumpAndSettle();
      expect(saves, [0]);
      expect(find.text('0'), findsWidgets);
    });

    testWidgets('one drag saves once, on release, in half steps', (t) async {
      final (saves, _) = await pumpBar(t);
      final slider = find.byType(Slider);
      final box = t.getRect(slider);
      final gesture = await t.startGesture(box.centerLeft + const Offset(30, 0));
      await gesture.moveTo(box.center);
      await gesture.moveTo(box.center + const Offset(13, 0));
      await t.pump();
      expect(saves, isEmpty); // nothing saved while dragging
      await gesture.up();
      await t.pumpAndSettle();
      expect(saves, hasLength(1));
      expect(saves.single * 2, saves.single * 2.roundToDouble());
    });

    testWidgets('tapping a saved score clears it; at least 48 px to tap', (t) async {
      final (_, clears) = await pumpBar(t, saved: 8.5);
      expect(find.text('8.5'), findsOneWidget);
      expect(find.text('tap to clear'), findsOneWidget);
      final cell = find.ancestor(of: find.text('8.5'), matching: find.byType(InkWell)).first;
      expect(t.getSize(cell).width, greaterThanOrEqualTo(48));
      expect(t.getSize(cell).height, greaterThanOrEqualTo(48));
      await t.tap(find.text('8.5'));
      expect(clears, [1]);
      expect(find.bySemanticsLabel('Your rating 8.5 out of 10. Tap to clear'), findsOneWidget);
      expect(find.bySemanticsLabel('Your song rating, 0 to 10 in steps of 0.5'), findsOneWidget);
    });

    testWidgets('the bar grows with 200% text instead of clipping', (t) async {
      await loadBrandFonts();
      t.view.devicePixelRatio = 1;
      t.view.physicalSize = const Size(360, 800);
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _withBar(RatingBar(saved: 9.5, onSave: (_) async {}, onClear: () {}), textScale: 2),
      );
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(RatingBar)).height, greaterThan(AppSizes.ratingBarHeight));
    });
  });

  testWidgets('progress, headers and empty, loading and error states', (t) async {
    var retries = 0;
    await t.pumpWidget(
      _app(
        ListView(
          children: [
            const SegmentedProgress(done: 2, total: 5),
            const SectionHeader('Tracklist', count: 12),
            const LoadingPlaceholder(label: 'Loading the tracklist'),
            const EmptyState(message: 'Nothing here yet.', icon: Icons.album_outlined),
            ErrorState(message: "Couldn't load the tracklist.", onRetry: () => retries++),
            AlbumListTile(cover: const CoverPlaceholder(), title: _long.title, subtitle: 'Review'),
          ],
        ),
      ),
    );
    final handle = t.ensureSemantics();
    expect(find.bySemanticsLabel('2 of 5 albums rated'), findsOneWidget);
    expect(find.bySemanticsLabel('Loading the tracklist'), findsOneWidget);
    expect(
      t.getSemantics(find.textContaining('Tracklist', findRichText: true)),
      matchesSemantics(label: 'Tracklist  12', isHeader: true),
    );
    await t.tap(find.text('Try again'));
    expect(retries, 1);
    expect(t.getSize(find.byType(AlbumListTile)).height, greaterThanOrEqualTo(72));
    handle.dispose();
  });
}
