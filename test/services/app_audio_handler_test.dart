import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:etherly/services/app_audio_handler.dart';

/// Mock implementation of AudioSession for testing.
class MockAudioSession extends Fake implements AudioSession {
  @override
  Stream<void> get becomingNoisyEventStream => const Stream.empty();
}

/// Fake implementation of AudioPlayer for testing state updates.
class FakeAudioPlayer extends Fake implements AudioPlayer {
  ProcessingState _processingState = ProcessingState.idle;
  bool _playing = false;
  final _playbackEventController = StreamController<PlaybackEvent>.broadcast();
  final _playerStateController = StreamController<PlayerState>.broadcast();

  @override
  ProcessingState get processingState => _processingState;

  @override
  bool get playing => _playing;

  @override
  Duration get position => Duration.zero;

  @override
  Duration get bufferedPosition => Duration.zero;

  @override
  double get speed => 1.0;

  @override
  Stream<PlaybackEvent> get playbackEventStream => _playbackEventController.stream;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  @override
  PlaybackEvent get playbackEvent => PlaybackEvent();

  @override
  Future<void> stop() async {}

  /// Emits playback event with configured state.
  void emitState({required ProcessingState processingState, required bool playing}) {
    _processingState = processingState;
    _playing = playing;
    _playbackEventController.add(PlaybackEvent());
  }

  /// Closes internal stream controllers.
  @override
  Future<void> dispose() async {
    await _playbackEventController.close();
    await _playerStateController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAudioHandler Unit Tests', () {
    late FakeAudioPlayer player;
    late AppAudioHandler handler;

    setUp(() {
      player = FakeAudioPlayer();
      handler = AppAudioHandler(
        player: player,
        session: MockAudioSession(),
        onSkipNext: () async {},
        onSkipPrev: () async {},
      );
    });

    tearDown(() async {
      await player.dispose();
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

    test('Idle state emits empty compact action indices and controls', () async {
      const item = MediaItem(
        id: 'st_1',
        title: 'NPO Radio 1',
      );
      await handler.updateMediaItem(item);
      player.emitState(processingState: ProcessingState.idle, playing: false);
      await pumpEventQueue();

      expect(handler.playbackState.value.processingState, equals(AudioProcessingState.idle));
      expect(handler.playbackState.value.controls, isEmpty);
      expect(handler.playbackState.value.androidCompactActionIndices, isEmpty);
    });

    test('Ready state emits compact action indices [0] and play/pause control', () async {
      const item = MediaItem(
        id: 'st_1',
        title: 'NPO Radio 1',
      );
      await handler.updateMediaItem(item);
      player.emitState(processingState: ProcessingState.ready, playing: true);
      await pumpEventQueue();

      expect(handler.playbackState.value.processingState, equals(AudioProcessingState.ready));
      expect(handler.playbackState.value.controls, isNotEmpty);
      expect(handler.playbackState.value.androidCompactActionIndices, equals(const [0]));
    });
  });
}
