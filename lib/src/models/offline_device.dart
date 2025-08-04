import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class OfflineDevice {
  final String id;
  final String name;
  final int rssi;
  final bool isConnected;
  final bool isConnectable;
  final DateTime discoveredAt;
  final BluetoothDevice? bluetoothDevice;

  const OfflineDevice({
    required this.id,
    required this.name,
    required this.rssi,
    this.isConnected = false,
    this.isConnectable = true,
    required this.discoveredAt,
    this.bluetoothDevice,
  });

  factory OfflineDevice.fromBluetoothDevice(
    BluetoothDevice device,
    int rssi,
  ) {
    return OfflineDevice(
      id: device.remoteId.toString(),
      name: device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown Device',
      rssi: rssi,
      discoveredAt: DateTime.now(),
      bluetoothDevice: device,
    );
  }

  OfflineDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    bool? isConnected,
    bool? isConnectable,
    DateTime? discoveredAt,
    BluetoothDevice? bluetoothDevice,
  }) {
    return OfflineDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      isConnected: isConnected ?? this.isConnected,
      isConnectable: isConnectable ?? this.isConnectable,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      bluetoothDevice: bluetoothDevice ?? this.bluetoothDevice,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineDevice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OfflineDevice(id: $id, name: $name, rssi: $rssi, isConnected: $isConnected)';
  }
}
