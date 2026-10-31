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

/// Test expeditions for the base app. Difficulty levels are hand-set placeholders.
const expeditions = [
  Expedition(
    'Into the Ambient',
    'Five records tracing ambient music from its naming to its outer edges.',
    [
      ExpeditionStop('Ambient 1: Music for Airports', 'Brian Eno', Difficulty.foothills),
      ExpeditionStop('Chill Out', 'The KLF', Difficulty.foothills),
      ExpeditionStop('Selected Ambient Works 85–92', 'Aphex Twin', Difficulty.baseCamp),
      ExpeditionStop(
        'The Tired Sounds of Stars of the Lid',
        'Stars of the Lid',
        Difficulty.highAltitude,
      ),
      ExpeditionStop('The Disintegration Loops', 'William Basinski', Difficulty.summit),
    ],
  ),
  Expedition(
    'Golden Age Hip-Hop',
    'How hip-hop albums grew from party records into the late-80s and early-90s classics.',
    [
      ExpeditionStop('Raising Hell', 'Run-DMC', Difficulty.baseCamp),
      ExpeditionStop(
        'It Takes a Nation of Millions to Hold Us Back',
        'Public Enemy',
        Difficulty.foothills,
      ),
      ExpeditionStop('The Low End Theory', 'A Tribe Called Quest', Difficulty.baseCamp),
      ExpeditionStop('Enter the Wu-Tang (36 Chambers)', 'Wu-Tang Clan', Difficulty.foothills),
      ExpeditionStop('Illmatic', 'Nas', Difficulty.baseCamp),
    ],
  ),
  Expedition('Jazz Breaks Free', 'From modal cool to free jazz in six years.', [
    ExpeditionStop('Kind of Blue', 'Miles Davis', Difficulty.baseCamp),
    ExpeditionStop('The Shape of Jazz to Come', 'Ornette Coleman', Difficulty.foothills),
    ExpeditionStop('Out to Lunch!', 'Eric Dolphy', Difficulty.highAltitude),
    ExpeditionStop('A Love Supreme', 'John Coltrane', Difficulty.foothills),
    ExpeditionStop('Spiritual Unity', 'Albert Ayler Trio', Difficulty.summit),
  ]),
];

/// Difficulty is known only for expedition albums for now; others show none.
Difficulty? difficultyOf(Store store, String albumId) {
  for (final e in expeditions) {
    for (final s in e.stops) {
      if (store.resolvedStop(s.key)?.id == albumId) return s.difficulty;
    }
  }
  return null;
}

/// How many stops of an expedition the user has rated.
int ratedCount(Store store, Expedition e) => e.stops.where((s) {
  final album = store.resolvedStop(s.key);
  return album != null && store.ratingOf(album.id) != null;
}).length;
