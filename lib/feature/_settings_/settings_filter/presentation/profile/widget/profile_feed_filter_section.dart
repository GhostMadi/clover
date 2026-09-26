import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/_settings_/settings_filter/data/catalog/filter_catalog.dart';
import 'package:clover/feature/_settings_/settings_filter/data/repository/filter_repository.dart';
import 'package:clover/feature/_settings_/settings_filter/presentation/profile/cubit/profile_filter_cubit.dart';
import 'package:clover/feature/_settings_/settings_filter/presentation/profile/filter_selection_sheet.dart';
import 'package:clover/feature/_settings_/settings_filter/presentation/profile/widget/profile_active_filters_row.dart';
import 'package:clover/feature/_settings_/settings_filter/presentation/profile/widget/profile_filter_button.dart';
import 'package:clover/feature/_settings_/settings_filter/presentation/profile/widget/profile_location_filter_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Табы ленты профиля + кнопки фильтра (витрина + местоположение).
class ProfileFeedFilterSection extends StatefulWidget {
  const ProfileFeedFilterSection({
    super.key,
    required this.tabs,
    required this.currentTabIndex,
    required this.onTabChanged,
    required this.hasFilters,
    this.profileId,
    this.selectedValues = const {},
    this.onSelectedValuesChanged,
    this.selectedLocationId,
    this.onSelectedLocationChanged,
  });

  final List<String> tabs;
  final int currentTabIndex;
  final ValueChanged<int> onTabChanged;
  final bool hasFilters;
  final String? profileId;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>>? onSelectedValuesChanged;
  final String? selectedLocationId;
  final ValueChanged<String?>? onSelectedLocationChanged;

  @override
  State<ProfileFeedFilterSection> createState() => _ProfileFeedFilterSectionState();
}

class _ProfileFeedFilterSectionState extends State<ProfileFeedFilterSection> {
  late final ProfileFilterCubit _filterCubit;
  late Set<String> _selected = Set<String>.of(widget.selectedValues);
  String? _locationId;

  @override
  void initState() {
    super.initState();
    _filterCubit = sl<ProfileFilterCubit>();
    _locationId = widget.selectedLocationId?.trim();
    if (_locationId != null && _locationId!.isEmpty) _locationId = null;
  }

  @override
  void dispose() {
    _filterCubit.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileFeedFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _selected = Set<String>.of(widget.selectedValues);
    }
    if (oldWidget.selectedLocationId != widget.selectedLocationId) {
      final next = widget.selectedLocationId?.trim();
      _locationId = (next == null || next.isEmpty) ? null : next;
    }
    if (oldWidget.profileId != widget.profileId) {
      _filterCubit.invalidate();
    }
  }

  Future<void> _openFilters() async {
    final profileId = widget.profileId?.trim();
    if (profileId == null || profileId.isEmpty) return;

    try {
      final categories = await _filterCubit.ensureLoaded(profileId);
      if (!mounted || categories.isEmpty) return;

      final picked = await FilterSelectionSheet.show(
        context,
        categories: categories,
        selected: _selected,
      );
      if (!mounted || picked == null) return;
      setState(() => _selected = picked);
      widget.onSelectedValuesChanged?.call(picked);
    } on FilterRepositoryException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: e.message, kind: AppSnackBarKind.error);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: context.l10n.settings_filters_load_failed,
        kind: AppSnackBarKind.error,
      );
    }
  }

  Future<void> _openLocationFilter() async {
    final profileId = widget.profileId?.trim();
    if (profileId == null || profileId.isEmpty) return;

    final picked = await ProfileLocationFilterSheet.show(
      context,
      profileId: profileId,
      selectedLocationId: _locationId,
    );
    if (!mounted || picked == null) return;

    final next = picked.trim().isEmpty ? null : picked.trim();
    setState(() => _locationId = next);
    widget.onSelectedLocationChanged?.call(next);
  }

  void _clearFilters() {
    setState(() => _selected = {});
    widget.onSelectedValuesChanged?.call({});
  }

  void _clearLocation() {
    setState(() => _locationId = null);
    widget.onSelectedLocationChanged?.call(null);
  }

  @override
  Widget build(BuildContext context) {
    final labels = FilterCatalog.selectionLabels(_selected);
    final showFilterButton = widget.hasFilters;
    final hasLocation = _locationId != null && _locationId!.isNotEmpty;
    final showLocationButton = widget.profileId != null && widget.profileId!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AppTab(
                tabs: widget.tabs,
                currentIndex: widget.currentTabIndex,
                onTabChanged: widget.onTabChanged,
                height: ProfileFilterButton.size,
              ),
            ),
            if (showFilterButton) ...[
              SizedBox(width: context.widthByContext(8)),
              BlocBuilder<ProfileFilterCubit, ProfileFilterState>(
                bloc: _filterCubit,
                builder: (context, state) {
                  return ProfileFilterButton(
                    activeCount: _selected.length,
                    isLoading: state is ProfileFilterLoading,
                    onTap: state is ProfileFilterLoading ? null : _openFilters,
                  );
                },
              ),
            ],
            if (showLocationButton) ...[
              SizedBox(width: context.widthByContext(8)),
              ProfileFilterButton(
                activeCount: hasLocation ? 1 : 0,
                icon: AppIcons.locationOn.icon,
                onTap: _openLocationFilter,
              ),
            ],
          ],
        ),
        if (_selected.isNotEmpty) ...[
          SizedBox(height: context.heightByContext(10)),
          ProfileActiveFiltersRow(labels: labels, onClear: _clearFilters),
        ],
        if (hasLocation) ...[
          SizedBox(height: context.heightByContext(10)),
          ProfileActiveFiltersRow(
            labels: [context.l10n.catalog_location],
            onClear: _clearLocation,
          ),
        ],
      ],
    );
  }
}
