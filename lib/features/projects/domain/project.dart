import 'package:flutter/foundation.dart';

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
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      description.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      address.hashCode ^
      status.hashCode;
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
