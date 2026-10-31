import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'models.dart';

/// Minimal client for the free MusicBrainz API.
/// MusicBrainz asks for a descriptive User-Agent and at most ~1 request/second.
class MusicBrainz {
  static const _base = 'https://musicbrainz.org/ws/2';
  static const _headers = {
    'User-Agent': 'MusicApp/0.1 (https://github.com/bailey2312741/music-app)',
    'Accept': 'application/json',
  };

  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<void> _throttle() async {
    final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_last);
    if (!wait.isNegative) await Future.delayed(wait);
    _last = DateTime.now();
  }

  /// Searches albums and EPs. Singles, compilations and live albums are left out.
  static Future<List<Album>> search(String text, {int limit = 25}) async {
    final q = text.trim();
    if (q.isEmpty) return [];
    return _query('($q) AND (primarytype:album OR primarytype:ep)', limit);
  }

  /// Finds one specific album by title and artist (used for expedition stops).
  static Future<Album?> find(String title, String artist) async {
    final results = await _query(
        'releasegroup:"${_esc(title)}" AND artist:"${_esc(artist)}" AND primarytype:album', 5);
    return results.isEmpty ? null : results.first;
  }

  static String _esc(String s) => s.replaceAll('"', r'\"');

  static Future<List<Album>> _query(String query, int limit) async {
    await _throttle();
    final uri = Uri.parse('$_base/release-group')
        .replace(queryParameters: {'query': query, 'fmt': 'json', 'limit': '$limit'});
    // Browsers don't allow setting User-Agent, so the web version sends no headers.
    final res = await http.get(uri, headers: kIsWeb ? null : _headers);
    if (res.statusCode != 200) {
      throw Exception('MusicBrainz error ${res.statusCode}');
    }
    final groups = (jsonDecode(res.body)['release-groups'] as List?) ?? [];
    return groups.where(_isStudioRelease).map(_toAlbum).toList();
  }

  // Keep plain studio albums and EPs: drop compilations, live albums, soundtracks etc.
  static bool _isStudioRelease(dynamic g) {
    final secondary = (g['secondary-types'] as List?) ?? const [];
    return secondary.isEmpty;
  }

  static Album _toAlbum(dynamic g) {
    final credits = (g['artist-credit'] as List?) ?? const [];
    final artist = credits
        .map((c) => '${c['name'] ?? c['artist']?['name'] ?? ''}${c['joinphrase'] ?? ''}')
        .join();
    final date = g['first-release-date'] as String?;
    return Album(
      id: g['id'] as String,
      title: g['title'] as String? ?? '?',
      artist: artist.isEmpty ? 'Unknown artist' : artist,
      year: (date != null && date.length >= 4) ? date.substring(0, 4) : null,
      type: g['primary-type'] as String?,
    );
  }
}
