import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// The app's album list, bundled with the app (built from data/albums.json
/// by tool/build_catalogue.py). Search only looks through these albums.
class Catalogue {
  static List<Album> albums = [];
  static Map<String, Album> _byId = {};
  static Map<String, Album> _byKey = {};

  static Future<void> load() async {
    final raw = jsonDecode(await rootBundle.loadString('assets/catalogue.json')) as List;
    use([for (final a in raw) Album.fromJson(Map<String, dynamic>.from(a as Map))]);
  }

  /// Sets the albums directly (used by tests).
  static void use(List<Album> list) {
    albums = list;
    _byId = {for (final a in list) a.id: a};
    _byKey = {for (final a in list) key(a.title, a.artist): a};
  }

  static String norm(String s) => s
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[‐-―]'), '-')
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .trim();

  static String key(String title, String artist) => '${norm(artist)}|${norm(title)}';

  static Album? byId(String id) => _byId[id];
  static Album? find(String title, String artist) => _byKey[key(title, artist)];

  /// Every artist name, A to Z.
  static List<String> get artists {
    final set = {for (final a in albums) a.artist}.toList();
    set.sort((a, b) => _sortName(a).compareTo(_sortName(b)));
    return set;
  }

  static String _sortName(String s) => norm(s).replaceFirst(RegExp(r'^the '), '');

  /// Every genre tag in use, main genres first, then subgenres, each A to Z.
  static List<String> get genres {
    final main = {for (final a in albums) ?a.genre}.toList()..sort();
    final sub = {for (final a in albums) ...a.subgenres}.difference(main.toSet()).toList()..sort();
    return [...main, ...sub];
  }

  static List<Album> byArtist(String artist) =>
      albums.where((a) => a.artist == artist).toList()
        ..sort((a, b) => (a.year ?? '').compareTo(b.year ?? ''));

  /// Albums whose title, artist or genre tags contain every word typed,
  /// optionally limited to one genre tag. Best matches first.
  static List<Album> search(String text, {String? genre}) {
    final words = norm(text).split(' ').where((w) => w.isNotEmpty).toList();
    final q = norm(text);
    final hits = <(Album, int)>[];
    for (final a in albums) {
      if (genre != null && !a.tags.contains(genre)) continue;
      final title = norm(a.title), artist = norm(a.artist);
      final hay = '$title $artist ${norm(a.tags.join(' '))}';
      if (!words.every(hay.contains)) continue;
      final score = q.isEmpty
          ? 0
          : (title == q || artist == q)
          ? 3
          : (title.startsWith(q) || artist.startsWith(q))
          ? 2
          : (title.contains(q) || artist.contains(q))
          ? 1
          : 0;
      hits.add((a, score));
    }
    hits.sort((x, y) {
      final s = y.$2.compareTo(x.$2);
      if (s != 0) return s;
      final ar = _sortName(x.$1.artist).compareTo(_sortName(y.$1.artist));
      return ar != 0 ? ar : (x.$1.year ?? '').compareTo(y.$1.year ?? '');
    });
    return [for (final h in hits) h.$1];
  }

  /// Artists whose name contains everything typed.
  static List<String> searchArtists(String text) {
    final q = norm(text);
    if (q.isEmpty) return [];
    final list = artists.where((a) => norm(a).contains(q)).toList();
    list.sort((a, b) => (norm(a).startsWith(q) ? 0 : 1).compareTo(norm(b).startsWith(q) ? 0 : 1));
    return list;
  }
}
