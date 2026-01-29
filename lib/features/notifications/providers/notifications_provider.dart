import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/app_notification.dart';

part 'notifications_provider.g.dart';

/// Provider for managing app notifications.
@riverpod
class NotificationsNotifier extends _$NotificationsNotifier {
  @override
  Future<List<AppNotification>> build() async {
    // TODO: Fetch notifications from API/local storage
    return [];
  }

  /// Refreshes the notifications list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // TODO: Fetch from API
      return [];
    });
  }

  /// Marks a notification as read.
  Future<void> markAsRead(String notificationId) async {
    final currentNotifications = state.valueOrNull ?? [];
    final updatedNotifications = currentNotifications.map((n) {
      if (n.id == notificationId) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();

    state = AsyncData(updatedNotifications);
    // TODO: Persist to API
  }

  /// Marks all notifications as read.
  Future<void> markAllAsRead() async {
    final currentNotifications = state.valueOrNull ?? [];
    final updatedNotifications = currentNotifications.map((n) {
      return n.copyWith(isRead: true);
    }).toList();

    state = AsyncData(updatedNotifications);
    // TODO: Persist to API
  }
}

/// Provider for the count of unread notifications.
@riverpod
int unreadNotificationCount(Ref ref) {
  final notificationsAsync = ref.watch(notificationsNotifierProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
}
