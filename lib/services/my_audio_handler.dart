import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

Future<MyAudioHandler>? _audioHandlerFuture;

/// Initializes the AudioService for OS-level background audio notifications and controls.
Future<MyAudioHandler> initAudioService({
  required AudioPlayer player,
  required String channelName,
  required Future<void> Function() onPlay,
  required Future<void> Function() onSkipToNext,
  required Future<void> Function() onSkipToPrevious,
}) {
  return _audioHandlerFuture ??= AudioService.init<MyAudioHandler>(
    builder: () => MyAudioHandler(
      player: player,
      onPlay: onPlay,
      onSkipNext: onSkipToNext,
      onSkipPrev: onSkipToPrevious,
    ),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.etherly.radio.channel.audio',
      androidNotificationChannelName: channelName,
      androidNotificationIcon: 'mipmap/notification_icon',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
    ),
  );
}

/// A lightweight handler that syncs just_audio's state to audio_service.
class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer player;
  final Future<void> Function() onPlay;
  final Future<void> Function() onSkipNext;
  final Future<void> Function() onSkipPrev;

  AudioSession? _audioSession;

  MyAudioHandler({
    required this.player,
    required this.onPlay,
    required this.onSkipNext,
    required this.onSkipPrev,
  }) {
    // Pipe just_audio's playback events to audio_service
    player.playbackEventStream.map(_transformEvent).listen(playbackState.add);
    _initAudioSession();
  }

  Future<void> _initAudioSession() async {
    _audioSession = await AudioSession.instance;
  }

  /// Updates the currently displaying media item on the OS lock screen.
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  /// Quickly patches metadata (like artist/song title from ICY data) into the existing MediaItem.
  void patchMediaItemMetadata({String? artist}) {
    final current = mediaItem.value;
    if (current == null) return;
    updateMediaItem(current.copyWith(artist: artist));
  }

  /// AudioService Overrides delegating directly to just_audio
  @override
  Future<void> play() async => onPlay();

  @override
  Future<void> pause() async => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
        controls: [],
      ),
    );
    await super.stop();
  }

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    await stop();
  }

  @override
  Future<void> skipToNext() async => onSkipNext();

  @override
  Future<void> skipToPrevious() async => onSkipPrev();

  /// Custom actions and notification management
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    if (name == 'dispose') {
      await stop();
      await player.dispose();
      return;
    }
    return super.customAction(name, extras);
  }

  /// Hides the OS notification when casting is taking place.
  Future<void> hideNotification() async {
    try {
      if (player.playing) await player.stop();
      if (_audioSession != null) await _audioSession!.setActive(false);

      // Tell audio_service we are idle, which clears the OS notification
      playbackState.add(
        PlaybackState(
          controls: [],
          processingState: AudioProcessingState.idle,
          playing: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) print('Error hiding notification: $e');
    }
  }

  /// Restores the OS notification when casting has ended.
  Future<void> showNotification() async {
    try {
      if (_audioSession != null) await _audioSession!.setActive(true);
      final current = mediaItem.value;
      if (current != null) {
        playbackState.add(_transformEvent(player.playbackEvent));
      }
    } catch (e) {
      if (kDebugMode) print('Error showing notification: $e');
    }
  }

  /// Transforms just_audio's generic PlaybackEvent into audio_service's PlaybackState
  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        if (player.processingState == ProcessingState.idle)
          if (player.playing) MediaControl.pause else MediaControl.play,
      ],
      androidCompactActionIndices: const [0],
      processingState: _getProcessingState(player.processingState),
      playing: player.playing,
      updatePosition: player.position,
      bufferedPosition: player.bufferedPosition,
      speed: player.speed,
      queueIndex: event.currentIndex,
    );
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
