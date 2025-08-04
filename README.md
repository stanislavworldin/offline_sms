# Offline SMS

A comprehensive Flutter package for peer-to-peer messaging via Bluetooth Low Energy (BLE) without requiring an internet connection. Perfect for offline communication between nearby devices.

## Features

- **Device Discovery**: Scan for nearby Bluetooth devices
- **Secure Connections**: Establish reliable BLE connections
- **Real-time Messaging**: Send and receive text messages instantly
- **Cross-platform**: Support for Android and iOS
- **Permission Handling**: Automatic Bluetooth permission management
- **Connection Monitoring**: Real-time connection state tracking
- **Event Streaming**: Stream-based architecture for UI integration
- **Error Handling**: Comprehensive error management and recovery
- **Debug Logging**: Detailed logging for development and troubleshooting
- **Demo Mode**: Web-based demonstration with device simulation
- **Adaptive UI**: Beautiful responsive design for mobile and web
- **Message Sender Selection**: Choose which device to send messages from (demo mode)

## Use Cases

- **Offline Messaging**: Send and receive text messages without internet connectivity
- **Proximity Communication**: Chat with devices in close physical proximity
- **Emergency Communication**: Reliable messaging when cellular networks are unavailable
- **Local Networks**: Create ad-hoc communication networks
- **Privacy-Focused**: Direct device-to-device communication without external servers
- **Demo Mode**: Web-based demonstration with simulated devices and messages

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  offline_sms: ^1.0.0
```

You can install packages from the command line:

```bash
flutter pub add offline_sms
```

## Quick Start

### Basic Usage

```dart
import 'package:offline_sms/offline_sms.dart';

