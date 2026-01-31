import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/entry.dart';

part 'entries_provider.g.dart';

/// Provider for managing entries.
@riverpod
class EntriesNotifier extends _$EntriesNotifier {
  @override
  Future<List<Entry>> build() async {
    // Return empty list initially
    return [];
  }

  /// Adds a new entry to the list.
  Future<Entry> addEntry(Entry entry) async {
    final currentEntries = state.valueOrNull ?? [];
    state = AsyncData([...currentEntries, entry]);
    return entry;
  }

  /// Updates an existing entry.
  Future<Entry> updateEntry(Entry entry) async {
    final currentEntries = state.valueOrNull ?? [];
    final updatedEntries = currentEntries.map((e) {
      return e.id == entry.id ? entry : e;
    }).toList();
    state = AsyncData(updatedEntries);
    return entry;
  }

  /// Deletes an entry by ID.
  Future<void> deleteEntry(String entryId) async {
    final currentEntries = state.valueOrNull ?? [];
    final updatedEntries =
        currentEntries.where((e) => e.id != entryId).toList();
    state = AsyncData(updatedEntries);
  }

  /// Gets entries for a specific report.
  List<Entry> getEntriesForReport(String reportId) {
    final currentEntries = state.valueOrNull ?? [];
    return currentEntries.where((e) => e.reportId == reportId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Reorders entries within a report.
  Future<void> reorderEntries(
      String reportId, int oldIndex, int newIndex) async {
    final currentEntries = state.valueOrNull ?? [];

    // Get entries for this report and sort by current order
    final reportEntries =
        currentEntries.where((e) => e.reportId == reportId).toList();
    reportEntries.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // Perform the reorder
    final movedEntry = reportEntries.removeAt(oldIndex);
    reportEntries.insert(newIndex, movedEntry);

    // Update sortOrder for all report entries
    final updatedReportEntries = <Entry>[];
    for (var i = 0; i < reportEntries.length; i++) {
      updatedReportEntries.add(reportEntries[i].copyWith(sortOrder: i));
    }

    // Replace entries in the full list
    final updatedEntries = currentEntries.map((e) {
      if (e.reportId != reportId) return e;
      return updatedReportEntries.firstWhere(
        (u) => u.id == e.id,
        orElse: () => e,
      );
    }).toList();

    state = AsyncData(updatedEntries);
  }
}

/// Provider for getting entries for a specific report.
@riverpod
class ReportEntriesNotifier extends _$ReportEntriesNotifier {
  @override
  Future<List<Entry>> build(String reportId) async {
    final entriesNotifier = ref.watch(entriesNotifierProvider);
    return entriesNotifier.valueOrNull
            ?.where((e) => e.reportId == reportId)
            .toList() ??
        [];
  }
}
