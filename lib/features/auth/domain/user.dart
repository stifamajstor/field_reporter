import 'package:flutter/foundation.dart';

/// User roles in the system.
enum UserRole {
  admin,
  manager,
  fieldWorker,
}

/// Represents a user in the system.
@immutable
class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    this.role = UserRole.fieldWorker,
  });

  /// Unique identifier for the user.
  final String id;

  /// User's email address.
  final String email;

  /// User's first name.
  final String firstName;

  /// User's last name.
  final String lastName;

  /// Optional URL to the user's avatar image.
  final String? avatarUrl;

  /// User's role in the system.
  final UserRole role;

  /// Returns the user's full name.
  String get fullName => '$firstName $lastName';

  /// Returns the user's initials (first letter of first and last name).
  String get initials {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  /// Returns true if user can manage team members.
  bool get canManageTeam => role == UserRole.admin || role == UserRole.manager;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          avatarUrl == other.avatarUrl &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      firstName.hashCode ^
      lastName.hashCode ^
      avatarUrl.hashCode ^
      role.hashCode;

  @override
  String toString() =>
      'User(id: $id, name: $fullName, email: $email, role: $role)';
}
