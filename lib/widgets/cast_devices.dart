import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/models/cast_device.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/theme_data.dart';

/// Dialog to show available Cast devices and connect/disconnect.
class CastDevices extends StatefulWidget {
  /// Creates an instance of [CastDevices].
  const CastDevices({super.key});

  @override
  State<CastDevices> createState() => _CastDevicesState();
}

class _CastDevicesState extends State<CastDevices> {
  ChromeCastService? _castService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cast = _castService ?? context.read<ChromeCastService>();
      if (cast.isCastSupported()) {
        if (!cast.isInitialized) {
          cast.init();
        }
        cast.startDiscovery();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _castService ??= context.read<ChromeCastService>();
  }


  @override
  void dispose() {
    if (_castService != null && _castService!.isCastSupported()) {
      _castService!.stopDiscovery();
    }
    super.dispose();
  }

  /// Build the Cast devices dialog.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.castDialogTitle ?? 'Cast devices',
        textAlign: TextAlign.center,
      ),
      content: Consumer<ChromeCastService>(
        builder: (context, cast, _) {
          final devices = cast.devices;
          final connected = cast.connectedDevice;
          final spacing = Theme.of(context).extension<Spacing>()!;

          if (!cast.isInitialized) {
            cast.init();
          }
          if (devices.isEmpty) {
            return Text(
              loc?.castNoDevices ?? 'No devices found',
              textAlign: TextAlign.center,
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...devices.map((device) {
                final isSelected = (connected?.id == device.id) ||
                    (connected?.name.isNotEmpty == true &&
                        connected?.name == device.name);

                return Padding(
                  key: ValueKey(device.id),
                  padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
                  child: isSelected
                      ? FilledButton.icon(
                          onPressed: () => _onDevicePressed(device, cast),
                          icon: const Icon(Icons.cast_connected_rounded),
                          label: Text(
                            device.name,
                            textAlign: TextAlign.center,
                          ),
                        )
                      : FilledButton.tonal(
                          onPressed: () => _onDevicePressed(device, cast),
                          child: Text(
                            device.name,
                            textAlign: TextAlign.center,
                          ),
                        ),
                );
              }),

            ],
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.close ?? 'Close'),
        ),
        Consumer<ChromeCastService>(
          builder: (context, cast, _) {
            final connected = cast.connectedDevice;
            if (connected == null) return const SizedBox.shrink();
            return FilledButton(
              onPressed: () async {
                if (context.mounted) Navigator.of(context).pop();
                await cast.endCasting();
              },
              child: Text(loc?.castStopCasting ?? 'Stop casting'),
            );
          },
        ),
      ],
    );
  }

  /// Handles selection of a Cast device from the dialog list.
  void _onDevicePressed(CastDevice device, ChromeCastService cast) async {

    if (mounted) {
      Navigator.of(context).pop();
    }
    final audio = context.read<AudioPlayerService>();
    await audio.playMediaItem(null, castDevice: device);
  }


}
