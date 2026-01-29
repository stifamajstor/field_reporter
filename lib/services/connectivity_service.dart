import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_service.g.dart';

/// Service to check network connectivity status.
class ConnectivityService {
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    _isOnline = value;
  }
}

/// Provider for ConnectivityService instance.
@Riverpod(keepAlive: true)
ConnectivityService connectivityService(Ref ref) {
  return ConnectivityService();
}
