import 'difficulty.dart';
import 'store.dart';

/// One stop on an expedition. The MusicBrainz ID is looked up on the phone
/// the first time the expedition opens, then remembered.
class ExpeditionStop {
  final String title;
  final String artist;

  /// Hand-set placeholder until AI difficulty scoring exists.
  final Difficulty? difficulty;

  const ExpeditionStop(this.title, this.artist, this.difficulty);

  String get key => '$artist — $title';
}

class Expedition {
  final String name;
  final String blurb;
  final List<ExpeditionStop> stops; // in the curator's suggested order
  const Expedition(this.name, this.blurb, this.stops);
}

/// The single test expedition for the base app. Order: chronological.
const ambientExpedition = Expedition(
  'Into the Ambient',
  'Five records tracing ambient music from its naming to its outer edges.',
  [
    ExpeditionStop('Ambient 1: Music for Airports', 'Brian Eno', Difficulty.foothills),
    ExpeditionStop('Chill Out', 'The KLF', Difficulty.foothills),
    ExpeditionStop('Selected Ambient Works 85–92', 'Aphex Twin', Difficulty.baseCamp),
    ExpeditionStop('The Tired Sounds of Stars of the Lid', 'Stars of the Lid', Difficulty.highAltitude),
    ExpeditionStop('The Disintegration Loops', 'William Basinski', Difficulty.summit),
  ],
);

/// Difficulty is known only for expedition albums for now; others show none.
Difficulty? difficultyOf(Store store, String albumId) {
  for (final s in ambientExpedition.stops) {
    if (store.resolvedStop(s.key)?.id == albumId) return s.difficulty;
  }
  return null;
}
