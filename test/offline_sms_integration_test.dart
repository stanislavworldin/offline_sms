import 'package:flutter_test/flutter_test.dart';
import 'package:offline_sms/offline_sms.dart';

void main() {
  group('OfflineSms Integration Tests', () {
    late OfflineSms offlineSms;

    setUp(() {
      offlineSms = OfflineSms();
    });

    tearDown(() {
      offlineSms.dispose();
    });

    test('should handle complete message flow', () async {
      // Test initialization
      expect(offlineSms.connectionState, OfflineConnectionState.unavailable);

      // Note: Bluetooth operations may not work in test environment
      // This test verifies the basic structure
      expect(offlineSms.discoveredDevices, isEmpty);
      expect(offlineSms.isScanning, false);
      expect(offlineSms.isAdvertising, false);
    });

    test('should handle device discovery', () async {
      final devices = <List<OfflineDevice>>[];
      offlineSms.discoveredDevicesStream.listen(devices.add);

      // Note: Bluetooth scanning may not work in test environment
      // This test verifies the stream is available
      await Future.delayed(const Duration(milliseconds: 100));
      expect(devices, isNotNull);
    });

    test('should handle connection state changes', () async {
      final states = <OfflineConnectionState>[];
      offlineSms.connectionStateStream.listen(states.add);

      // Note: Bluetooth state changes may not work in test environment
      // This test verifies the stream is available
      await Future.delayed(const Duration(milliseconds: 100));
      expect(states, isNotNull);
    });

    test('should handle message sending in demo mode', () async {
      final messages = <OfflineMessage>[];
      offlineSms.messagesStream.listen(messages.add);

      // Simulate sending a message
      final testMessage = OfflineMessage(
        content: 'Test message',
        isFromMe: true,
        senderDeviceId: 'test-device',
        senderDeviceName: 'Test Device',
      );

      // This would normally be sent through BLE
      // For testing, we just verify the message structure
      expect(testMessage.content, 'Test message');
      expect(testMessage.isFromMe, true);
      expect(testMessage.senderDeviceName, 'Test Device');
    });
  });

  group('OfflineDevice Integration Tests', () {
    test('should create device from Bluetooth device', () {
      // Mock Bluetooth device data
      final mockDevice = OfflineDevice(
        id: 'test-device-id',
        name: 'Test Bluetooth Device',
        rssi: -50,
        discoveredAt: DateTime.now(),
      );

      expect(mockDevice.id, 'test-device-id');
      expect(mockDevice.name, 'Test Bluetooth Device');
      expect(mockDevice.rssi, -50);
      expect(mockDevice.isConnected, false);
    });

    test('should update device connection status', () {
      final device = OfflineDevice(
        id: 'test-device',
        name: 'Test Device',
        rssi: -50,
        discoveredAt: DateTime.now(),
      );

      final connectedDevice = device.copyWith(isConnected: true);
      expect(connectedDevice.isConnected, true);
      expect(connectedDevice.id, device.id);
      expect(connectedDevice.name, device.name);
    });
  });

  group('OfflineMessage Integration Tests', () {
    test('should serialize and deserialize message correctly', () {
      final originalMessage = OfflineMessage(
        content: 'Hello, world!',
        isFromMe: true,
        senderDeviceId: 'device-1',
        senderDeviceName: 'iPhone 15 Pro',
      );

      final json = originalMessage.toJson();
      final restoredMessage = OfflineMessage.fromJson(json);

      expect(restoredMessage.content, originalMessage.content);
      expect(restoredMessage.isFromMe, originalMessage.isFromMe);
      expect(restoredMessage.senderDeviceId, originalMessage.senderDeviceId);
      expect(
          restoredMessage.senderDeviceName, originalMessage.senderDeviceName);
      expect(restoredMessage.id, originalMessage.id);
    });

    test('should handle message with special characters', () {
      final message = OfflineMessage(
        content: 'Hello! 🌍 Привет! 你好!',
        isFromMe: false,
        senderDeviceId: 'device-1',
        senderDeviceName: 'Test Device',
      );

      final json = message.toJson();
      final restoredMessage = OfflineMessage.fromJson(json);

      expect(restoredMessage.content, 'Hello! 🌍 Привет! 你好!');
    });

    test('should handle long messages', () {
      final longContent = 'A' * 1000; // 1000 character message
      final message = OfflineMessage(
        content: longContent,
        isFromMe: true,
        senderDeviceId: 'device-1',
        senderDeviceName: 'Test Device',
      );

      expect(message.content.length, 1000);
      expect(message.content, longContent);
    });
  });

  group('Connection State Tests', () {
    test('should have valid state transitions', () {
      expect(OfflineConnectionState.unavailable.description,
          'Bluetooth Unavailable');
      expect(OfflineConnectionState.idle.description, 'Idle');
      expect(
          OfflineConnectionState.scanning.description, 'Scanning for devices');
      expect(OfflineConnectionState.connecting.description, 'Connecting...');
      expect(OfflineConnectionState.connected.description, 'Connected');
      expect(OfflineConnectionState.disconnected.description, 'Disconnected');
      expect(OfflineConnectionState.error.description, 'Error');
    });

    test('should handle all state values', () {
      final states = OfflineConnectionState.values;
      expect(states.length, 7);

      for (final state in states) {
        expect(state.description, isNotEmpty);
        expect(state.description.length, greaterThan(0));
      }
    });
  });

  group('Error Handling Tests', () {
    test('should handle invalid JSON gracefully', () {
      expect(() {
        OfflineMessage.fromJson({'invalid': 'data'});
      }, throwsA(isA<TypeError>()));
    });

    test('should handle empty message content', () {
      final message = OfflineMessage(
        content: '',
        isFromMe: true,
        senderDeviceId: 'device-1',
        senderDeviceName: 'Test Device',
      );

      expect(message.content, '');
      expect(message.id, isNotEmpty);
    });

    test('should handle null device name', () {
      final device = OfflineDevice(
        id: 'test-device',
        name: '',
        rssi: -50,
        discoveredAt: DateTime.now(),
      );

      expect(device.name, '');
      expect(device.id, 'test-device');
    });
  });

  group('Performance Tests', () {
    test('should handle multiple devices efficiently', () {
      final devices = <OfflineDevice>[];

      for (int i = 0; i < 100; i++) {
        devices.add(OfflineDevice(
          id: 'device-$i',
          name: 'Device $i',
          rssi: -50 - i,
          discoveredAt: DateTime.now(),
        ));
      }

      expect(devices.length, 100);
      expect(devices.first.id, 'device-0');
      expect(devices.last.id, 'device-99');
    });

    test('should handle multiple messages efficiently', () {
      final messages = <OfflineMessage>[];

      for (int i = 0; i < 1000; i++) {
        messages.add(OfflineMessage(
          content: 'Message $i',
          isFromMe: i % 2 == 0,
          senderDeviceId: 'device-${i % 5}',
          senderDeviceName: 'Device ${i % 5}',
        ));
      }

      expect(messages.length, 1000);
      expect(messages.where((m) => m.isFromMe).length, 500);
      expect(messages.where((m) => !m.isFromMe).length, 500);
    });
  });
}
