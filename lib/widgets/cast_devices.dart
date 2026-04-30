import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/audio_player_service.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import '../services/theme_data.dart';

/// Dialog to show available Cast devices and connect/disconnect.
class CastDevices extends StatefulWidget {
  const CastDevices({super.key});

  @override
  State<CastDevices> createState() => _CastDevicesState();
}

class _CastDevicesState extends State<CastDevices> {
  @override
  void initState() {
    super.initState();
    final cast = context.read<ChromeCastService>();
    if (cast.isCastSupported() && cast.initialized) {
      GoogleCastDiscoveryManager.instance.stopDiscovery();
      GoogleCastDiscoveryManager.instance.startDiscovery();
    }
  }

  @override
  void dispose() {
    Future.microtask(() {
      try {
        GoogleCastDiscoveryManager.instance.stopDiscovery();
      } catch (_) {}
    });
    super.dispose();
  }

  /// Build the Cast devices dialog.
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return AlertDialog(
      scrollable: true,
      title: Text(
        loc?.translate('castDialogTitle') ?? 'Cast devices',
        textAlign: TextAlign.center,
      ),
      content: Consumer<ChromeCastService>(
        builder: (context, cast, _) {
          final devices = cast.devices;
          final connected = cast.connectedDevice;
          if (!cast.initialized) {
            cast.init();
          }
          if (devices.isEmpty) {
            return Text(
              loc?.translate('castNoDevices') ?? 'No devices found',
              textAlign: TextAlign.center,
            );
          }
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            switchInCurve: Easing.emphasizedDecelerate,
            switchOutCurve: Easing.emphasizedAccelerate,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Column(
              key: ValueKey(devices.length),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...devices.map((device) {
                  final isSelected = connected?.uniqueID == device.uniqueID;
                  final spacing = Theme.of(context).extension<Spacing>()!;

                  return Padding(
                    key: ValueKey(device.uniqueID),
                    padding: EdgeInsets.symmetric(vertical: spacing.extraSmall),
                    child: isSelected
                        ? FilledButton.icon(
                            onPressed: () => _onDevicePressed(device, cast),
                            icon: const Icon(Icons.cast_connected),
                            label: Text(
                              device.friendlyName,
                              textAlign: TextAlign.center,
                            ),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: () => _onDevicePressed(device, cast),
                            icon: const Icon(Icons.cast),
                            label: Text(
                              device.friendlyName,
                              textAlign: TextAlign.center,
                            ),
                          ),
                  );
                }),
              ],
            ),
          );
        },
      ),
      actions: [
        Consumer<ChromeCastService>(
          builder: (context, cast, _) {
            final connected = cast.connectedDevice;
            if (connected == null) return const SizedBox.shrink();
            return TextButton(
              onPressed: () async {
                if (context.mounted) Navigator.of(context).pop();
                await cast.endCasting();
              },
              child: Text(loc?.translate('castStopCasting') ?? 'Stop casting'),
            );
          },
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc?.translate('close') ?? 'Close'),
        ),
      ],
    );
  }

  void _onDevicePressed(dynamic device, ChromeCastService cast) async {
    if (mounted) {
      Navigator.of(context).pop();
    }
    final audio = context.read<AudioPlayerService>();
    final mediaItem = audio.mediaItem;
    if (mediaItem == null) return;

    final selectedId = device.uniqueID;
    final currentDevice = cast.devices.firstWhere(
      (d) => d.uniqueID == selectedId,
      orElse: () => device,
    );

    try {
      await audio.stop();
      await cast.connectAndWait(currentDevice);
      await cast.castAudio(mediaItem: mediaItem);
    } catch (_) {
      // Connection or casting failed
    }
  }
}
