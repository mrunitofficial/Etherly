import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:etherly/models/station.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPlayerService Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (MethodCall methodCall) async {
              return '.';
            },
          );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_service.client'),
            (MethodCall methodCall) async {
              return null;
            },
          );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_service.handler'),
            (MethodCall methodCall) async {
              return null;
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_service.client'),
            null,
          );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.ryanheise.audio_service.handler'),
            null,
          );
    });

    test('Station favorite toggle logic works via copyWith', () {
      final station = Station(
        id: 'st_1',
        name: 'Test Radio',
        slogan: 'Best Music',
        streams: {'mp3': 'https://stream.test'},
        art: {'default': 'https://example.com/art.jpg'},
        category: 'Pop',
        country: 'NL',
        isFavorite: false,
      );

      expect(station.isFavorite, isFalse);
      final updated = station.copyWith(isFavorite: true);
      expect(updated.isFavorite, isTrue);
      expect(station.isFavorite, isFalse);
    });
  });
}
