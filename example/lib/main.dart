import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:offline_sms/offline_sms.dart';

void main() {
  runApp(const OfflineSmsApp());
}

class OfflineSmsApp extends StatelessWidget {
  const OfflineSmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline SMS Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final OfflineSms _offlineSms = OfflineSms();
  final List<OfflineMessage> _messages = [];
  final List<OfflineDevice> _devices = [];
  final TextEditingController _messageController = TextEditingController();
  OfflineConnectionState _connectionState = OfflineConnectionState.unavailable;
  OfflineDevice? _connectedDevice;
  final bool _isDemoMode = kIsWeb;
  String _selectedSenderDevice = 'MacBook Pro (Demo)';

  @override
  void initState() {
    super.initState();
    if (_isDemoMode) {
      _initializeDemoMode();
    } else {
      _initializeOfflineSms();
    }
  }

  void _initializeDemoMode() {
    // Demo data for web platform
    setState(() {
      _connectionState = OfflineConnectionState.idle;
      _devices.addAll([
        OfflineDevice(
          id: 'demo-device-1',
          name: 'iPhone 15 Pro',
          rssi: -45,
          discoveredAt: DateTime.now(),
        ),
        OfflineDevice(
          id: 'demo-device-2',
          name: 'Samsung Galaxy S24',
          rssi: -52,
          discoveredAt: DateTime.now(),
        ),
        OfflineDevice(
          id: 'demo-device-3',
          name: 'Google Pixel 8',
          rssi: -58,
          discoveredAt: DateTime.now(),
        ),
      ]);
    });
  }

  // String get _currentDeviceName {
  //   if (_isDemoMode) {
  //     return 'MacBook Pro (Demo)';
  //   }
  //   // For real devices, you would get the actual device name
  //   if (defaultTargetPlatform == TargetPlatform.android) {
  //     return 'Android Device';
  //   } else if (defaultTargetPlatform == TargetPlatform.iOS) {
  //     return 'iPhone Device';
  //   }
  //   return 'This Device';
  // }

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
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize Bluetooth')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Offline SMS - ${_connectionState.description}'),
        backgroundColor: _getConnectionStateColor(),
        actions: [
          if (!_isDemoMode)
            IconButton(
              icon: Icon(_offlineSms.isScanning ? Icons.stop : Icons.search),
              onPressed: _offlineSms.isScanning
                  ? _offlineSms.stopScanning
                  : _offlineSms.startScanning,
            ),
          if (_isDemoMode)
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => _showDemoInfo(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            child: Row(
              children: [
                Icon(_getConnectionStateIcon()),
                const SizedBox(width: 8),
                Text(_connectionState.description),
                const Spacer(),
                if (_connectedDevice != null)
                  Text('Connected to: ${_connectedDevice!.name}'),
                if (_isDemoMode)
                  const Text(' (Demo Mode)',
                      style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          ),

          // Device list
          if (_devices.isNotEmpty)
            Container(
              height: 160,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        const Text(
                          'Discovered Devices',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Text('(${_devices.length})',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Container(
                            width: 220,
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.phone_android,
                                        size: 20, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        device.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Signal: ${device.rssi} dBm',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      minimumSize: const Size(0, 32),
                                    ),
                                    child: const Text('Connect',
                                        style: TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.message, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Connect to a device to start messaging',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (_isDemoMode) ...[
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addDemoMessages,
                            child: const Text('Add Demo Messages'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageTile(message);
                    },
                  ),
          ),

          // Message input
          if (_connectedDevice != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (_isDemoMode)
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Text('Send as: ',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: _selectedSenderDevice,
                            items: [
                              'MacBook Pro (Demo)',
                              'iPhone 15 Pro',
                              'Samsung Galaxy S24',
                              'Google Pixel 8',
                            ].map((String device) {
                              return DropdownMenuItem<String>(
                                value: device,
                                child: Text(device,
                                    style: const TextStyle(fontSize: 12)),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedSenderDevice = newValue;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _sendMessage,
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(OfflineMessage message) {
    final isFromMe = message.isFromMe;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFromMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isFromMe ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isFromMe ? Icons.phone_android : Icons.phone_iphone,
                      size: 12,
                      color: isFromMe ? Colors.white70 : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      message.senderDeviceName,
                      style: TextStyle(
                        fontSize: 10,
                        color: isFromMe ? Colors.white70 : Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(message.timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isFromMe ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getConnectionStateColor() {
    switch (_connectionState) {
      case OfflineConnectionState.connected:
        return Colors.green;
      case OfflineConnectionState.scanning:
        return Colors.orange;
      case OfflineConnectionState.connecting:
        return Colors.yellow;
      case OfflineConnectionState.error:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getConnectionStateIcon() {
    switch (_connectionState) {
      case OfflineConnectionState.connected:
        return Icons.bluetooth_connected;
      case OfflineConnectionState.scanning:
        return Icons.bluetooth_searching;
      case OfflineConnectionState.connecting:
        return Icons.bluetooth;
      case OfflineConnectionState.error:
        return Icons.error;
      default:
        return Icons.bluetooth_disabled;
    }
  }

  Future<void> _connectToDevice(OfflineDevice device) async {
    if (_isDemoMode) {
      setState(() => _connectedDevice = device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name} (Demo Mode)')),
      );
      return;
    }

    final success = await _offlineSms.connectToDevice(device);
    if (!mounted) return;

    if (success) {
      setState(() => _connectedDevice = device);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected to ${device.name}')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to connect to ${device.name}')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_isDemoMode) {
      final demoMessage = OfflineMessage(
        content: message,
        isFromMe: true,
        senderDeviceId: 'demo-device',
        senderDeviceName: _selectedSenderDevice,
      );
      setState(() => _messages.add(demoMessage));
      _messageController.clear();
      return;
    }

    final success = await _offlineSms.sendMessage(message);
    if (!mounted) return;

    if (success) {
      _messageController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  void _addDemoMessages() {
    setState(() {
      _messages.addAll([
        OfflineMessage(
          content: 'Hello! This is a demo message.',
          isFromMe: false,
          senderDeviceId: 'demo-device-1',
          senderDeviceName: 'iPhone 15 Pro',
        ),
        OfflineMessage(
          content: 'Hi! How are you?',
          isFromMe: true,
          senderDeviceId: 'demo-device',
          senderDeviceName: 'MacBook Pro (Demo)',
        ),
      ]);
    });
  }

  void _showDemoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Mode'),
        content: const Text(
          'This is a demo version running in the browser. '
          'Bluetooth functionality is not available in web browsers. '
          'To test the full functionality, run this app on a physical Android or iOS device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (!_isDemoMode) {
      _offlineSms.dispose();
    }
    _messageController.dispose();
    super.dispose();
  }
}
