import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// One song on an album. The ID is the MusicBrainz recording ID, so the same
/// song keeps its rating wherever it appears.
class Track {
  final String id;
  final String number; // as printed on the release, e.g. "3" or "A1"
  final String title;
  final int? ms; // length
  final String albumId;
  const Track({
    required this.id,
    required this.number,
    required this.title,
    required this.albumId,
    this.ms,
  });

  Map<String, dynamic> toJson() => {'id': id, 'n': number, 't': title, 'ms': ms, 'al': albumId};
  factory Track.fromJson(Map<String, dynamic> j) => Track(
    id: j['id'] as String,
    number: j['n'] as String? ?? '',
    title: j['t'] as String,
    ms: (j['ms'] as num?)?.toInt(),
    albumId: j['al'] as String,
  );
}

/// Extra album facts loaded from MusicBrainz the first time an album is opened,
/// then saved on the phone.
class AlbumDetails {
  final String? date; // "2006", "2006-01" or "2006-01-23"
  final String? label;
  final List<Track> tracks;
  const AlbumDetails({this.date, this.label, this.tracks = const []});

  int? get totalMs {
    if (tracks.isEmpty || tracks.any((t) => t.ms == null)) return null;
    return tracks.fold<int>(0, (sum, t) => sum + t.ms!);
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'label': label,
    'tracks': [for (final t in tracks) t.toJson()],
  };
  factory AlbumDetails.fromJson(Map<String, dynamic> j) => AlbumDetails(
    date: j['date'] as String?,
    label: j['label'] as String?,
    tracks: [
      for (final t in (j['tracks'] as List?) ?? const [])
        Track.fromJson(Map<String, dynamic>.from(t as Map)),
    ],
  );

  /// Picks the first official release of the album (falling back to the one
  /// the cover comes from) from a MusicBrainz release-group lookup.
  static String? pickRelease(Map<String, dynamic> group, {String? prefer}) {
    final releases = [
      for (final r in (group['releases'] as List?) ?? const []) Map<String, dynamic>.from(r as Map),
    ];
    if (releases.isEmpty) return prefer;
    int rank(Map<String, dynamic> r) =>
        (r['status'] == 'Official' ? 0 : 2) + ((r['date'] as String?)?.isNotEmpty == true ? 0 : 1);
    releases.sort((a, b) {
      final c = rank(a).compareTo(rank(b));
      if (c != 0) return c;
      final d = ((a['date'] as String?) ?? '9999').compareTo((b['date'] as String?) ?? '9999');
      if (d != 0) return d;
      return (b['id'] == prefer ? 1 : 0).compareTo(a['id'] == prefer ? 1 : 0);
    });
    return releases.first['id'] as String?;
  }

  /// Builds the details from a MusicBrainz release (with recordings and labels).
  factory AlbumDetails.fromRelease(
    String albumId,
    Map<String, dynamic> release, {
    String? firstDate,
  }) {
    final tracks = <Track>[];
    for (final m in (release['media'] as List?) ?? const []) {
      for (final t in ((m as Map)['tracks'] as List?) ?? const []) {
        final tm = Map<String, dynamic>.from(t as Map);
        final rec = Map<String, dynamic>.from((tm['recording'] as Map?) ?? const {});
        tracks.add(
          Track(
            id: (rec['id'] ?? tm['id']) as String,
            number: (tm['number'] ?? '${tm['position'] ?? tracks.length + 1}').toString(),
            title: (tm['title'] ?? rec['title'] ?? '') as String,
            ms: ((tm['length'] ?? rec['length']) as num?)?.toInt(),
            albumId: albumId,
          ),
        );
      }
    }
    final labels = [
      for (final l in (release['label-info'] as List?) ?? const [])
        if (((l as Map)['label'] as Map?)?['name'] case final String name) name,
    ];
    final date = (firstDate?.isNotEmpty == true) ? firstDate : release['date'] as String?;
    return AlbumDetails(
      date: date?.isNotEmpty == true ? date : null,
      label: labels.isEmpty ? null : labels.toSet().join(', '),
      tracks: tracks,
    );
  }
}

/// Loads album details: from the phone if saved, otherwise from MusicBrainz.
class DetailsLoader {
  static const _base = 'https://musicbrainz.org/ws/2';
  static DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  static final Map<String, AlbumDetails> _memory = {};

  static AlbumDetails? cached(String albumId) => _memory[albumId];

  static Future<AlbumDetails?> load(Album album) async {
    if (album.id.isEmpty || album.id.startsWith('local:')) return null;
    if (_memory[album.id] case final d?) return d;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('details:${album.id}');
    if (saved != null) {
      return _memory[album.id] = AlbumDetails.fromJson(
        Map<String, dynamic>.from(jsonDecode(saved) as Map),
      );
    }
    final group = await _get('release-group/${album.id}?inc=releases&fmt=json');
    final releaseId = AlbumDetails.pickRelease(group, prefer: album.coverRelease);
    if (releaseId == null) return const AlbumDetails();
    final release = await _get('release/$releaseId?inc=recordings+labels&fmt=json');
    final details = AlbumDetails.fromRelease(
      album.id,
      release,
      firstDate: group['first-release-date'] as String?,
    );
    await prefs.setString('details:${album.id}', jsonEncode(details.toJson()));
    return _memory[album.id] = details;
  }

  /// MusicBrainz allows about one request a second, so requests wait their turn.
  static Future<Map<String, dynamic>> _get(String path) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final wait = const Duration(milliseconds: 1100) - DateTime.now().difference(_last);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _last = DateTime.now();
      final res = await http
          .get(
            Uri.parse('$_base/$path'),
            headers: {
              'Accept': 'application/json',
              // Browsers don't allow setting this; MusicBrainz asks apps to.
              if (!kIsWeb)
                'User-Agent': 'MusicApp/0.7 (https://github.com/bailey2312741/music-app)',
            },
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(utf8.decode(res.bodyBytes)) as Map);
      }
      if (res.statusCode != 503 && res.statusCode != 429) {
        throw Exception('MusicBrainz ${res.statusCode}');
      }
      await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
    }
    throw Exception('MusicBrainz is busy');
  }
}

/// "3:45", or "1:02:03" for long ones.
String fmtLength(int ms) {
  final s = (ms / 1000).round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  final ss = sec.toString().padLeft(2, '0');
  return h > 0 ? '$h:${m.toString().padLeft(2, '0')}:$ss' : '$m:$ss';
}

/// "January 23, 2006" (or less when only the year or month is known).
String fmtDate(String date) {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June', //
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final p = date.split('-');
  if (p.length >= 3) return '${months[int.parse(p[1]) - 1]} ${int.parse(p[2])}, ${p[0]}';
  if (p.length == 2) return '${months[int.parse(p[1]) - 1]} ${p[0]}';
  return p[0];
}

/// "42 min 17 sec".
String fmtDuration(int ms) {
  final s = (ms / 1000).round();
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  return [if (h > 0) '$h hr', '$m min', '$sec sec'].join(' ');
}
