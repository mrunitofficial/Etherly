import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';

import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/screens/settings_screen.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/sleep_timer.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:etherly/widgets/quality_setting.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/play_button.dart';
import 'package:etherly/widgets/icy_text_display.dart';

/// Full player content shown in the expanded state of the radio player.
class FullPlayerContent extends StatelessWidget {
  const FullPlayerContent({super.key, this.scrollController, this.onClose});

  final ScrollController? scrollController;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;
    final shapes = theme.extension<Shapes>()!;
    final sizes = theme.extension<Sizes>()!;

    Widget content = Padding(
      padding: EdgeInsets.only(bottom: spacing.extraLarge),
      child: Consumer<AudioPlayerService>(
        builder: (context, service, _) {
          final mediaItem = service.mediaItem;
          final loc = AppLocalizations.of(context);

          return Column(
            children: [
              FullPlayerHeader(
                onClose: onClose,
                slogan: mediaItem?.album ?? '',
              ),
              SizedBox(height: spacing.small),
              Center(
                child: ClipRRect(
                  borderRadius: shapes.medium,
                  child: SizedBox.square(
                    dimension:
                        sizes.extraLargeIncreased + sizes.largeIncreased, // 280
                    child: StationArt(artUrl: mediaItem.safeArtUrl),
                  ),
                ),
              ),
              SizedBox(height: spacing.large),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing.extraLarge),
                child: Column(
                  children: [
                    MarqueeText(
                      text:
                          mediaItem?.title ??
                          (loc?.translate('playerLoadingStation') ??
                              'Select a station...'),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      centerWhenFits: true,
                    ),
                    if (!kIsWeb)
                      SizedBox(
                        height: spacing.extraLarge,
                        child: const IcyTextDisplay(),
                      ),
                  ],
                ),
              ),
              SizedBox(height: spacing.large),
              const FullPlayerControls(),
              if (kIsWeb) ...[
                SizedBox(height: spacing.medium),
                const VolumeSlider(),
              ],
            ],
          );
        },
      ),
    );

    if (scrollController != null) {
      return SingleChildScrollView(
        controller: scrollController,
        child: content,
      );
    }
    return content;
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
    final spacing = theme.extension<Spacing>()!;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        spacing.medium,
        spacing.extraLarge,
        spacing.medium,
        spacing.medium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (onClose != null)
            PlayerCloseButton(onClose: onClose)
          else
            const QualityButton(),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: spacing.small),
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
          PlayerMenuButton(showQualityInMenu: onClose != null),
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
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final spacing = theme.extension<Spacing>()!;
        final loc = AppLocalizations.of(context);
        final station = service.mediaItem == null
            ? null
            : service.stations.firstWhere(
                (s) => s.id == service.mediaItem!.id,
                orElse: () => service.stations.first,
              );
        final isFavorite = station?.isFavorite ?? false;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.extraLarge),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: service.sleepTimerActive,
                builder: (context, isSleepTimerSet, _) =>
                    IconButton.filledTonal(
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
                              if (selected != null) {
                                service.setSleepTimer(selected);
                              }
                            },
                      icon: Icon(
                        isSleepTimerSet ? Icons.timer : Icons.timer_outlined,
                        color: isSleepTimerSet ? colorScheme.primary : null,
                      ),
                      tooltip: isSleepTimerSet
                          ? (loc?.translate('playerCancelSleepTimer') ??
                                'Cancel sleep timer')
                          : (loc?.translate('playerSleepTimer') ??
                                'Sleep timer'),
                      padding: EdgeInsets.all(spacing.medium),
                    ),
              ),
              SizedBox(width: spacing.extraLarge),
              ValueListenableBuilder<int>(
                valueListenable: service.autoplayCountdownNotifier,
                builder: (context, countdown, _) => PlayButton(
                  service: service,
                  countdown: countdown,
                  processingState: service.player.processingState,
                  isPlaying: service.isPlaying,
                  heroTag: "full_player_fab",
                  elevation: 0,
                  tooltip: service.isPlaying
                      ? (loc?.translate('playerPause') ?? 'Pause')
                      : (loc?.translate('playerPlay') ?? 'Play'),
                  size: PlayButtonSize.large,
                ),
              ),
              SizedBox(width: spacing.extraLarge),
              IconButton.filledTonal(
                onPressed: station == null
                    ? null
                    : () => service.toggleFavorite(station),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? colorScheme.primary : null,
                ),
                tooltip: loc?.translate('playerFavorite') ?? 'Favorite',
                padding: EdgeInsets.all(spacing.medium),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Quality button in the full player header (web only).
class QualityButton extends StatelessWidget {
  const QualityButton({super.key});

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final loc = AppLocalizations.of(context);

    return IconButton(
      onPressed: () => QualitySetting.show(context),
      icon: const Icon(Icons.high_quality_outlined),
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
    final theme = Theme.of(context);
    final sizes = theme.extension<Sizes>()!;

    if (onClose == null) return SizedBox(width: sizes.normal);

    final loc = AppLocalizations.of(context);

    return IconButton(
      onPressed: onClose,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      tooltip: loc?.translate('playerClose') ?? 'Close',
    );
  }
}

/// Menu button in the full player header.
class PlayerMenuButton extends StatelessWidget {
  const PlayerMenuButton({super.key, required this.showQualityInMenu});

  final bool showQualityInMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context);

    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      color: theme.colorScheme.surfaceContainerHigh,
      itemBuilder: (context) => [
        _buildMenuItem(
          context,
          Icons.settings_outlined,
          loc?.translate('playerSettings') ?? 'Settings',
          'settings',
        ),
        if (showQualityInMenu)
          _buildMenuItem(
            context,
            Icons.high_quality_outlined,
            loc?.translate('playerStreamQuality') ?? 'Stream quality',
            'stream_quality',
          ),
        _buildMenuItem(
          context,
          Icons.info_outline,
          loc?.translate('playerAbout') ?? 'About',
          'about',
        ),
        _buildMenuItem(
          context,
          Icons.feedback_outlined,
          loc?.translate('playerSendFeedback') ?? 'Send Feedback',
          'send_feedback',
        ),
      ],
      onSelected: (value) {
        if (value == 'stream_quality') {
          QualitySetting.show(context);
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
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final spacing = Theme.of(context).extension<Spacing>()!;

    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: spacing.medium),
          Text(label),
        ],
      ),
    );
  }
}

class VolumeSlider extends StatelessWidget {
  const VolumeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        final theme = Theme.of(context);
        final spacing = theme.extension<Spacing>()!;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing.extraLarge),
          child: Row(
            children: [
              IconButton(
                onPressed: service.toggleMute,
                icon: Icon(
                  service.isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_mute_rounded,
                ),
                tooltip:
                    AppLocalizations.of(context)?.translate('playerMute') ??
                    'Mute',
              ),
              Expanded(
                child: Slider(
                  value: service.volume,
                  onChanged: service.setVolume,
                ),
              ),
              IconButton(
                onPressed: () => service.setVolume(1.0),
                icon: const Icon(Icons.volume_up_rounded),
                tooltip:
                    AppLocalizations.of(
                      context,
                    )?.translate('playerMaxVolume') ??
                    'Max Volume',
              ),
            ],
          ),
        );
      },
    );
  }
}
