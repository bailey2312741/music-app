/// An album. The ID is the MusicBrainz release-group ID when known.
class Album {
  final String id;
  final String title;
  final String artist;
  final String? year;
  final String? type; // Studio, EP, Live
  final String? genre; // main genre, from Bailey's sheet
  final List<String> subgenres;
  final String? cover; // small cover image (250px)
  final String? coverLarge; // large cover image (500px)

  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.year,
    this.type,
    this.genre,
    this.subgenres = const [],
    this.cover,
    this.coverLarge,
  });

  /// All genre tags, main genre first.
  List<String> get tags => [?genre, ...subgenres];

  String coverUrl({bool large = false}) {
    if (large && coverLarge != null) return coverLarge!;
    if (cover != null) return cover!;
    if (id.isEmpty || id.startsWith('local:')) return '';
    return 'https://coverartarchive.org/release-group/$id/front-250';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'year': year,
    'type': type,
    'genre': genre,
    'subgenres': subgenres,
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
    cover: j['cover'] as String?,
    coverLarge: j['coverLarge'] as String?,
  );
}
