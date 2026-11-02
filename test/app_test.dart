import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/chart.dart';
import 'package:music_app/details.dart';
import 'package:music_app/difficulty.dart';
import 'package:music_app/expeditions.dart';
import 'package:music_app/models.dart';
import 'package:music_app/page_parts.dart';
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

  test('library rows: exact covers, popularity order, featured artists', () async {
    final hit = Album.fromLibrary({
      'id': 'p1',
      't': 'Popular',
      'a': 'Big Band',
      'y': '2001',
      'ty': 'Live',
      'g': 'Rock',
      'p': 900,
      'cr': 'rel',
      'ci': '42',
    });
    final noCover = Album.fromLibrary({'id': 'p2', 't': 'Quiet', 'a': 'Small Band', 'p': 5});
    expect(hit.coverUrl(), 'https://coverartarchive.org/release/rel/42-250');
    expect(hit.coverUrl(large: true), 'https://coverartarchive.org/release/rel/42-500');
    expect(noCover.coverUrl(), ''); // placeholder, never a guessed cover
    expect(Album.fromJson(hit.toJson()).coverUrl(), hit.coverUrl());

    Catalogue.use([noCover, ...Catalogue.albums, hit], featured: ['Big Band']);
    expect(Catalogue.albums.first.id, 'p1'); // most popular first
    expect(Catalogue.search('band').map((a) => a.id), ['p1', 'p2']);
    expect(Catalogue.inGenre('Rock').first.id, 'p1');
    expect(Catalogue.featuredArtists(), ['Big Band']);
    expect(Catalogue.featuredArtists(['Small Band', 'Nobody']), ['Big Band', 'Small Band']);
    expect(Catalogue.artistImage('Big Band')?.id, 'p1');

    final store = await Store.load();
    final sorted = const SortOrder(SortBy.popularity).apply([noCover, hit], store);
    expect(sorted.first.id, 'p1');
  });

  test('album details: first official release, tracks, label, date', () {
    final group = {
      'first-release-date': '1997-05-21',
      'releases': [
        {'id': 'reissue', 'status': 'Official', 'date': '2009-03-24'},
        {'id': 'bootleg', 'status': 'Bootleg', 'date': '1996-01-01'},
        {'id': 'first', 'status': 'Official', 'date': '1997-05-21'},
      ],
    };
    expect(AlbumDetails.pickRelease(group, prefer: 'reissue'), 'first');
    expect(AlbumDetails.pickRelease(const {}, prefer: 'cover'), 'cover');
    final d = AlbumDetails.fromRelease('rg', {
      'date': '1997-06-16',
      'label-info': [
        {
          'label': {'name': 'Parlophone'},
        },
        {
          'label': {'name': 'Parlophone'},
        },
      ],
      'media': [
        {
          'tracks': [
            {
              'number': '1',
              'title': 'Airbag',
              'length': 284000,
              'recording': {'id': 'r1'},
            },
            {
              'number': '2',
              'title': 'Paranoid Android',
              'length': 383000,
              'recording': {'id': 'r2'},
            },
          ],
        },
      ],
    }, firstDate: '1997-05-21');
    expect(d.tracks.map((t) => t.id), ['r1', 'r2']);
    expect(d.label, 'Parlophone');
    expect(fmtDate(d.date!), 'May 21, 1997');
    expect(fmtDuration(d.totalMs!), '11 min 7 sec');
    expect(fmtLength(284000), '4:44');
    final back = AlbumDetails.fromJson(d.toJson());
    expect(back.tracks.last.title, 'Paranoid Android');
  });

  test('track ratings, reviews, likes, comments and reports persist', () async {
    final store = await Store.load();
    const t = Track(id: 'r1', number: '1', title: 'Airbag', albumId: 'rg', ms: 284000);
    await store.rateTrack(t, 8.6);
    await store.saveReview('album:rg', '  Great record  ');
    await store.toggleLike('album:rg');
    await store.addComment('album:rg', 'Agreed');
    await store.report('album:rg', 'Spam', comment: 0);
    final again = await Store.load();
    expect(again.trackRatingOf('r1'), 8.5);
    expect(again.trackRatingCount('r1'), 1);
    final r = again.reviewOf('album:rg')!;
    expect(r.text, 'Great record');
    expect(r.liked, isTrue);
    expect(r.comments.single.reported, isTrue);
    expect(r.reported, isFalse);
    await again.saveReview('album:rg', '');
    expect(again.reviewOf('album:rg'), isNull);
  });

  test('rating spread groups scores into whole numbers', () {
    final b = ratingBuckets([8.5, 8, 0, 10, 7.4]);
    expect(b[9], 1);
    expect(b[8], 1);
    expect(b[0], 1);
    expect(b[10], 1);
    expect(b[7], 1);
  });

  test('saved ratings follow an album when its ID is corrected', () async {
    SharedPreferences.setMockInitialValues({
      'ratings': '{"old-bends": 9}',
      'rated_at': '{"old-bends": 5}',
      'listen_later': '["old-bends"]',
      'range': '["old-bends"]',
      'reviews': '{"album:old-bends": {"text": "Great", "at": 1}}',
    });
    Catalogue.use([
      ...Catalogue.albums,
      const Album(id: 'bends', title: 'The Bends', artist: 'Radiohead', year: '1995'),
    ]);
    Catalogue.aliases = {'old-bends': 'bends'};
    expect(Catalogue.byId('old-bends')?.id, 'bends');
    final store = await Store.load();
    await store.applyAliases(Catalogue.aliases);
    expect(store.ratingOf('bends'), 9);
    expect(store.ratingOf('old-bends'), isNull);
    expect(store.isListenLater('bends'), isTrue);
    expect(store.isPinned('bends'), isTrue);
    expect(store.reviewOf('album:bends')?.text, 'Great');
    final again = await Store.load();
    expect(again.ratingOf('bends'), 9);
    Catalogue.aliases = {};
  });

  testWidgets('v0.8: tab bar stays on album pages, rating bar saves and clears', (t) async {
    final store = await Store.load();
    await t.pumpWidget(MaterialApp.router(routerConfig: buildRouter(store)));
    await t.pumpAndSettle();
    expect(find.text('Discover'), findsWidgets);
    expect(find.text('Popular'), findsOneWidget);
    await t.enterText(find.byType(TextField), 'kind of blue');
    await t.pumpAndSettle();
    await t.tap(find.text('Kind of Blue').last);
    await t.pumpAndSettle();
    // Album page: tab bar still there, rating bar unrated.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(RatingBar), findsOneWidget);
    expect(find.text('tap to clear'), findsNothing);
    await store.rate(Catalogue.byId('k1')!, 8);
    await t.pumpAndSettle();
    expect(find.text('tap to clear'), findsOneWidget);
    await t.tap(find.text('tap to clear'));
    await t.pumpAndSettle();
    expect(store.ratingOf('k1'), isNull);
    expect(find.text('Rating removed'), findsOneWidget);
    await t.tap(find.text('Undo'));
    await t.pumpAndSettle();
    expect(store.ratingOf('k1'), 8);
    // You tab, with the Rated list.
    await t.tap(find.text('You').first);
    await t.pumpAndSettle();
    expect(find.text('Rated (1)'), findsOneWidget);
  });

  test('v0.8: reset progress can be undone; release date and date rated sorts', () async {
    final store = await Store.load();
    final e = builtInExpeditions.first;
    await store.rateExpedition(e.id, 7);
    await store.resetProgress(e.id);
    expect(store.expeditionRating(e.id), isNull);
    await store.undoReset(e.id);
    expect(store.expeditionRating(e.id), 7);

    final albums = Catalogue.albums;
    expect(const SortOrder(SortBy.releaseDate).apply(albums, store).first.id, 'k1');
    await store.rate(albums[1], 5, at: 1000);
    await store.rate(albums[0], 6, at: 2000);
    expect(const SortOrder(SortBy.dateRated).apply(albums, store).take(2).map((a) => a.id), [
      'b1',
      'b2',
    ]);
  });
}
