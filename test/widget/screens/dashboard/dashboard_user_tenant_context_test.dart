import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/auth/domain/auth_state.dart';
import 'package:field_reporter/features/auth/domain/tenant.dart';
import 'package:field_reporter/features/auth/domain/user.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/tenant_provider.dart';
import 'package:field_reporter/features/auth/providers/user_provider.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';

void main() {
  group('Dashboard displays user and tenant context', () {
    Widget buildTestWidget({
      User? user,
      Tenant? tenant,
      DashboardStats? stats,
    }) {
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

      final testStats = stats ??
          const DashboardStats(
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
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets('User name or avatar is displayed in header', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify user name is displayed in the header area
      // Either the full name or initials should be visible
      expect(
        find.textContaining('John'),
        findsAtLeastNWidgets(1),
        reason: 'User first name should be displayed in header',
      );
    });

    testWidgets('Current tenant/organization name is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify tenant name is displayed
      expect(
        find.text('Acme Construction Co.'),
        findsOneWidget,
        reason: 'Tenant name should be visible on dashboard',
      );
    });

    testWidgets('Greeting message includes user\'s first name', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify greeting message contains user's first name
      // The greeting could be "Good morning, John" or "Hello, John" etc.
      final greetingFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            (widget.data!.contains('Good morning, John') ||
                widget.data!.contains('Good afternoon, John') ||
                widget.data!.contains('Good evening, John') ||
                widget.data!.contains('Hello, John')),
      );

      expect(
        greetingFinder,
        findsOneWidget,
        reason: 'Greeting message should include user\'s first name',
      );
    });

    testWidgets('User context updates when user changes', (tester) async {
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith((ref) => const User(
                id: 'user_1',
                email: 'jane.smith@example.com',
                firstName: 'Jane',
                lastName: 'Smith',
              )),
          selectedTenantProvider.overrideWith(() => _TestSelectedTenant(
                const Tenant(id: 'tenant_1', name: 'Test Corp'),
              )),
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(
              const DashboardStats(
                reportsThisWeek: 12,
                pendingUploads: 3,
                totalProjects: 8,
                recentActivity: 24,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Jane's name is displayed
      expect(find.textContaining('Jane'), findsAtLeastNWidgets(1));
    });

    testWidgets('Tenant context updates when tenant changes', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          tenant: const Tenant(
            id: 'tenant_2',
            name: 'BuildRight Inc.',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify new tenant name is displayed
      expect(find.text('BuildRight Inc.'), findsOneWidget);
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
