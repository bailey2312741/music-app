import 'catalogue.dart';
import 'difficulty.dart';
import 'models.dart';
import 'store.dart';

/// One stop on an expedition. Built-in stops name an album by title and artist,
/// found in the bundled catalogue; stops in user-made expeditions already
/// carry the album picked from search.
class ExpeditionStop {
  final String title;
  final String artist;

  /// Hand-set placeholder until AI difficulty scoring exists.
  final Difficulty? difficulty;
  final Album? album;

  const ExpeditionStop(this.title, this.artist, this.difficulty, {this.album});

  factory ExpeditionStop.ofAlbum(Album a) => ExpeditionStop(a.title, a.artist, null, album: a);

  String get key => album != null ? 'id:${album!.id}' : '$artist — $title';
}

class Expedition {
  final String id;
  final String name;
  final String blurb;
  final List<ExpeditionStop> stops; // in the curator's suggested order

  /// When true, each album unlocks only after the one before it is rated.
  final bool inOrder;

  /// Made by the user on this device.
  final bool custom;

  const Expedition(
    this.id,
    this.name,
    this.blurb,
    this.stops, {
    this.inOrder = false,
    this.custom = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'blurb': blurb,
    'inOrder': inOrder,
    'albums': [for (final s in stops) s.album!.toJson()],
  };

  factory Expedition.fromJson(Map<String, dynamic> j) => Expedition(
    j['id'] as String,
    j['name'] as String,
    (j['blurb'] as String?) ?? '',
    [
      for (final a in j['albums'] as List)
        ExpeditionStop.ofAlbum(Album.fromJson(Map<String, dynamic>.from(a as Map))),
    ],
    inOrder: j['inOrder'] as bool? ?? false,
    custom: true,
  );
}

/// Built-in test expeditions. Difficulty levels are hand-set placeholders.
const builtInExpeditions = [
  Expedition(
    'ambient',
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
    'hiphop',
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
  Expedition(
    'jazz',
    'Jazz Breaks Free',
    'From modal cool to free jazz in six years. Each album unlocks once you rate the one before.',
    [
      ExpeditionStop('Kind of Blue', 'Miles Davis', Difficulty.baseCamp),
      ExpeditionStop('The Shape of Jazz to Come', 'Ornette Coleman', Difficulty.foothills),
      ExpeditionStop('Out to Lunch!', 'Eric Dolphy', Difficulty.highAltitude),
      ExpeditionStop('A Love Supreme', 'John Coltrane', Difficulty.foothills),
      ExpeditionStop('Spiritual Unity', 'Albert Ayler Trio', Difficulty.summit),
    ],
    inOrder: true,
  ),
];

/// Built-in expeditions first, then the user's own.
List<Expedition> allExpeditions(Store store) => [...builtInExpeditions, ...store.customExpeditions];

/// The album behind a stop, once known.
Album? albumFor(Store store, ExpeditionStop s) =>
    s.album ?? Catalogue.find(s.title, s.artist) ?? store.resolvedStop(s.key);

bool isRated(Store store, ExpeditionStop s) {
  final a = albumFor(store, s);
  return a != null && store.ratingOf(a.id) != null;
}

/// Difficulty is known only for built-in expedition albums for now; others show none.
Difficulty? difficultyOf(Store store, String albumId) {
  for (final e in builtInExpeditions) {
    for (final s in e.stops) {
      if (albumFor(store, s)?.id == albumId) return s.difficulty;
    }
  }
  return null;
}

/// How many stops of an expedition the user has rated.
int ratedCount(Store store, Expedition e) => e.stops.where((s) => isRated(store, s)).length;

/// How many stops are open. In-order expeditions open one stop past the
/// furthest rated one, so removing an earlier rating doesn't lock anything again.
int unlockedCount(Store store, Expedition e) {
  if (!e.inOrder) return e.stops.length;
  var furthest = -1;
  for (var i = 0; i < e.stops.length; i++) {
    if (isRated(store, e.stops[i])) furthest = i;
  }
  return (furthest + 2).clamp(1, e.stops.length);
}

/// First unrated open stop, or null when everything open is rated.
int? nextStop(Store store, Expedition e) {
  final open = unlockedCount(store, e);
  for (var i = 0; i < open; i++) {
    if (!isRated(store, e.stops[i])) return i;
  }
  return null;
}
