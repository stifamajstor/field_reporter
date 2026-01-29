import 'package:flutter/foundation.dart';

/// State for offline PIN authentication.
@immutable
class OfflinePinState {
  const OfflinePinState({
    this.isEnabled = false,
    this.isPinSet = false,
    this.requiresPinEntry = false,
    this.isOffline = false,
    this.isVerifying = false,
    this.error,
  });

  final bool isEnabled;
  final bool isPinSet;
  final bool requiresPinEntry;
  final bool isOffline;
  final bool isVerifying;
  final String? error;

  OfflinePinState copyWith({
    bool? isEnabled,
    bool? isPinSet,
    bool? requiresPinEntry,
    bool? isOffline,
    bool? isVerifying,
    String? error,
  }) {
    return OfflinePinState(
      isEnabled: isEnabled ?? this.isEnabled,
      isPinSet: isPinSet ?? this.isPinSet,
      requiresPinEntry: requiresPinEntry ?? this.requiresPinEntry,
      isOffline: isOffline ?? this.isOffline,
      isVerifying: isVerifying ?? this.isVerifying,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflinePinState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          isPinSet == other.isPinSet &&
          requiresPinEntry == other.requiresPinEntry &&
          isOffline == other.isOffline &&
          isVerifying == other.isVerifying &&
          error == other.error;

  @override
  int get hashCode =>
      isEnabled.hashCode ^
      isPinSet.hashCode ^
      requiresPinEntry.hashCode ^
      isOffline.hashCode ^
      isVerifying.hashCode ^
      error.hashCode;
}