void main() async {
  // Create an OfflineSms instance
  final offlineSms = OfflineSms();
  
  // Initialize the Bluetooth system
  final success = await offlineSms.initialize();
  if (!success) {
    print('Failed to initialize Bluetooth');
    return;
  }
  
  // Listen to connection state changes
  offlineSms.connectionStateStream.listen((state) {
    print('Connection state: ${state.description}');
  });
  
  // Listen to discovered devices
  offlineSms.discoveredDevicesStream.listen((devices) {
    print('Found ${devices.length} devices');
    for (final device in devices) {
      print('- ${device.name} (RSSI: ${device.rssi})');
    }
  });
  
  // Listen to incoming messages
  offlineSms.messagesStream.listen((message) {
    print('Received: ${message.content} from ${message.senderDeviceName}');
  });
  
  // Start scanning for devices
  await offlineSms.startScanning();
  
  // Connect to a device (assuming you have a device from discovery)
  // await offlineSms.connectToDevice(device);
  
  // Send a message
  // await offlineSms.sendMessage('Hello, world!');
}
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:offline_sms/offline_sms.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final OfflineSms _offlineSms = OfflineSms();
  final List<OfflineMessage> _messages = [];
  final List<OfflineDevice> _devices = [];
  OfflineConnectionState _connectionState = OfflineConnectionState.unavailable;
  OfflineDevice? _connectedDevice;

  @override
  void initState() {
    super.initState();
    _initializeOfflineSms();
  }

  Future<void> _initializeOfflineSms() async {
    final success = await _offlineSms.initialize();
    if (success) {
      // Listen to state changes
      _offlineSms.connectionStateStream.listen((state) {
        setState(() => _connectionState = state);
      });
      
      // Listen to discovered devices
      _offlineSms.discoveredDevicesStream.listen((devices) {
        setState(() {
          _devices.clear();
          _devices.addAll(devices);
        });
      });
      
      // Listen to messages
      _offlineSms.messagesStream.listen((message) {
        setState(() => _messages.add(message));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('OfflineSMS - ${_connectionState.description}'),
        actions: [
          IconButton(
            icon: Icon(_offlineSms.isScanning ? Icons.stop : Icons.search),
            onPressed: _offlineSms.isScanning 
                ? _offlineSms.stopScanning 
                : _offlineSms.startScanning,
          ),
        ],
      ),
      body: Column(
        children: [
          // Device list
          if (_devices.isNotEmpty)
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final device = _devices[index];
                  return Card(
                    child: ListTile(
                      title: Text(device.name),
                      subtitle: Text('RSSI: ${device.rssi}'),
                      trailing: ElevatedButton(
                        onPressed: () => _connectToDevice(device),
                        child: Text('Connect'),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Messages
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.content),
                  subtitle: Text(message.senderDeviceName),
                  trailing: Text(message.isFromMe ? 'Sent' : 'Received'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(OfflineDevice device) async {
    final success = await _offlineSms.connectToDevice(device);
    if (success) {
      setState(() => _connectedDevice = device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    }
  }

  @override
  void dispose() {
    _offlineSms.dispose();
    super.dispose();
  }
}
```

## Platform Support

| Platform | Support       | Notes                                         |
| -------- | ------------- | --------------------------------------------- |
| Android  | Full          | Requires location permission for BLE scanning |
| iOS      | Full          | Uses CoreBluetooth framework                  |
| Web      | Demo mode only | BLE not available in web browsers             |
| Desktop  | Limited       | Platform-specific BLE implementation required |

## Configuration

### Android Permissions

The necessary permissions are automatically included in the package. The Android manifest includes:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />
```

### iOS Permissions

The necessary permissions are automatically included in the package. The Info.plist includes:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with nearby devices</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to communicate with nearby devices</string>
```

## API Reference

### OfflineSms Class

The main class for Bluetooth chat functionality.

#### Properties

- `connectionStateStream` - Stream of connection state changes
- `discoveredDevicesStream` - Stream of discovered devices
- `messagesStream` - Stream of incoming and outgoing messages
- `connectionState` - Current connection state
- `connectedDevice` - Currently connected device
- `discoveredDevices` - List of discovered devices
- `isScanning` - Whether currently scanning
- `isAdvertising` - Whether currently advertising

#### Methods

- `initialize()` - Initialize the Bluetooth system
- `startScanning()` - Start scanning for nearby devices
- `stopScanning()` - Stop scanning for devices
- `connectToDevice(OfflineDevice device)` - Connect to a specific device
- `disconnect()` - Disconnect from current device
- `sendMessage(String message)` - Send a message to connected device
- `startAdvertising()` - Start advertising this device
- `stopAdvertising()` - Stop advertising this device
- `dispose()` - Clean up resources

### OfflineMessage Class

Represents a chat message.

#### Properties

- `id` - Unique message identifier
- `content` - Message text content
- `timestamp` - When the message was sent/received
- `isFromMe` - Whether sent by current device
- `senderDeviceId` - ID of the sending device
- `senderDeviceName` - Name of the sending device

### OfflineDevice Class

Represents a discovered Bluetooth device.

#### Properties

- `id` - Unique device identifier
- `name` - Device name
- `rssi` - Signal strength indicator
- `isConnected` - Whether currently connected
- `isConnectable` - Whether device can be connected to
- `discoveredAt` - When device was discovered

### OfflineConnectionState Enum

Represents the current connection state.

#### Values

- `unavailable` - Bluetooth not available
- `idle` - Ready to scan
- `scanning` - Currently scanning
- `connecting` - Attempting to connect
- `connected` - Successfully connected
- `disconnected` - Disconnected from device
- `error` - Error occurred

## Development

### Running the Example

```bash
cd example
flutter run -d chrome  # For web demo
flutter run -d android # For Android device
flutter run -d ios     # For iOS device
```

### Testing

```bash
flutter test                    # Run all tests
flutter test test/offline_sms_test.dart  # Run basic tests
flutter test test/offline_sms_integration_test.dart  # Run integration tests
```

### Code Analysis

```bash
flutter analyze
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Technical Details

### Bluetooth Low Energy (BLE)
- **Range**: 10-30 meters (depending on environment)
- **Speed**: ~1KB/second for message transfer
- **Power**: Low energy consumption, optimized for mobile devices
- **Security**: Built-in AES-128 encryption
- **No Internet Required**: Works completely offline

### Message Format
Messages are serialized as JSON and transmitted via BLE characteristics:
```json
{
  "id": "unique-message-id",
  "content": "Message text",
  "timestamp": "2024-01-01T12:00:00Z",
  "isFromMe": true,
  "senderDeviceId": "device-uuid",
  "senderDeviceName": "Device Name"
}
```

## Support

If you encounter any problems or have suggestions, please file an issue on GitHub. 