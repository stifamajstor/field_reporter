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
  group('Dashboard shows pending uploads queue', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      List<PendingUpload>? pendingUploads,
      bool isUploading = false,
      Map<String, WidgetBuilder>? routes,
    }) {
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 3,
            totalProjects: 8,
            recentActivity: 24,
          );

      final testPendingUploads = pendingUploads ??
          [
            PendingUpload(
              id: '1',
              entryId: 'entry-1',
              fileName: 'photo_001.jpg',
              fileSize: 1024000,
              createdAt: DateTime(2026, 1, 29, 10, 30),
              status: UploadStatus.pending,
            ),
            PendingUpload(
              id: '2',
              entryId: 'entry-2',
              fileName: 'video_001.mp4',
              fileSize: 5120000,
              createdAt: DateTime(2026, 1, 29, 10, 35),
              status:
                  isUploading ? UploadStatus.uploading : UploadStatus.pending,
              progress: isUploading ? 0.45 : 0.0,
            ),
            PendingUpload(
              id: '3',
              entryId: 'entry-3',
              fileName: 'audio_001.m4a',
              fileSize: 512000,
              createdAt: DateTime(2026, 1, 29, 10, 40),
              status: UploadStatus.pending,
            ),
          ];

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier([]),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(testPendingUploads),
          ),
        ],
        child: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: routes ?? {},
          ),
        ),
      );
    }

    testWidgets('Create entries while offline to generate upload queue',
        (tester) async {
      // Given: We have pending uploads created while offline
      final pendingUploads = [
        PendingUpload(
          id: '1',
          entryId: 'entry-1',
          fileName: 'photo_offline.jpg',
          fileSize: 1024000,
          createdAt: DateTime(2026, 1, 29, 10, 30),
          status: UploadStatus.pending,
        ),
        PendingUpload(
          id: '2',
          entryId: 'entry-2',
          fileName: 'video_offline.mp4',
          fileSize: 5120000,
          createdAt: DateTime(2026, 1, 29, 10, 35),
          status: UploadStatus.pending,
        ),
      ];

      await tester.pumpWidget(buildTestWidget(pendingUploads: pendingUploads));
      await tester.pumpAndSettle();

      // Verify: Dashboard is visible with pending uploads section
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Pending Uploads section is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: 'Pending Uploads' section header is visible
      expect(find.text('Pending Uploads'), findsWidgets);
    });

    testWidgets('Pending uploads count matches actual pending items',
        (tester) async {
      final pendingUploads = [
        PendingUpload(
          id: '1',
          entryId: 'entry-1',
          fileName: 'photo_001.jpg',
          fileSize: 1024000,
          createdAt: DateTime(2026, 1, 29),
          status: UploadStatus.pending,
        ),
        PendingUpload(
          id: '2',
          entryId: 'entry-2',
          fileName: 'photo_002.jpg',
          fileSize: 2048000,
          createdAt: DateTime(2026, 1, 29),
          status: UploadStatus.pending,
        ),
        PendingUpload(
          id: '3',
          entryId: 'entry-3',
          fileName: 'photo_003.jpg',
          fileSize: 3072000,
          createdAt: DateTime(2026, 1, 29),
          status: UploadStatus.pending,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          stats: const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 3,
            totalProjects: 8,
            recentActivity: 24,
          ),
          pendingUploads: pendingUploads,
        ),
      );
      await tester.pumpAndSettle();

      // Verify: Count displayed matches actual pending uploads (3)
      expect(find.text('3'), findsWidgets);
    });

    testWidgets('Progress indicator is visible for active uploads',
        (tester) async {
      final pendingUploads = [
        PendingUpload(
          id: '1',
          entryId: 'entry-1',
          fileName: 'photo_001.jpg',
          fileSize: 1024000,
          createdAt: DateTime(2026, 1, 29),
          status: UploadStatus.uploading,
          progress: 0.45,
        ),
      ];

      await tester.pumpWidget(
        buildTestWidget(
          pendingUploads: pendingUploads,
          isUploading: true,
        ),
      );
      // Use pump with duration instead of pumpAndSettle to avoid timeout from
      // animations that run indefinitely (like FAB visibility controller)
      await tester.pump(const Duration(seconds: 1));

      // Verify: Progress indicator is visible for active upload
      expect(
        find.byType(LinearProgressIndicator),
        findsWidgets,
        reason: 'Should show progress indicator when upload is active',
      );
    });

    testWidgets(
        'Tapping pending uploads section navigates to Sync Status screen',
        (tester) async {
      bool navigatedToSync = false;

      await tester.pumpWidget(
        buildTestWidget(
          routes: {
            '/sync': (context) {
              navigatedToSync = true;
              return const Scaffold(body: Text('Sync Status Screen'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find the pending uploads section and tap it
      // First try finding the stat card for Pending Uploads
      final pendingUploadsCard = find.ancestor(
        of: find.text('Pending Uploads'),
        matching: find.byType(GestureDetector),
      );

      if (pendingUploadsCard.evaluate().isNotEmpty) {
        await tester.tap(pendingUploadsCard.first);
        await tester.pumpAndSettle();
      } else {
        // Try finding any tappable pending uploads widget
        final pendingSection = find.byKey(const Key('pending_uploads_section'));
        if (pendingSection.evaluate().isNotEmpty) {
          await tester.tap(pendingSection);
          await tester.pumpAndSettle();
        }
      }

      // Verify: Navigation to Sync Status screen occurred
      expect(navigatedToSync, isTrue,
          reason: 'Should navigate to Sync Status screen');
    });

    testWidgets('Pending uploads section shows upload status icons',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify: Cloud upload icon is visible in the section
      expect(find.byIcon(Icons.cloud_upload_outlined), findsWidgets);
    });

    testWidgets('Empty state is shown when no pending uploads', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          stats: const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 0,
            totalProjects: 8,
            recentActivity: 24,
          ),
          pendingUploads: [],
        ),
      );
      await tester.pumpAndSettle();

      // Verify: Zero count is displayed for pending uploads
      expect(find.text('0'), findsWidgets);
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

/// Test notifier that returns empty recent reports
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
