import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalogue.dart';
import 'details.dart';
import 'expeditions.dart';
import 'models.dart';

/// One saved rating, with enough album info to show it in lists.
class RatedAlbum {
  final Album album;
  final double rating;
  final DateTime ratedAt;
  const RatedAlbum(this.album, this.rating, this.ratedAt);
}

/// Everything the user saves, kept on the device only (no accounts yet).
class Store extends ChangeNotifier {
  final SharedPreferences _prefs;
  final Map<String, double> _ratings; // album id -> 0..10 in 0.5 steps
  final Map<String, Album> _info; // album id -> album details (rated, saved or pinned)
  final Map<String, int> _ratedAt; // album id -> time rated (ms)
  final Map<String, Album> _resolved; // old expedition stop key -> album (pre-v0.4 data)
  final List<Expedition> _custom; // expeditions the user made
  final List<String> _listenLater; // album ids, newest first
  final List<String?> _range; // "Your Range": up to 5 pinned album ids, in order
  final Map<String, double> _expeditionRatings; // expedition id -> rating
  final Map<String, int> _resetAt; // expedition id -> time progress was reset (ms)
  String _nickname;

  static const rangeSize = 5;

  Store._(
    this._prefs,
    this._ratings,
    this._info,
    this._ratedAt,
    this._resolved,
    this._custom,
    this._listenLater,
    this._range,
    this._expeditionRatings,
    this._resetAt,
    this._nickname,
  );

  static Future<Store> load() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> read(String key) =>
        Map<String, dynamic>.from(jsonDecode(prefs.getString(key) ?? '{}') as Map);
    List<dynamic> readList(String key) => jsonDecode(prefs.getString(key) ?? '[]') as List;
    Album album(dynamic v) => Album.fromJson(Map<String, dynamic>.from(v as Map));

    final range = [for (final v in readList('range')) v as String?];
    final store = Store._(
      prefs,
      read('ratings').map((k, v) => MapEntry(k, (v as num).toDouble())),
      read('rated_info').map((k, v) => MapEntry(k, album(v))),
      read('rated_at').map((k, v) => MapEntry(k, v as int)),
      read('resolved').map((k, v) => MapEntry(k, album(v))),
      [
        for (final e in readList('custom_expeditions'))
          Expedition.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      [for (final v in readList('listen_later')) v as String],
      [...range, ...List<String?>.filled(rangeSize - range.length, null)].take(rangeSize).toList(),
      read('expedition_ratings').map((k, v) => MapEntry(k, (v as num).toDouble())),
      read('reset_at').map((k, v) => MapEntry(k, v as int)),
      prefs.getString('nickname') ?? '',
    );
    store._trackRatings = read('track_ratings').map((k, v) => MapEntry(k, (v as num).toDouble()));
    store._trackInfo = read('track_info')
        .map((k, v) => MapEntry(k, Track.fromJson(Map<String, dynamic>.from(v as Map))));
    store._reviews = read('reviews')
        .map((k, v) => MapEntry(k, Review.fromJson(Map<String, dynamic>.from(v as Map))));
    store._reports = readList('reports');
    return store;
  }

  // ------------------------------------------------------------ albums

  /// Moves anything saved under an album's old ID to its current one (the
  /// library sometimes corrects which MusicBrainz entry an album points at).
  Future<void> applyAliases(Map<String, String> aliases) async {
    var changed = false;
    void move<T>(Map<String, T> map) {
      for (final old in map.keys.where(aliases.containsKey).toList()) {
        final value = map.remove(old) as T;
        map.putIfAbsent(aliases[old]!, () => value);
        changed = true;
      }
    }

    move(_ratings);
    move(_ratedAt);
    move(_info);
    for (var i = 0; i < _listenLater.length; i++) {
      if (aliases[_listenLater[i]] case final now?) {
        _listenLater[i] = now;
        changed = true;
      }
    }
    for (var i = 0; i < _range.length; i++) {
      if (aliases[_range[i]] case final now?) {
        _range[i] = now;
        changed = true;
      }
    }
    final unique = _listenLater.toSet().toList();
    _listenLater
      ..clear()
      ..addAll(unique);
    final reviews = {
      for (final e in _reviews.entries)
        if (e.key.startsWith('album:') && aliases.containsKey(e.key.substring(6)))
          e.key: 'album:${aliases[e.key.substring(6)]}',
    };
    for (final e in reviews.entries) {
      _reviews.putIfAbsent(e.value, () => _reviews[e.key]!);
      _reviews.remove(e.key);
      changed = true;
    }
    if (!changed) return;
    // Info entries still hold the old ID inside; refresh them from the library.
    for (final id in _info.keys.toList()) {
      if (Catalogue.byId(id) case final a?) _info[id] = a;
    }
    await _prefs.setString('ratings', jsonEncode(_ratings));
    await _prefs.setString('rated_at', jsonEncode(_ratedAt));
    await _prefs.setString('rated_info', jsonEncode(_info.map((k, v) => MapEntry(k, v.toJson()))));
    await _prefs.setString('listen_later', jsonEncode(_listenLater.toSet().toList()));
    await _prefs.setString('range', jsonEncode(_range));
    await _prefs.setString('reviews', jsonEncode(_reviews.map((k, v) => MapEntry(k, v.toJson()))));
    notifyListeners();
  }

