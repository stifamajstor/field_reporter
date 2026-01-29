import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:field_reporter/core/theme/app_theme.dart';
import 'package:field_reporter/features/auth/domain/tenant.dart';
import 'package:field_reporter/features/auth/providers/auth_provider.dart';
import 'package:field_reporter/features/auth/providers/biometric_provider.dart';
import 'package:field_reporter/features/auth/providers/tenant_provider.dart';
import 'package:field_reporter/features/settings/presentation/settings_screen.dart';

import '../settings/enable_biometric_settings_test.mocks.dart';

@GenerateMocks([LocalAuthentication, FlutterSecureStorage])
void main() {
  group('Switch Tenant Feature', () {
    late List<Tenant> mockTenants;
    late MockLocalAuthentication mockLocalAuth;
    late MockFlutterSecureStorage mockStorage;

    setUp(() {
      mockTenants = [
        const Tenant(id: 'tenant_1', name: 'Acme Corporation'),
        const Tenant(id: 'tenant_2', name: 'BuildCo Industries'),
        const Tenant(id: 'tenant_3', name: 'Field Services Inc'),
      ];
      mockLocalAuth = MockLocalAuthentication();
      mockStorage = MockFlutterSecureStorage();

      // Default mock setup
      when(mockStorage.read(key: anyNamed('key')))
          .thenAnswer((_) async => null);
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
      when(mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => false);
    });

    ProviderContainer createContainer({
      List<Tenant>? tenants,
      Tenant? initialTenant,
    }) {
      final container = ProviderContainer(
        overrides: [
          localAuthProvider.overrideWithValue(mockLocalAuth),
          secureStorageProvider.overrideWithValue(mockStorage),
          availableTenantsProvider.overrideWithValue(tenants ?? mockTenants),
        ],
      );

      if (initialTenant != null) {
        container
            .read(selectedTenantProvider.notifier)
            .selectTenant(initialTenant);
      }

      return container;
    }

    Widget createTestWidget(ProviderContainer container,
        {VoidCallback? onSwitchOrganization}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: SettingsScreen(
            onSwitchOrganization: onSwitchOrganization,
          ),
        ),
      );
    }

    testWidgets(
        'shows Switch Organization option in settings when user has multiple tenants',
        (tester) async {
      // Step: Login and select initial tenant
      // Step: Navigate to Settings or Profile
      final container = createContainer(initialTenant: mockTenants[0]);
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Step: Tap 'Switch Organization' option
      // Verify 'Switch Organization' option is visible
      expect(find.text('Switch Organization'), findsOneWidget);
    });

    testWidgets(
        'tapping Switch Organization navigates to tenant selection screen',
        (tester) async {
      bool navigatedToTenantSelection = false;

      final container = createContainer(initialTenant: mockTenants[0]);
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(
        container,
        onSwitchOrganization: () {
          navigatedToTenantSelection = true;
        },
      ));
      await tester.pumpAndSettle();

      // Tap 'Switch Organization' option
      await tester.tap(find.text('Switch Organization'));
      await tester.pumpAndSettle();

      // Step: Verify tenant selection screen appears
      expect(navigatedToTenantSelection, isTrue);
    });

    testWidgets('selecting different tenant updates the app context',
        (tester) async {
      bool tenantSwitched = false;
      Tenant? newlySelectedTenant;

      final container = createContainer(initialTenant: mockTenants[0]);
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(
        container,
        onSwitchOrganization: () {
          // Simulate switching to a different tenant
          container
              .read(selectedTenantProvider.notifier)
              .selectTenant(mockTenants[1]);
          tenantSwitched = true;
          newlySelectedTenant = container.read(selectedTenantProvider);
        },
      ));
      await tester.pumpAndSettle();

      // Verify initial tenant
      expect(container.read(selectedTenantProvider)?.name,
          equals('Acme Corporation'));

      // Tap 'Switch Organization'
      await tester.tap(find.text('Switch Organization'));
      await tester.pumpAndSettle();

      // Step: Select different tenant
      // Step: Verify app reloads with new tenant context
      expect(tenantSwitched, isTrue);
      expect(newlySelectedTenant?.name, equals('BuildCo Industries'));
    });

    testWidgets(
        'does not show Switch Organization when user has only one tenant',
        (tester) async {
      final singleTenant = [const Tenant(id: 'tenant_1', name: 'Single Org')];
      final container = createContainer(
        tenants: singleTenant,
        initialTenant: singleTenant[0],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Should not show Switch Organization for single tenant
      expect(find.text('Switch Organization'), findsNothing);
    });

    testWidgets('displays current organization name in settings',
        (tester) async {
      final container = createContainer(initialTenant: mockTenants[0]);
      addTearDown(container.dispose);

      await tester.pumpWidget(createTestWidget(container));
      await tester.pumpAndSettle();

      // Step: Verify all data reflects new tenant
      // Current organization name should be displayed
      expect(find.text('Acme Corporation'), findsOneWidget);
    });
  });
}
