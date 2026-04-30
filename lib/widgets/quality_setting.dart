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
  final void Function(String) onQualitySelected;

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
    final availableQualities = station.streams.keys.toList();

    final selectedQuality = availableQualities.contains(prefQuality)
        ? prefQuality
        : availableQualities.first;

    final newQuality = await showDialog<String>(
      context: context,
      builder: (context) => QualitySetting(
        station: station,
        selectedQuality: selectedQuality,
        onQualitySelected: (q) => Navigator.of(context).pop(q),
      ),
    );

    if (newQuality != null && newQuality != selectedQuality) {
      service.prefs.setString('streamQuality', newQuality);
      service.stop();
      service.playMediaItem(station);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final streams = station!.streams;
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
          ...streams.keys.map((key) {
            final isSelected = selectedQuality == key;
            final label = _getQualityLabel(key, loc);

            return Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
              child: isSelected
                  ? FilledButton(
                      onPressed: () => onQualitySelected(key),
                      child: Text(label, textAlign: TextAlign.center),
                    )
                  : FilledButton.tonal(
                      onPressed: () => onQualitySelected(key),
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
  String _getQualityLabel(String key, AppLocalizations? loc) {
    switch (key.toLowerCase()) {
      case 'mp3':
        return loc?.translate('settingsStreamingQualityHigh') ?? 'High (MP3)';
      case 'aac':
        return loc?.translate('settingsStreamingQualityHighest') ?? 'Highest (AAC)';
      default:
        return key.toUpperCase();
    }
  }
}
