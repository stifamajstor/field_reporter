import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../../../services/location_service.dart';
import '../../../../widgets/buttons/primary_button.dart';

/// A modal bottom sheet for picking a location.
class LocationPicker extends ConsumerStatefulWidget {
  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddress,
    required this.onLocationSelected,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialAddress;
  final void Function(double lat, double lng, String address)
      onLocationSelected;

  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  final _addressController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _address;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _latitude = widget.initialLatitude;
    _longitude = widget.initialLongitude;
    _address = widget.initialAddress;
    if (_address != null) {
      _addressController.text = _address!;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onAddressChanged(String value) {
    setState(() {
      _address = value;
      // In a real implementation, we would geocode the address
      // For now, set mock coordinates when address is entered
      if (value.isNotEmpty) {
        _latitude = 40.7128;
        _longitude = -74.0060;
      } else {
        _latitude = null;
        _longitude = null;
      }
    });
  }

  void _selectLocation() {
    if (_latitude != null && _longitude != null && _address != null) {
      widget.onLocationSelected(_latitude!, _longitude!, _address!);
    }
  }

  Future<void> _useCurrentLocation() async {
    final locationService = ref.read(locationServiceProvider);

    setState(() => _isLoadingLocation = true);

    try {
      // Check permission first
      var status = await locationService.checkPermission();

      if (status == LocationPermissionStatus.denied) {
        status = await locationService.requestPermission();
      }

      if (status == LocationPermissionStatus.permanentlyDenied) {
        if (mounted) {
          _showSettingsDialog();
        }
        return;
      }

      if (status == LocationPermissionStatus.serviceDisabled) {
        if (mounted) {
          _showServiceDisabledDialog();
        }
        return;
      }

      if (status != LocationPermissionStatus.granted) {
        return;
      }

      // Get current position
      final position = await locationService.getCurrentPosition();

      // Reverse geocode
      final address = await locationService.reverseGeocode(
        position.latitude,
        position.longitude,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _address = address;
          _addressController.text = address;
        });
      }
    } on LocationServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Location permission is permanently denied. Please enable it in Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(locationServiceProvider).openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
    );
  }

  void _showServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Please enable location services to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title
              Text(
                'Select Location',
                style: AppTypography.headline2.copyWith(
                  color:
                      isDark ? AppColors.darkTextPrimary : AppColors.slate900,
                ),
              ),
              AppSpacing.verticalMd,

              // Use Current Location button
              GestureDetector(
                onTap: _isLoadingLocation ? null : _useCurrentLocation,
                child: Container(
                  padding: AppSpacing.cardInsets,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                    borderRadius: AppSpacing.borderRadiusLg,
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.slate200,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_isLoadingLocation)
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.my_location,
                          color: AppColors.orange500,
                          size: 24,
                        ),
                      AppSpacing.horizontalMd,
                      Text(
                        'Use Current Location',
                        style: AppTypography.body1.copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.slate900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppSpacing.verticalMd,

              // Divider with "or"
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkBorder : AppColors.slate200,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'or',
                      style: AppTypography.caption.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.slate400,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: isDark ? AppColors.darkBorder : AppColors.slate200,
                    ),
                  ),
                ],
              ),
              AppSpacing.verticalMd,

              // Address search field
              TextField(
                key: const Key('address_search_field'),
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Search address',
                  hintText: 'Enter address or place name',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor:
                      isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
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
                onChanged: _onAddressChanged,
              ),
              AppSpacing.verticalMd,

              // Map preview with location
              Container(
                key: const Key('location_map_preview'),
                height: 200,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
                  ),
                ),
                child: _buildMapContent(isDark),
              ),
              AppSpacing.verticalLg,

              // Select button
              PrimaryButton(
                label: 'Select Location',
                onPressed: (_latitude != null && _address?.isNotEmpty == true)
                    ? _selectLocation
                    : null,
              ),
              AppSpacing.verticalMd,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapContent(bool isDark) {
    if (_latitude != null && _longitude != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_on,
            size: 48,
            color: AppColors.orange500,
          ),
          AppSpacing.verticalSm,
          Text(
            _address ?? '',
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          AppSpacing.verticalXs,
          Text(
            '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
            style: AppTypography.mono.copyWith(
              color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
            ),
          ),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_outlined,
            size: 48,
            color: isDark ? AppColors.darkTextMuted : AppColors.slate400,
          ),
          AppSpacing.verticalSm,
          Text(
            'Tap to select location on map',
            style: AppTypography.body2.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.slate700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
