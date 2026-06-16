import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/models/song.dart';

class HistoryService extends ChangeNotifier {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _historyKey = 'played_songs_history';
  SharedPreferences? _prefs;
  List<Song> _history = [];

  List<Song> get history => _history;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHistory();
  }

  void _loadHistory() {
    if (_prefs == null) return;
    final jsonList = _prefs!.getStringList(_historyKey);
    if (jsonList != null) {
      try {
        _history = jsonList
            .map((item) => Song.fromJson(jsonDecode(item) as Map<String, dynamic>))
            .toList();
        _pruneOldEntries();
      } catch (e) {
        if (kDebugMode) print('Error parsing song history: $e');
        _history = [];
      }
    }
  }

  Future<void> addSong({
    required String title,
    required String artist,
    required String stationId,
    required String stationName,
    required String stationArtUrl,
  }) async {
    if (_prefs == null) return;

    // Check if the exact same song was the very last one added to avoid duplicate contiguous listings
    if (_history.isNotEmpty) {
      final last = _history.first;
      if (last.title == title && last.artist == artist && last.stationId == stationId) {
        return;
      }
    }

    final newSong = Song(
      title: title,
      artist: artist,
      timestamp: DateTime.now(),
      stationId: stationId,
      stationName: stationName,
      stationArtUrl: stationArtUrl,
    );

    _history.insert(0, newSong);
    _pruneOldEntries();
    await _saveHistory();
    notifyListeners();
  }

  void _pruneOldEntries() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _history.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
  }

  Future<void> _saveHistory() async {
    if (_prefs == null) return;
    final jsonList = _history
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    await _prefs!.setStringList(_historyKey, jsonList);
  }

  Future<void> clearHistory() async {
    _history.clear();
    if (_prefs != null) {
      await _prefs!.remove(_historyKey);
    }
    notifyListeners();
  }
}
