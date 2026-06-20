import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/settings/presentation/widget/settings_tile_section.dart';
import 'package:clover/feature/settings_filter/data/models/filter_category.dart';
import 'package:clover/feature/settings_filter/presentation/settings/cubit/settings_filters_cubit.dart';
import 'package:clover/feature/settings_filter/presentation/settings/widget/filter_category_card.dart';
import 'package:clover/feature/settings_filter/presentation/settings/widget/filter_category_editor_sheet.dart';
import 'package:clover/feature/settings_filter/presentation/settings/widget/filter_settings_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsFiltersPage extends StatefulWidget {
  const SettingsFiltersPage({super.key});

  @override
  State<SettingsFiltersPage> createState() => _SettingsFiltersPageState();
}

class _SettingsFiltersPageState extends State<SettingsFiltersPage> {
  late final SettingsFiltersCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<SettingsFiltersCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _createCategory() async {
    final draft = await FilterCategoryEditorSheet.showCreate(context);
    if (draft == null || !mounted) return;
    await _saveDraft(draft);
  }

  Future<void> _editCategory(FilterCategory category) async {
    final draft = await FilterCategoryEditorSheet.showEdit(context, category: category);
    if (draft == null || !mounted) return;
    await _saveDraft(draft);
  }

  Future<void> _saveDraft(FilterCategory draft) async {
    final error = await _cubit.upsert(draft);
    if (!mounted || error == null) return;
    AppSnackBar.show(context, message: error, kind: AppSnackBarKind.error);
  }

  void _requestDeleteCategory(FilterCategory category) {
    AppSnackBar.show(
      context,
      title: 'Удаление',
      message: 'Нажмите, чтобы удалить «${category.name}»',
      kind: AppSnackBarKind.error,
      duration: const Duration(seconds: 5),
      onTap: () async {
        if (!mounted) return;
        final error = await _cubit.deleteCategory(category.id);
        if (!mounted) return;
        if (error != null) {
          AppSnackBar.show(context, message: error, kind: AppSnackBarKind.error);
          return;
        }
        AppSnackBar.show(context, message: '«${category.name}» удалена', kind: AppSnackBarKind.success);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: 'Фильтры',
        body: BlocBuilder<SettingsFiltersCubit, SettingsFiltersState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => _SettingsFiltersError(message: message, onRetry: _cubit.load),
              loaded: (categories, isMutating) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoftGreen.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderCardGreen.withValues(alpha: 0.8)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Категории фильтров',
                            style: AppTextStyle.base(
                              15,
                              color: AppColors.textColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Создайте категорию, укажите название и добавьте варианты значений. После первой категории фильтр появится в профиле.',
                            style: AppTextStyle.base(13, color: AppColors.subTextColor, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      text: 'Создать категорию',
                      isExpanded: true,
                      isLoading: isMutating,
                      onTap: isMutating ? null : _createCategory,
                    ),
                    const SizedBox(height: 20),
                    SettingsTileSectionTitle('Сохранённые категории (${categories.length})'),
                    if (categories.isEmpty)
                      FilterSettingsEmptyState(onCreate: isMutating ? () {} : _createCategory)
                    else
                      Column(
                        children: [
                          for (var i = 0; i < categories.length; i++) ...[
                            FilterCategoryCard(
                              category: categories[i],
                              onTap: isMutating ? () {} : () => _editCategory(categories[i]),
                              onDelete: isMutating ? () {} : () => _requestDeleteCategory(categories[i]),
                            ),
                            if (i < categories.length - 1) const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SettingsFiltersError extends StatelessWidget {
  const _SettingsFiltersError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.base(14, color: AppColors.subTextColor),
          ),
          const SizedBox(height: 16),
          AppButton(text: 'Повторить', isExpanded: true, onTap: onRetry),
        ],
      ),
    );
  }
}
