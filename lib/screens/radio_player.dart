import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/models/device.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/full_player.dart';
import 'package:etherly/widgets/small_player.dart';
import 'package:etherly/widgets/play_button.dart';
import 'package:etherly/widgets/sleep_timer.dart';
import 'package:etherly/widgets/quality_setting.dart';

/// Radio player widget with draggable sheet for small screens.
class RadioPlayer extends StatefulWidget {
  final ScreenType screenType;
  const RadioPlayer({super.key, required this.screenType});

  static const double _minPlayerHeight = 120.0;
  static const double _maxPlayerHeight = 620.0;
  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Fractional min size based on available height
  static double getMinPlayerSize(double screenHeight) {
    return (_minPlayerHeight / screenHeight).clamp(0.0, 1.0);
  }

  // Fractional max size based on available height
  static double getMaxPlayerSize(double screenHeight) {
    return (_maxPlayerHeight / screenHeight).clamp(0.0, 1.0);
  }

  // Transition progress (0 = mini, 1 = full)
  static double getTransitionProgress(double currentHeight) {
    return ((currentHeight - _minPlayerHeight) /
            (_maxPlayerHeight - _minPlayerHeight))
        .clamp(0.0, 1.0);
  }

  @override
  State<RadioPlayer> createState() => _RadioPlayerState();
}

class _RadioPlayerState extends State<RadioPlayer> {
  final _controller = DraggableScrollableController();
  final _sideScrollController = ScrollController();
  late ValueNotifier<bool> _closeNotifier;
  double? _latestMinPlayerSize;

  double? _cachedMinPlayerSize;
  double? _cachedMaxPlayerSize;
  double? _cachedScreenHeight;

  @override
  void initState() {
    super.initState();
    _closeNotifier = Provider.of<AudioPlayerService>(
      context,
      listen: false,
    ).radioPlayerShouldClose;
    _closeNotifier.addListener(_handleCloseSignal);
  }

  @override
  void dispose() {
    _closeNotifier.removeListener(_handleCloseSignal);
    _controller.dispose();
    _sideScrollController.dispose();
    super.dispose();
  }

  void _handleCloseSignal() {
    if (!_closeNotifier.value || _latestMinPlayerSize == null) {
      return;
    }

    _closeNotifier.value = false;

    if (_controller.isAttached) {
      _controller
          .animateTo(
            _latestMinPlayerSize!,
            duration: RadioPlayer._animationDuration,
            curve: Curves.easeOut,
          )
          .catchError((error) {});
    }
  }

  /// Build the radio player with draggable sheet.
  @override
  Widget build(BuildContext context) {
    final isSidePanel = widget.screenType == ScreenType.largeScreen;

    // Tablet/Web: persistent right side panel with the full player.
    if (isSidePanel) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
        ),
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: FullPlayerContent(
              scrollController: _sideScrollController,
              onClose: null,
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_cachedScreenHeight != constraints.maxHeight) {
          _cachedScreenHeight = constraints.maxHeight;
          _cachedMinPlayerSize = RadioPlayer.getMinPlayerSize(
            constraints.maxHeight,
          );
          _cachedMaxPlayerSize = RadioPlayer.getMaxPlayerSize(
            constraints.maxHeight,
          );
        }

        final minPlayerSize = _cachedMinPlayerSize!;
        final maxPlayerSize = _cachedMaxPlayerSize!;
        _latestMinPlayerSize = minPlayerSize;

