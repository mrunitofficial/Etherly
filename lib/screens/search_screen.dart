import 'package:etherly/models/station.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:etherly/widgets/station_card_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

/// A screen that allows users to search for radio stations by typing or voice input.
class SearchScreen extends StatefulWidget {
  final bool startListening;

  const SearchScreen({super.key, this.startListening = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  late stt.SpeechToText _speech;
  bool _isListening = false;

  /// Initializes and disposes resources.
  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controller.addListener(_onQueryChanged);

    if (widget.startListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _toggleListening());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();

    if (_speech.isListening) {
      _speech.stop();
    }
    super.dispose();
  }

  /// Manages states.
  void _onQueryChanged() {
    setState(() {
      _query = _controller.text;
    });
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) {
        setState(() => _isListening = false);
        FocusScope.of(context).requestFocus(FocusNode());
        _onQueryChanged();
      }
    }
  }

  void _onSpeechError(dynamic error) {
    if (mounted) setState(() => _isListening = false);
  }

  Future<void> _toggleListening() async {
    if (!_isListening) {
      final micStatus = await Permission.microphone.request();
      if (!mounted) return;

      if (!micStatus.isGranted) {
        return;
      }

      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      if (!mounted) return;

      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (result) {
            if (!mounted) return;
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
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

  /// Builds the search screen UI.
  @override
  Widget build(BuildContext context) {
    final audioPlayerService = Provider.of<AudioPlayerService>(context);
    final stations = audioPlayerService.stations;
    final loc = AppLocalizations.of(context);

    final filtered = _query.isEmpty
        ? <Station>[]
        : stations.where((station) {
            final q = _query.toLowerCase();
            return station.name.toLowerCase().contains(q) ||
                station.category.toLowerCase().contains(q) ||
                station.id.toLowerCase().contains(q);
          }).toList();

    Widget bodyContent;
    if (_query.isEmpty) {
      bodyContent = Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 256.0),
          child: Text(
            loc?.translate(
                  _isListening
                      ? 'searchPanelVoiceToSearch'
                      : 'searchPanelTypeToSearch',
                ) ??
                (_isListening
                    ? 'Speak to search stations......'
                    : 'Type to search stations...'),
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (filtered.isEmpty) {
      bodyContent = Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 256.0),
          child: Text(
            loc?.translate('searchPanelNoResults') ?? 'No stations found',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      bodyContent = ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final station = filtered[index];
          return StationCardItem(
            station: station,
            isFavorite: station.isFavorite,
            onTap: () async {
              audioPlayerService.playMediaItem(station);
              audioPlayerService.radioPlayerShouldClose.value = true;
              Navigator.of(context).pop();
              await Future.delayed(const Duration(milliseconds: 350));
            },
            onFavorite: () {
              audioPlayerService.toggleFavorite(station);
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_speech.isListening) {
              _speech.stop();
            }
            Navigator.of(context).pop();
          },
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: _isListening
                      ? loc?.translate('searchPanelVoiceHint') ??
                            'Start talking to search stations...'
                      : loc?.translate('searchPanelHint') ??
                            'Search stations...',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              tooltip:
                  loc?.translate('searchPanelVoiceTooltip') ?? 'Voice search',
              onPressed: _toggleListening,
            ),
          ],
        ),
      ),
      body: bodyContent,
    );
  }
}
