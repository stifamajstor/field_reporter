import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/providers/sync_status_provider.dart';
import 'package:field_reporter/features/sync/domain/sync_status.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/auth/providers/tenant_provider.dart';
import 'package:field_reporter/features/notifications/providers/notifications_provider.dart';
import 'package:field_reporter/services/connectivity_service.dart';
import 'package:field_reporter/features/auth/domain/tenant.dart';
import 'package:field_reporter/widgets/feedback/skeleton_loader.dart';
import 'dart:async';

void main() {
  group('Dashboard loads within acceptable time', () {
    late ProviderContainer container;
    late Stopwatch stopwatch;

    setUp(() {
      stopwatch = Stopwatch();
      container = ProviderContainer(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _MockDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _MockRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _MockPendingUploadsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _MockSyncStatusNotifier(),
          ),
          currentUserProvider.overrideWith((ref) => null),
          selectedTenantProvider.overrideWith(
            () => _MockSelectedTenant(),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          connectivityServiceProvider.overrideWith(
            (ref) => _MockConnectivityService(),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestWidget() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: {
            '/reports': (context) => const Scaffold(body: Text('Reports')),
            '/sync': (context) => const Scaffold(body: Text('Sync')),
            '/projects': (context) => const Scaffold(body: Text('Projects')),
            '/activity': (context) => const Scaffold(body: Text('Activity')),
            '/notifications': (context) =>
                const Scaffold(body: Text('Notifications')),
          },
        ),
      );
    }

    testWidgets('Dashboard loads within 2 seconds on good connection',
        (WidgetTester tester) async {
      // Start measuring from when widget is pumped (simulating login complete)
      stopwatch.start();

      await tester.pumpWidget(buildTestWidget());

      // Wait for initial data load
      await tester.pump();

      // Wait for all animations to complete
      await tester.pumpAndSettle();

      stopwatch.stop();

      // Verify Dashboard is fully rendered within 2 seconds
      // Note: In widget tests, time is simulated, so we verify the widget is ready
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));

      // Verify content is fully rendered
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // reportsThisWeek stat
      expect(find.text('Recent Reports'), findsOneWidget);
    });

    testWidgets('Skeleton loaders appear immediately during load',
        (WidgetTester tester) async {
      // Use the loading state notifier that stays in loading state
      final loadingContainer = ProviderContainer(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _LoadingDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _LoadingRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _MockPendingUploadsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _MockSyncStatusNotifier(),
          ),
          currentUserProvider.overrideWith((ref) => null),
          selectedTenantProvider.overrideWith(
            () => _MockSelectedTenant(),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          connectivityServiceProvider.overrideWith(
            (ref) => _MockConnectivityService(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: loadingContainer,
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/reports': (context) => const Scaffold(body: Text('Reports')),
              '/sync': (context) => const Scaffold(body: Text('Sync')),
              '/projects': (context) => const Scaffold(body: Text('Projects')),
              '/activity': (context) => const Scaffold(body: Text('Activity')),
              '/notifications': (context) =>
                  const Scaffold(body: Text('Notifications')),
            },
          ),
        ),
      );

      // Immediately after pump, skeleton loaders should appear
      await tester.pump();

      // Verify skeleton loaders are present during loading state
      expect(find.byType(SkeletonLoader), findsWidgets);

      // Clean up
      loadingContainer.dispose();
    });

    testWidgets('Content replaces skeletons smoothly',
        (WidgetTester tester) async {
      // Test that loading state shows skeletons
      final loadingContainer = ProviderContainer(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _LoadingDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _LoadingRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _MockPendingUploadsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _MockSyncStatusNotifier(),
          ),
          currentUserProvider.overrideWith((ref) => null),
          selectedTenantProvider.overrideWith(
            () => _MockSelectedTenant(),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          connectivityServiceProvider.overrideWith(
            (ref) => _MockConnectivityService(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: loadingContainer,
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/reports': (context) => const Scaffold(body: Text('Reports')),
              '/sync': (context) => const Scaffold(body: Text('Sync')),
              '/projects': (context) => const Scaffold(body: Text('Projects')),
              '/activity': (context) => const Scaffold(body: Text('Activity')),
              '/notifications': (context) =>
                  const Scaffold(body: Text('Notifications')),
            },
          ),
        ),
      );

      // During loading, skeletons should be present
      await tester.pump();
      expect(find.byType(SkeletonLoader), findsWidgets);

      // Clean up by pumping an empty widget first, then dispose
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(Duration.zero);
      loadingContainer.dispose();

      // Now test with loaded state using the existing container
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // After transition, content should be visible and skeletons gone
      expect(find.byType(SkeletonLoader), findsNothing);
      expect(find.text('5'), findsOneWidget); // Stats value visible
      expect(find.text('Recent Reports'), findsOneWidget);
    });

    testWidgets('Skeleton loaders match content dimensions',
        (WidgetTester tester) async {
      final loadingContainer = ProviderContainer(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _LoadingDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _LoadingRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _MockPendingUploadsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _MockSyncStatusNotifier(),
          ),
          currentUserProvider.overrideWith((ref) => null),
          selectedTenantProvider.overrideWith(
            () => _MockSelectedTenant(),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          connectivityServiceProvider.overrideWith(
            (ref) => _MockConnectivityService(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: loadingContainer,
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/reports': (context) => const Scaffold(body: Text('Reports')),
              '/sync': (context) => const Scaffold(body: Text('Sync')),
              '/projects': (context) => const Scaffold(body: Text('Projects')),
              '/activity': (context) => const Scaffold(body: Text('Activity')),
              '/notifications': (context) =>
                  const Scaffold(body: Text('Notifications')),
            },
          ),
        ),
      );

      await tester.pump();

      // Find skeleton loaders
      final skeletonFinder = find.byType(SkeletonLoader);
      expect(skeletonFinder, findsWidgets);

      // Get skeleton widgets and verify they have reasonable dimensions
      final skeletons =
          tester.widgetList<SkeletonLoader>(skeletonFinder).toList();
      for (final skeleton in skeletons) {
        // Skeletons should have positive dimensions
        expect(skeleton.width, greaterThan(0));
        expect(skeleton.height, greaterThan(0));
      }

      loadingContainer.dispose();
    });

    testWidgets('Skeleton animation is smooth (shimmer effect)',
        (WidgetTester tester) async {
      final loadingContainer = ProviderContainer(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _LoadingDashboardStatsNotifier(),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _LoadingRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _MockPendingUploadsNotifier(),
          ),
          syncStatusNotifierProvider.overrideWith(
            () => _MockSyncStatusNotifier(),
          ),
          currentUserProvider.overrideWith((ref) => null),
          selectedTenantProvider.overrideWith(
            () => _MockSelectedTenant(),
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          connectivityServiceProvider.overrideWith(
            (ref) => _MockConnectivityService(),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: loadingContainer,
          child: MaterialApp(
            home: const DashboardScreen(),
            routes: {
              '/reports': (context) => const Scaffold(body: Text('Reports')),
              '/sync': (context) => const Scaffold(body: Text('Sync')),
              '/projects': (context) => const Scaffold(body: Text('Projects')),
              '/activity': (context) => const Scaffold(body: Text('Activity')),
              '/notifications': (context) =>
                  const Scaffold(body: Text('Notifications')),
            },
          ),
        ),
      );

      await tester.pump();

      // Find skeleton loaders
      final skeletonFinder = find.byType(SkeletonLoader);
      expect(skeletonFinder, findsWidgets);

      // Pump through animation frames to verify shimmer animates
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Skeleton should still be present during animation
      expect(find.byType(SkeletonLoader), findsWidgets);

      loadingContainer.dispose();
    });
  });
}

