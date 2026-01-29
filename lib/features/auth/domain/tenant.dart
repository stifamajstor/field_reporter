import 'package:flutter/foundation.dart';

/// Represents a tenant/organization in the multi-tenant system.
@immutable
class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  /// Unique identifier for the tenant.
  final String id;

  /// Display name of the tenant/organization.
  final String name;

  /// Optional URL to the tenant's logo.
  final String? logoUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tenant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          logoUrl == other.logoUrl;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ logoUrl.hashCode;

  @override
  String toString() => 'Tenant(id: $id, name: $name)';
}
