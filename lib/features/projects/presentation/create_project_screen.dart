import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/theme.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../domain/project.dart';
import '../providers/projects_provider.dart';
import 'widgets/location_picker.dart';

/// Screen for creating a new project.
class CreateProjectScreen extends ConsumerStatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _address;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isFormValid => _nameController.text.trim().isNotEmpty;

  void _onLocationSelected(double lat, double lng, String address) {
    setState(() {
      _latitude = lat;
      _longitude = lng;
      _address = address;
    });
    Navigator.of(context).pop();
  }

  Future<void> _createProject() async {
    if (!_isFormValid || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      HapticFeedback.lightImpact();

      final project = Project(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        address: _address,
        status: ProjectStatus.active,
        reportCount: 0,
        lastActivityAt: DateTime.now(),
      );

      final createdProject = await ref
          .read(projectsNotifierProvider.notifier)
          .createProject(project);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          '/projects/${createdProject.id}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationPicker(
        key: const Key('location_picker'),
        initialLatitude: _latitude,
        initialLongitude: _longitude,
        initialAddress: _address,
        onLocationSelected: _onLocationSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Form(
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
                fillColor: isDark ? AppColors.darkSurface : AppColors.slate100,
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
                fillColor: isDark ? AppColors.darkSurface : AppColors.slate100,
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
              textInputAction: TextInputAction.next,
            ),
            AppSpacing.verticalMd,

            // Location Field
            GestureDetector(
              onTap: _showLocationPicker,
              child: Container(
                padding: AppSpacing.cardInsets,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.slate100,
                  borderRadius: AppSpacing.borderRadiusLg,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                    AppSpacing.horizontalSm,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: AppTypography.caption.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.slate400,
                            ),
                          ),
                          if (_address != null) ...[
                            AppSpacing.verticalXs,
                            Text(
                              _address!,
                              style: AppTypography.body2.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.slate900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ],
                ),
              ),
            ),
            AppSpacing.verticalXl,

            // Create Button
            PrimaryButton(
              label: 'Create',
              onPressed: _isFormValid ? _createProject : null,
              isLoading: _isSubmitting,
            ),
          ],
        ),
      ),
    );
  }
}
