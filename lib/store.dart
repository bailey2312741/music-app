import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Everything the user saves, kept on the device only (no accounts yet).
class Store extends ChangeNotifier {
  final SharedPreferences _prefs;
  final Map<String, double> _ratings; // album id -> 0..10 in 0.5 steps
  final Map<String, Album> _resolved; // expedition stop key -> MusicBrainz album

  Store._(this._prefs, this._ratings, this._resolved);

  static Future<Store> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ratings = (jsonDecode(prefs.getString('ratings') ?? '{}') as Map)
        .map((k, v) => MapEntry(k as String, (v as num).toDouble()));
    final resolved = (jsonDecode(prefs.getString('resolved') ?? '{}') as Map).map(
        (k, v) => MapEntry(k as String, Album.fromJson(Map<String, dynamic>.from(v))));
    return Store._(prefs, ratings, resolved);
  }

  double? ratingOf(String albumId) => _ratings[albumId];

  Future<void> rate(String albumId, double? score) async {
    if (score == null) {
      _ratings.remove(albumId);
    } else {
      _ratings[albumId] = (score * 2).round() / 2; // snap to 0.5 steps
    }
    await _prefs.setString('ratings', jsonEncode(_ratings));
    notifyListeners();
  }

  Album? resolvedStop(String key) => _resolved[key];

  Future<void> saveResolvedStop(String key, Album album) async {
    _resolved[key] = album;
    await _prefs.setString(
        'resolved', jsonEncode(_resolved.map((k, v) => MapEntry(k, v.toJson()))));
    notifyListeners();
  }
}
