enum OfflineConnectionState {
  unavailable,
  idle,
  scanning,
  connecting,
  connected,
  disconnected,
  error;

  String get description {
    switch (this) {
      case OfflineConnectionState.unavailable:
        return 'Bluetooth Unavailable';
      case OfflineConnectionState.idle:
        return 'Idle';
      case OfflineConnectionState.scanning:
        return 'Scanning for devices';
      case OfflineConnectionState.connecting:
        return 'Connecting...';
      case OfflineConnectionState.connected:
        return 'Connected';
      case OfflineConnectionState.disconnected:
        return 'Disconnected';
      case OfflineConnectionState.error:
        return 'Error';
    }
  }
}
