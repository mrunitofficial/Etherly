import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:etherly/services/audio_player_service.dart';

enum PlayButtonSize { medium, large }

class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.service,
    required this.processingState,
    required this.isPlaying,
    required this.countdown,
    this.size = PlayButtonSize.medium,
    this.tooltip,
    this.heroTag,
    this.elevation,
  });

  final AudioPlayerService service;
  final ProcessingState processingState;
  final bool isPlaying;
  final int countdown;
  final PlayButtonSize size;
  final String? tooltip;
  final String? heroTag;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    final Widget content = Builder(
      builder: (context) => _buildButtonContent(context),
    );

    switch (size) {
      case PlayButtonSize.large:
        return FloatingActionButton.large(
          heroTag: heroTag,
          elevation: elevation,
          tooltip: tooltip,
          onPressed: _handlePlayPause,
          child: content,
        );
      case PlayButtonSize.medium:
        return FloatingActionButton(
          heroTag: heroTag,
          elevation: elevation,
          tooltip: tooltip,
          onPressed: _handlePlayPause,
          child: content,
        );
    }
  }

  Widget _buildButtonContent(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    final baseSize = iconTheme.size!;
    final color = iconTheme.color;

    if (countdown > 0) {
      final textStyle = switch (size) {
        PlayButtonSize.large => theme.textTheme.headlineLarge,
        PlayButtonSize.medium => theme.textTheme.titleLarge,
      };

      return Text(
        countdown.toString(),
        style: textStyle?.copyWith(fontWeight: FontWeight.bold, color: color),
      );
    }

    if (processingState == ProcessingState.loading ||
        (processingState == ProcessingState.buffering &&
            (!kIsWeb || !isPlaying))) {
      return SizedBox.square(
        dimension: baseSize,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }

    return Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded);
  }

  void _handlePlayPause() {
    if (processingState == ProcessingState.buffering ||
        processingState == ProcessingState.loading) {
      service.stop();
    } else if (countdown > 0 || isPlaying) {
      service.pause();
    } else {
      service.play();
    }
  }
}
