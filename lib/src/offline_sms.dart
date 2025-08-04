import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'models/offline_connection_state.dart';
import 'models/offline_device.dart';
import 'models/offline_message.dart';

class OfflineSms {
  static const String _serviceUuid = '6ba1b218-15a8-461b-9fa8-5bdae927e7b5';
  static const String _characteristicUuid =
      '6ba1b219-15a8-461b-9fa8-5bdae927e7b5';
  static const String _deviceNamePrefix = 'OfflineSMS_';

  // Stream controllers
  final StreamController<OfflineConnectionState> _connectionStateController =
      StreamController<OfflineConnectionState>.broadcast();
  final StreamController<List<OfflineDevice>> _discoveredDevicesController =
      StreamController<List<OfflineDevice>>.broadcast();
  final StreamController<OfflineMessage> _messagesController =
      StreamController<OfflineMessage>.broadcast();

  // State variables
  OfflineConnectionState _connectionState = OfflineConnectionState.unavailable;
  OfflineDevice? _connectedDevice;
  final List<OfflineDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isAdvertising = false;
  String? _deviceId;
  String? _deviceName;

  // Bluetooth objects
  BluetoothDevice? _currentDevice;
  BluetoothCharacteristic? _messageCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  // Getters
  Stream<OfflineConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<List<OfflineDevice>> get discoveredDevicesStream =>
      _discoveredDevicesController.stream;
  Stream<OfflineMessage> get messagesStream => _messagesController.stream;
  OfflineConnectionState get connectionState => _connectionState;
  OfflineDevice? get connectedDevice => _connectedDevice;
  List<OfflineDevice> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;

