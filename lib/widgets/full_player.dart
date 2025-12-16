import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/screens/settings_screen.dart';
import 'package:etherly/main.dart' show themeNotifier;
import 'package:etherly/widgets/sleep_timer.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:etherly/widgets/quality_setting.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/play_button.dart';

/// Full player content shown in the expanded state of the radio player.
class FullPlayerContent extends StatefulWidget {
  const FullPlayerContent({
    super.key,
    required this.scrollController,
    this.onClose,
  });

  final ScrollController scrollController;
  final VoidCallback? onClose;

  @override
  State<FullPlayerContent> createState() => _FullPlayerContentState();
}

class _FullPlayerContentState extends State<FullPlayerContent> {
  String? _lastStationId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 32),
        child: Consumer<AudioPlayerService>(
          builder: (context, service, _) {
            final mediaItem = service.mediaItem;
            if (mediaItem?.id != _lastStationId) _lastStationId = mediaItem?.id;

            final loc = AppLocalizations.of(context);
            final theme = Theme.of(context);

            return Column(
              children: [
                FullPlayerHeader(
                  onClose: widget.onClose,
                  slogan: mediaItem?.album ?? '',
                ),
                const SizedBox(height: 8),
                Center(
                  child: StationArt(
                    artUrl: getSafeArtUrl(mediaItem),
                    size: 280,
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      MarqueeText(
                        text:
                            mediaItem?.title ??
                            (loc?.translate('playerLoadingStation') ??
                                'Select a station...'),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        centerWhenFits: true,
                      ),
                      if (!kIsWeb)
                        SizedBox(
                          height: 28,
                          child: service.isCasting
                              ? const SizedBox.shrink()
                              : () {
                                  final icy = service.icyService;
                                  final text = icy.isLoading
                                      ? (loc?.translate('playerLoadingSong') ??
                                            'Loading song...')
                                      : (icy.text?.isNotEmpty == true
                                            ? icy.text!
                                            : null);
                                  return text == null
                                      ? const SizedBox.shrink()
                                      : MarqueeText(
                                          text: text,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                          centerWhenFits: true,
                                        );
                                }(),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const FullPlayerControls(),
                if (kIsWeb) ...[
                  const SizedBox(height: 32),
                  const VolumeSlider(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Header bar for the full player with close button and slogan.
class FullPlayerHeader extends StatelessWidget {
  const FullPlayerHeader({super.key, this.onClose, required this.slogan});

  final VoidCallback? onClose;
  final String slogan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 32, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (!kIsWeb) PlayerCloseButton(onClose: onClose),
          if (kIsWeb) const QualityButton(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: slogan.isEmpty
                  ? const SizedBox.shrink()
                  : Text(
                      slogan,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
            ),
          ),
          const PlayerMenuButton(),
        ],
      ),
    );
  }
}

/// Control buttons for the full player (sleep timer, play/pause, favorite).
class FullPlayerControls extends StatelessWidget {
  const FullPlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        final colorScheme = Theme.of(context).colorScheme;
        final loc = AppLocalizations.of(context);
        final station = service.mediaItem == null
            ? null
            : service.stations.cast<Station?>().firstWhere(
                (s) => s?.id == service.mediaItem!.id,
                orElse: () => null,
              );
        final isFavorite = station?.isFavorite ?? false;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: service.sleepTimerActive,
                builder: (context, isSleepTimerSet, _) => IconButton(
                  onPressed: isSleepTimerSet
                      ? () => service.cancelSleepTimer()
                      : () async {
                          final selected = await showDialog<Duration>(
                            context: context,
                            builder: (context) => SleepTimer(
                              onTimerSelected: (duration) =>
                                  Navigator.of(context).pop(duration),
                            ),
                          );
                          if (selected != null) service.setSleepTimer(selected);
                        },
                  icon: Icon(
                    isSleepTimerSet ? Icons.timer : Icons.timer_outlined,
                    size: 28,
                    color: isSleepTimerSet
                        ? colorScheme.primary
                        : colorScheme.onSecondaryContainer,
                  ),
                  tooltip: isSleepTimerSet
                      ? (loc?.translate('playerCancelSleepTimer') ??
                            'Cancel sleep timer')
                      : (loc?.translate('playerSleepTimer') ?? 'Sleep timer'),
                  padding: const EdgeInsets.all(16),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.secondaryContainer,
                    shape: const CircleBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              ValueListenableBuilder<int>(
                valueListenable: service.autoplayCountdownNotifier,
                builder: (context, countdown, _) => SizedBox(
                  width: 80,
                  height: 80,
                  child: PlayButton(
                    service: service,
                    countdown: countdown,
                    processingState: service.playbackState.processingState,
                    isPlaying: service.isPlaying,
                    isCastLoading: service.isCastLoading,
                    heroTag: "full_player_fab",
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    tooltip: service.isPlaying
                        ? (loc?.translate('playerPause') ?? 'Pause')
                        : (loc?.translate('playerPlay') ?? 'Play'),
                  ),
                ),
              ),
              const SizedBox(width: 32),
              IconButton(
                onPressed: station == null
                    ? null
                    : () => service.toggleFavorite(station),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 28,
                  color: isFavorite
                      ? colorScheme.primary
                      : colorScheme.onSecondaryContainer,
                ),
                tooltip: loc?.translate('playerFavorite') ?? 'Favorite',
                padding: const EdgeInsets.all(16),
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.secondaryContainer,
                  shape: const CircleBorder(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Helper function to handle stream quality changes.
void handleStreamQuality(BuildContext context) {
  final service = Provider.of<AudioPlayerService>(context, listen: false);
  final mediaItem = service.mediaItem;
  if (mediaItem == null || service.stations.isEmpty) return;

  final station = service.stations.firstWhere(
    (s) => s.id == mediaItem.id,
    orElse: () => service.stations.first,
  );

  final prefQuality = service.prefs.getString('streamQuality') ?? 'mp3';
  final selectedQuality = prefQuality == 'aac'
      ? (station.streamAAC.isNotEmpty ? 'aac' : 'mp3')
      : (station.streamMP3.isNotEmpty ? 'mp3' : 'aac');

  showDialog<String>(
    context: context,
    builder: (context) => QualitySetting(
      station: station,
      selectedQuality: selectedQuality,
      onQualitySelected: (q) => Navigator.of(context).pop(q),
    ),
  ).then((newQuality) {
    if (newQuality != null && newQuality != selectedQuality) {
      service.prefs.setString('streamQuality', newQuality);
      service.stop();
      service.playMediaItem(station);
    }
  });
}

/// Quality button in the full player header (web only).
class QualityButton extends StatelessWidget {
  const QualityButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => handleStreamQuality(context),
      icon: Icon(
        Icons.high_quality_outlined,
        size: 28,
        color: theme.colorScheme.onSurface,
      ),
      tooltip: loc?.translate('playerStreamQuality') ?? 'Stream quality',
    );
  }
}

/// Close button in the full player header (mobile only).
class PlayerCloseButton extends StatelessWidget {
  const PlayerCloseButton({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    if (onClose == null) return const SizedBox(width: 48);

    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return IconButton(
      onPressed: onClose,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 32,
        color: theme.colorScheme.onSurface,
      ),
      tooltip: loc?.translate('playerClose') ?? 'Close',
    );
  }
}

/// Menu button in the full player header.
class PlayerMenuButton extends StatelessWidget {
  const PlayerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 28,
        color: theme.colorScheme.onSurface,
      ),
      color: theme.colorScheme.surfaceContainerHigh,
      itemBuilder: (context) => [
        _buildMenuItem(
          Icons.settings_outlined,
          loc?.translate('playerSettings') ?? 'Settings',
          'settings',
          theme.colorScheme.onSurfaceVariant,
        ),
        if (!kIsWeb)
          _buildMenuItem(
            Icons.high_quality_outlined,
            loc?.translate('playerStreamQuality') ?? 'Stream quality',
            'stream_quality',
            theme.colorScheme.onSurfaceVariant,
          ),
        _buildMenuItem(
          Icons.info_outline,
          loc?.translate('playerAbout') ?? 'About',
          'about',
          theme.colorScheme.onSurfaceVariant,
        ),
        _buildMenuItem(
          Icons.feedback_outlined,
          loc?.translate('playerSendFeedback') ?? 'Send Feedback',
          'send_feedback',
          theme.colorScheme.onSurfaceVariant,
        ),
      ],
      onSelected: (value) {
        if (value == 'stream_quality') {
          handleStreamQuality(context);
        } else {
          // All other options navigate to settings screen.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  SettingsScreen(themeNotifier: themeNotifier),
            ),
          );
        }
      },
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

/// Volume slider widget for web player.
class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  State<VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Icon(
                Icons.volume_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              Expanded(
                child: Slider(
                  value: service.volume,
                  min: 0.0,
                  max: 1.0,
                  onChanged: (value) => service.setVolume(value),
                ),
              ),
              Icon(
                Icons.volume_up,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }
}
