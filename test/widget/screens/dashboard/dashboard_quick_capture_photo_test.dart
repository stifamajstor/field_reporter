import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:field_reporter/features/dashboard/presentation/dashboard_screen.dart';
import 'package:field_reporter/features/dashboard/providers/dashboard_provider.dart';
import 'package:field_reporter/features/dashboard/domain/dashboard_stats.dart';
import 'package:field_reporter/features/dashboard/domain/recent_report.dart';
import 'package:field_reporter/features/sync/domain/pending_upload.dart';
import 'package:field_reporter/features/sync/providers/pending_uploads_provider.dart';
import 'package:field_reporter/features/capture/providers/quick_capture_provider.dart';
import 'package:field_reporter/features/capture/domain/quick_capture_state.dart';
import 'package:field_reporter/features/projects/domain/project.dart';
import 'package:field_reporter/features/projects/providers/projects_provider.dart';

void main() {
  group('Quick Capture initiates photo capture without project selection', () {
    late List<Project> testProjects;
    late List<RecentReport> testReports;

    setUp(() {
      testProjects = [
        const Project(
          id: 'proj-1',
          name: 'Construction Site A',
          description: 'Main construction site',
        ),
        const Project(
          id: 'proj-2',
          name: 'Office Building B',
          description: 'Office renovation project',
        ),
      ];

      testReports = [
        RecentReport(
          id: 'report-1',
          title: 'Site Inspection Report',
          projectName: 'Construction Site A',
          date: DateTime(2026, 1, 29),
          status: ReportStatus.draft,
        ),
        RecentReport(
          id: 'report-2',
          title: 'Progress Update',
          projectName: 'Construction Site A',
          date: DateTime(2026, 1, 28),
          status: ReportStatus.complete,
        ),
      ];
    });

    Widget buildTestWidget({
      DashboardStats? stats,
      List<RecentReport>? reports,
      List<PendingUpload>? pendingUploads,
      List<Project>? projects,
      QuickCaptureState? captureState,
    }) {
      final testStats = stats ??
          const DashboardStats(
            reportsThisWeek: 12,
            pendingUploads: 0,
            totalProjects: 8,
            recentActivity: 24,
          );

      final testReportsList = reports ?? testReports;
      final testPendingUploads = pendingUploads ?? [];
      final testProjectsList = projects ?? testProjects;
      final testCaptureState =
          captureState ?? const QuickCaptureState.initial();

      return ProviderScope(
        overrides: [
          dashboardStatsNotifierProvider.overrideWith(
            () => _TestDashboardStatsNotifier(testStats),
          ),
          recentReportsNotifierProvider.overrideWith(
            () => _TestRecentReportsNotifier(testReportsList),
          ),
          pendingUploadsNotifierProvider.overrideWith(
            () => _TestPendingUploadsNotifier(testPendingUploads),
          ),
          projectsNotifierProvider.overrideWith(
            () => _TestProjectsNotifier(testProjectsList),
          ),
          quickCaptureNotifierProvider.overrideWith(
            () => _TestQuickCaptureNotifier(testCaptureState),
          ),
        ],
        child: MaterialApp(
          home: const DashboardScreen(),
          routes: {
            '/camera': (context) => const _MockCameraScreen(),
            '/project-selection': (context) =>
                const _MockProjectSelectionScreen(),
            '/report-selection': (context) =>
                const _MockReportSelectionScreen(),
          },
        ),
      );
    }

    testWidgets('Navigate to Dashboard and tap Quick Capture FAB',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Navigate to Dashboard - it's the home screen
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Step 2: Tap Quick Capture FAB
      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Verify capture menu is open
      expect(find.text('Photo'), findsOneWidget);
    });

    testWidgets('Select Photo option opens camera', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1-2: Open capture menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 3: Select 'Photo' option
      final photoOption = find.text('Photo');
      expect(photoOption, findsOneWidget);
      await tester.tap(photoOption);
      await tester.pumpAndSettle();

      // Step 4: Verify camera opens (navigates to camera screen)
      expect(find.byType(_MockCameraScreen), findsOneWidget);
    });

    testWidgets('After capturing photo, prompt to select project appears',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        captureState: const QuickCaptureState.photoCaptured(
          photoPath: '/tmp/photo.jpg',
        ),
      ));
      await tester.pumpAndSettle();

      // Step 1-2: Open capture menu
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 3: Select 'Photo' option
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Step 4: Camera screen appears
      expect(find.byType(_MockCameraScreen), findsOneWidget);

      // Step 5: Capture a photo (tap capture button)
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      // Step 6: Verify prompt to select project appears
      expect(find.byType(_MockProjectSelectionScreen), findsOneWidget);
      expect(find.text('Select Project'), findsOneWidget);
    });

    testWidgets('Selecting project shows report selection prompt',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        captureState: QuickCaptureState.projectSelected(
          photoPath: '/tmp/photo.jpg',
          project: testProjects.first,
        ),
      ));
      await tester.pumpAndSettle();

      // Open capture menu and select photo
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Capture photo
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      // Step 7: Select a project
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 8: Verify prompt to select or create report appears
      expect(find.byType(_MockReportSelectionScreen), findsOneWidget);
      expect(find.text('Select Report'), findsOneWidget);
      // Should show option to create new report
      expect(find.text('Create New Report'), findsOneWidget);
    });

    testWidgets('Selecting existing report adds photo to report',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        captureState: QuickCaptureState.projectSelected(
          photoPath: '/tmp/photo.jpg',
          project: testProjects.first,
        ),
      ));
      await tester.pumpAndSettle();

      // Navigate through the flow
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 9: Select existing report
      await tester.tap(find.text('Site Inspection Report'));
      await tester.pumpAndSettle();

      // Step 10: Verify photo is added to report (success message or navigation)
      expect(find.text('Photo added to report'), findsOneWidget);
    });

    testWidgets('Creating new report adds photo to new report', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        captureState: QuickCaptureState.projectSelected(
          photoPath: '/tmp/photo.jpg',
          project: testProjects.first,
        ),
      ));
      await tester.pumpAndSettle();

      // Navigate through the flow
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 9: Create new report instead
      await tester.tap(find.text('Create New Report'));
      await tester.pumpAndSettle();

      // Enter report title
      final titleField = find.byKey(const Key('report_title_field'));
      await tester.enterText(titleField, 'New Field Report');
      await tester.pumpAndSettle();

      // Confirm creation
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      // Step 10: Verify photo is added to new report
      expect(find.text('Photo added to report'), findsOneWidget);
    });

    testWidgets('Full flow: capture photo, select project, select report',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Navigate to Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Step 2: Tap Quick Capture FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Step 3: Select 'Photo' option
      await tester.tap(find.text('Photo'));
      await tester.pumpAndSettle();

      // Step 4: Verify camera opens
      expect(find.byType(_MockCameraScreen), findsOneWidget);

      // Step 5: Capture a photo
      await tester.tap(find.byKey(const Key('capture_button')));
      await tester.pumpAndSettle();

      // Step 6: Verify prompt to select project appears
      expect(find.text('Select Project'), findsOneWidget);

      // Step 7: Select a project
      await tester.tap(find.text('Construction Site A'));
      await tester.pumpAndSettle();

      // Step 8: Verify prompt to select or create report appears
      expect(find.text('Select Report'), findsOneWidget);

      // Step 9: Select existing report
      await tester.tap(find.text('Site Inspection Report'));
      await tester.pumpAndSettle();

      // Step 10: Verify photo is added to report
      expect(find.text('Photo added to report'), findsOneWidget);
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

/// Test notifier that returns preset pending uploads
class _TestPendingUploadsNotifier extends PendingUploadsNotifier {
  _TestPendingUploadsNotifier(this._uploads);

  final List<PendingUpload> _uploads;

  @override
  Future<List<PendingUpload>> build() async {
    return _uploads;
  }
}

/// Test notifier that returns preset projects
class _TestProjectsNotifier extends ProjectsNotifier {
  _TestProjectsNotifier(this._projects);

  final List<Project> _projects;

  @override
  Future<List<Project>> build() async {
    return _projects;
  }
}

/// Test notifier for quick capture state
class _TestQuickCaptureNotifier extends QuickCaptureNotifier {
  _TestQuickCaptureNotifier(this._initialState);

  final QuickCaptureState _initialState;

  @override
  QuickCaptureState build() {
    return _initialState;
  }
}

/// Mock camera screen for testing
class _MockCameraScreen extends ConsumerStatefulWidget {
  const _MockCameraScreen();

  @override
  ConsumerState<_MockCameraScreen> createState() => _MockCameraScreenState();
}

class _MockCameraScreenState extends ConsumerState<_MockCameraScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Camera')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Camera Preview'),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('capture_button'),
              onPressed: () {
                // Simulate photo capture
                ref
                    .read(quickCaptureNotifierProvider.notifier)
                    .capturePhoto('/tmp/photo.jpg');
                Navigator.pushReplacementNamed(context, '/project-selection');
              },
              child: const Text('Capture'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mock project selection screen for testing
class _MockProjectSelectionScreen extends ConsumerWidget {
  const _MockProjectSelectionScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Project')),
      body: projectsAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, s) => Text('Error: $e'),
        data: (projects) => ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            return ListTile(
              title: Text(project.name),
              onTap: () {
                ref
                    .read(quickCaptureNotifierProvider.notifier)
                    .selectProject(project);
                Navigator.pushReplacementNamed(context, '/report-selection');
              },
            );
          },
        ),
      ),
    );
  }
}

