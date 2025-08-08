import 'package:uuid/uuid.dart';

class OfflineMessage {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isFromMe;
  final String senderDeviceId;
  final String senderDeviceName;

  OfflineMessage({
    String? id,
    required this.content,
    DateTime? timestamp,
    required this.isFromMe,
    required this.senderDeviceId,
    required this.senderDeviceName,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  factory OfflineMessage.fromJson(Map<String, dynamic> json) {
    return OfflineMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isFromMe: json['isFromMe'] as bool,
      senderDeviceId: json['senderDeviceId'] as String,
      senderDeviceName: json['senderDeviceName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isFromMe': isFromMe,
      'senderDeviceId': senderDeviceId,
      'senderDeviceName': senderDeviceName,
    };
  }

  OfflineMessage copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isFromMe,
    String? senderDeviceId,
    String? senderDeviceName,
  }) {
    return OfflineMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isFromMe: isFromMe ?? this.isFromMe,
      senderDeviceId: senderDeviceId ?? this.senderDeviceId,
      senderDeviceName: senderDeviceName ?? this.senderDeviceName,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'OfflineMessage(id: $id, content: $content, isFromMe: $isFromMe, sender: $senderDeviceName)';
  }
}
