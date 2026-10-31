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
    await store.rate('a', 7.3);
    expect(store.ratingOf('a'), 7.5);
    final reloaded = await Store.load();
    expect(reloaded.ratingOf('a'), 7.5);
    await reloaded.rate('a', null);
    expect(reloaded.ratingOf('a'), isNull);
  });

  test('difficulty only shows for expedition albums', () async {
    final store = await Store.load();
    final stop = ambientExpedition.stops.last;
    await store.saveResolvedStop(
        stop.key, const Album(id: 'x', title: 't', artist: 'a'));
    expect(difficultyOf(store, 'x'), Difficulty.summit);
    expect(difficultyOf(store, 'other'), isNull);
  });

  test('ratings display without trailing .0', () {
    expect(fmt(8), '8');
    expect(fmt(8.5), '8.5');
  });
}
