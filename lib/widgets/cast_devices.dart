import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:etherly/localization/app_localizations.dart';
import 'package:etherly/services/chrome_cast_service.dart';
import 'package:etherly/services/radio_player_service.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

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
      title: Center(
        child: Text(
          loc?.translate('castDialogTitle') ?? 'Cast devices',
          textAlign: TextAlign.center,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: Consumer<ChromeCastService>(
          builder: (context, cast, _) {
            final devices = cast.devices;
            final connected = cast.connectedDevice;
            if (!cast.initialized) {
              cast.init();
            }
            if (devices.isEmpty) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: Text(
                  loc?.translate('castNoDevices') ?? 'No devices found',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 480),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: SingleChildScrollView(
                  key: ValueKey(devices.length),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...devices.map((device) {
                        final isSelected =
                            connected?.uniqueID == device.uniqueID;
                        final colorScheme = Theme.of(context).colorScheme;
                        return Padding(
                          key: ValueKey(device.uniqueID),
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: isSelected
                                  ? colorScheme.primaryContainer
                                  : colorScheme.secondaryContainer,
                              foregroundColor: isSelected
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSecondaryContainer,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                              final audio = context
                                  .read<AudioPlayerService>();
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
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Icon(
                                    isSelected
                                        ? Icons.cast_connected
                                        : Icons.cast,
                                  ),
                                ),
                                Text(
                                  device.friendlyName,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
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
}
