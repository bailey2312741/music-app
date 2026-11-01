/// An album. The ID is the MusicBrainz release-group ID when known.
class Album {
  final String id;
  final String title;
  final String artist;
  final String? year;
  final String? type; // Studio, EP, Live
  final String? genre; // main genre, from Bailey's sheet
  final List<String> subgenres;
  final int popularity; // listens on ListenBrainz (0 when unknown)
  final String? coverRelease; // Cover Art Archive release ID for the checked cover
  final String? coverImage; // Cover Art Archive image ID
  final String? cover; // older saved albums: direct cover image URL
  final String? coverLarge;

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.year,
    this.type,
    this.genre,
    this.subgenres = const [],
    this.popularity = 0,
    this.coverRelease,
    this.coverImage,
    this.cover,
    this.coverLarge,
  });

  /// All genre tags, main genre first.
  List<String> get tags => [?genre, ...subgenres];

  /// Empty when the album has no checked cover (the app then shows a plain
  /// placeholder, never a guess).
  String coverUrl({bool large = false}) {
    if (coverRelease != null && coverImage != null) {
      return 'https://coverartarchive.org/release/$coverRelease/$coverImage-${large ? 500 : 250}';
    }
    if (large && coverLarge != null) return coverLarge!;
    return cover ?? '';
  }

  /// One row of the bundled library file (short keys keep the file small).
  factory Album.fromLibrary(Map<String, dynamic> j) => Album(
    id: j['id'] as String,
    title: j['t'] as String,
    artist: j['a'] as String,
    year: j['y'] as String?,
    type: j['ty'] as String?,
    genre: j['g'] as String?,
    subgenres: [for (final s in (j['s'] as List?) ?? const []) s as String],
    popularity: (j['p'] as num?)?.toInt() ?? 0,
    coverRelease: j['cr'] as String?,
    coverImage: j['ci'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'year': year,
    'type': type,
    'genre': genre,
    'subgenres': subgenres,
    'popularity': popularity,
    'coverRelease': coverRelease,
    'coverImage': coverImage,
    'cover': cover,
    'coverLarge': coverLarge,
  };

  factory Album.fromJson(Map<String, dynamic> j) => Album(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    year: j['year'] as String?,
    type: j['type'] as String?,
    genre: j['genre'] as String?,
    subgenres: [for (final s in (j['subgenres'] as List?) ?? const []) s as String],
    popularity: (j['popularity'] as num?)?.toInt() ?? 0,
    coverRelease: j['coverRelease'] as String?,
    coverImage: j['coverImage'] as String?,
    cover: j['cover'] as String?,
    coverLarge: j['coverLarge'] as String?,
  );
}
