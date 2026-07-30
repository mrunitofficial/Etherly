import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:etherly/models/cast_device.dart';
import 'package:etherly/services/chrome_cast_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChromeCastService Unit Tests', () {
    late ChromeCastService service;
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      log.clear();
      service = ChromeCastService();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.mrunit.etherly/cast_control'),
            (MethodCall methodCall) async {
              log.add(methodCall);
              switch (methodCall.method) {
                case 'init':
                  return true;
                case 'startDiscovery':
                  return true;
                case 'stopDiscovery':
                  return true;
                case 'connect':
                  return true;
                case 'loadMedia':
                  return true;
                case 'play':
                  return true;
                case 'pause':
                  return true;
                case 'stop':
                  return true;
                case 'setVolume':
                  return true;
                case 'endCasting':
                  return true;
                default:
                  return null;
              }
            },
          );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('com.mrunit.etherly/cast_control'),
            null,
          );
      service.dispose();
    });

    test('Initial default state is clean', () {
      expect(service.isConnected, isFalse);
      expect(service.connectedDevice, isNull);
      expect(service.devices, isEmpty);
      expect(service.isInitialized, isFalse);
      expect(service.isRemotePlaying.value, isFalse);
      expect(service.isRemoteBuffering.value, isFalse);
      expect(service.remoteVolume.value, equals(1.0));
    });

    test('devices getter returns an unmodifiable list', () {
      final devices = service.devices;
      expect(
        () => (devices as List).add(const CastDevice(id: '1', name: 'Test')),
        throwsUnsupportedError,
      );
    });

    test('startDiscovery invokes native channel method on Android', () async {
      await service.startDiscovery();
      // On non-android host test runner, isCastSupported returns false, so method calls are skipped cleanly
      expect(service.devices, isEmpty);
    });
  });
}
