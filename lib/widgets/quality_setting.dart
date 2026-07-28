import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:etherly/localization/app_localizations.dart';

import 'package:etherly/models/station.dart';

import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/theme_data.dart';

/// A dialog widget for selecting the streaming quality of a radio station.
class QualitySetting extends StatelessWidget {
  final Station station;
  final String selectedQuality;
  final List<String> failedQualities;
  final void Function(MapEntry<String, String>) onQualitySelected;

  const QualitySetting({
    super.key,
    required this.station,
    required this.selectedQuality,
    this.failedQualities = const [],
    required this.onQualitySelected,
  });

  /// Static method to show the quality selection dialog and handle the result.
  static Future<void> show(BuildContext context) async {
    final service = Provider.of<AudioPlayerService>(context, listen: false);
    final mediaItem = service.mediaItem;
    if (mediaItem == null) return;

    final station = service.currentStation;
    if (station == null) return;

    final prefQuality = service.prefs.getString('streamQuality') ?? 'mp3';
    final activeQuality =
        mediaItem.extras?['activeQuality'] as String? ?? prefQuality;

    final failedQualities =
        (mediaItem.extras?['failedQualities'] as List?)?.cast<String>() ?? [];

    final allStreams = <String, String>{
      'mp3': station.streams['mp3'] ?? '',
      'aac': station.streams['aac'] ?? '',
      ...station.streams,
    };

    final selectedQuality = allStreams.containsKey(activeQuality)
        ? activeQuality
        : (allStreams.keys.firstWhere(
            (k) => allStreams[k]!.trim().isNotEmpty,
            orElse: () => allStreams.keys.first,
          ));

    final newEntry = await showDialog<MapEntry<String, String>>(
      context: context,
      builder: (context) => QualitySetting(
        station: station,
        selectedQuality: selectedQuality,
        failedQualities: failedQualities,
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
    final spacing = Theme.of(context).extension<Spacing>()!;

    final allStreams = <String, String>{
      'mp3': station.streams['mp3'] ?? '',
      'aac': station.streams['aac'] ?? '',
      ...station.streams,
    };

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.playerStreamQuality ?? 'Stream Quality',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: allStreams.entries.map((entry) {
          final key = entry.key;
          final isSelected = selectedQuality == key;
          final label = _getQualityLabel(key, loc);
          final isAvailable = entry.value.trim().isNotEmpty &&
              !failedQualities.contains(key);

          final VoidCallback? onPressed =
              isAvailable ? () => onQualitySelected(entry) : null;

          return Padding(
            padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
            child: Semantics(
              selected: isSelected,
              button: true,
              enabled: isAvailable,
              label: label,
              excludeSemantics: true,
              child: isSelected
                  ? FilledButton(
                      onPressed: onPressed,
                      child: Text(label, textAlign: TextAlign.center),
                    )
                  : FilledButton.tonal(
                      onPressed: onPressed,
                      child: Text(label, textAlign: TextAlign.center),
                    ),
            ),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.close ?? 'Close'),
        ),
      ],
    );
  }

  static const Map<String, String> _qualityDefaultLabels = {
    'mp3': 'High (MP3)',
    'aac': 'Highest (AAC)',
  };

  String _getQualityLabel(String key, AppLocalizations? loc) {
    final cleanKey = key.toLowerCase();

    if (loc != null) {
      if (cleanKey == 'mp3') return loc.settingsStreamingQualityHigh;
      if (cleanKey == 'aac') return loc.settingsStreamingQualityHighest;
    }

    return _qualityDefaultLabels[cleanKey] ?? key.toUpperCase();
  }
}
