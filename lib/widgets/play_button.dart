import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:etherly/services/audio_player_service.dart';

/// A reusable play/pause button widget that handles loading, countdown, and play states.
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.service,
    required this.processingState,
    required this.isPlaying,
    required this.countdown,
    required this.small,
    this.tooltip,
    this.heroTag,
    this.elevation,
  });

  final AudioPlayerService service;
  final ProcessingState processingState;
  final bool isPlaying;
  final int countdown;
  final bool small;
  final String? tooltip;
  final String? heroTag;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      elevation: elevation,
      tooltip: tooltip,
      onPressed: () => _handlePlayPause(),
      child: _buildButtonContent(context),
    );
  }

  // This determines the icon to show when the player is loading, buffering, or playing.
  Widget _buildButtonContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (countdown > 0) {
      return Text(
        countdown.toString(),
        style: TextStyle(
          fontSize: small ? 24.0 : 48.0,
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimaryContainer,
        ),
      );
    }

    if ((processingState == ProcessingState.buffering) ||
        processingState == ProcessingState.loading) {
      return SizedBox.square(
        dimension: small ? 24.0 : 48.0,
        child: CircularProgressIndicator(
          strokeWidth: small ? 2.0 : 4.0,
          valueColor: AlwaysStoppedAnimation(colorScheme.onPrimaryContainer),
        ),
      );
    }

    return Icon(
      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: small ? 24.0 : 48.0,
    );
  }

  // This handles the play/pause logic.
  void _handlePlayPause() {
    if (countdown > 0 || isPlaying) {
      service.pause();
    } else {
      service.play();
    }
  }
}
