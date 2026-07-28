import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

import 'package:shared_preferences/shared_preferences.dart';

Future<AppAudioHandler>? _audioHandlerFuture;

/// Initializes the AudioService for OS-level background audio notifications and controls.
Future<AppAudioHandler> initAudioService({
  required AudioPlayer player,
  required String channelName,
  required Future<void> Function() onSkipToNext,
  required Future<void> Function() onSkipToPrevious,
}) async {
  // Pre-configure the singleton audio session BEFORE initializing the handler to avoid race conditions
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.music());

  return _audioHandlerFuture ??= AudioService.init<AppAudioHandler>(
    builder: () => AppAudioHandler(
      player: player,
      session: session,
      onSkipNext: onSkipToNext,
      onSkipPrev: onSkipToPrevious,
    ),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.etherly.radio.channel.audio',
      androidNotificationChannelName: channelName,
      androidNotificationIcon: 'mipmap/notification_icon',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: true,
    ),
  );
}

/// A lightweight handler that syncs just_audio's state to audio_service.
class AppAudioHandler extends BaseAudioHandler {
  final AudioPlayer player;
  final AudioSession session;
  final Future<void> Function() onSkipNext;
  final Future<void> Function() onSkipPrev;
  bool isRemoteSession = false;

  AppAudioHandler({
    required this.player,
    required this.session,
    required this.onSkipNext,
    required this.onSkipPrev,
  }) {
    player.playbackEventStream.listen((_) => _updatePlaybackState());
    player.playerStateStream.listen((_) => _updatePlaybackState());
  }

  void _updatePlaybackState() {
    if (isRemoteSession) return;
    if (mediaItem.value == null) {
      playbackState.add(
        PlaybackState(
          processingState: AudioProcessingState.idle,
          playing: false,
          controls: [],
        ),
      );
      return;
    }
    playbackState.add(_transformEvent(player.playbackEvent));
  }

  /// Manually updates playback state for external or remote sessions (e.g. Chromecast).
  void updateRemotePlaybackState({
    required bool playing,
    required bool isBuffering,
  }) {
    isRemoteSession = true;
    if (mediaItem.value == null) return;
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          playing ? MediaControl.pause : MediaControl.play,
          MediaControl.stop,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 3],
        processingState: isBuffering
            ? AudioProcessingState.buffering
            : (playing
                  ? AudioProcessingState.ready
                  : AudioProcessingState.idle),
        playing: playing,
        updatePosition: Duration.zero,
      ),
    );
  }

  /// Clears active media item and stops AudioService to dismiss local OS notification card.
  Future<void> clearNotification() async {
    isRemoteSession = false;
    mediaItem.add(null);
    playbackState.add(
      PlaybackState(
        processingState: AudioProcessingState.idle,
        playing: false,
        controls: [],
      ),
    );
    await stop();
  }

  /// Updates the currently displaying media item on the OS lock screen.
  @override
  Future<void> updateMediaItem(MediaItem item) async {
    mediaItem.add(item);
  }

  bool _isCurrentStation(String id) => mediaItem.value?.id == id;

  /// Plays a media item by setting the audio source and beginning playback.
  @override
  Future<void> playMediaItem(MediaItem item) async {
    isRemoteSession = false;
    mediaItem.add(item);

    final streamsObj = item.extras?['streams'];
    Map<String, String> streams = {};
    if (streamsObj is Map) {
      streams = streamsObj.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      final url = item.extras?['url'] as String? ?? '';
      if (url.isNotEmpty) {
        streams['mp3'] = url;
      }
    }

    if (streams.isEmpty) throw Exception("No valid stream URL found");

    final prefs = await SharedPreferences.getInstance();
    final quality = prefs.getString('streamQuality') ?? 'mp3';

    final entriesPriority = [
      if (streams.containsKey(quality)) MapEntry(quality, streams[quality]!),
      ...streams.entries.where((e) => e.key != quality),
    ];

    final failedQualities = <String>[];

    for (int i = 0; i < entriesPriority.length; i++) {
      final entry = entriesPriority[i];
      if (entry.value.trim().isEmpty) {
        failedQualities.add(entry.key);
        continue;
      }
      try {
        if (!_isCurrentStation(item.id)) return;
        await player.setAudioSource(
          AudioSource.uri(Uri.parse(entry.value), tag: item),
        );
        if (!_isCurrentStation(item.id)) return;
        await player.play();

        if (_isCurrentStation(item.id)) {
          final extras = Map<String, dynamic>.from(item.extras ?? {});
          extras['activeQuality'] = entry.key;
          extras['failedQualities'] = failedQualities;
          updateMediaItem(mediaItem.value!.copyWith(extras: extras));
        }
        return;
      } on PlayerInterruptedException {
        rethrow;
      } catch (e) {
        failedQualities.add(entry.key);
        if (i == entriesPriority.length - 1) {
          if (_isCurrentStation(item.id)) {
            final extras = Map<String, dynamic>.from(item.extras ?? {});
            extras['failedQualities'] = failedQualities;
            updateMediaItem(mediaItem.value!.copyWith(extras: extras));
          }
          rethrow;
        }
      }
    }
  }

  /// Quickly patches metadata (like artist/song title or secondary text) into the existing MediaItem.
  void patchMediaItemMetadata({required String stationId, String? artist}) {
    if (!_isCurrentStation(stationId)) return;
    updateMediaItem(mediaItem.value!.copyWith(artist: artist));
  }

  /// AudioService Overrides delegating directly to just_audio player.
  @override
  Future<void> play() async {
    final current = mediaItem.value;
    if (current != null) {
      await playMediaItem(current);
    } else {
      await player.play();
    }
  }

  @override
  Future<void> pause() async => player.pause();

  @override
  Future<void> stop() async {
    await player.stop();
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

  /// Transforms just_audio's generic PlaybackEvent into audio_service's PlaybackState
  PlaybackState _transformEvent(PlaybackEvent event) {
    final playing = player.playing;
    final isIdle = player.processingState == ProcessingState.idle;

    return PlaybackState(
      controls: [
        if (!isIdle) ...[
          if (kIsWeb) MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          if (kIsWeb) MediaControl.skipToNext,
          if (kIsWeb) MediaControl.stop,
        ],
      ],
      systemActions: {
        if (!isIdle) ...{
          MediaAction.skipToNext,
          MediaAction.skipToPrevious,
          if (kIsWeb) MediaAction.stop,
        },
      },
      androidCompactActionIndices: const [0],
      processingState: _getProcessingState(player.processingState),
      playing: playing,
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
