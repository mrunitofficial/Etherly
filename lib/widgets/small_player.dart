import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/station_art.dart';
import 'package:etherly/widgets/marquee_text.dart';
import 'package:etherly/widgets/play_button.dart';

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

        final artUrl = getSafeArtUrl(mediaItem);
        final theme = Theme.of(context);
        final loc = AppLocalizations.of(context);
        final stationName =
            mediaItem?.title ??
            (loc?.translate('playerLoadingStation') ?? 'Loading station...');
        final processingState = service.playbackState.processingState;
        final isPlaying = service.isPlaying;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
          child: Row(
            children: [
              IgnorePointer(
                ignoring: true,
                child: StationArt(
                  artUrl: artUrl,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IgnorePointer(
                      ignoring: true,
                      child: MarqueeText(
                        text: stationName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final icy = service.icyService;
                        if (service.isCasting) {
                          return const SizedBox.shrink();
                        }
                        if (icy.isLoading) {
                          return IgnorePointer(
                            ignoring: true,
                            child: MarqueeText(
                              text:
                                  loc?.translate('playerLoadingSong') ??
                                  'Loading song...',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        final text = icy.text;
                        if (text != null && text.isNotEmpty) {
                          return IgnorePointer(
                            ignoring: true,
                            child: MarqueeText(
                              text: text,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
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
                    isCastLoading: service.isCastLoading,
                    small: true,
                    heroTag: "mini_player_fab",
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
