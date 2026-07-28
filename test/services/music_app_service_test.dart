import 'package:flutter_test/flutter_test.dart';

import 'package:etherly/models/music_app.dart';
import 'package:etherly/services/music_app_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MusicAppService Unit Tests', () {
    late MusicAppService service;

    setUp(() {
      service = MusicAppService();
    });

    test('getAllSupportedApps returns full set of supported music apps', () {
      final apps = service.getAllSupportedApps();
      expect(apps, isNotEmpty);
      final ids = apps.map((app) => app['id']).toList();
      expect(ids, contains('youtube'));
      expect(ids, contains('spotify'));
      expect(ids, contains('apple_music'));
    });

    test('MusicApp model constructs valid search URLs', () {
      const app = MusicApp(
        id: 'spotify',
        name: 'Spotify',
      );

      expect(app.id, equals('spotify'));
      expect(app.name, equals('Spotify'));
      final searchUri = app.getSearchUri('Daft Punk');
      expect(searchUri.toString(), contains('spotify:search:Daft%20Punk'));
    });
  });
}
