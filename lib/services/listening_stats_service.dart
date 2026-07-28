import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:etherly/models/song.dart';

/// Centralized service for tracking played songs history, recent stations, and station listening metrics.
class ListeningStatsService extends ChangeNotifier {
  static final ListeningStatsService _instance =
      ListeningStatsService._internal();

  /// Factory constructor returning the singleton instance.
  factory ListeningStatsService() => _instance;
  ListeningStatsService._internal();

  static const String _historyKey = 'played_songs_history';
  static const String _recentStationIdsKey = 'recent_station_ids';
  static const String _minuteTicksKey = 'most_listened_minute_ticks';
  static const int _maxRecentStations = 10;
  static const int _maxMinuteWindow = 500;
  static const int _maxTopStations = 10;

  SharedPreferences? _prefs;
  List<Song> _history = [];
  List<String> _recentStationIds = [];
  List<String> _minuteTicks = [];

  /// Unmodifiable view of played songs history.
  List<Song> get history => List.unmodifiable(_history);

  /// Unmodifiable view of recent station IDs.
  List<String> get recentStationIds => List.unmodifiable(_recentStationIds);

  /// Initializes SharedPreferences and loads persisted stats.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAll();
  }

  /// Loads all stored statistics from SharedPreferences.
  void _loadAll() {
    if (_prefs == null) return;
    _loadHistory();
    _loadRecentStations();
    _loadMinuteTicks();
  }

  /// Loads song history from SharedPreferences.
  void _loadHistory() {
    final jsonList = _prefs!.getStringList(_historyKey);
    if (jsonList != null) {
      try {
        _history = jsonList
            .map(
              (item) => Song.fromJson(jsonDecode(item) as Map<String, dynamic>),
            )
            .toList();
        _pruneOldSongs();
      } catch (e) {
        if (kDebugMode) print('Error parsing song history: $e');
        _history = [];
      }
    }
  }

  /// Loads recent station IDs from SharedPreferences.
  void _loadRecentStations() {
    _recentStationIds = _prefs!.getStringList(_recentStationIdsKey) ?? [];
  }

  /// Loads minute ticks buffer from SharedPreferences.
  void _loadMinuteTicks() {
    _minuteTicks = _prefs!.getStringList(_minuteTicksKey) ?? [];
    if (_minuteTicks.length > _maxMinuteWindow) {
      _minuteTicks = _minuteTicks.sublist(
        _minuteTicks.length - _maxMinuteWindow,
      );
    }
  }

  /// Adds a song to history if not duplicate of the last entry.
  Future<void> addSong({
    required String title,
    required String artist,
    required String stationId,
    required String stationName,
    required String stationArtUrl,
  }) async {
    if (_prefs == null) return;

    if (_history.isNotEmpty) {
      final last = _history.first;
      if (last.title == title &&
          last.artist == artist &&
          last.stationId == stationId) {
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
    _pruneOldSongs();
    await _saveHistory();
    notifyListeners();
  }

  /// Removes older song entries beyond 7 days.
  void _pruneOldSongs() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _history.removeWhere((entry) => entry.timestamp.isBefore(cutoff));
  }

  /// Saves song history to SharedPreferences.
  Future<void> _saveHistory() async {
    if (_prefs == null) return;
    final jsonList = _history
        .map((entry) => jsonEncode(entry.toJson()))
        .toList();
    await _prefs!.setStringList(_historyKey, jsonList);
  }

  /// Removes a single song entry from history.
  Future<void> removeSong(Song song) async {
    _history.remove(song);
    await _saveHistory();
    notifyListeners();
  }

  /// Clears all song history.
  Future<void> clearHistory() async {
    _history.clear();
    if (_prefs != null) {
      await _prefs!.remove(_historyKey);
    }
    notifyListeners();
  }

  /// Adds a station ID to recent stations list.
  Future<void> addRecentStation(String stationId) async {
    _recentStationIds.remove(stationId);
    _recentStationIds.insert(0, stationId);
    if (_recentStationIds.length > _maxRecentStations) {
      _recentStationIds = _recentStationIds.sublist(0, _maxRecentStations);
    }
    await _prefs?.setStringList(_recentStationIdsKey, _recentStationIds);
    notifyListeners();
  }

  /// Records 1 minute of listening time for a station ID in the rolling 500-minute window.
  Future<void> recordListeningMinute(String stationId) async {
    _minuteTicks.add(stationId);
    if (_minuteTicks.length > _maxMinuteWindow) {
      _minuteTicks.removeAt(0);
    }
    await _prefs?.setStringList(_minuteTicksKey, _minuteTicks);
    notifyListeners();
  }

  /// Returns up to 10 most listened station IDs in the last 500 minutes ordered by minutes played.
  List<String> getMostListenedStationIds() {
    if (_minuteTicks.isEmpty) return [];

    final counts = <String, int>{};
    for (final id in _minuteTicks) {
      counts[id] = (counts[id] ?? 0) + 1;
    }

    final sortedEntries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEntries
        .take(_maxTopStations)
        .map((entry) => entry.key)
        .toList();
  }
}
