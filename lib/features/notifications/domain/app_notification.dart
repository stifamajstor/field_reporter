import 'package:flutter/foundation.dart';

/// Types of notifications in the app.
enum NotificationType {
  /// General notification.
  general,

  /// Sync completed notification.
  syncComplete,

  /// PDF ready notification.
  pdfReady,

  /// AI processing complete notification.
  aiProcessingComplete,

  /// Team member mention notification.
  mention,

  /// Project assignment notification.
  projectAssignment,

  /// Report shared notification.
  reportShared,

  /// Upload failed notification.
  uploadFailed,
}

/// Represents an in-app notification.
@immutable
class AppNotification {
  /// Creates an [AppNotification].
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.data,
  });

  /// Unique identifier for the notification.
  final String id;

  /// Title of the notification.
  final String title;

  /// Body text of the notification.
  final String body;

  /// When the notification was created.
  final DateTime createdAt;

  /// Whether the notification has been read.
  final bool isRead;

  /// Type of notification.
  final NotificationType type;

  /// Optional additional data associated with the notification.
  final Map<String, dynamic>? data;

  /// Creates a copy with modified fields.
  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    bool? isRead,
    NotificationType? type,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification &&
        other.id == id &&
        other.title == title &&
        other.body == body &&
        other.createdAt == createdAt &&
        other.isRead == isRead &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, body, createdAt, isRead, type);
  }
}
