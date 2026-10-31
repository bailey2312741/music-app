import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalogue.dart';
import 'expeditions.dart';
import 'models.dart';

/// One saved rating, with enough album info to show it in the Ratings tab.
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
  final Map<String, Album> _ratedInfo; // album id -> album details
  final Map<String, int> _ratedAt; // album id -> time rated (ms)
  final Map<String, Album> _resolved; // expedition stop key -> MusicBrainz album
  final List<Expedition> _custom; // expeditions the user made

  Store._(this._prefs, this._ratings, this._ratedInfo, this._ratedAt, this._resolved, this._custom);

  static Future<Store> load() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> read(String key) =>
        Map<String, dynamic>.from(jsonDecode(prefs.getString(key) ?? '{}') as Map);
    Album album(dynamic v) => Album.fromJson(Map<String, dynamic>.from(v as Map));

    return Store._(
      prefs,
      read('ratings').map((k, v) => MapEntry(k, (v as num).toDouble())),
      read('rated_info').map((k, v) => MapEntry(k, album(v))),
      read('rated_at').map((k, v) => MapEntry(k, v as int)),
      read('resolved').map((k, v) => MapEntry(k, album(v))),
      [
        for (final e in jsonDecode(prefs.getString('custom_expeditions') ?? '[]') as List)
          Expedition.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
    );
  }

  double? ratingOf(String albumId) => _ratings[albumId];

  /// Saves a rating, or removes it when [score] is null.
  Future<void> rate(Album album, double? score) async {
    final id = album.id;
    if (score == null) {
      _ratings.remove(id);
      _ratedInfo.remove(id);
      _ratedAt.remove(id);
    } else {
      _ratings[id] = (score * 2).round() / 2; // snap to 0.5 steps
      _ratedInfo[id] = album;
      _ratedAt[id] = DateTime.now().millisecondsSinceEpoch;
    }
    await _prefs.setString('ratings', jsonEncode(_ratings));
    await _prefs.setString(
      'rated_info',
      jsonEncode(_ratedInfo.map((k, v) => MapEntry(k, v.toJson()))),
    );
    await _prefs.setString('rated_at', jsonEncode(_ratedAt));
    notifyListeners();
  }

  /// All rated albums, most recently rated first.
  List<RatedAlbum> get ratedAlbums {
    final byId = {for (final a in _resolved.values) a.id: a, ..._ratedInfo};
    final list = <RatedAlbum>[
      for (final e in _ratings.entries)
        if (Catalogue.byId(e.key) != null || byId[e.key] != null)
          RatedAlbum(
            Catalogue.byId(e.key) ?? byId[e.key]!,
            e.value,
            DateTime.fromMillisecondsSinceEpoch(_ratedAt[e.key] ?? 0),
          ),
    ];
    list.sort((a, b) => b.ratedAt.compareTo(a.ratedAt));
    return list;
  }

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

  Future<void> saveExpedition(Expedition e) async {
    _custom.removeWhere((x) => x.id == e.id);
    _custom.add(e);
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
}
