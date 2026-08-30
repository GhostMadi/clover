import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_multi_selector.dart';
import 'package:clover/feature/_settings_/settings_filter/data/catalog/filter_catalog.dart';
import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:clover/feature/_settings_/settings_filter/data/repository/filter_repository.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Множественный выбор значений из категорий фильтров профиля (шаг публикации поста).
class PostCreateFilterField extends StatefulWidget {
  const PostCreateFilterField({
    super.key,
    required this.values,
    required this.onChanged,
    this.enabled = true,
  });

  final Set<String> values;
  final ValueChanged<Set<String>> onChanged;
  final bool enabled;

  @override
  State<PostCreateFilterField> createState() => _PostCreateFilterFieldState();
}

class _PostCreateFilterFieldState extends State<PostCreateFilterField> {
  final _repository = sl<FilterRepository>();

  List<FilterCategory> _categories = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    if (uid == null || uid.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _categories = const [];
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repository.listCategories(uid);
      if (!mounted) return;
      setState(() {
        _categories = items;
        _loading = false;
      });
    } on FilterRepositoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить фильтры';
      });
    }
  }

  Set<String> _normalizeValues() {
    if (widget.values.isEmpty || _categories.isEmpty) return const {};

    final known = <String>{
      for (final category in _categories)
        for (final value in category.values) FilterCatalog.selectionValue(category.id, value),
    };
    return widget.values.where(known.contains).toSet();
  }

  List<AppMultiSelectGroup<String>> get _groups => FilterCatalog.multiSelectGroups(_categories);

  Future<void> _openSheet() async {
    if (_categories.isEmpty || !widget.enabled) return;

    final picked = await AppMultiSelect.showSheet<String>(
      context: context,
      title: 'Фильтры публикации',
      groups: _groups,
      selected: _normalizeValues(),
      searchHint: 'Поиск по фильтрам',
      confirmLabel: 'Готово',
    );

    if (!mounted || picked == null) return;
    widget.onChanged(picked);
  }

  void _removeValue(String value) {
    if (!widget.enabled) return;
    widget.onChanged(widget.values.where((item) => item != value).toSet());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _SectionShell(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)),
          ),
        ),
      );
    }

    if (_error != null) {
      return _SectionShell(
        child: Text(_error!, style: AppTextStyle.base(13, color: context.colors.subTextColor)),
      );
    }

    if (_categories.isEmpty) return const SizedBox.shrink();

    final selected = _normalizeValues();
    final labels = FilterCatalog.selectionLabels(selected);
    final canOpen = widget.enabled;

    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.55,
        child: _SectionShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: context.colors.fieldBackground,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: canOpen ? _openSheet : null,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: selected.isEmpty
                                ? context.colors.surfaceSoft
                                : context.colors.successSoft.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            AppIcons.tune.icon,
                            size: 20,
                            color: selected.isEmpty ? context.colors.iconMuted : context.colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selected.isEmpty ? 'Выберите фильтры' : 'Фильтры выбраны',
                                style: AppTextStyle.base(
                                  15,
                                  color: context.colors.textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selected.isEmpty
                                    ? 'Размер, цвет, бренд и другие категории'
                                    : '${selected.length} ${_countLabel(selected.length)}',
                                style: AppTextStyle.base(13, color: context.colors.subTextColor),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          AppIcons.arrowDown.icon,
                          color: context.colors.subTextColor.withValues(alpha: 0.55),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (labels.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final entry in selected)
                      InputChip(
                        label: Text(
                          FilterCatalog.selectionLabel(entry),
                          style: AppTextStyle.base(
                            13,
                            color: context.colors.textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        deleteIcon: Icon(AppIcons.closeRounded.icon, size: 16),
                        onDeleted: canOpen ? () => _removeValue(entry) : null,
                        backgroundColor: context.colors.surfaceSoft,
                        side: BorderSide(color: context.colors.border.withValues(alpha: 0.7)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _countLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;
    if (mod100 >= 11 && mod100 <= 14) return 'значений';
    if (mod10 == 1) return 'значение';
    if (mod10 >= 2 && mod10 <= 4) return 'значения';
    return 'значений';
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            'Фильтры',
            style: AppTextStyle.base(
              13,
              fontWeight: FontWeight.w600,
              color: context.colors.fieldLabel,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
