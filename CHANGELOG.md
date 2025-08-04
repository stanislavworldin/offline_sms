# Changelog

## [1.0.0] - 2024-01-01

### Added
- Initial release of Offline SMS package
- Bluetooth Low Energy (BLE) device discovery
- Peer-to-peer messaging functionality
- Cross-platform support for Android and iOS
- Automatic permission handling
- Real-time connection state monitoring
- Stream-based architecture for UI integration
- Comprehensive error handling and recovery
- Debug logging for development and troubleshooting

### Features
- Device discovery and scanning
- Secure BLE connections
- Real-time message sending and receiving
- Connection state tracking
- Message history with timestamps
- Device information display (name, RSSI, connection status)
- Automatic permission requests for Bluetooth and location

### Technical Details
- Uses flutter_blue_plus for BLE functionality
- Implements custom service and characteristic UUIDs
- JSON-based message serialization
- UUID-based device and message identification
- Stream-based event handling
- Comprehensive error management

### Platform Support
- Android: Full support with location permissions
- iOS: Full support using CoreBluetooth framework
- Web: Not supported (BLE not available in browsers)
- Desktop: Limited (requires platform-specific implementation) 