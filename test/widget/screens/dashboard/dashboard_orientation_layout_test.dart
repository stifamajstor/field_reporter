import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/providers/sync_status_provider.dart';
import 'package:field_reporter/features/sync/domain/sync_status.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';

/// Tests for: Dashboard layout adapts to screen orientation
///
/// Acceptance Criteria:
/// - Navigate to Dashboard in portrait mode
/// - Verify single-column layout for stats
/// - Rotate device to landscape
/// - Verify layout adapts to multi-column
/// - Verify all content remains accessible
/// - Rotate back to portrait
/// - Verify layout returns to original
void main() {
  group('Dashboard orientation layout', () {
    Widget buildTestWidget({
      required Size screenSize,
    }) {
      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _TestSyncStatusNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(),
          ),
        ],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: const DashboardScreen(),
          ),
        ),
      );
    }

    testWidgets('displays 2-column layout in portrait mode', (tester) async {
      // Portrait: 375 x 812 (iPhone X dimensions)
      const portraitSize = Size(375, 812);
      tester.view.physicalSize = portraitSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(screenSize: portraitSize));
      await tester.pumpAndSettle();

      // Find the stats grid
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      // In portrait (narrow width < 500), we expect 2 columns
      final GridView grid = tester.widget(gridFinder);
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      expect(delegate.crossAxisCount, equals(2));

      // Verify all 4 stat cards are visible
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('Pending Uploads'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('displays multi-column layout in landscape mode',
        (tester) async {
      // Landscape: 812 x 375 (iPhone X rotated)
      const landscapeSize = Size(812, 375);
      tester.view.physicalSize = landscapeSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(screenSize: landscapeSize));
      await tester.pumpAndSettle();

      // Find the stats grid
      final gridFinder = find.byType(GridView);
      expect(gridFinder, findsOneWidget);

      final GridView grid = tester.widget(gridFinder);
      final SliverGridDelegateWithFixedCrossAxisCount delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

      // In landscape (wider screen >= 700), we expect 4 columns
      expect(delegate.crossAxisCount, greaterThanOrEqualTo(4));

      // Verify all 4 stat cards remain accessible
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('Pending Uploads'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('all content remains accessible after rotation',
        (tester) async {
      // Start in portrait
      const portraitSize = Size(375, 812);
      tester.view.physicalSize = portraitSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(screenSize: portraitSize));
      await tester.pumpAndSettle();

      // Verify content in portrait
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('Recent Reports'), findsOneWidget);

      // "Rotate" to landscape
      const landscapeSize = Size(812, 375);
      tester.view.physicalSize = landscapeSize;
      await tester.pumpWidget(buildTestWidget(screenSize: landscapeSize));
      await tester.pumpAndSettle();

      // Verify all content is still accessible in landscape
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('Pending Uploads'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('Recent Reports'), findsOneWidget);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('layout returns to original when rotating back to portrait',
        (tester) async {
      // Start in portrait
      const portraitSize = Size(375, 812);
      tester.view.physicalSize = portraitSize;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(buildTestWidget(screenSize: portraitSize));
      await tester.pumpAndSettle();

      // Get initial grid column count
      final initialGrid = tester.widget<GridView>(find.byType(GridView));
      final initialDelegate =
          initialGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      final initialColumnCount = initialDelegate.crossAxisCount;

      // "Rotate" to landscape
      const landscapeSize = Size(812, 375);
      tester.view.physicalSize = landscapeSize;
      await tester.pumpWidget(buildTestWidget(screenSize: landscapeSize));
      await tester.pumpAndSettle();

      // Verify landscape has more columns
      final landscapeGrid = tester.widget<GridView>(find.byType(GridView));
      final landscapeDelegate = landscapeGrid.gridDelegate
          as SliverGridDelegateWithFixedCrossAxisCount;
      expect(landscapeDelegate.crossAxisCount, greaterThan(initialColumnCount));

      // "Rotate" back to portrait
      tester.view.physicalSize = portraitSize;
      await tester.pumpWidget(buildTestWidget(screenSize: portraitSize));
      await tester.pumpAndSettle();

      // Verify layout returns to original column count
      final finalGrid = tester.widget<GridView>(find.byType(GridView));
      final finalDelegate =
          finalGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(finalDelegate.crossAxisCount, equals(initialColumnCount));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('responsive breakpoints work correctly', (tester) async {
      // Test various widths to verify responsive breakpoints

      // Very narrow (small phone portrait) - should be 2 columns
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      await tester
          .pumpWidget(buildTestWidget(screenSize: const Size(320, 568)));
      await tester.pumpAndSettle();

      var grid = tester.widget<GridView>(find.byType(GridView));
      var delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(2));

      // Medium width (tablet portrait) - should be 3 columns
      tester.view.physicalSize = const Size(600, 800);
      await tester
          .pumpWidget(buildTestWidget(screenSize: const Size(600, 800)));
      await tester.pumpAndSettle();

      grid = tester.widget<GridView>(find.byType(GridView));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));

      // Wide (tablet landscape) - should be 4 columns
      tester.view.physicalSize = const Size(1024, 768);
      await tester
          .pumpWidget(buildTestWidget(screenSize: const Size(1024, 768)));
      await tester.pumpAndSettle();

      grid = tester.widget<GridView>(find.byType(GridView));
      delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(4));

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });
  });
}

/// Test notifier that returns preset dashboard stats.
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  @override
  Future<DashboardStats> build() async {
    return const DashboardStats(
      reportsThisWeek: 5,
      pendingUploads: 2,
      totalProjects: 10,
      recentActivity: 8,
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

/// Test notifier that returns preset sync status.
class _TestSyncStatusNotifier extends SyncStatusNotifier {
  @override
  SyncStatus build() {
    return const SyncStatus.synced();
  }
}

/// Test notifier that returns preset pending uploads.
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    return [];
  }
}
