import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/user.dart';

part 'user_provider.g.dart';

/// Provider for the currently logged-in user.
///
/// Returns null if no user is logged in.
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  // Default mock user for now - will be overridden when user data is fetched after login
  return const User(
    id: 'user-default',
    email: 'user@test.com',
    firstName: 'Default',
    lastName: 'User',
    role: UserRole.admin,
  );
}
