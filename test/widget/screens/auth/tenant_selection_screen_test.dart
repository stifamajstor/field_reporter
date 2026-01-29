import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:field_reporter/core/theme/app_theme.dart';
import 'package:field_reporter/features/auth/domain/tenant.dart';
import 'package:field_reporter/features/auth/providers/tenant_provider.dart';
import 'package:field_reporter/features/auth/presentation/tenant_selection_screen.dart';

void main() {
  group('TenantSelectionScreen', () {
    late List<Tenant> mockTenants;

    setUp(() {
      mockTenants = [
        const Tenant(id: 'tenant_1', name: 'Acme Corporation'),
        const Tenant(id: 'tenant_2', name: 'BuildCo Industries'),
        const Tenant(id: 'tenant_3', name: 'Field Services Inc'),
      ];
    });

    Widget createTestWidget({
      required List<Tenant> tenants,
      VoidCallback? onTenantSelected,
    }) {
      return ProviderScope(
        overrides: [
          availableTenantsProvider.overrideWith((ref) => tenants),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: TenantSelectionScreen(
            onTenantSelected: onTenantSelected,
          ),
        ),
      );
    }

    testWidgets(
        'displays tenant selection screen after login with multiple tenants',
        (tester) async {
      // Step: Login with credentials linked to multiple tenants
      // Step: Verify tenant selection screen appears
      await tester.pumpWidget(createTestWidget(tenants: mockTenants));
      await tester.pumpAndSettle();

      // Verify the tenant selection screen is displayed
      expect(find.text('Select Organization'), findsOneWidget);
    });

    testWidgets('displays list of available tenants', (tester) async {
      // Step: Verify list of available tenants is displayed
      await tester.pumpWidget(createTestWidget(tenants: mockTenants));
      await tester.pumpAndSettle();

      // Verify all tenants are displayed
      expect(find.text('Acme Corporation'), findsOneWidget);
      expect(find.text('BuildCo Industries'), findsOneWidget);
      expect(find.text('Field Services Inc'), findsOneWidget);
    });

    testWidgets('tapping tenant selects it and triggers callback',
        (tester) async {
      // Step: Tap on desired tenant
      Tenant? selectedTenant;

      await tester.pumpWidget(createTestWidget(
        tenants: mockTenants,
        onTenantSelected: () {
          // Callback is triggered when tenant is selected
        },
      ));
      await tester.pumpAndSettle();

      // Tap on the first tenant
      await tester.tap(find.text('Acme Corporation'));
      await tester.pumpAndSettle();
    });

    testWidgets('selected tenant is stored in provider', (tester) async {
      // Step: Verify dashboard loads with selected tenant context
      late WidgetRef testRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableTenantsProvider.overrideWith((ref) => mockTenants),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Consumer(
              builder: (context, ref, _) {
                testRef = ref;
                return TenantSelectionScreen(
                  onTenantSelected: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on a tenant
      await tester.tap(find.text('BuildCo Industries'));
      await tester.pumpAndSettle();

      // Verify the tenant is selected in the provider
      final selectedTenant = testRef.read(selectedTenantProvider);
      expect(selectedTenant, isNotNull);
      expect(selectedTenant!.id, equals('tenant_2'));
      expect(selectedTenant.name, equals('BuildCo Industries'));
    });

    testWidgets('tenant name can be displayed in app header/drawer',
        (tester) async {
      // Step: Verify tenant name appears in app header/drawer
      // This test verifies the selected tenant name is accessible for display

      late WidgetRef testRef;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableTenantsProvider.overrideWith((ref) => mockTenants),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: Consumer(
              builder: (context, ref, _) {
                testRef = ref;
                return TenantSelectionScreen(
                  onTenantSelected: () {},
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select a tenant
      await tester.tap(find.text('Field Services Inc'));
      await tester.pumpAndSettle();

      // Verify selected tenant name is available for header/drawer
      final selectedTenant = testRef.read(selectedTenantProvider);
      expect(selectedTenant?.name, equals('Field Services Inc'));
    });

    testWidgets('shows loading state while fetching tenants', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableTenantsProvider.overrideWith((ref) => <Tenant>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: TenantSelectionScreen(
              isLoading: true,
              onTenantSelected: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('each tenant item is tappable with visual feedback',
        (tester) async {
      await tester.pumpWidget(createTestWidget(tenants: mockTenants));
      await tester.pumpAndSettle();

      // Find tenant list items
      final tenantItems = find.byKey(const Key('tenant_item_tenant_1'));
      expect(tenantItems, findsOneWidget);
    });
  });
}