        // Landscape mode and small web screen: show mini floating button.
        if (widget.screenType == ScreenType.smallScreenHorizontal ||
            (widget.screenType != ScreenType.largeScreen && kIsWeb)) {
          return Consumer<AudioPlayerService>(
            builder: (context, service, _) => ValueListenableBuilder<int>(
              valueListenable: service.autoplayCountdownNotifier,
              builder: (context, countdown, _) => SafeArea(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<bool>(
                          valueListenable: service.sleepTimerActive,
                          builder: (context, isSleepTimerSet, _) => FloatingActionButton.small(
                            heroTag: 'mini_timer_fab',
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
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
                            tooltip: isSleepTimerSet
                                ? (AppLocalizations.of(context)?.translate('playerCancelSleepTimer') ??
                                    'Cancel sleep timer')
                                : (AppLocalizations.of(context)?.translate('playerSleepTimer') ?? 'Sleep timer'),
                            child: Icon(
                              isSleepTimerSet ? Icons.timer : Icons.timer_outlined,
                              color: isSleepTimerSet
                                  ? Theme.of(context).colorScheme.onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FloatingActionButton.small(
                          heroTag: 'mini_quality_fab',
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          onPressed: () async {
                            final mediaItem = service.mediaItem;
                            Station? station;
                            
                            if (mediaItem != null && service.stations.isNotEmpty) {
                              station = service.stations.firstWhere(
                                (s) => s.id == mediaItem.id,
                                orElse: () => service.stations.first,
                              );
                            }

                            final prefQuality = service.prefs.getString('streamQuality') ?? 'mp3';
                            final selectedQuality = station != null && prefQuality == 'aac'
                                ? (station.streamAAC.isNotEmpty ? 'aac' : 'mp3')
                                : 'mp3';

                            final newQuality = await showDialog<String>(
                              context: context,
                              builder: (context) => QualitySetting(
                                station: station,
                                selectedQuality: selectedQuality,
                                onQualitySelected: (q) => Navigator.of(context).pop(q),
                              ),
                            );
                            
                            if (newQuality != null && station != null && newQuality != selectedQuality) {
                              service.prefs.setString('streamQuality', newQuality);
                              service.stop();
                              service.playMediaItem(station);
                            }
                          },
                          tooltip: AppLocalizations.of(context)?.translate('playerStreamQuality') ?? 'Stream quality',
                          child: Icon(
                            Icons.high_quality_outlined,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        PlayButton(
                          service: service,
                          countdown: countdown,
                          processingState: service.playbackState.processingState,
                          isPlaying: service.isPlaying,
                          isCastLoading: service.isCastLoading,
                          small: true,
                          heroTag: 'mini_player_fab_landscape',
                          elevation: 6,
                          tooltip:
                              AppLocalizations.of(
                                context,
                              )?.translate('playerPlay') ??
                              'Play',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        // Portrait mode on mobile: show draggable sheet.
        if (widget.screenType == ScreenType.smallScreenVertical && !kIsWeb) {
          return DraggableScrollableSheet(
            controller: _controller,
            initialChildSize: minPlayerSize,
            minChildSize: minPlayerSize,
            maxChildSize: maxPlayerSize,
            snap: true,
            snapSizes: [minPlayerSize, maxPlayerSize],
            builder: (context, scrollController) => LayoutBuilder(
              builder: (context, constraints) {
                final progress = RadioPlayer.getTransitionProgress(
                  constraints.maxHeight,
                );
                final miniPlayerOpacity = (1.0 - (progress / 0.3)).clamp(
                  0.0,
                  1.0,
                );
                final fullPlayerOpacity = ((progress - 0.3) / 0.3).clamp(
                  0.0,
                  1.0,
                );

                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Opacity(
                        opacity: fullPlayerOpacity,
                        child: FullPlayerContent(
                          scrollController: scrollController,
                          onClose: () => _controller.isAttached
                              ? _controller
                                    .animateTo(
                                      minPlayerSize,
                                      duration: RadioPlayer._animationDuration,
                                      curve: Curves.easeOut,
                                    )
                                    .catchError((_) {})
                              : null,
                        ),
                      ),
                      IgnorePointer(
                        ignoring: miniPlayerOpacity == 0,
                        child: Opacity(
                          opacity: miniPlayerOpacity,
                          child: MiniPlayerTapRegion(
                            onExpand: () => _controller.isAttached
                                ? _controller
                                      .animateTo(
                                        maxPlayerSize,
                                        duration:
                                            RadioPlayer._animationDuration,
                                        curve: Curves.easeOut,
                                      )
                                      .catchError((_) {})
                                : null,
                            child: const MiniPlayerContent(),
                          ),
                        ),
                      ),
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: _DragHandle(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

/// Drag handle widget for the draggable sheet
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) => Container(
    height: 4,
    width: 32,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurface,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
