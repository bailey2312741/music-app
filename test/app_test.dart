import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/difficulty.dart';
import 'package:music_app/expeditions.dart';
import 'package:music_app/models.dart';
import 'package:music_app/screens.dart';
import 'package:music_app/sorting.dart';
import 'package:music_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Catalogue.use(const [
      Album(
        id: 'b1',
        title: 'Abbey Road',
        artist: 'The Beatles',
        year: '1969',
        genre: 'Rock',
        subgenres: ['Pop Rock'],
      ),
      Album(id: 'b2', title: 'Revolver', artist: 'The Beatles', year: '1966', genre: 'Rock'),
      Album(
        id: 'k1',
        title: 'Kind of Blue',
        artist: 'Miles Davis',
        year: '1959',
        genre: 'Jazz',
        subgenres: ['Modal Jazz'],
      ),
      Album(id: 'x1', title: 'Beatles Tribute', artist: 'Someone Else', year: '2000', genre: 'Pop'),
    ]);
  });

  test('ratings snap to half steps and persist', () async {
    final store = await Store.load();
    const album = Album(id: 'a', title: 'T', artist: 'A');
    await store.rate(album, 7.3);
    expect(store.ratingOf('a'), 7.5);
    final reloaded = await Store.load();
    expect(reloaded.ratingOf('a'), 7.5);
    expect(reloaded.ratedAlbums.single.album.title, 'T');
    await reloaded.rate(album, null);
    expect(reloaded.ratedAlbums, isEmpty);
    expect(reloaded.ratingOf('a'), isNull);
  });

  test('difficulty only shows for expedition albums', () async {
    final store = await Store.load();
    final stop = builtInExpeditions.first.stops.last;
    await store.saveResolvedStop(stop.key, const Album(id: 'x', title: 't', artist: 'a'));
    expect(difficultyOf(store, 'x'), Difficulty.summit);
    expect(difficultyOf(store, 'other'), isNull);
  });

  test('stops are unique across expeditions', () {
    final keys = [for (final e in builtInExpeditions) ...e.stops.map((s) => s.key)];
    expect(keys.toSet().length, keys.length);
    expect(builtInExpeditions.length, 3);
  });

  test('in-order expeditions unlock one album at a time', () async {
    final store = await Store.load();
    final albums = [for (var i = 0; i < 4; i++) Album(id: 'a$i', title: 'T$i', artist: 'A')];
    final e = Expedition(
      'x',
      'X',
      '',
      [for (final a in albums) ExpeditionStop.ofAlbum(a)],
      inOrder: true,
      custom: true,
    );
    expect(unlockedCount(store, e), 1);
    expect(nextStop(store, e), 0);
    await store.rate(albums[0], 8);
    expect(unlockedCount(store, e), 2);
    expect(nextStop(store, e), 1);
    await store.rate(albums[1], 6);
    await store.rate(albums[0], null); // removing an earlier rating keeps later ones open
    expect(unlockedCount(store, e), 3);
    final free = Expedition('y', 'Y', '', e.stops, custom: true);
    expect(unlockedCount(store, free), 4);
  });

  test('custom expeditions persist', () async {
    final store = await Store.load();
    const a = Album(id: 'z', title: 'Z', artist: 'A', year: '1999');
    await store.saveExpedition(
      Expedition(
        'id1',
        'Mine',
        'blurb',
        [ExpeditionStop.ofAlbum(a), ExpeditionStop.ofAlbum(a)],
        inOrder: true,
        custom: true,
      ),
    );
    final reloaded = await Store.load();
    final e = reloaded.customExpeditions.single;
    expect(e.name, 'Mine');
    expect(e.inOrder, isTrue);
    expect(e.stops.first.album!.year, '1999');
    await reloaded.deleteExpedition('id1');
    expect(reloaded.customExpeditions, isEmpty);
  });

  test('search puts the artist people typed first and finds artists', () {
    final r = Catalogue.search('the beatles');
    expect(r.take(2).map((a) => a.artist), everyElement('The Beatles'));
    expect(Catalogue.searchArtists('beat'), ['The Beatles']);
    expect(Catalogue.byArtist('The Beatles').first.title, 'Revolver'); // oldest first
  });

  test('genre filter and genre words both work', () {
    expect(Catalogue.search('', genre: 'Jazz').single.title, 'Kind of Blue');
    expect(Catalogue.search('modal').single.title, 'Kind of Blue');
    expect(Catalogue.search('', genre: 'Pop Rock').single.title, 'Abbey Road');
  });

  test('built-in stops find their album in the catalogue', () async {
    final store = await Store.load();
    final jazz = builtInExpeditions.firstWhere((e) => e.id == 'jazz');
    expect(albumFor(store, jazz.stops.first)?.id, 'k1');
  });

  testWidgets('picking an album for an expedition returns it instead of opening it', (t) async {
    final store = await Store.load();
    Album? picked;
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => picked = await Navigator.of(context).push<Album>(
                MaterialPageRoute(builder: (_) => SearchScreen(store: store, pickMode: true)),
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'kind of blue');
    await t.pumpAndSettle();
    await t.tap(find.text('Kind of Blue').last);
    await t.pumpAndSettle();
    expect(picked?.id, 'k1');
    expect(find.text('Slide to rate'), findsNothing);
  });

  test('sort: each option reverses on a second tap, missing values go last', () async {
    final store = await Store.load();
    final albums = Catalogue.albums;
    await store.rate(albums[0], 6);
    await store.rate(albums[2], 9);
    final byRating = const SortOrder(SortBy.rating).apply(albums, store);
    expect(byRating.take(2).map((a) => a.id), ['k1', 'b1']);
    final lowFirst = const SortOrder(SortBy.rating, reversed: true).apply(albums, store);
    expect(lowFirst.take(2).map((a) => a.id), ['b1', 'k1']);
    expect(const SortOrder(SortBy.alphabetical).apply(albums, store).first.title, 'Abbey Road');
    expect(
      const SortOrder(SortBy.alphabetical, reversed: true).apply(albums, store).first.title,
      'Revolver',
    );
  });

  test('listen later toggles and persists', () async {
    final store = await Store.load();
    final a = Catalogue.albums.first;
    expect(await store.toggleListenLater(a), isTrue);
    expect((await Store.load()).listenLater.single.id, a.id);
    expect(await store.toggleListenLater(a), isFalse);
    expect(store.listenLater, isEmpty);
  });

  test('Your Range holds five albums in order and can replace one', () async {
    final store = await Store.load();
    final albums = [for (var i = 0; i < 6; i++) Album(id: 'r$i', title: 'R$i', artist: 'A')];
    for (final a in albums.take(5)) {
      await store.pin(a);
    }
    expect(store.rangeFull, isTrue);
    await store.pin(albums[5], slot: 2);
    final reloaded = await Store.load();
    expect(reloaded.range.map((a) => a?.id), ['r0', 'r1', 'r5', 'r3', 'r4']);
    await reloaded.unpin('r1');
    expect(reloaded.range[1], isNull);
    expect(reloaded.rangeFull, isFalse);
  });

  test('expedition average, own rating, and reset progress keeping album ratings', () async {
    final store = await Store.load();
    final albums = [for (var i = 0; i < 3; i++) Album(id: 'e$i', title: 'E$i', artist: 'A')];
    final e = Expedition(
      'ex',
      'Ex',
      '',
      [for (final a in albums) ExpeditionStop.ofAlbum(a)],
      inOrder: true,
      custom: true,
    );
    await store.rate(albums[0], 7);
    await store.rate(albums[1], 8.5);
    expect(expeditionAverage(store, e), 7.8);
    await store.rateExpedition('ex', 9);
    expect(store.expeditionRating('ex'), 9);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await store.resetProgress('ex');
    expect(ratedCount(store, e), 0);
    expect(unlockedCount(store, e), 1);
    expect(store.ratingOf('e0'), 7); // album ratings are kept
    expect(store.expeditionRating('ex'), isNull);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await store.rate(albums[0], 7);
    expect(ratedCount(store, e), 1);
  });

  test('editing an expedition keeps its place and id', () async {
    final store = await Store.load();
    const a = Album(id: 'z', title: 'Z', artist: 'A');
    const b = Album(id: 'y', title: 'Y', artist: 'A');
    await store.saveExpedition(
      Expedition('one', 'One', '', [
        ExpeditionStop.ofAlbum(a),
        ExpeditionStop.ofAlbum(b),
      ], custom: true),
    );
    await store.saveExpedition(
      Expedition('two', 'Two', '', [
        ExpeditionStop.ofAlbum(a),
        ExpeditionStop.ofAlbum(b),
      ], custom: true),
    );
    await store.saveExpedition(
      Expedition(
        'one',
        'One renamed',
        '',
        [ExpeditionStop.ofAlbum(b), ExpeditionStop.ofAlbum(a)],
        inOrder: true,
        custom: true,
      ),
    );
    final list = (await Store.load()).customExpeditions;
    expect(list.map((e) => e.name), ['One renamed', 'Two']);
    expect(list.first.stops.first.album!.id, 'y');
    expect(list.first.inOrder, isTrue);
  });

  test('ratings display without trailing .0', () {
    expect(fmt(8), '8');
    expect(fmt(8.5), '8.5');
  });
}
