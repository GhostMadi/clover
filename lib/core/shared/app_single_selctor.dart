import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:flutter/material.dart';

/// Элемент списка для [AppSingleSelect].
class AppSingleSelectOption<T> {
  const AppSingleSelectOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Поле с одним выбором: по тапу открывается шторка со строкой поиска и списком.
class AppSingleSelect<T> extends StatelessWidget {
  const AppSingleSelect({
    super.key,
    this.label,
    required this.hint,
    required this.options,
    required this.value,
    required this.onChanged,
    this.searchHint = 'Поиск',
    this.sheetTitle,
  });

  /// Подпись над полем (опционально).
  final String? label;

  /// Текст, когда значение не выбрано.
  final String hint;

  final List<AppSingleSelectOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;

  final String searchHint;
  final String? sheetTitle;

  static const double _radius = 12;

  String? _selectedLabel() {
    if (value == null) return null;
    for (final o in options) {
      if (o.value == value) return o.label;
    }
    return null;
  }

  Future<void> _openSheet(BuildContext context) async {
    final h = MediaQuery.sizeOf(context).height * 0.58;
    final picked = await AppBottomSheet.show<T>(
      context: context,
      title: sheetTitle ?? label ?? hint,
      upperCaseTitle: false,
      showCloseButton: true,
      contentHeight: h,
      content: AppSingleSelectSheetContent<T>(searchHint: searchHint, options: options, selected: value),
    );
    if (!context.mounted || picked == null) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final display = _selectedLabel();
    final hasValue = display != null && display.isNotEmpty;

    final field = Material(
      color: AppColors.fieldBackground,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: options.isEmpty ? null : () => _openSheet(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? display : hint,
                  style: AppTextStyle.base(
                    16,
                    color: hasValue ? AppColors.textColor : AppColors.subTextColor.withValues(alpha: 0.65),
                    height: 1.25,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.subTextColor.withValues(alpha: 0.55),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyle.base(14, color: AppColors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        field,
      ],
    );
  }

  /// Открыть только шторку со списком (без поля над формой).
  static Future<T?> showSheet<T>({
    required BuildContext context,
    required String title,
    required List<AppSingleSelectOption<T>> options,
    T? selected,
    String searchHint = 'Поиск',
  }) async {
    final h = MediaQuery.sizeOf(context).height * 0.58;
    return AppBottomSheet.show<T>(
      context: context,
      title: title,
      upperCaseTitle: false,
      showCloseButton: true,
      contentHeight: h,
      contentBottomSpacing: 0,
      content: AppSingleSelectSheetContent<T>(searchHint: searchHint, options: options, selected: selected),
    );
  }
}

/// Контент шторки: поиск + список (то же, что внутри [AppSingleSelect]).
class AppSingleSelectSheetContent<T> extends StatefulWidget {
  const AppSingleSelectSheetContent({
    super.key,
    required this.searchHint,
    required this.options,
    required this.selected,
  });

  final String searchHint;
  final List<AppSingleSelectOption<T>> options;
  final T? selected;

  @override
  State<AppSingleSelectSheetContent<T>> createState() => _AppSingleSelectSheetContentState<T>();
}

class _AppSingleSelectSheetContentState<T> extends State<AppSingleSelectSheetContent<T>> {
  late final TextEditingController _search;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<AppSingleSelectOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((e) => e.label.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          hintText: widget.searchHint,
          controller: _search,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ничего не найдено',
                      style: AppTextStyle.base(14, color: AppColors.subTextColor),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.only(bottom: 16 + bottom),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: AppColors.border.withValues(alpha: 0.6)),
                  itemBuilder: (context, i) {
                    final o = _filtered[i];
                    final isSelected = widget.selected == o.value;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Text(
                        o.label,
                        style: AppTextStyle.base(
                          16,
                          color: AppColors.textColor,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_rounded, color: AppColors.btnBackground, size: 22)
                          : null,
                      onTap: () => Navigator.pop(context, o.value),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
