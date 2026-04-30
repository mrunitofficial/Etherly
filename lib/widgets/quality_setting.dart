import 'package:flutter/material.dart';
import 'package:etherly/models/station.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:provider/provider.dart';
import '../services/audio_player_service.dart';
import '../services/theme_data.dart';

/// A dialog widget for selecting the streaming quality of a radio station.
class QualitySetting extends StatelessWidget {
  final Station station;
  final String selectedQuality;
  final void Function(MapEntry<String, String>) onQualitySelected;

  const QualitySetting({
    super.key,
    required this.station,
    required this.selectedQuality,
    required this.onQualitySelected,
  });

  /// Static method to show the quality selection dialog and handle the result.
  static Future<void> show(BuildContext context) async {
    final service = Provider.of<AudioPlayerService>(context, listen: false);
    final mediaItem = service.mediaItem;
    if (mediaItem == null) return;

    final station = service.stations.firstWhere(
      (s) => s.id == mediaItem.id,
      orElse: () => service.stations.first,
    );

    final prefQuality = service.prefs.getString('streamQuality') ?? 'mp3';
    final availableStreams = station.streams;

    final selectedQuality = availableStreams.containsKey(prefQuality)
        ? prefQuality
        : availableStreams.keys.first;

    final newEntry = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) => QualitySetting(
        station: station,
        selectedQuality: selectedQuality,
        onQualitySelected: (entry) => Navigator.of(context).pop(entry),
      ),
    );

    if (newEntry != null && newEntry.key != selectedQuality) {
      service.prefs.setString('streamQuality', newEntry.key);
      service.stop();
      service.playMediaItem(station);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final streams = station.streams;
    final spacing = Theme.of(context).extension<Spacing>()!;

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.translate('playerStreamQuality') ?? 'Stream Quality',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...streams.entries.map((entry) {
            final key = entry.key;
            final isSelected = selectedQuality == key;
            final label = _getQualityLabel(key, loc);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
              child: isSelected
                  ? FilledButton(
                      onPressed: () => onQualitySelected(entry),
                      child: Text(label, textAlign: TextAlign.center),
                    )
                  : FilledButton.tonal(
                      onPressed: () => onQualitySelected(entry),
                      child: Text(label, textAlign: TextAlign.center),
                    ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }

  static const Map<String, String> _qualityLabelKeys = {
    'mp3': 'settingsStreamingQualityHigh',
    'aac': 'settingsStreamingQualityHighest',
  };

  static const Map<String, String> _qualityDefaultLabels = {
    'mp3': 'High (MP3)',
    'aac': 'Highest (AAC)',
  };

  String _getQualityLabel(String key, AppLocalizations? loc) {
    final cleanKey = key.toLowerCase();
    final translationKey = _qualityLabelKeys[cleanKey];
    
    if (translationKey != null && loc != null) {
      return loc.translate(translationKey);
    }
    
    return _qualityDefaultLabels[cleanKey] ?? key.toUpperCase();
  }
}
