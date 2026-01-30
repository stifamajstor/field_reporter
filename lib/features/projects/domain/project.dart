import 'package:flutter/foundation.dart';

/// A team member assigned to a project.
@immutable
class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? role;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamMember &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          avatarUrl == other.avatarUrl &&
          role == other.role;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ avatarUrl.hashCode ^ role.hashCode;
}

/// A project in the Field Reporter app.
@immutable
class Project {
  const Project({
    required this.id,
    required this.name,
    this.description,
    this.latitude,
    this.longitude,
    this.address,
    this.status = ProjectStatus.active,
    this.reportCount = 0,
    this.lastActivityAt,
    this.teamMembers = const [],
    this.syncPending = false,
  });

  /// Unique identifier of the project.
  final String id;

  /// Name of the project.
  final String name;

  /// Description of the project.
  final String? description;

  /// Latitude coordinate of the project location.
  final double? latitude;

  /// Longitude coordinate of the project location.
  final double? longitude;

  /// Address of the project location.
  final String? address;

  /// Current status of the project.
  final ProjectStatus status;

  /// Number of reports associated with this project.
  final int reportCount;

  /// Timestamp of the most recent activity on this project.
  final DateTime? lastActivityAt;

  /// Team members assigned to this project.
  final List<TeamMember> teamMembers;

  /// Whether this project has pending changes to sync.
  final bool syncPending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Project &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          description == other.description &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          address == other.address &&
          status == other.status &&
          reportCount == other.reportCount &&
          lastActivityAt == other.lastActivityAt &&
          listEquals(teamMembers, other.teamMembers) &&
          syncPending == other.syncPending;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      address.hashCode ^
      status.hashCode ^
      reportCount.hashCode ^
      lastActivityAt.hashCode ^
      teamMembers.hashCode ^
      syncPending.hashCode;

  Project copyWith({
    String? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    String? address,
    ProjectStatus? status,
    int? reportCount,
    DateTime? lastActivityAt,
    List<TeamMember>? teamMembers,
    bool? syncPending,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      status: status ?? this.status,
      reportCount: reportCount ?? this.reportCount,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      teamMembers: teamMembers ?? this.teamMembers,
      syncPending: syncPending ?? this.syncPending,
    );
  }
}

/// Status of a project.
enum ProjectStatus {
  /// Project is currently active.
  active,

  /// Project has been completed.
  completed,

  /// Project has been archived.
  archived,
}
