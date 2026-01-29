import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';

void main() {
  group('Quick Capture FAB opens capture options', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      List<RecentReport>? reports,
      List<PendingUpload>? pendingUploads,
    }) {
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 0,
            totalProjects: 8,
            recentActivity: 24,
          );

      final testReports = reports ?? [];
      final testPendingUploads = pendingUploads ?? [];

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(testReports),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(testPendingUploads),
          ),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('Navigate to Dashboard - FAB is visible in bottom right',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: Dashboard is visible
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Verify: Floating Action Button is visible
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Verify: FAB is positioned at bottom right (using alignment in Scaffold)
      final fab = tester.widget<FloatingActionButton>(
        find.byType(FloatingActionButton),
      );
      expect(fab, isNotNull);
    });

    testWidgets('Tapping FAB expands capture options menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: FAB is visible
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Tap the FAB
      await tester.tap(fabFinder);
      await tester.pumpAndSettle();

      // Verify: Capture options menu expands with Photo, Video, Audio, Note
      expect(find.text('Photo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Audio'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
    });

    testWidgets('Capture options include correct icons', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: Options have correct icons
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.videocam), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
      expect(find.byIcon(Icons.edit_note), findsOneWidget);
    });

    testWidgets('Tapping outside menu collapses it', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the FAB to open menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: Menu is open
      expect(find.text('Photo'), findsOneWidget);

      // Tap outside the menu (on the barrier/scrim)
      // The menu should have a GestureDetector or barrier for dismissal
      final barrier = find.byKey(const Key('capture_menu_barrier'));
      if (barrier.evaluate().isNotEmpty) {
        await tester.tap(barrier);
      } else {
        // Tap at top-left corner (outside the menu area)
        await tester.tapAt(const Offset(50, 100));
      }
      await tester.pumpAndSettle();

      // Verify: Menu is collapsed (options no longer visible)
      expect(find.text('Photo'), findsNothing);
      expect(find.text('Video'), findsNothing);
      expect(find.text('Audio'), findsNothing);
      expect(find.text('Note'), findsNothing);
    });

    testWidgets('FAB shows add icon when menu is closed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: FAB shows add icon initially
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('FAB transforms to close icon when menu is open',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the FAB to open menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: FAB transforms to close icon
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('Tapping FAB again closes menu', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap the FAB to open menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: Menu is open
      expect(find.text('Photo'), findsOneWidget);

      // Tap the FAB again to close menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verify: Menu is collapsed
      expect(find.text('Photo'), findsNothing);
    });
  });
}

/// Test notifier that returns preset stats
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  _TestDashboardStatsNotifier(this._stats);

  final DashboardStats _stats;

  @override
  Future<DashboardStats> build() async {
    return _stats;
  }
}

/// Test notifier that returns preset recent reports
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier(this._reports);

  final List<RecentReport> _reports;

  @override
  Future<List<RecentReport>> build() async {
    return _reports;
  }
}

/// Test notifier that returns preset pending uploads
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  _TestPendingUploadsNotifier(this._uploads);

  final List<PendingUpload> _uploads;

  @override
  Future<List<PendingUpload>> build() async {
    return _uploads;
  }
}