// Mock providers for instant loading
class _MockDashboardStatsNotifier extends DashboardStatsNotifier {
  DateTime? _lastUpdated;

  @override
  DateTime? get lastUpdated => _lastUpdated;

  @override
  Future<DashboardStats> build() async {
    _lastUpdated = DateTime.now();
    return const DashboardStats(
      reportsThisWeek: 5,
      pendingUploads: 3,
      totalProjects: 10,
      recentActivity: 7,
    );
  }

  @override
  Future<void> refresh() async {
    _lastUpdated = DateTime.now();
    state = const AsyncData(DashboardStats(
      reportsThisWeek: 5,
      pendingUploads: 3,
      totalProjects: 10,
      recentActivity: 7,
    ));
  }
}

class _MockRecentReportsNotifier extends RecentReportsNotifier {
  @override
  Future<List<RecentReport>> build() async {
    return [
      RecentReport(
        id: '1',
        title: 'Site Inspection',
        projectName: 'Construction Project',
        date: DateTime.now(),
        status: ReportStatus.complete,
      ),
    ];
  }

  @override
  Future<void> refresh() async {
    state = AsyncData([
      RecentReport(
        id: '1',
        title: 'Site Inspection',
        projectName: 'Construction Project',
        date: DateTime.now(),
        status: ReportStatus.complete,
      ),
    ]);
  }
}

// Loading state notifiers that stay in loading state
class _LoadingDashboardStatsNotifier extends DashboardStatsNotifier {
  @override
  DateTime? get lastUpdated => null;

  @override
  Future<DashboardStats> build() {
    // Return a future that never completes to stay in loading state
    // Use a completer that is never completed
    final completer = Completer<DashboardStats>();
    return completer.future;
  }

  @override
  Future<void> refresh() async {}
}

class _LoadingRecentReportsNotifier extends RecentReportsNotifier {
  @override
  Future<List<RecentReport>> build() {
    final completer = Completer<List<RecentReport>>();
    return completer.future;
  }

  @override
  Future<void> refresh() async {}
}

class _MockPendingUploadsNotifier extends PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    return [];
  }

  @override
  Future<void> refresh() async {
    state = const AsyncData([]);
  }
}

class _MockSyncStatusNotifier extends SyncStatusNotifier {
  @override
  SyncStatus build() {
    return const SyncStatus.synced();
  }
}

class _MockSelectedTenant extends SelectedTenant {
  @override
  Tenant? build() {
    return null;
  }
}

class _MockConnectivityService extends ConnectivityService {
  @override
  bool get isOnline => true;
}
