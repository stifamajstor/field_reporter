import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../widgets/buttons/primary_button.dart';

/// A modal bottom sheet for picking a location.
class LocationPicker extends StatefulWidget {
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
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _addressController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _address;

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

              // Map placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkSurfaceHigh : AppColors.slate100,
                  borderRadius: AppSpacing.borderRadiusLg,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.slate200,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 48,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.slate400,
                      ),
                      AppSpacing.verticalSm,
                      Text(
                        _address ?? 'Tap to select location on map',
                        style: AppTypography.body2.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.slate700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
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
}
