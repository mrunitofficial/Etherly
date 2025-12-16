import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:etherly/services/radio_player_service.dart';

/// A reusable play/pause button widget that handles loading, countdown, and play states
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.service,
    required this.countdown,
    required this.processingState,
    required this.isPlaying,
    this.isCastLoading = false,
    this.small = false,
    this.heroTag,
    this.tooltip,
    this.elevation = 0,
    this.shape,
  });

  final AudioPlayerService service;
  final int countdown;
  final AudioProcessingState processingState;
  final bool isPlaying;
  final bool isCastLoading;
  final bool small;
  final String? heroTag;
  final String? tooltip;
  final double elevation;
  final ShapeBorder? shape;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: () => _handlePlayPause(),
      elevation: elevation,
      tooltip: tooltip,
      shape: shape,
      child: _buildButtonContent(context),
    );
  }

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

    if (isCastLoading ||
        processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering) {
      return SizedBox.square(
        dimension: small ? 24.0 : 40.0,
        child: CircularProgressIndicator(
          strokeWidth: small ? 2.0 : 3.0,
          valueColor: AlwaysStoppedAnimation(colorScheme.onPrimaryContainer),
        ),
      );
    }

    return Icon(
      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
      size: small ? 24.0 : 48.0,
    );
  }

  void _handlePlayPause() {
    if (countdown > 0 || service.isAutoplayInProgress) {
      service.cancelAutoplayCountdown();
      return;
    }
    if (isCastLoading ||
        processingState == AudioProcessingState.loading ||
        processingState == AudioProcessingState.buffering) {
      service.stop();
      return;
    }
    if (isPlaying) {
      service.stop();
    } else {
      service.play();
    }
  }
}
