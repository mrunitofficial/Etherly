import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/play_button.dart';
import 'package:etherly/widgets/icy_text_display.dart';

/// Mini player content shown in the collapsed state of the radio player
class MiniPlayerContent extends StatefulWidget {
  const MiniPlayerContent({super.key});

  @override
  State<MiniPlayerContent> createState() => _MiniPlayerContentState();
}

class _MiniPlayerContentState extends State<MiniPlayerContent> {
  String? _lastStationId;

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerService>(
      builder: (context, service, _) {
        final mediaItem = service.mediaItem;

        if (mediaItem?.id != _lastStationId) {
          _lastStationId = mediaItem?.id;
        }

        final artUrl = mediaItem.safeArtUrl;
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);
        final stationName =
            mediaItem?.title ??
            (loc?.translate('playerLoadingStation') ?? 'Loading station...');
        final processingState = service.player.processingState;
        final isPlaying = service.isPlaying;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            children: [
              IgnorePointer(
                ignoring: true,
                child: StationArt(
                  artUrl: artUrl,
                  size: theme.extension<Sizes>()!.normal,
                  borderRadius: theme.extension<Shapes>()!.small,
                ),
              ),
              SizedBox(width: theme.extension<Spacing>()!.medium),
              Expanded(
                child: IgnorePointer(
                  ignoring: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MarqueeText(
                        text: stationName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IcyTextDisplay(
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        centerWhenFits: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<int>(
                valueListenable: service.autoplayCountdownNotifier,
                builder: (context, countdown, _) {
                  return PlayButton(
                    service: service,
                    countdown: countdown,
                    processingState: processingState,
                    isPlaying: isPlaying,
                    size: PlayButtonSize.medium,
                    heroTag: "mini_player_fab",
                    elevation: 0,
                    tooltip: isPlaying
                        ? (loc?.translate('playerPause') ?? 'Pause')
                        : (loc?.translate('playerPlay') ?? 'Play'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tap region wrapper for mini player that handles expansion
class MiniPlayerTapRegion extends StatelessWidget {
  const MiniPlayerTapRegion({
    super.key,
    required this.child,
    required this.onExpand,
  });

  final Widget child;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onExpand,
      child: child,
    );
  }
}
