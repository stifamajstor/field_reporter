import 'package:field_reporter/core/theme/app_colors.dart';
import 'package:field_reporter/core/theme/app_theme.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/sync/domain/sync_status.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/sync/providers/sync_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Dashboard Sync Status Indicator', () {
    Widget buildTestWidget({
      SyncStatus syncStatus = const SyncStatus.synced(),
      List<PendingUpload> pendingUploads = const [],
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
            () => _TestPendingUploadsNotifier(pendingUploads),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _TestSyncStatusNotifier(syncStatus),
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
              },
        ),
      );
    }

    testWidgets('displays sync status indicator in header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify sync status indicator exists in the app bar area
      expect(find.byKey(const Key('sync_status_indicator')), findsOneWidget);
    });

    testWidgets('shows green checkmark when fully synced', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        syncStatus: const SyncStatus.synced(),
      ));
      await tester.pumpAndSettle();

      // Verify green checkmark icon is displayed
      final indicator = find.byKey(const Key('sync_status_indicator'));
      expect(indicator, findsOneWidget);

      // Find the check icon within the indicator
      final checkIcon = find.descendant(
        of: indicator,
        matching: find.byIcon(Icons.check_circle),
      );
      expect(checkIcon, findsOneWidget);

      // Verify the icon color is emerald (green)
      final iconWidget = tester.widget<Icon>(checkIcon);
      expect(iconWidget.color, equals(AppColors.emerald500));
    });

    testWidgets('shows "Synced" text when fully synced', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        syncStatus: const SyncStatus.synced(),
      ));
      await tester.pumpAndSettle();

      // Verify "Synced" text is present
      expect(find.text('Synced'), findsOneWidget);
    });

    testWidgets('shows pending count badge when items pending', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        syncStatus: const SyncStatus.pending(pendingCount: 5),
        pendingUploads: [
          PendingUpload(
            id: '1',
            entryId: 'e1',
            fileName: 'photo1.jpg',
            fileSize: 1024,
            createdAt: DateTime.now(),
            status: UploadStatus.pending,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      // Verify pending count badge shows "5"
      final indicator = find.byKey(const Key('sync_status_indicator'));
      expect(indicator, findsOneWidget);

      // Find the badge with pending count
      final badge = find.descendant(
        of: indicator,
        matching: find.byKey(const Key('sync_pending_badge')),
      );
      expect(badge, findsOneWidget);

      // Verify count text
      expect(
        find.descendant(of: badge, matching: find.text('5')),
        findsOneWidget,
      );
    });

    testWidgets('shows sync animation when syncing', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        syncStatus: const SyncStatus.syncing(progress: 0.5),
        pendingUploads: [
          PendingUpload(
            id: '1',
            entryId: 'e1',
            fileName: 'photo1.jpg',
            fileSize: 1024,
            createdAt: DateTime.now(),
            status: UploadStatus.uploading,
            progress: 0.5,
          ),
        ],
      ));
      await tester.pump();

      // Verify sync icon with animation
      final indicator = find.byKey(const Key('sync_status_indicator'));
      expect(indicator, findsOneWidget);

      // Find the animated sync icon
      final syncIcon = find.descendant(
        of: indicator,
        matching: find.byKey(const Key('sync_animating_icon')),
      );
      expect(syncIcon, findsOneWidget);
    });

    testWidgets('tapping sync indicator navigates to Sync Status screen',
        (tester) async {
      bool navigatedToSync = false;

      await tester.pumpWidget(buildTestWidget(
        routes: {
          '/sync': (context) {
            navigatedToSync = true;
            return const Scaffold(body: Text('Sync Status Screen'));
          },
        },
      ));
      await tester.pumpAndSettle();

      // Tap the sync status indicator
      await tester.tap(find.byKey(const Key('sync_status_indicator')));
      await tester.pumpAndSettle();

      // Verify navigation to Sync Status screen
      expect(navigatedToSync, isTrue);
    });

    testWidgets('sync indicator has correct tooltip for accessibility',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        syncStatus: const SyncStatus.pending(pendingCount: 3),
      ));
      await tester.pumpAndSettle();

      // Verify the indicator has a tooltip for accessibility
      final tooltip = find.byTooltip('Sync status: 3 items pending');
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
  _TestPendingUploadsNotifier(this._uploads);
  final List<PendingUpload> _uploads;

  @override
  Future<List<PendingUpload>> build() async {
    return _uploads;
  }
}

/// Test notifier that returns preset sync status.
class _TestSyncStatusNotifier extends SyncStatusNotifier {
  _TestSyncStatusNotifier(this._status);
  final SyncStatus _status;

  @override
  SyncStatus build() {
    return _status;
  }
}
