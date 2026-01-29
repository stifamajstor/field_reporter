import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/tenant.dart';
import '../providers/tenant_provider.dart';

/// Screen for selecting a tenant when user belongs to multiple organizations.
///
/// Follows the "Confident Clarity" design philosophy.
class TenantSelectionScreen extends ConsumerWidget {
  const TenantSelectionScreen({
    super.key,
    this.onTenantSelected,
    this.isLoading = false,
  });

  /// Callback invoked when a tenant is selected.
  final VoidCallback? onTenantSelected;

  /// Whether the screen is loading tenants.
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final tenants = ref.watch(availableTenantsProvider);

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSpacing.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Text(
                    'Select Organization',
                    style: AppTypography.headline1.copyWith(
                      color: AppColors.textPrimary(brightness),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalSm,
                  Text(
                    'Choose which organization to access',
                    style: AppTypography.body1.copyWith(
                      color: AppColors.textSecondary(brightness),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.verticalXl,

                  // Loading or tenant list
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ...tenants.map(
                      (tenant) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.listItemSpacing,
                        ),
                        child: _TenantItem(
                          key: Key('tenant_item_${tenant.id}'),
                          tenant: tenant,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(selectedTenantProvider.notifier)
                                .selectTenant(tenant);
                            onTenantSelected?.call();
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual tenant item in the selection list.
class _TenantItem extends StatelessWidget {
  const _TenantItem({
    super.key,
    required this.tenant,
    required this.onTap,
  });

  final Tenant tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.cardInsets,
        decoration: BoxDecoration(
          color: AppColors.surface(brightness),
          borderRadius: AppSpacing.borderRadiusLg,
          border: brightness == Brightness.light
              ? Border.all(color: AppColors.border(brightness))
              : null,
        ),
        child: Row(
          children: [
            // Organization icon
            Container(
              width: AppSpacing.touchTargetMin,
              height: AppSpacing.touchTargetMin,
              decoration: BoxDecoration(
                color: brightness == Brightness.dark
                    ? AppColors.darkOrangeSubtle
                    : AppColors.orange50,
                borderRadius: AppSpacing.borderRadiusMd,
              ),
              child: Center(
                child: Text(
                  tenant.name.isNotEmpty ? tenant.name[0].toUpperCase() : '?',
                  style: AppTypography.headline2.copyWith(
                    color: AppColors.primary(brightness),
                  ),
                ),
              ),
            ),
            AppSpacing.horizontalMd,
            // Tenant name
            Expanded(
              child: Text(
                tenant.name,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary(brightness),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Chevron
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted(brightness),
              size: AppSpacing.iconSize,
            ),
          ],
        ),
      ),
    );
  }
}
