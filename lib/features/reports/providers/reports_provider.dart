import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/report.dart';

part 'reports_provider.g.dart';

/// Provider for fetching reports by project ID.
@riverpod
class ProjectReportsNotifier extends _$ProjectReportsNotifier {
  @override
  Future<List<Report>> build(String projectId) async {
    // TODO: Fetch from repository
    return [];
  }
}
