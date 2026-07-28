import 'package:flutter_test/flutter_test.dart';

import 'package:etherly/models/station.dart';
import 'package:etherly/services/audio_player_service.dart';

void main() {
  group('Station Model Unit Tests', () {
    test('Station constructor sets properties correctly', () {
      final station = Station(
        id: 'st_1',
        name: 'NPO Radio 1',
        slogan: 'Het nieuws van alle kanten',
        streams: {'mp3': 'https://stream.radio1.nl'},
        art: {'300': 'https://example.com/300.jpg', '600': 'https://example.com/600.jpg'},
        category: 'News',
        country: 'NL',
        rank: 1,
        tags: ['news', 'talk'],
      );

      expect(station.id, equals('st_1'));
      expect(station.name, equals('NPO Radio 1'));
      expect(station.slogan, equals('Het nieuws van alle kanten'));
      expect(station.category, equals('News'));
      expect(station.country, equals('NL'));
      expect(station.rank, equals(1));
      expect(station.isFavorite, isFalse);
    });

    test('getArtUrl returns best fit size', () {
      final station = Station(
        id: 'st_1',
        name: 'Radio Test',
        slogan: 'Test Slogan',
        streams: {'mp3': 'https://stream.test'},
        art: {
          '100': 'https://example.com/100.jpg',
          '300': 'https://example.com/300.jpg',
          '600': 'https://example.com/600.jpg',
          'default': 'https://example.com/default.jpg',
        },
        category: 'Music',
        country: 'NL',
      );

      expect(station.getArtUrl(size: 250), equals('https://example.com/300.jpg'));
      expect(station.getArtUrl(size: 50), equals('https://example.com/100.jpg'));
      expect(station.getArtUrl(size: 1000), equals('https://example.com/600.jpg'));
      expect(station.getArtUrl(), equals('https://example.com/600.jpg'));
    });

    test('toMediaItem converts Station to MediaItem cleanly', () {
      final station = Station(
        id: 'st_1',
        name: 'Radio Test',
        slogan: 'Test Slogan',
        streams: {'mp3': 'https://stream.test'},
        art: {'default': 'https://example.com/default.jpg'},
        category: 'Music',
        country: 'NL',
      );

      final mediaItem = station.toMediaItem();
      expect(mediaItem.id, equals('st_1'));
      expect(mediaItem.title, equals('Radio Test'));
      expect(mediaItem.extras?['url'], equals('https://stream.test'));
    });
  });
}