  /// The freshest details for an album: the bundled catalogue first.
  Album? albumById(String id) =>
      Catalogue.byId(id) ?? _info[id] ?? _resolved.values.where((a) => a.id == id).firstOrNull;

  Future<void> _remember(Album a) async {
    _info[a.id] = a;
    await _prefs.setString('rated_info', jsonEncode(_info.map((k, v) => MapEntry(k, v.toJson()))));
  }

  // ------------------------------------------------------------ ratings

  double? ratingOf(String albumId) => _ratings[albumId];
  int ratedAtOf(String albumId) => _ratedAt[albumId] ?? 0;

  /// How many ratings an album has. Only this device's for now; becomes the
  /// community count once there are online accounts.
  int ratingCount(String albumId) => _ratings.containsKey(albumId) ? 1 : 0;

  /// Average rating across everyone. Only this device's for now.
  double? averageOf(String albumId) => _ratings[albumId];

  /// Saves a rating, or removes it when [score] is null.
  /// Saves a rating (null removes it). [at] restores the original time when
  /// undoing a removal, so expedition progress comes back exactly as it was.
  Future<void> rate(Album album, double? score, {int? at}) async {
    final id = album.id;
    if (score == null) {
      _ratings.remove(id);
      _ratedAt.remove(id);
    } else {
      _ratings[id] = (score * 2).round() / 2; // snap to 0.5 steps
      _ratedAt[id] = at ?? DateTime.now().millisecondsSinceEpoch;
      await _remember(album);
    }
    await _prefs.setString('ratings', jsonEncode(_ratings));
    await _prefs.setString('rated_at', jsonEncode(_ratedAt));
    notifyListeners();
  }

  /// All rated albums, most recently rated first.
  List<RatedAlbum> get ratedAlbums {
    final list = <RatedAlbum>[
      for (final e in _ratings.entries)
        if (albumById(e.key) case final a?)
          RatedAlbum(a, e.value, DateTime.fromMillisecondsSinceEpoch(_ratedAt[e.key] ?? 0)),
    ];
    list.sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
    return list;
  }

  // ------------------------------------------------------------ listen later

  bool isListenLater(String albumId) => _listenLater.contains(albumId);

  List<Album> get listenLater => [for (final id in _listenLater) ?albumById(id)];

  /// Adds or removes an album from the listen-later list. Returns true when added.
  Future<bool> toggleListenLater(Album album) async {
    final added = !_listenLater.remove(album.id);
    if (added) {
      _listenLater.insert(0, album.id);
      await _remember(album);
    }
    await _prefs.setString('listen_later', jsonEncode(_listenLater));
    notifyListeners();
    return added;
  }

  // ------------------------------------------------------------ profile

  String get nickname => _nickname;

  Future<void> setNickname(String value) async {
    _nickname = value.trim();
    await _prefs.setString('nickname', _nickname);
    notifyListeners();
  }

  /// The five "Your Range" slots, in the user's order; null = empty.
  List<Album?> get range => [for (final id in _range) id == null ? null : albumById(id)];

  bool isPinned(String albumId) => _range.contains(albumId);
  bool get rangeFull => !_range.contains(null);

  /// Pins an album into the first empty slot, or into [slot] (replacing what's there).
  Future<void> pin(Album album, {int? slot}) async {
    if (isPinned(album.id)) return;
    final i = slot ?? _range.indexOf(null);
    if (i < 0) return;
    _range[i] = album.id;
    await _remember(album);
    await _saveRange();
  }

