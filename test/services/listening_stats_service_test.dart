import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:etherly/services/listening_stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListeningStatsService Unit Tests', () {
    late ListeningStatsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = ListeningStatsService();
      await service.init();
    });

    test('Initial history and recent stations are empty', () {
      expect(service.history, isEmpty);
      expect(service.recentStationIds, isEmpty);
    });

    test('addSong inserts song into history', () async {
      await service.addSong(
        title: 'Song Title',
        artist: 'Artist Name',
        stationId: 'st_1',
        stationName: 'Test Station',
        stationArtUrl: 'https://example.com/art.jpg',
      );

      expect(service.history.length, equals(1));
      expect(service.history.first.title, equals('Song Title'));
      expect(service.history.first.artist, equals('Artist Name'));
    });

    test('addRecentStation keeps most recent station at index 0', () async {
      await service.addRecentStation('st_1');
      await service.addRecentStation('st_2');

      expect(service.recentStationIds.first, equals('st_2'));
      expect(service.recentStationIds.length, equals(2));
    });

    test('clearHistory empties history list', () async {
      await service.addSong(
        title: 'Song Title',
        artist: 'Artist Name',
        stationId: 'st_1',
        stationName: 'Test Station',
        stationArtUrl: 'https://example.com/art.jpg',
      );
      expect(service.history, isNotEmpty);

      await service.clearHistory();
      expect(service.history, isEmpty);
    });
  });
}
