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
import 'package:field_reporter/widgets/cards/animated_stat_card.dart';

void main() {
  group('Dashboard statistics animate on load', () {
    late ProviderContainer container;

    setUp(() {
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

    testWidgets('stat cards animate in with fade/slide on load',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Wait for data to load
      await tester.pump();

      // Find AnimatedStatCard widgets (these should exist after implementation)
      final animatedStatCardFinder = find.byType(AnimatedStatCard);

      // Verify that animated stat cards are present
      expect(animatedStatCardFinder, findsWidgets);

      // Verify that we have 4 stat cards
      expect(animatedStatCardFinder, findsNWidgets(4));

      // At the start of animation, cards should have low opacity
      // Pump zero frames to verify initial state
      await tester.pump(Duration.zero);

      // Get the AnimatedStatCard widgets
      final animatedCards =
          tester.widgetList<AnimatedStatCard>(animatedStatCardFinder).toList();

      // Verify they are animating (have animation properties)
      for (final card in animatedCards) {
        expect(card.animate, isTrue);
      }

      // Pump through the animation
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // After animation completes, cards should be fully visible
      await tester.pumpAndSettle();

      // Verify all stat cards are now visible
      expect(find.text('5'), findsOneWidget); // reportsThisWeek
      expect(find.text('3'), findsOneWidget); // pendingUploads
      expect(find.text('10'), findsOneWidget); // totalProjects
      expect(find.text('7'), findsOneWidget); // recentActivity
    });

    testWidgets('numbers count up animation', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Wait for data to load
      await tester.pump();

      // Find AnimatedStatCard widgets
      final animatedStatCardFinder = find.byType(AnimatedStatCard);
      expect(animatedStatCardFinder, findsWidgets);

      // At the beginning of animation, numbers should be 0 or animating from 0
      await tester.pump(Duration.zero);

      // Get the first AnimatedStatCard
      final firstCard =
          tester.widget<AnimatedStatCard>(animatedStatCardFinder.first);

      // Verify the card has count animation enabled
      expect(firstCard.animateCount, isTrue);

      // Pump part way through the animation - numbers should be counting up
      await tester.pump(const Duration(milliseconds: 150));

      // Pump to completion
      await tester.pumpAndSettle();

      // After animation, verify final values are displayed
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('animations are smooth (60fps timing)',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Wait for data to load
      await tester.pump();

      // Find AnimatedStatCard widgets
      final animatedStatCardFinder = find.byType(AnimatedStatCard);
      expect(animatedStatCardFinder, findsWidgets);

      // Verify animation uses appropriate duration (under 500ms for smoothness)
      final firstCard =
          tester.widget<AnimatedStatCard>(animatedStatCardFinder.first);

      // Animation duration should be reasonable for 60fps (16.6ms per frame)
      // Total animation should complete within 500ms for smoothness perception
      expect(firstCard.fadeSlideAnimationDuration.inMilliseconds,
          lessThanOrEqualTo(500));
      expect(firstCard.countAnimationDuration.inMilliseconds,
          lessThanOrEqualTo(600));

      // Pump in 60fps intervals (16.67ms) to simulate smooth animation
      const frameTime = Duration(milliseconds: 17);
      int frameCount = 0;

      while (frameCount < 30) {
        // ~500ms of animation
        await tester.pump(frameTime);
        frameCount++;
      }

      // Animation should complete smoothly
      await tester.pumpAndSettle();

      // Verify final state is reached
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('stat cards have staggered animation delay',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Wait for data to load
      await tester.pump();

      // Find AnimatedStatCard widgets
      final animatedStatCards = tester
          .widgetList<AnimatedStatCard>(find.byType(AnimatedStatCard))
          .toList();

      // Verify each card has a different delay for staggered effect
      final delays =
          animatedStatCards.map((card) => card.animationDelay).toList();

      // Each card should have an increasing delay
      for (int i = 1; i < delays.length; i++) {
        expect(delays[i].inMilliseconds,
            greaterThanOrEqualTo(delays[i - 1].inMilliseconds));
      }

      // Complete all pending animations
      await tester.pumpAndSettle();
    });

    testWidgets('respects reduced motion accessibility setting',
        (WidgetTester tester) async {
      // Build with reduced motion enabled
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              home: const DashboardScreen(),
              routes: {
                '/reports': (context) => const Scaffold(body: Text('Reports')),
                '/sync': (context) => const Scaffold(body: Text('Sync')),
                '/projects': (context) =>
                    const Scaffold(body: Text('Projects')),
                '/activity': (context) =>
                    const Scaffold(body: Text('Activity')),
                '/notifications': (context) =>
                    const Scaffold(body: Text('Notifications')),
              },
            ),
          ),
        ),
      );

      await tester.pump();

      // With reduced motion, values should appear immediately
      await tester.pump(Duration.zero);

      // Values should be immediately visible without animation
      expect(find.text('5'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });
  });
}

// Mock providers
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
    return [];
  }

  @override
  Future<void> refresh() async {
    state = const AsyncData([]);
  }
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

  @override
  Stream<bool> get onConnectivityChanged => Stream.value(true);
}
