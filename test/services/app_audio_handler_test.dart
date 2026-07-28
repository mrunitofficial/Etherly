import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:etherly/services/app_audio_handler.dart';

class MockAudioSession extends Fake implements AudioSession {}

class FakeAudioPlayer extends Fake implements AudioPlayer {
  @override
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  PlaybackEvent get playbackEvent => PlaybackEvent();

  @override
  Future<void> stop() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAudioHandler Unit Tests', () {
    late AppAudioHandler handler;

    setUp(() {
      handler = AppAudioHandler(
        player: FakeAudioPlayer(),
        session: MockAudioSession(),
        onSkipNext: () async {},
        onSkipPrev: () async {},
      );
    });

    test('Initial mediaItem and playbackState are clean', () {
      expect(handler.mediaItem.value, isNull);
      expect(handler.isRemoteSession, isFalse);
    });

    test('updateMediaItem updates mediaItem Subject', () async {
      const item = MediaItem(
        id: 'st_1',
        title: 'NPO Radio 1',
        artist: 'Slogan',
      );

      await handler.updateMediaItem(item);
      expect(handler.mediaItem.value?.id, equals('st_1'));
      expect(handler.mediaItem.value?.title, equals('NPO Radio 1'));
    });

    test('updateRemotePlaybackState sets isRemoteSession to true', () async {
      const item = MediaItem(
        id: 'st_1',
        title: 'NPO Radio 1',
      );
      await handler.updateMediaItem(item);

      handler.updateRemotePlaybackState(playing: true, isBuffering: false);
      expect(handler.isRemoteSession, isTrue);
      expect(handler.playbackState.value.playing, isTrue);
      expect(handler.playbackState.value.processingState, equals(AudioProcessingState.ready));
    });

    test('clearNotification resets mediaItem and isRemoteSession', () async {
      const item = MediaItem(
        id: 'st_1',
        title: 'NPO Radio 1',
      );
      await handler.updateMediaItem(item);
      handler.updateRemotePlaybackState(playing: true, isBuffering: false);

      await handler.clearNotification();
      expect(handler.isRemoteSession, isFalse);
      expect(handler.mediaItem.value, isNull);
      expect(handler.playbackState.value.playing, isFalse);
    });
  });
}