/// Mock report selection screen for testing
class _MockReportSelectionScreen extends ConsumerStatefulWidget {
  const _MockReportSelectionScreen();

  @override
  ConsumerState<_MockReportSelectionScreen> createState() =>
      _MockReportSelectionScreenState();
}

class _MockReportSelectionScreenState
    extends ConsumerState<_MockReportSelectionScreen> {
  bool _showCreateForm = false;
  bool _photoAdded = false;

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(recentReportsNotifierProvider);

    if (_photoAdded) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, size: 64, color: Colors.green),
              SizedBox(height: 16),
              Text('Photo added to report'),
            ],
          ),
        ),
      );
    }

    if (_showCreateForm) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create New Report')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                key: const Key('report_title_field'),
                decoration: const InputDecoration(
                  labelText: 'Report Title',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(quickCaptureNotifierProvider.notifier)
                      .createReportAndAddPhoto('New Report');
                  setState(() {
                    _photoAdded = true;
                  });
                },
                child: const Text('Create'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select Report')),
      body: reportsAsync.when(
        loading: () => const CircularProgressIndicator(),
        error: (e, s) => Text('Error: $e'),
        data: (reports) => Column(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create New Report'),
              onTap: () {
                setState(() {
                  _showCreateForm = true;
                });
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return ListTile(
                    title: Text(report.title),
                    subtitle: Text(report.projectName),
                    onTap: () {
                      ref
                          .read(quickCaptureNotifierProvider.notifier)
                          .selectReportAndAddPhoto(report.id);
                      setState(() {
                        _photoAdded = true;
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
