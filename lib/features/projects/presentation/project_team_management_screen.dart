import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme.dart';
import '../../auth/domain/user.dart';
import '../domain/project.dart';
import '../providers/available_users_provider.dart';
import '../providers/projects_provider.dart';

/// Screen for managing team members assigned to a project.
class ProjectTeamManagementScreen extends ConsumerStatefulWidget {
  const ProjectTeamManagementScreen({
    super.key,
    required this.projectId,
  });

  final String projectId;

  @override
  ConsumerState<ProjectTeamManagementScreen> createState() =>
      _ProjectTeamManagementScreenState();
}

class _ProjectTeamManagementScreenState
    extends ConsumerState<ProjectTeamManagementScreen> {
  bool _showingAddMember = false;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final projectsAsync = ref.watch(projectsNotifierProvider);
    final availableUsersAsync = ref.watch(availableUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Team'),
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

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Current team section
              _CurrentTeamSection(
                project: project,
                isDark: isDark,
                onRemoveMember: (memberId) => _removeMember(project, memberId),
              ),
              AppSpacing.verticalLg,

              // Add member button
              if (!_showingAddMember) ...[
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showingAddMember = true);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Member'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        isDark ? AppColors.darkOrange : AppColors.orange500,
                    side: BorderSide(
                      color:
                          isDark ? AppColors.darkOrange : AppColors.orange500,
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ],

              // Available users list
              if (_showingAddMember) ...[
                _AvailableUsersSection(
                  project: project,
                  isDark: isDark,
                  availableUsersAsync: availableUsersAsync,
                  onSelectUser: (user) => _addMember(project, user),
                  onCancel: () => setState(() => _showingAddMember = false),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _addMember(Project project, User user) async {
    HapticFeedback.lightImpact();
    final member = TeamMember(
      id: user.id,
      name: user.fullName,
      role: _roleToString(user.role),
    );
    await ref
        .read(projectsNotifierProvider.notifier)
        .addTeamMember(project.id, member);
    setState(() => _showingAddMember = false);
  }

  Future<void> _removeMember(Project project, String memberId) async {
    HapticFeedback.lightImpact();
    await ref
        .read(projectsNotifierProvider.notifier)
        .removeTeamMember(project.id, memberId);
  }

  String _roleToString(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Admin',
      UserRole.manager => 'Manager',
      UserRole.fieldWorker => 'Field Worker',
    };
  }
}

class _CurrentTeamSection extends StatelessWidget {
  const _CurrentTeamSection({
    required this.project,
    required this.isDark,
    required this.onRemoveMember,
  });

  final Project project;
  final bool isDark;
  final void Function(String memberId) onRemoveMember;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Current Team',
          style: AppTypography.headline3.copyWith(
            color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
          ),
        ),
        AppSpacing.verticalSm,
        if (project.teamMembers.isEmpty)
          Container(
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: AppSpacing.borderRadiusLg,
              border: isDark ? null : Border.all(color: AppColors.slate200),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'No team members assigned',
                  style: AppTypography.body2.copyWith(
                    color:
                        isDark ? AppColors.darkTextMuted : AppColors.slate400,
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            padding: AppSpacing.cardInsets,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.white,
              borderRadius: AppSpacing.borderRadiusLg,
              border: isDark ? null : Border.all(color: AppColors.slate200),
            ),
            child: Column(
              children: project.teamMembers.asMap().entries.map((entry) {
                final index = entry.key;
                final member = entry.value;
                return _TeamMemberTile(
                  member: member,
                  isDark: isDark,
                  isLast: index == project.teamMembers.length - 1,
                  onRemove: () => onRemoveMember(member.id),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _TeamMemberTile extends StatelessWidget {
  const _TeamMemberTile({
    required this.member,
    required this.isDark,
    required this.isLast,
    required this.onRemove,
  });

  final TeamMember member;
  final bool isDark;
  final bool isLast;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                isDark ? AppColors.darkSurfaceHigh : AppColors.slate200,
            child: Text(
              member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
              style: AppTypography.body1.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          AppSpacing.horizontalSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: AppTypography.body1.copyWith(
                    color:
                        isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                  ),
                ),
                if (member.role != null)
                  Text(
                    member.role!,
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.remove_circle_outline,
              color: isDark ? AppColors.darkRose : AppColors.rose500,
            ),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AvailableUsersSection extends StatelessWidget {
  const _AvailableUsersSection({
    required this.project,
    required this.isDark,
    required this.availableUsersAsync,
    required this.onSelectUser,
    required this.onCancel,
  });

  final Project project;
  final bool isDark;
  final AsyncValue<List<User>> availableUsersAsync;
  final void Function(User user) onSelectUser;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Select Member to Add',
              style: AppTypography.headline3.copyWith(
                color: isDark ? AppColors.darkTextPrimary : AppColors.slate900,
              ),
            ),
            TextButton(
              onPressed: onCancel,
              child: Text(
                'Cancel',
                style: AppTypography.button.copyWith(
                  color:
                      isDark ? AppColors.darkTextSecondary : AppColors.slate700,
                ),
              ),
            ),
          ],
        ),
        AppSpacing.verticalSm,
        Container(
          padding: AppSpacing.cardInsets,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.white,
            borderRadius: AppSpacing.borderRadiusLg,
            border: isDark ? null : Border.all(color: AppColors.slate200),
          ),
          child: availableUsersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text(
                  'Error loading users',
                  style: AppTypography.body2.copyWith(
                    color: isDark ? AppColors.darkRose : AppColors.rose500,
                  ),
                ),
              ),
            ),
            data: (users) {
              // Filter out users already on the team
              final existingMemberIds =
                  project.teamMembers.map((m) => m.id).toSet();
              final availableUsers = users
                  .where((u) => !existingMemberIds.contains(u.id))
                  .toList();

              if (availableUsers.isEmpty) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    child: Text(
                      'No available users to add',
                      style: AppTypography.body2.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.slate400,
                      ),
                    ),
                  ),
                );
              }

              return Column(
                children: availableUsers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  return _AvailableUserTile(
                    user: user,
                    isDark: isDark,
                    isLast: index == availableUsers.length - 1,
                    onSelect: () => onSelectUser(user),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AvailableUserTile extends StatelessWidget {
  const _AvailableUserTile({
    required this.user,
    required this.isDark,
    required this.isLast,
    required this.onSelect,
  });

  final User user;
  final bool isDark;
  final bool isLast;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor:
                  isDark ? AppColors.darkSurfaceHigh : AppColors.slate200,
              child: Text(
                user.initials,
                style: AppTypography.body1.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            AppSpacing.horizontalSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: AppTypography.body1.copyWith(
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.slate900,
                    ),
                  ),
                  Text(
                    _roleToString(user.role),
                    style: AppTypography.caption.copyWith(
                      color:
                          isDark ? AppColors.darkTextMuted : AppColors.slate400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.add_circle_outline,
              color: isDark ? AppColors.darkOrange : AppColors.orange500,
            ),
          ],
        ),
      ),
    );
  }

  String _roleToString(UserRole role) {
    return switch (role) {
      UserRole.admin => 'Admin',
      UserRole.manager => 'Manager',
      UserRole.fieldWorker => 'Field Worker',
    };
  }
}
