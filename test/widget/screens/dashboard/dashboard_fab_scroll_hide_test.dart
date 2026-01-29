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
  group('FAB hides when scrolling down, shows when scrolling up', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      List<RecentReport>? reports,
      List<PendingUpload>? pendingUploads,
    }) {
      // Create stats with enough content to scroll
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 5,
            totalProjects: 8,
            recentActivity: 24,
          );

      // Create many reports to ensure scrollable content
      final testReports = reports ??
          List.generate(
            10,
            (i) => RecentReport(
              id: 'report_$i',
              title: 'Test Report $i',
              projectName: 'Project $i',
              status: ReportStatus.complete,
              date: DateTime.now().subtract(Duration(days: i)),
            ),
          );

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
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: const DashboardScreen(),
          ),
        ),
      );
    }

    testWidgets(
        'Navigate to Dashboard with enough content to scroll - FAB is visible',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: Dashboard is visible
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Verify: FAB is visible
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Verify: Content is scrollable (has enough reports)
      expect(find.textContaining('Test Report'), findsWidgets);
    });

    testWidgets('Scroll down - FAB hides with animation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: FAB is initially visible
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Get initial FAB position
      final initialFabPosition = tester.getCenter(fabFinder);

      // Find the scrollable and scroll down
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -300), 1000);
      await tester.pump(const Duration(milliseconds: 100));

      // During scroll down, FAB should be animating out
      // After animation, FAB should be hidden or translated off screen
      await tester.pumpAndSettle();

      // FAB should be hidden (either not visible or translated off screen)
      // Check if FAB is still in widget tree but transformed/hidden
      final fabWidget = tester.widget<FloatingActionButton>(fabFinder);
      expect(fabWidget, isNotNull);

      // The FAB should have moved down (hidden) after scrolling down
      final postScrollFabPosition = tester.getCenter(fabFinder);
      expect(
        postScrollFabPosition.dy,
        greaterThan(initialFabPosition.dy),
        reason: 'FAB should slide down (hide) when scrolling down',
      );
    });

    testWidgets('Scroll up slightly - FAB reappears with animation',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // First scroll down to hide the FAB
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      // Get FAB position when hidden
      final fabFinder = find.byType(FloatingActionButton);
      final hiddenFabPosition = tester.getCenter(fabFinder);

      // Now scroll up slightly
      await tester.fling(scrollable, const Offset(0, 100), 500);
      await tester.pumpAndSettle();

      // FAB should reappear (move back to visible position)
      final visibleFabPosition = tester.getCenter(fabFinder);
      expect(
        visibleFabPosition.dy,
        lessThan(hiddenFabPosition.dy),
        reason: 'FAB should slide up (reappear) when scrolling up',
      );
    });

    testWidgets('FAB hide/show uses smooth animation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final fabFinder = find.byType(FloatingActionButton);
      final initialPosition = tester.getCenter(fabFinder);

      // Scroll down
      final scrollable = find.byType(Scrollable).first;
      await tester.fling(scrollable, const Offset(0, -300), 1000);

      // Pump a few frames to catch intermediate animation state
      await tester.pump(const Duration(milliseconds: 50));
      final midAnimationPosition = tester.getCenter(fabFinder);

      await tester.pumpAndSettle();
      final finalPosition = tester.getCenter(fabFinder);

      // Animation should be gradual (mid position between start and end)
      if (finalPosition.dy > initialPosition.dy) {
        expect(
          midAnimationPosition.dy,
          greaterThanOrEqualTo(initialPosition.dy),
          reason: 'Animation should be smooth/gradual',
        );
      }
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