  Future<void> unpin(String albumId) async {
    final i = _range.indexOf(albumId);
    if (i < 0) return;
    _range[i] = null;
    await _saveRange();
  }

  Future<void> _saveRange() async {
    await _prefs.setString('range', jsonEncode(_range));
    notifyListeners();
  }

  // ------------------------------------------------------------ expeditions

  Album? resolvedStop(String key) => _resolved[key];

  Future<void> saveResolvedStop(String key, Album album) async {
    _resolved[key] = album;
    await _prefs.setString(
      'resolved',
      jsonEncode(_resolved.map((k, v) => MapEntry(k, v.toJson()))),
    );
    notifyListeners();
  }

  List<Expedition> get customExpeditions => List.unmodifiable(_custom);

  /// Adds a new expedition, or replaces an edited one in place.
  Future<void> saveExpedition(Expedition e) async {
    final i = _custom.indexWhere((x) => x.id == e.id);
    if (i >= 0) {
      _custom[i] = e;
    } else {
      _custom.add(e);
    }
    await _saveCustom();
  }

  Future<void> deleteExpedition(String id) async {
    _custom.removeWhere((x) => x.id == id);
    await _saveCustom();
  }

  Future<void> _saveCustom() async {
    await _prefs.setString('custom_expeditions', jsonEncode([for (final e in _custom) e.toJson()]));
    notifyListeners();
  }

  double? expeditionRating(String id) => _expeditionRatings[id];

  Future<void> rateExpedition(String id, double? score) async {
    if (score == null) {
      _expeditionRatings.remove(id);
    } else {
      _expeditionRatings[id] = (score * 2).round() / 2;
    }
    await _prefs.setString('expedition_ratings', jsonEncode(_expeditionRatings));
    notifyListeners();
  }

  final Map<String, (int?, double?)> _undoReset = {};

  /// Puts an expedition back as it was before the last reset (for Undo).
  Future<void> undoReset(String id) async {
    final prev = _undoReset.remove(id);
    if (prev == null) return;
    final (at, rating) = prev;
    if (at == null) {
      _resetAt.remove(id);
    } else {
      _resetAt[id] = at;
    }
    if (rating != null) _expeditionRatings[id] = rating;
    await _prefs.setString('reset_at', jsonEncode(_resetAt));
    await _prefs.setString('expedition_ratings', jsonEncode(_expeditionRatings));
    notifyListeners();
  }

  /// When progress on an expedition was last reset (0 = never).
  int resetAtOf(String id) => _resetAt[id] ?? 0;

  /// Starts an expedition over. Album ratings are kept; albums count again
  /// once you rate them afresh. The expedition's own rating is cleared.
  Future<void> resetProgress(String id) async {
    _undoReset[id] = (_resetAt[id], _expeditionRatings[id]);
    _resetAt[id] = DateTime.now().millisecondsSinceEpoch;
    _expeditionRatings.remove(id);
    await _prefs.setString('reset_at', jsonEncode(_resetAt));
    await _prefs.setString('expedition_ratings', jsonEncode(_expeditionRatings));
    notifyListeners();
  }

  // ------------------------------------------------------------ tracks

  Map<String, double> _trackRatings = {}; // recording id -> 0..10
  Map<String, Track> _trackInfo = {}; // recording id -> track details (rated tracks)

  double? trackRatingOf(String trackId) => _trackRatings[trackId];

  /// Only this device's for now, like albums.
  int trackRatingCount(String trackId) => _trackRatings.containsKey(trackId) ? 1 : 0;
  double? trackAverageOf(String trackId) => _trackRatings[trackId];

  Future<void> rateTrack(Track track, double? score) async {
    if (score == null) {
      _trackRatings.remove(track.id);
    } else {
      _trackRatings[track.id] = (score * 2).round() / 2;
      _trackInfo[track.id] = track;
      await _prefs.setString(
        'track_info',
        jsonEncode(_trackInfo.map((k, v) => MapEntry(k, v.toJson()))),
      );
    }
    await _prefs.setString('track_ratings', jsonEncode(_trackRatings));
    notifyListeners();
  }

  // ------------------------------------------------------------ reviews

