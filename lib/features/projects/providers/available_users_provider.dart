import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/domain/user.dart';

part 'available_users_provider.g.dart';

/// Provider for fetching available users that can be assigned to projects.
@riverpod
Future<List<User>> availableUsers(Ref ref) async {
  // Simulate loading users from API
  await Future.delayed(const Duration(milliseconds: 100));

  // Return mock data for now - will be replaced with actual API calls
  return const [
    User(
      id: 'user-1',
      email: 'john@test.com',
      firstName: 'John',
      lastName: 'Doe',
      role: UserRole.fieldWorker,
    ),
    User(
      id: 'user-2',
      email: 'jane@test.com',
      firstName: 'Jane',
      lastName: 'Smith',
      role: UserRole.fieldWorker,
    ),
    User(
      id: 'user-3',
      email: 'bob@test.com',
      firstName: 'Bob',
      lastName: 'Wilson',
      role: UserRole.manager,
    ),
  ];
}
