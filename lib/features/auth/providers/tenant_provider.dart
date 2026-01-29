import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/tenant.dart';

part 'tenant_provider.g.dart';

/// Provider for the list of available tenants for the current user.
@Riverpod(keepAlive: true)
List<Tenant> availableTenants(Ref ref) {
  // Default empty list - will be overridden when tenants are fetched
  return [];
}

/// Provider for the currently selected tenant.
@Riverpod(keepAlive: true)
class SelectedTenant extends _$SelectedTenant {
  @override
  Tenant? build() {
    return null;
  }

  /// Selects a tenant.
  void selectTenant(Tenant tenant) {
    state = tenant;
  }

  /// Clears the selected tenant.
  void clearTenant() {
    state = null;
  }
}
