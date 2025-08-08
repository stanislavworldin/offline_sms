import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sms/offline_sms.dart';

void main() {
  group('OfflineSms Tests', () {
    late OfflineSms offlineSms;

    setUp(() {
      offlineSms = OfflineSms();
    });

    tearDown(() {
      offlineSms.dispose();
    });

    test('should create OfflineSms instance', () {
      expect(offlineSms, isNotNull);
      expect(offlineSms.connectionState, OfflineConnectionState.unavailable);
      expect(offlineSms.discoveredDevices, isEmpty);
      expect(offlineSms.isScanning, isFalse);
      expect(offlineSms.isAdvertising, isFalse);
    });

    test('should have correct initial state', () {
      expect(offlineSms.connectionState, OfflineConnectionState.unavailable);
      expect(offlineSms.connectedDevice, isNull);
      expect(offlineSms.discoveredDevices, isEmpty);
    });

    test('should emit connection state changes', () async {
      final states = <OfflineConnectionState>[];
      offlineSms.connectionStateStream.listen(states.add);

      // Wait for initial state
      await Future.delayed(const Duration(milliseconds: 100));

      expect(states, isNotEmpty);
      expect(states.first, OfflineConnectionState.unavailable);
    });

    test('should emit discovered devices', () async {
      final devices = <List<OfflineDevice>>[];
      offlineSms.discoveredDevicesStream.listen(devices.add);

      // Wait for initial empty list
      await Future.delayed(const Duration(milliseconds: 100));

      expect(devices, isNotEmpty);
    });

    test('should emit messages', () async {
      final messages = <OfflineMessage>[];
      offlineSms.messagesStream.listen(messages.add);

      // Wait for any potential messages
      await Future.delayed(const Duration(milliseconds: 100));

      expect(messages, isNotNull);
    });
  });

  group('OfflineMessage Tests', () {
    test('should create message with required fields', () {
      final message = OfflineMessage(
        content: 'Test message',
        isFromMe: true,
        senderDeviceId: 'device1',
        senderDeviceName: 'Device 1',
      );

      expect(message.content, 'Test message');
      expect(message.isFromMe, true);
      expect(message.senderDeviceId, 'device1');
      expect(message.senderDeviceName, 'Device 1');
      expect(message.id, isNotEmpty);
      expect(message.timestamp, isNotNull);
    });

    test('should convert to and from JSON', () {
      final originalMessage = OfflineMessage(
        content: 'Test message',
        isFromMe: true,
        senderDeviceId: 'device1',
        senderDeviceName: 'Device 1',
      );

      final json = originalMessage.toJson();
      final restoredMessage = OfflineMessage.fromJson(json);

      expect(restoredMessage.content, originalMessage.content);
      expect(restoredMessage.isFromMe, originalMessage.isFromMe);
      expect(restoredMessage.senderDeviceId, originalMessage.senderDeviceId);
      expect(
        restoredMessage.senderDeviceName,
        originalMessage.senderDeviceName,
      );
      expect(restoredMessage.id, originalMessage.id);
    });
  });

  group('OfflineDevice Tests', () {
    test('should create device with required fields', () {
      final device = OfflineDevice(
        id: 'device1',
        name: 'Test Device',
        rssi: -50,
        discoveredAt: DateTime.now(),
      );

      expect(device.id, 'device1');
      expect(device.name, 'Test Device');
      expect(device.rssi, -50);
      expect(device.isConnected, false);
      expect(device.isConnectable, true);
      expect(device.discoveredAt, isNotNull);
    });

    test('should copy with new values', () {
      final originalDevice = OfflineDevice(
        id: 'device1',
        name: 'Test Device',
        rssi: -50,
        discoveredAt: DateTime.now(),
      );

      final updatedDevice = originalDevice.copyWith(
        isConnected: true,
        rssi: -40,
      );

      expect(updatedDevice.id, originalDevice.id);
      expect(updatedDevice.name, originalDevice.name);
      expect(updatedDevice.isConnected, true);
      expect(updatedDevice.rssi, -40);
      expect(updatedDevice.discoveredAt, originalDevice.discoveredAt);
    });
  });

  group('OfflineConnectionState Tests', () {
    test('should have correct descriptions', () {
      expect(
        OfflineConnectionState.unavailable.description,
        'Bluetooth Unavailable',
      );
      expect(OfflineConnectionState.idle.description, 'Idle');
      expect(
        OfflineConnectionState.scanning.description,
        'Scanning for devices',
      );
      expect(OfflineConnectionState.connecting.description, 'Connecting...');
      expect(OfflineConnectionState.connected.description, 'Connected');
      expect(OfflineConnectionState.disconnected.description, 'Disconnected');
      expect(OfflineConnectionState.error.description, 'Error');
    });
  });
}
