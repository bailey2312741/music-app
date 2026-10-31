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
    final stop = expeditions.first.stops.last;
    await store.saveResolvedStop(
        stop.key, const Album(id: 'x', title: 't', artist: 'a'));
    expect(difficultyOf(store, 'x'), Difficulty.summit);
    expect(difficultyOf(store, 'other'), isNull);
  });

  test('stops are unique across expeditions', () {
    final keys = [for (final e in expeditions) ...e.stops.map((s) => s.key)];
    expect(keys.toSet().length, keys.length);
    expect(expeditions.length, 3);
  });

  test('ratings display without trailing .0', () {
    expect(fmt(8), '8');
    expect(fmt(8.5), '8.5');
  });
}
