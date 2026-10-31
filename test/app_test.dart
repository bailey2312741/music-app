import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/difficulty.dart';
import 'package:music_app/expeditions.dart';
import 'package:music_app/models.dart';
import 'package:music_app/screens.dart';
import 'package:music_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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

  test('ratings display without trailing .0', () {
    expect(fmt(8), '8');
    expect(fmt(8.5), '8.5');
  });
}
