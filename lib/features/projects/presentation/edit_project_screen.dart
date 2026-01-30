import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../domain/project.dart';
import '../providers/projects_provider.dart';

/// Screen for editing an existing project.
class EditProjectScreen extends ConsumerStatefulWidget {
  const EditProjectScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  ConsumerState<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends ConsumerState<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  bool _initialized = false;
  Project? _project;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _initializeForm(Project project) {
    if (!_initialized) {
      _project = project;
      _nameController.text = project.name;
      _descriptionController.text = project.description ?? '';
      _initialized = true;
    }
  }

  bool get _isFormValid => _nameController.text.trim().isNotEmpty;

  Future<void> _saveProject() async {
    if (!_isFormValid || _isSubmitting || _project == null) return;

    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.lightImpact();

      final updatedProject = _project!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      await ref
          .read(projectsNotifierProvider.notifier)
          .updateProject(updatedProject);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Project'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: projectsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (projects) {
          final project =
              projects.where((p) => p.id == widget.projectId).firstOrNull;

          if (project == null) {
            return Center(
              child: Text(
                'Project not found',
                style: AppTypography.body1.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                ),
              ),
            );
          }

          // Initialize form with project data
          _initializeForm(project);

          return Form(
            key: _formKey,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // Project Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Project Name',
                    hintText: 'Enter project name',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkSurface : AppColors.slate100,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                      borderSide: const BorderSide(
                        color: AppColors.orange500,
                        width: 2,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() {}),
                ),
                AppSpacing.verticalMd,

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter project description (optional)',
                    filled: true,
                    fillColor:
                        isDark ? AppColors.darkSurface : AppColors.slate100,
                    border: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: AppSpacing.borderRadiusLg,
                      borderSide: const BorderSide(
                        color: AppColors.orange500,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
                AppSpacing.verticalXl,

                // Save Button
                PrimaryButton(
                  label: 'Save',
                  onPressed: _isFormValid ? _saveProject : null,
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
