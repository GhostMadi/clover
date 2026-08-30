import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/feature/_settings_/settings_filter/data/models/filter_category.dart';
import 'package:flutter/material.dart';

abstract final class FilterCategoryEditorSheet {
  static Future<FilterCategory?> showCreate(BuildContext context) {
    return show(context, title: 'Новая категория');
  }

  static Future<FilterCategory?> showEdit(
    BuildContext context, {
    required FilterCategory category,
  }) {
    return show(context, title: 'Редактировать категорию', initial: category);
  }

  static Future<FilterCategory?> show(
    BuildContext context, {
    required String title,
    FilterCategory? initial,
  }) {
    return AppBottomSheet.show<FilterCategory>(
      context: context,
      title: title,
      showCloseButton: true,
      contentBottomSpacing: 0,
      content: _FilterCategoryEditor(initial: initial),
    );
  }
}

class _FilterCategoryEditor extends StatefulWidget {
  const _FilterCategoryEditor({this.initial});

  final FilterCategory? initial;

  @override
  State<_FilterCategoryEditor> createState() => _FilterCategoryEditorState();
}

class _FilterCategoryEditorState extends State<_FilterCategoryEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _valueController;
  late List<String> _values;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _valueController = TextEditingController();
    _values = [...?widget.initial?.values];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    return name.isNotEmpty && _values.isNotEmpty;
  }

  void _addValue() {
    final value = _valueController.text.trim();
    if (value.isEmpty) return;
    if (_values.any((v) => v.toLowerCase() == value.toLowerCase())) {
      _valueController.clear();
      return;
    }
    setState(() {
      _values = [..._values, value];
      _valueController.clear();
    });
  }

  void _removeValue(String value) {
    setState(() => _values = _values.where((v) => v != value).toList());
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      FilterCategory(
        id: widget.initial?.id ?? '',
        name: _nameController.text.trim(),
        values: List.unmodifiable(_values),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          controller: _nameController,
          labelText: 'Название категории',
          hintText: 'Например: Размер, Цвет, Бренд',
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        Text(
          'Значения',
          style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppField(
                controller: _valueController,
                hintText: 'XS, Черный, Nike…',
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _addValue,
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: Icon(Icons.add_rounded, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_values.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
            ),
            child: Text(
              'Добавьте хотя бы одно значение',
              style: AppTextStyle.base(13, color: AppColors.subTextColor, fontWeight: FontWeight.w500),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in _values)
                InputChip(
                  label: Text(
                    value,
                    style: AppTextStyle.base(13, color: AppColors.textColor, fontWeight: FontWeight.w600),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 18),
                  onDeleted: () => _removeValue(value),
                  backgroundColor: AppColors.surfaceSoft,
                  side: BorderSide(color: AppColors.border.withValues(alpha: 0.7)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
            ],
          ),
        const SizedBox(height: 20),
        AppButton(
          text: widget.initial == null ? 'Сохранить категорию' : 'Сохранить изменения',
          isExpanded: true,
          onTap: _canSave ? _save : null,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