  /// Initialize the Bluetooth system and request permissions
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isSupported) {
        _updateConnectionState(OfflineConnectionState.unavailable);
        return false;
      }

      // Request permissions
      final bluetoothPermission = await Permission.bluetooth.request();
      final bluetoothScanPermission = await Permission.bluetoothScan.request();
      final bluetoothConnectPermission =
          await Permission.bluetoothConnect.request();
      final locationPermission = await Permission.location.request();

      if (bluetoothPermission.isDenied ||
          bluetoothScanPermission.isDenied ||
          bluetoothConnectPermission.isDenied ||
          locationPermission.isDenied) {
        _updateConnectionState(OfflineConnectionState.unavailable);
        return false;
      }

      // Generate device ID and name
      _deviceId = const Uuid().v4();
      _deviceName = '$_deviceNamePrefix${_deviceId!.substring(0, 8)}';

      // Listen to Bluetooth state changes
      FlutterBluePlus.adapterState.listen((state) {
        if (state == BluetoothAdapterState.on) {
          _updateConnectionState(OfflineConnectionState.idle);
        } else {
          _updateConnectionState(OfflineConnectionState.unavailable);
        }
      });

      _updateConnectionState(OfflineConnectionState.idle);
      return true;
    } catch (e) {
      debugPrint('Failed to initialize OfflineSms: $e');
      _updateConnectionState(OfflineConnectionState.error);
      return false;
    }
  }

  /// Start scanning for nearby devices
  Future<void> startScanning() async {
    if (_isScanning || _connectionState == OfflineConnectionState.unavailable) {
      return;
    }

    try {
      _isScanning = true;
      _updateConnectionState(OfflineConnectionState.scanning);
      _discoveredDevices.clear();
      _emitDiscoveredDevices();

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final device = OfflineDevice.fromBluetoothDevice(
            result.device,
            result.rssi,
          );

          // Only add devices that are not already in the list
          if (!_discoveredDevices.any((d) => d.id == device.id)) {
            _discoveredDevices.add(device);
            _emitDiscoveredDevices();
          }
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        androidUsesFineLocation: true,
      );
    } catch (e) {
      debugPrint('Error starting scan: $e');
      _isScanning = false;
      _updateConnectionState(OfflineConnectionState.error);
    }
  }

  /// Stop scanning for devices
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      _isScanning = false;
      _updateConnectionState(OfflineConnectionState.idle);
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Connect to a specific device
  Future<bool> connectToDevice(OfflineDevice device) async {
    if (device.bluetoothDevice == null) return false;

    try {
      _updateConnectionState(OfflineConnectionState.connecting);

      _currentDevice = device.bluetoothDevice!;
      await _currentDevice!.connect(timeout: const Duration(seconds: 10));

      // Discover services
      final services = await _currentDevice!.discoverServices();
      final targetService = services.firstWhere(
        (service) => service.uuid.toString() == _serviceUuid,
        orElse: () => throw Exception('Service not found'),
      );

      // Get the message characteristic
      _messageCharacteristic = targetService.characteristics.firstWhere(
        (char) => char.uuid.toString() == _characteristicUuid,
        orElse: () => throw Exception('Characteristic not found'),
      );

      // Subscribe to notifications
      await _messageCharacteristic!.setNotifyValue(true);
      _messageCharacteristic!.onValueReceived.listen(_handleIncomingMessage);

      // Listen to connection state changes
      _connectionSubscription = _currentDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      _connectedDevice = device.copyWith(isConnected: true);
      _updateConnectionState(OfflineConnectionState.connected);
      return true;
    } catch (e) {
      debugPrint('Error connecting to device: $e');
      _updateConnectionState(OfflineConnectionState.error);
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect() async {
    try {
      await _currentDevice?.disconnect();
      _handleDisconnection();
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }

  /// Send a message to the connected device
  Future<bool> sendMessage(String message) async {
    if (_messageCharacteristic == null || _connectedDevice == null) {
      return false;
    }

    try {
      final offlineMessage = OfflineMessage(
        content: message,
        isFromMe: true,
        senderDeviceId: _deviceId!,
        senderDeviceName: _deviceName!,
      );

      final messageData = jsonEncode(offlineMessage.toJson());
      final bytes = utf8.encode(messageData);
      final data = Uint8List.fromList(bytes);

      await _messageCharacteristic!.write(data, withoutResponse: true);

      // Emit the sent message
      _messagesController.add(offlineMessage);
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Start advertising this device
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    try {
      _isAdvertising = true;
      // Note: Advertising functionality would need platform-specific implementation
      // This is a placeholder for the concept
      debugPrint('Advertising started');
    } catch (e) {
      debugPrint('Error starting advertising: $e');
      _isAdvertising = false;
    }
  }

  /// Stop advertising this device
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;

    try {
      _isAdvertising = false;
      debugPrint('Advertising stopped');
    } catch (e) {
      debugPrint('Error stopping advertising: $e');
    }
  }

  /// Handle incoming messages
  void _handleIncomingMessage(List<int> value) {
    try {
      final messageString = utf8.decode(value);
      final messageData = jsonDecode(messageString) as Map<String, dynamic>;
      final message = OfflineMessage.fromJson(messageData);

      // Only process messages from other devices
      if (message.senderDeviceId != _deviceId) {
        _messagesController.add(message);
      }
    } catch (e) {
      debugPrint('Error handling incoming message: $e');
    }
  }

  /// Handle device disconnection
  void _handleDisconnection() {
    _connectedDevice = null;
    _currentDevice = null;
    _messageCharacteristic = null;
    _connectionSubscription?.cancel();
    _connectionSubscription = null;
    _updateConnectionState(OfflineConnectionState.disconnected);
  }

  /// Update connection state and emit to stream
  void _updateConnectionState(OfflineConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }

  /// Emit discovered devices to stream
  void _emitDiscoveredDevices() {
    _discoveredDevicesController.add(_discoveredDevices);
  }

  /// Clean up resources
  void dispose() {
    stopScanning();
    disconnect();
    stopAdvertising();
    _connectionStateController.close();
    _discoveredDevicesController.close();
    _messagesController.close();
  }
}