  /// Reviews are keyed by what they are about: `album:ID` or `track:ID`.
  /// Kept on the phone for now; likes, comments and reports become shared
  /// once there are online accounts.
  Map<String, Review> _reviews = {};
  List<dynamic> _reports = [];

  Review? reviewOf(String subject) => _reviews[subject];

  /// All of the user's reviews, newest first, as (subject, review).
  List<(String, Review)> get reviews =>
      [for (final e in _reviews.entries) (e.key, e.value)]
        ..sort((a, b) => b.$2.at.compareTo(a.$2.at));

  /// A rated track's details (to open its page from a list).
  Track? trackInfo(String trackId) => _trackInfo[trackId];

  /// Saves the user's review; empty text deletes it.
  Future<void> saveReview(String subject, String text) async {
    final t = text.trim();
    if (t.isEmpty) {
      _reviews.remove(subject);
    } else {
      final old = _reviews[subject];
      _reviews[subject] = Review(
        text: t,
        at: DateTime.now().millisecondsSinceEpoch,
        liked: old?.liked ?? false,
        comments: old?.comments ?? const [],
      );
    }
    await _saveReviews();
  }

  Future<void> toggleLike(String subject) async {
    final r = _reviews[subject];
    if (r == null) return;
    _reviews[subject] = r.copyWith(liked: !r.liked);
    await _saveReviews();
  }

  Future<void> addComment(String subject, String text) async {
    final r = _reviews[subject];
    if (r == null || text.trim().isEmpty) return;
    _reviews[subject] = r.copyWith(
      comments: [
        ...r.comments,
        ReviewComment(text: text.trim(), at: DateTime.now().millisecondsSinceEpoch),
      ],
    );
    await _saveReviews();
  }

  /// Records a report on a review (or on one of its comments). With no server
  /// yet, it is only kept on the phone.
  Future<void> report(String subject, String reason, {int? comment}) async {
    final r = _reviews[subject];
    if (r == null) return;
    if (comment == null) {
      _reviews[subject] = r.copyWith(reported: true);
    } else {
      final list = [...r.comments];
      list[comment] = list[comment].copyWith(reported: true);
      _reviews[subject] = r.copyWith(comments: list);
    }
    _reports.add({
      'subject': subject,
      'comment': comment,
      'reason': reason,
      'at': DateTime.now().millisecondsSinceEpoch,
    });
    await _prefs.setString('reports', jsonEncode(_reports));
    await _saveReviews();
  }

  Future<void> _saveReviews() async {
    await _prefs.setString('reviews', jsonEncode(_reviews.map((k, v) => MapEntry(k, v.toJson()))));
    notifyListeners();
  }
}

class Review {
  final String text;
  final int at; // when written (ms)
  final bool liked;
  final bool reported;
  final List<ReviewComment> comments;
  const Review({
    required this.text,
    required this.at,
    this.liked = false,
    this.reported = false,
    this.comments = const [],
  });

  Review copyWith({bool? liked, bool? reported, List<ReviewComment>? comments}) => Review(
    text: text,
    at: at,
    liked: liked ?? this.liked,
    reported: reported ?? this.reported,
    comments: comments ?? this.comments,
  );

  Map<String, dynamic> toJson() => {
    'text': text,
    'at': at,
    'liked': liked,
    'reported': reported,
    'comments': [for (final c in comments) c.toJson()],
  };
  factory Review.fromJson(Map<String, dynamic> j) => Review(
    text: j['text'] as String,
    at: j['at'] as int,
    liked: j['liked'] as bool? ?? false,
    reported: j['reported'] as bool? ?? false,
    comments: [
      for (final c in (j['comments'] as List?) ?? const [])
        ReviewComment.fromJson(Map<String, dynamic>.from(c as Map)),
    ],
  );
}

class ReviewComment {
  final String text;
  final int at;
  final bool reported;
  const ReviewComment({required this.text, required this.at, this.reported = false});

  ReviewComment copyWith({bool? reported}) =>
      ReviewComment(text: text, at: at, reported: reported ?? this.reported);

  Map<String, dynamic> toJson() => {'text': text, 'at': at, 'reported': reported};
  factory ReviewComment.fromJson(Map<String, dynamic> j) => ReviewComment(
    text: j['text'] as String,
    at: j['at'] as int,
    reported: j['reported'] as bool? ?? false,
  );
}
