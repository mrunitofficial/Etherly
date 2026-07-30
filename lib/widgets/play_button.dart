import 'package:material_ui/material_ui.dart';

import 'package:etherly/services/audio_player_service.dart';

/// Button visual size variants.
enum PlayButtonSize { medium, large }

/// A button widget that toggles radio playback, displaying countdown or buffer state.
class PlayButton extends StatelessWidget {
  const PlayButton({
    super.key,
    required this.service,
    required this.countdown,
    this.size = PlayButtonSize.medium,
    this.tooltip,
    this.heroTag,
    this.elevation,
  });

  final AudioPlayerService service;
  final int countdown;
  final PlayButtonSize size;
  final String? tooltip;
  final String? heroTag;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        final Widget content = _PlayButtonContent(
          service: service,
          countdown: countdown,
          size: size,
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
      },
    );
  }

  /// Toggles playback state or stops buffering/countdown.
  void _handlePlayPause() {
    final bool isPlaying = service.isPlaying;
    if (countdown > 0) {
      service.pause();
    } else if (isPlaying) {
      service.pause();
    } else {
      if (service.isLoading) {
        service.stop();
      } else {
        service.play();
      }
    }
  }
}

/// Inner icon, spinner, or countdown label widget for [PlayButton].
class _PlayButtonContent extends StatelessWidget {
  final AudioPlayerService service;
  final int countdown;
  final PlayButtonSize size;

  const _PlayButtonContent({
    required this.service,
    required this.countdown,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    final baseSize = iconTheme.size!;
    final color = iconTheme.color;
    final bool isPlaying = service.isPlaying;
    final bool showSpinner = service.isLoading;

    final String semanticLabel = switch ((countdown > 0, showSpinner, isPlaying)) {
      (true, _, _) => 'Sleep timer active: $countdown seconds remaining',
      (_, true, _) => 'Buffering stream',
      (_, _, true) => 'Pause',
      _ => 'Play',
    };

    Widget childWidget;
    if (countdown > 0) {
      final textStyle = switch (size) {
        PlayButtonSize.large => theme.textTheme.headlineLarge,
        PlayButtonSize.medium => theme.textTheme.titleLarge,
      };

      childWidget = Text(
        countdown.toString(),
        style: textStyle?.copyWith(fontWeight: FontWeight.bold, color: color),
      );
    } else if (showSpinner) {
      childWidget = SizedBox.square(
        dimension: baseSize,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    } else {
      childWidget = Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded);
    }

    return Semantics(
      button: true,
      liveRegion: true,
      label: semanticLabel,
      child: childWidget,
    );
  }
}
