import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/widgets/cards/report_card.dart';

void main() {
  group('Dashboard shows recent reports list', () {
    Widget buildTestWidget({
      DashboardStats? stats,
      List<RecentReport>? recentReports,
      Map<String, WidgetBuilder>? routes,
    }) {
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 3,
            totalProjects: 8,
            recentActivity: 24,
          );

      final testReports = recentReports ??
          [
            RecentReport(
              id: '1',
              title: 'Site Inspection Report',
              projectName: 'Construction Site A',
              date: DateTime(2026, 1, 29),
              status: ReportStatus.complete,
            ),
            RecentReport(
              id: '2',
              title: 'Progress Update',
              projectName: 'Building B',
              date: DateTime(2026, 1, 28),
              status: ReportStatus.draft,
            ),
            RecentReport(
              id: '3',
              title: 'Safety Audit',
              projectName: 'Warehouse C',
              date: DateTime(2026, 1, 27),
              status: ReportStatus.processing,
            ),
            RecentReport(
              id: '4',
              title: 'Final Assessment',
              projectName: 'Office D',
              date: DateTime(2026, 1, 26),
              status: ReportStatus.complete,
            ),
            RecentReport(
              id: '5',
              title: 'Weekly Summary',
              projectName: 'Site E',
              date: DateTime(2026, 1, 25),
              status: ReportStatus.draft,
            ),
          ];

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(testReports),
          ),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: routes ?? {},
        ),
      );
    }

    testWidgets('Recent Reports section is visible', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify 'Recent Reports' section header is visible
      expect(find.text('Recent Reports'), findsOneWidget);
    });

    testWidgets('Up to 5 recent reports are displayed', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify up to 5 report cards are displayed
      expect(find.byType(ReportCard), findsNWidgets(5));
    });

    testWidgets('Each report shows title, project name, and date',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify first report shows title
      expect(find.text('Site Inspection Report'), findsOneWidget);

      // Verify first report shows project name
      expect(find.text('Construction Site A'), findsOneWidget);

      // Verify date is displayed (formatted)
      expect(find.textContaining('Jan 29'), findsOneWidget);
    });

    testWidgets('Each report shows status indicator', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify status indicators are present
      // Complete status shown as green indicator
      expect(find.text('COMPLETE'), findsNWidgets(2));

      // Draft status shown
      expect(find.text('DRAFT'), findsNWidgets(2));

      // Processing status shown
      expect(find.text('PROCESSING'), findsOneWidget);
    });

    testWidgets('Tapping report navigates to Report Detail screen',
        (tester) async {
      bool navigatedToReportDetail = false;
      String? navigatedReportId;

      await tester.pumpWidget(
        buildTestWidget(
          routes: {
            '/report-detail': (context) {
              navigatedToReportDetail = true;
              final args = ModalRoute.of(context)?.settings.arguments;
              if (args is String) {
                navigatedReportId = args;
              }
              return const Scaffold(body: Text('Report Detail Screen'));
            },
          },
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to make the first report card visible
      await tester.ensureVisible(find.byType(ReportCard).first);
      await tester.pumpAndSettle();

      // Find and tap the first report card
      final firstReportCard = find.byType(ReportCard).first;
      await tester.tap(firstReportCard);
      await tester.pumpAndSettle();

      // Verify navigation occurred
      expect(navigatedToReportDetail, isTrue);
      expect(navigatedReportId, equals('1'));
    });

    testWidgets('Shows maximum of 5 reports even if more exist',
        (tester) async {
      final sixReports = List.generate(
        6,
        (i) => RecentReport(
          id: '$i',
          title: 'Report $i',
          projectName: 'Project $i',
          date: DateTime(2026, 1, 29 - i),
          status: ReportStatus.complete,
        ),
      );

      await tester.pumpWidget(buildTestWidget(recentReports: sixReports));
      await tester.pumpAndSettle();

      // Should only show 5 even though 6 exist
      expect(find.byType(ReportCard), findsNWidgets(5));
    });

    testWidgets('Report cards are tappable with visual feedback',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Verify report cards have gesture detector for tap
      final reportCard = find.byType(ReportCard).first;
      final gestureDetector = find.descendant(
        of: reportCard,
        matching: find.byType(GestureDetector),
      );

      expect(
        gestureDetector.evaluate().isNotEmpty,
        isTrue,
        reason: 'Report cards should be tappable',
      );
    });

    testWidgets('Reports are displayed in chronological order (most recent first)',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Find all report cards
      final reportCards = find.byType(ReportCard);

      // Get the first report card's title
      final firstCardFinder = reportCards.first;
      final firstCard = tester.widget<ReportCard>(firstCardFinder);

      // Most recent should be first
      expect(firstCard.report.title, equals('Site Inspection Report'));
    });
  });
}

/// Test notifier that returns preset stats
class _TestDashboardStatsNotifier extends DashboardStatsNotifier {
  _TestDashboardStatsNotifier(this._stats);

  final DashboardStats _stats;

  @override
  Future<DashboardStats> build() async {
    return _stats;
  }
}

/// Test notifier that returns preset recent reports
class _TestRecentReportsNotifier extends RecentReportsNotifier {
  _TestRecentReportsNotifier(this._reports);

  final List<RecentReport> _reports;

  @override
  Future<List<RecentReport>> build() async {
    return _reports;
  }
}
