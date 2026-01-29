import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/domain/tenant.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/tenant_provider.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/dashboard/presentation/main_shell.dart';

void main() {
  group('Bottom navigation provides quick access to main sections', () {
    Widget buildTestWidget() {
      const testUser = User(
        id: 'user_1',
        email: 'john.doe@example.com',
        firstName: 'John',
        lastName: 'Doe',
      );

      const testTenant = Tenant(
        id: 'tenant_1',
        name: 'Acme Construction Co.',
      );

      const testStats = DashboardStats(
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
          availableTenantsProvider.overrideWith((ref) => [testTenant]),
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(),
          ),
          biometricProvider.overrideWith(() => _TestBiometricNotifier()),
        ],
        child: const MaterialApp(
          home: MainShell(),
        ),
      );
    }

    testWidgets('Bottom navigation bar is visible on Dashboard',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify bottom navigation bar is visible
      expect(find.byType(BottomNavigationBar), findsOneWidget,
          reason: 'Bottom navigation bar should be visible');
    });

    testWidgets('Bottom navigation has all required tabs', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify tabs: Home, Projects, Capture, Reports, Settings
      expect(find.text('Home'), findsOneWidget,
          reason: 'Home tab should be present');
      expect(find.text('Projects'), findsOneWidget,
          reason: 'Projects tab should be present');
      expect(find.text('Capture'), findsOneWidget,
          reason: 'Capture tab should be present');
      expect(find.text('Reports'), findsOneWidget,
          reason: 'Reports tab should be present');
      expect(find.text('Settings'), findsOneWidget,
          reason: 'Settings tab should be present');
    });

    testWidgets('Tap Projects tab navigates to Projects screen',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Projects tab
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Verify we're on Projects screen (check for Projects title in app bar)
      expect(find.text('Projects').first, findsOneWidget,
          reason: 'Should show Projects screen title');
    });

    testWidgets('Projects tab is highlighted when selected', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Projects tab
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Find the BottomNavigationBar and check selected index
      final bottomNav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(1),
          reason: 'Projects tab (index 1) should be highlighted');
    });

    testWidgets('Tap Home tab returns to Dashboard', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // First navigate to Projects
      await tester.tap(find.text('Projects'));
      await tester.pumpAndSettle();

      // Tap Home tab
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Verify we're back on Dashboard
      final bottomNav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(0),
          reason: 'Home tab (index 0) should be highlighted');

      // Verify Dashboard content is visible (greeting)
      expect(find.textContaining('Good'), findsOneWidget,
          reason: 'Dashboard greeting should be visible');
    });

    testWidgets('Home tab is highlighted by default', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify Home tab is selected by default
      final bottomNav =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(bottomNav.currentIndex, equals(0),
          reason: 'Home tab (index 0) should be highlighted by default');
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

/// Test notifier for biometric
class _TestBiometricNotifier extends Biometric {
  @override
  BiometricState build() {
    return BiometricState.initial;
  }

  @override
  Future<bool> checkBiometricAvailability() async => false;

  @override
  Future<bool> isBiometricEnabled() async => false;
}
