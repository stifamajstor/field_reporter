import 'package:field_reporter/core/theme/app_colors.dart';
import 'package:field_reporter/core/theme/app_theme.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/notifications/domain/app_notification.dart';
import 'package:field_reporter/features/notifications/providers/notifications_provider.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/sync/domain/sync_status.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/sync/providers/sync_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Notifications Badge', () {
    Widget buildTestWidget({
      List<AppNotification> notifications = const [],
      int unreadCount = 0,
      Map<String, WidgetBuilder>? routes,
    }) {
      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _TestSyncStatusNotifier(),
          ),
          notificationsNotifierProvider.overrideWith(
            () => _TestNotificationsNotifier(notifications),
          ),
          unreadNotificationCountProvider.overrideWith(
            (ref) => unreadCount,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const DashboardScreen(),
          routes: routes ??
              {
                '/sync': (context) => const Scaffold(
                      body: Center(child: Text('Sync Status Screen')),
                    ),
                '/notifications': (context) => const Scaffold(
                      body: Center(child: Text('Notifications Screen')),
                    ),
              },
        ),
      );
    }

    testWidgets('displays notification bell icon in header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify notification bell icon exists in the app bar
      expect(find.byKey(const Key('notification_bell_icon')), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('shows badge with unread count when notifications pending',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unreadCount: 5,
        notifications: [
          AppNotification(
            id: '1',
            title: 'Test Notification',
            body: 'Test body',
            createdAt: DateTime.now(),
            isRead: false,
            type: NotificationType.general,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify badge is displayed with count
      final badge = find.byKey(const Key('notification_badge'));
      expect(badge, findsOneWidget);

      // Verify count shows "5"
      expect(
        find.descendant(of: badge, matching: find.text('5')),
        findsOneWidget,
      );
    });

    testWidgets('badge not shown when no unread notifications', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unreadCount: 0,
        notifications: [],
      ));
      await tester.pumpAndSettle();

      // Verify bell icon exists but no badge
      expect(find.byKey(const Key('notification_bell_icon')), findsOneWidget);
      expect(find.byKey(const Key('notification_badge')), findsNothing);
    });

    testWidgets('tapping notification icon navigates to notifications list',
        (tester) async {
      bool navigatedToNotifications = false;

      await tester.pumpWidget(buildTestWidget(
        routes: {
          '/sync': (context) => const Scaffold(body: Text('Sync')),
          '/notifications': (context) {
            navigatedToNotifications = true;
            return const Scaffold(body: Text('Notifications Screen'));
          },
        },
      ));
      await tester.pumpAndSettle();

      // Tap the notification bell icon
      await tester.tap(find.byKey(const Key('notification_bell_icon')));
      await tester.pumpAndSettle();

      // Verify navigation to notifications screen
      expect(navigatedToNotifications, isTrue);
    });

    testWidgets('badge shows 9+ when count exceeds 9', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unreadCount: 15,
      ));
      await tester.pumpAndSettle();

      // Verify badge shows "9+"
      final badge = find.byKey(const Key('notification_badge'));
      expect(badge, findsOneWidget);
      expect(
        find.descendant(of: badge, matching: find.text('9+')),
        findsOneWidget,
      );
    });

    testWidgets('badge has correct styling', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unreadCount: 3,
      ));
      await tester.pumpAndSettle();

      // Verify badge container exists and has rose/red color
      final badge = find.byKey(const Key('notification_badge'));
      expect(badge, findsOneWidget);

      // Find the container with the badge key directly
      final container = tester.widget<Container>(badge);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(AppColors.rose500));
    });

    testWidgets('notification icon has tooltip for accessibility',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        unreadCount: 2,
      ));
      await tester.pumpAndSettle();

      // Verify the icon button has a tooltip
      final tooltip = find.byTooltip('Notifications: 2 unread');
      expect(tooltip, findsOneWidget);
    });
  });
}

/// Test notifier that returns preset dashboard stats.
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  @override
  Future<DashboardStats> build() async {
    return const DashboardStats(
      reportsThisWeek: 12,
      pendingUploads: 3,
      totalProjects: 8,
      recentActivity: 24,
    );
  }
}

/// Test notifier that returns preset recent reports.
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  @override
  Future<List<RecentReport>> build() async {
    return [];
  }
}

/// Test notifier that returns preset pending uploads.
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    return [];
  }
}

/// Test notifier that returns preset sync status.
class _TestSyncStatusNotifier extends SyncStatusNotifier {
  @override
  SyncStatus build() {
    return const SyncStatus.synced();
  }
}

/// Test notifier that returns preset notifications.
class _TestNotificationsNotifier extends NotificationsNotifier {
  _TestNotificationsNotifier(this._notifications);
  final List<AppNotification> _notifications;

  @override
  Future<List<AppNotification>> build() async {
    return _notifications;
  }
}
