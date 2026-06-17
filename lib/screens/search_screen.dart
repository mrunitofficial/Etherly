import 'package:etherly/models/station.dart';
import 'package:etherly/models/device.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/theme_data.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// A native search bar that allows users to search for radio stations.
class StationSearchBar extends StatefulWidget {
  const StationSearchBar({super.key});

  @override
  State<StationSearchBar> createState() => _StationSearchBarState();
}

class _StationSearchBarState extends State<StationSearchBar> {
  final SearchController _controller = SearchController();
  final FocusNode _focusNode = FocusNode();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _onSpeechError(dynamic error) {
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!mounted) return;

      if (available) {
        setState(() => _isListening = true);
        if (!_controller.isOpen) {
          _controller.openView();
        }
        _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            _controller.text = result.recognizedWords;
          },
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
            listenMode: stt.ListenMode.confirmation,
          ),
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioPlayerService = context.watch<AudioPlayerService>();
    final stations = audioPlayerService.stations;
    final loc = AppLocalizations.of(context);
    final screenType = ScreenType.fromContext(context);
    final theme = Theme.of(context);
    final spacing = theme.extension<Spacing>()!;

    return SearchAnchor(
      searchController: _controller,
      viewElevation: 0,
      viewBackgroundColor: theme.colorScheme.surfaceContainerHighest,
      isFullScreen: !screenType.isLargeFormat,
      builder: (BuildContext context, SearchController controller) {
        return SearchBar(
          focusNode: _focusNode,
          controller: controller,
          elevation: const WidgetStatePropertyAll<double>(0.0),
          backgroundColor: WidgetStatePropertyAll<Color>(
            theme.colorScheme.surfaceContainerHigh,
          ),
          padding: WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: spacing.extraSmall),
          ),
          onTap: () {
            controller.openView();
          },
          leading: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.small + spacing.extraSmall),
            child: Icon(
              Icons.search,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          hintText: _isListening
              ? loc?.searchPanelVoiceHint ??
                    'Start talking to search stations...'
              : loc?.searchPanelHint ?? 'Search stations...',
          trailing: [
            IconButton(
              icon: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: loc?.mainTooltipVoiceSearch ?? 'Voice search',
              onPressed: _toggleListening,
            ),
          ],
        );
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        final query = controller.text.toLowerCase();

        final filtered = query.isEmpty
            ? <Station>[]
            : stations.where((station) {
                return station.name.toLowerCase().contains(query) ||
                    station.category.toLowerCase().contains(query) ||
                    station.id.toLowerCase().contains(query) ||
                    station.tags.any(
                      (tag) => tag.toLowerCase().contains(query),
                    );
              }).toList();

        if (query.isEmpty) {
          return [
            Padding(
              padding: EdgeInsets.only(top: spacing.extraLarge * 2),
              child: Center(
                child: Text(
                  _isListening
                      ? (loc?.searchPanelVoiceToSearch ??
                            'Speak to search stations......')
                      : (loc?.searchPanelTypeToSearch ??
                            'Type to search stations...'),
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ];
        }

        if (filtered.isEmpty) {
          return [
            Padding(
              padding: EdgeInsets.only(top: spacing.extraLarge * 2),
              child: Center(
                child: Text(
                  loc?.searchPanelNoResults ?? 'No stations found',
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ];
        }

        return [
          SizedBox(height: spacing.small),
          ...filtered.map((station) {
            return ListenableBuilder(
              listenable: audioPlayerService,
              builder: (context, _) {
                final currentStation = audioPlayerService.stations.firstWhere(
                  (s) => s.id == station.id,
                  orElse: () => station,
                );

                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing.small + spacing.extraSmall,
                    vertical: spacing.extraSmall,
                  ),
                  child: StationCardItem(
                    station: currentStation,
                    isFavorite: currentStation.isFavorite,
                    screenType: screenType,
                    onTap: () async {
                      audioPlayerService.playMediaItem(currentStation);
                      audioPlayerService.radioPlayerShouldClose.value = true;
                      FocusManager.instance.primaryFocus?.unfocus();
                      controller.closeView(currentStation.name);
                    },
                    onFavorite: () {
                      audioPlayerService.toggleFavorite(currentStation);
                    },
                  ),
                );
              },
            );
          }),
          SizedBox(height: spacing.small),
        ];
      },
    );
  }
}
