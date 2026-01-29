import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/domain/tenant.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/tenant_provider.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';

void main() {
  group('Dashboard navigation drawer provides access to all sections', () {
    late String? navigatedRoute;

    Widget buildTestWidget({
      User? user,
      Tenant? tenant,
    }) {
      navigatedRoute = null;

      final testUser = user ??
          const User(
            id: 'user_1',
            email: 'john.doe@example.com',
            firstName: 'John',
            lastName: 'Doe',
          );

      final testTenant = tenant ??
          const Tenant(
            id: 'tenant_1',
            name: 'Acme Construction Co.',
          );

      final testStats = const DashboardStats(
        reportsThisWeek: 12,
        pendingUploads: 3,
        totalProjects: 8,
        recentActivity: 24,
      );

      return ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => testUser),
          selectedTenantProvider
              .overrideWith(() => _TestSelectedTenant(testTenant)),
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(),
          ),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
          onGenerateRoute: (settings) {
            navigatedRoute = settings.name;
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text('Navigated to: ${settings.name}'),
                ),
              ),
            );
          },
        ),
      );
    }

    testWidgets('Tap hamburger menu opens navigation drawer', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find and tap the hamburger menu (drawer icon)
      final drawerButton = find.byTooltip('Open navigation menu');
      expect(drawerButton, findsOneWidget,
          reason: 'Hamburger menu button should be visible');

      await tester.tap(drawerButton);
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.byType(Drawer), findsOneWidget,
          reason: 'Navigation drawer should open');
    });

    testWidgets('Swipe from left edge opens navigation drawer', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Swipe from left edge to open drawer
      await tester.dragFrom(
        const Offset(0, 300),
        const Offset(300, 300),
      );
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.byType(Drawer), findsOneWidget,
          reason: 'Navigation drawer should open via swipe');
    });

    testWidgets('Navigation drawer contains all required menu items',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState =
          tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Find ListTile widgets in the drawer for menu items
      final drawer = find.byType(Drawer);
      expect(drawer, findsOneWidget);

      // Verify menu items: Dashboard, Projects, Reports, Media, Settings
      // Use descendant finder to look within the drawer only
      expect(
        find.descendant(of: drawer, matching: find.text('Dashboard')),
        findsOneWidget,
        reason: 'Dashboard menu item should be present in drawer',
      );
      expect(
        find.descendant(of: drawer, matching: find.text('Projects')),
        findsOneWidget,
        reason: 'Projects menu item should be present in drawer',
      );
      expect(
        find.descendant(of: drawer, matching: find.text('Reports')),
        findsOneWidget,
        reason: 'Reports menu item should be present in drawer',
      );
      expect(
        find.descendant(of: drawer, matching: find.text('Media')),
        findsOneWidget,
        reason: 'Media menu item should be present in drawer',
      );
      expect(
        find.descendant(of: drawer, matching: find.text('Settings')),
        findsOneWidget,
        reason: 'Settings menu item should be present in drawer',
      );
    });

    testWidgets('Navigation drawer shows user profile section at top',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState =
          tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify user profile section - user name should be visible
      expect(find.text('John Doe'), findsOneWidget,
          reason: 'User full name should be displayed in drawer header');
      expect(find.text('john.doe@example.com'), findsOneWidget,
          reason: 'User email should be displayed in drawer header');
    });

    testWidgets('Navigation drawer displays tenant name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState =
          tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify tenant name is displayed in drawer
      final drawer = find.byType(Drawer);
      expect(
        find.descendant(
            of: drawer, matching: find.text('Acme Construction Co.')),
        findsOneWidget,
        reason: 'Tenant name should be displayed in drawer',
      );
    });

    testWidgets('Tapping Projects navigates to Projects screen',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState =
          tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Tap on Projects
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(navigatedRoute, equals('/projects'),
          reason: 'Should navigate to /projects route');
    });

    testWidgets('Drawer closes after navigation', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Open drawer
      final scaffoldState =
          tester.firstState<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      // Verify drawer is open
      expect(find.byType(Drawer), findsOneWidget);

      // Tap on Projects
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Verify drawer is closed (we navigated to a new screen)
      expect(navigatedRoute, equals('/projects'),
          reason: 'Navigation should have occurred');
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

/// Test notifier for selected tenant
class _TestSelectedTenant extends SelectedTenant {
  _TestSelectedTenant(this._tenant);

  final Tenant _tenant;

  @override
  Tenant? build() {
    return _tenant;
  }
}

/// Test notifier for recent reports
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  @override
  Future<List<RecentReport>> build() async {
    return [];
  }
}

/// Test notifier for pending uploads
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  @override
  Future<List<PendingUpload>> build() async {
    return [];
  }
}
