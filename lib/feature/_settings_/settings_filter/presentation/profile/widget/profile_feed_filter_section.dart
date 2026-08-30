import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/settings_filter/data/catalog/filter_catalog.dart';
import 'package:clover/feature/settings_filter/data/repository/filter_repository.dart';
import 'package:clover/feature/settings_filter/presentation/profile/cubit/profile_filter_cubit.dart';
import 'package:clover/feature/settings_filter/presentation/profile/filter_selection_sheet.dart';
import 'package:clover/feature/settings_filter/presentation/profile/widget/profile_active_filters_row.dart';
import 'package:clover/feature/settings_filter/presentation/profile/widget/profile_filter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Табы ленты профиля + кнопка фильтра и строка активных значений.
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
  });

  final List<String> tabs;
  final int currentTabIndex;
  final ValueChanged<int> onTabChanged;
  final bool hasFilters;
  final String? profileId;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>>? onSelectedValuesChanged;

  @override
  State<ProfileFeedFilterSection> createState() => _ProfileFeedFilterSectionState();
}

class _ProfileFeedFilterSectionState extends State<ProfileFeedFilterSection> {
  late final ProfileFilterCubit _filterCubit;
  late Set<String> _selected = Set<String>.of(widget.selectedValues);

  @override
  void initState() {
    super.initState();
    _filterCubit = sl<ProfileFilterCubit>();
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
        message: 'Не удалось загрузить фильтры',
        kind: AppSnackBarKind.error,
      );
    }
  }

  void _clearFilters() {
    setState(() => _selected = {});
    widget.onSelectedValuesChanged?.call({});
  }

  @override
  Widget build(BuildContext context) {
    final labels = FilterCatalog.selectionLabels(_selected);
    final showFilterButton = widget.hasFilters;

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
          ],
        ),
        if (_selected.isNotEmpty) ...[
          SizedBox(height: context.heightByContext(10)),
          ProfileActiveFiltersRow(labels: labels, onClear: _clearFilters),
        ],
      ],
    );
  }
}
