import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// The app's album library, bundled with the app (built by
/// tool/build_library.py). Albums are kept most popular first.
class Catalogue {
  static List<Album> albums = [];
  static Map<String, Album> _byId = {};
  static Map<String, String> aliases = {}; // old album ID -> current one
  static Map<String, Album> _byKey = {};
  static Map<String, List<Album>> _byArtist = {};
  static Map<String, int> _artistPopularity = {};
  static List<String> _artists = [];
  static List<String> _featured = [];
  static List<String> _families = [];
  static List<String> _genres = [];
  // Normalised text per album, worked out once so search stays fast.
  static List<(String, String, String)> _text = [];

  static Future<void> load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/catalogue.json'));
    if (raw is List) {
      // Older file format (version 0.5 and before).
      use([for (final a in raw) Album.fromJson(Map<String, dynamic>.from(a as Map))]);
      return;
    }
    final j = Map<String, dynamic>.from(raw as Map);
    use(
      [for (final a in j['albums'] as List) Album.fromLibrary(Map<String, dynamic>.from(a as Map))],
      featured: [for (final n in (j['featuredArtists'] as List?) ?? const []) n as String],
    );
    aliases = Map<String, String>.from((j['aliases'] as Map?) ?? const {});
  }

  /// Sets the albums directly (also used by tests). [featured] is the list
  /// of artists shown as cards, most popular first.
  static void use(List<Album> list, {List<String>? featured}) {
    albums = [...list]..sort((a, b) => b.popularity.compareTo(a.popularity));
    _byId = {for (final a in albums) a.id: a};
    _byKey = {for (final a in albums) key(a.title, a.artist): a};
    _byArtist = {};
    _artistPopularity = {};
    for (final a in albums) {
      (_byArtist[a.artist] ??= []).add(a);
      _artistPopularity[a.artist] = (_artistPopularity[a.artist] ?? 0) + a.popularity;
    }
    for (final own in _byArtist.values) {
      own.sort((a, b) => (a.year ?? '').compareTo(b.year ?? ''));
    }
    _artists = _byArtist.keys.toList()
      ..sort((a, b) {
        final c = (_artistPopularity[b] ?? 0).compareTo(_artistPopularity[a] ?? 0);
        return c != 0 ? c : sortName(a).compareTo(sortName(b));
      });
    _featured = featured ?? _artists.take(2000).toList();
    final counts = <String, int>{};
    for (final a in albums) {
      if (a.genre case final g?) counts[g] = (counts[g] ?? 0) + 1;
    }
    _families = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    final sub = {for (final a in albums) ...a.subgenres}.difference(counts.keys.toSet()).toList()
      ..sort();
    _genres = [..._families, ...sub];
    _text = [for (final a in albums) (norm(a.title), norm(a.artist), norm(a.tags.join(' ')))];
  }

  static String norm(String s) => s
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[‐-―]'), '-')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  static String key(String title, String artist) => '${norm(artist)}|${norm(title)}';

  /// Name used for A to Z order: ignores case, punctuation and a leading "The".
  static String sortName(String s) => norm(s).replaceFirst(RegExp(r'^the '), '');

  static Album? byId(String id) => _byId[id] ?? _byId[aliases[id]];
  static Album? find(String title, String artist) => _byKey[key(title, artist)];

  /// Every artist, most popular first.
  static List<String> get artists => _artists;

  /// Artists shown as cards: the most popular ones plus any extra artists given
  /// (the artists the user has rated), most popular first.
  static List<String> featuredArtists([Iterable<String> extra = const []]) {
    final set = {..._featured};
    final more = [
      for (final a in extra)
        if (!set.contains(a) && _byArtist.containsKey(a)) a,
    ];
    return [..._featured, ...more.toSet()];
  }

  static int artistPopularity(String artist) => _artistPopularity[artist] ?? 0;

  /// The artist's most popular album that has a cover (for the artist card).
  static Album? artistImage(String artist) {
    final own = _byArtist[artist] ?? const <Album>[];
    Album? best;
    for (final a in own) {
      if (a.coverUrl().isEmpty) continue;
      if (best == null || a.popularity > best.popularity) best = a;
    }
    return best ?? own.firstOrNull;
  }

  /// Main genres, the biggest first.
  static List<String> get families => _families;

  /// Every genre tag in use: main genres first, then subgenres A to Z.
  static List<String> get genres => _genres;

  /// Albums in one genre tag, most popular first.
  static List<Album> inGenre(String genre) => albums.where((a) => a.tags.contains(genre)).toList();

  /// One artist's albums, oldest first.
  static List<Album> byArtist(String artist) => [...?_byArtist[artist]];

  /// Albums whose title, artist or genre tags contain every word typed,
  /// optionally limited to one genre tag. Best matches first, then most popular.
  static List<Album> search(String text, {String? genre}) {
    final q = norm(text);
    final words = q.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return genre == null ? albums : inGenre(genre);
    final hits = <(Album, int)>[];
    for (var i = 0; i < albums.length; i++) {
      final a = albums[i];
      if (genre != null && !a.tags.contains(genre)) continue;
      final (title, artist, tags) = _text[i];
      bool has(String w) => title.contains(w) || artist.contains(w) || tags.contains(w);
      if (!words.every(has)) continue;
      final score = (title == q || artist == q)
          ? 3
          : (title.startsWith(q) || artist.startsWith(q))
          ? 2
          : (title.contains(q) || artist.contains(q))
          ? 1
          : 0;
      hits.add((a, score));
    }
    // Albums are already most popular first, and sort is stable for equal scores.
    _bucketByScore(hits);
    return [for (final h in hits) h.$1];
  }

  static void _bucketByScore(List<(Album, int)> hits) {
    final buckets = [<(Album, int)>[], <(Album, int)>[], <(Album, int)>[], <(Album, int)>[]];
    for (final h in hits) {
      buckets[3 - h.$2].add(h);
    }
    hits
      ..clear()
      ..addAll(buckets.expand((b) => b));
  }

  /// Artists whose name contains everything typed: names starting with it
  /// first, then most popular.
  static List<String> searchArtists(String text) {
    final q = norm(text);
    if (q.isEmpty) return [];
    final starts = <String>[], contains = <String>[];
    for (final a in _artists) {
      final n = norm(a);
      if (n.startsWith(q) || sortName(a).startsWith(q)) {
        starts.add(a);
      } else if (n.contains(q)) {
        contains.add(a);
      }
    }
    return [...starts, ...contains];
  }
}
