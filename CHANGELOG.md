# Changelog

## [1.0.1] - 2025-08-08

### Changed
- Updated `permission_handler` to ^12.0.1
- Updated `flutter_lints` to ^6.0.0 and fixed lint warnings in example and package
- Added extended debug logging across BLE lifecycle in `lib/src/offline_sms.dart`
- Seeded initial stream emissions in `OfflineSms` constructor
- Cleaned up `.gitignore` and ignored local `deploy_pages.sh`
- Example app marked as non-publishable and minor UI/lint fixes

### CI/Docs
- Added GitHub Pages deploy for web demo via `deploy_pages.sh`
- Ensured `flutter analyze` passes with no issues

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