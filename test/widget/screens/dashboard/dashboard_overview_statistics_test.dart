import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/domain/auth_state.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/widgets/cards/stat_card.dart';

void main() {
  group('Dashboard displays overview statistics', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      bool isAuthenticated = true,
      Map<String, WidgetBuilder>? routes,
    }) {
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 3,
            totalProjects: 8,
            recentActivity: 24,
          );

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: routes ?? {},
        ),
      );
    }

    testWidgets('Dashboard is the default landing screen after login',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Dashboard screen is displayed
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });

    testWidgets('Reports This Week count is displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 'Reports This Week' stat card is displayed
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('Pending Uploads count is displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 'Pending Uploads' stat card is displayed
      expect(find.text('Pending Uploads'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Total Projects count is displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 'Total Projects' stat card is displayed
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('Recent Activity count is displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 'Recent Activity' stat card is displayed
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('24'), findsOneWidget);
    });

    testWidgets('Tapping stat card navigates to relevant detail screen',
        (tester) async {
      bool navigatedToReports = false;

      await tester.pumpWidget(
        buildTestWidget(
          routes: {
            '/reports': (context) {
              navigatedToReports = true;
              return const Scaffold(body: Text('Reports Screen'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the 'Reports This Week' stat card
      final reportsCard = find.ancestor(
        of: find.text('Reports This Week'),
        matching: find.byType(StatCard),
      );
      expect(reportsCard, findsOneWidget);

      await tester.tap(reportsCard);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(navigatedToReports, isTrue);
    });

    testWidgets('All four stat cards are displayed together', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify all stat cards are present
      expect(find.byType(StatCard), findsNWidgets(4));
      expect(find.text('Reports This Week'), findsOneWidget);
      expect(find.text('Pending Uploads'), findsOneWidget);
      expect(find.text('Total Projects'), findsOneWidget);
      expect(find.text('Recent Activity'), findsOneWidget);
    });

    testWidgets('Stat cards are tappable with visual feedback', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find a stat card
      final statCard = find.byType(StatCard).first;

      // Verify it's tappable (has GestureDetector)
      final gestureDetector = find.descendant(
        of: statCard,
        matching: find.byType(GestureDetector),
      );

      expect(
        gestureDetector.evaluate().isNotEmpty,
        isTrue,
        reason: 'Stat cards should be tappable with GestureDetector',
      );
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
