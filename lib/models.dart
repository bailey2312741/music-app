/// An album (a MusicBrainz "release group").
class Album {
  final String id; // MusicBrainz release-group ID
  final String title;
  final String artist;
  final String? year;
  final String? type; // Album, EP, ...

  const Album({required this.id, required this.title, required this.artist, this.year, this.type});

  String get coverUrl =>
      id.isEmpty ? '' : 'https://coverartarchive.org/release-group/$id/front-250';

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'artist': artist,
    'year': year,
    'type': type,
  };

  factory Album.fromJson(Map<String, dynamic> j) => Album(
    id: j['id'] as String,
    title: j['title'] as String,
    artist: j['artist'] as String,
    year: j['year'] as String?,
    type: j['type'] as String?,
  );
}
