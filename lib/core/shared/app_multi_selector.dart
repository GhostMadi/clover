import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:flutter/material.dart';

/// Элемент списка для [AppMultiSelect].
class AppMultiSelectOption<T> {
  const AppMultiSelectOption({
    required this.value,
    required this.label,
    this.service,
  });

  final T value;
  final String label;

  /// Акцент сервиса (силовые теги и т.п.) — красит строку в шторке.
  final AppServiceKind? service;
}

/// Секция с заголовком для [AppMultiSelect].
class AppMultiSelectGroup<T> {
  const AppMultiSelectGroup({required this.title, required this.options});

  final String title;
  final List<AppMultiSelectOption<T>> options;
}

/// Поле с множественным выбором: по тапу — шторка с поиском и списком (опционально с группами).
class AppMultiSelect<T> extends StatelessWidget {
  AppMultiSelect({
    super.key,
    this.label,
    required this.hint,
    this.options = const [],
    this.groups = const [],
    required this.values,
    required this.onChanged,
    this.searchHint = 'Поиск',
    this.sheetTitle,
    this.confirmLabel = 'Готово',
    this.emptySelectionHint,
  }) : assert(groups.isNotEmpty || options.isNotEmpty, 'Provide options or groups');

  /// Подпись над полем (опционально).
  final String? label;

  /// Текст, когда ничего не выбрано.
  final String hint;

  /// Плоский список (если [groups] пуст).
  final List<AppMultiSelectOption<T>> options;

  /// Группы: заголовок + список. Если не пуст — [options] в шторке не используется.
  final List<AppMultiSelectGroup<T>> groups;

  final Set<T> values;
  final ValueChanged<Set<T>> onChanged;

  final String searchHint;
  final String? sheetTitle;
  final String confirmLabel;

  /// Подсказка в поле, когда выбрано 0 (перекрывает [hint] только для отображения счётчика).
  final String? emptySelectionHint;

  static const double _radius = 12;
  static const double _sheetHeightFactor = 0.58;

  static double _contentHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height * _sheetHeightFactor;
  }

  Future<Set<T>?> _showSheet(BuildContext context) {
    return AppBottomSheet.show<Set<T>>(
      context: context,
      title: sheetTitle ?? label ?? hint,
      upperCaseTitle: false,
      showCloseButton: true,
      contentHeight: _contentHeight(context),
      contentBottomSpacing: 12,
      content: AppMultiSelectSheetContent<T>(
        searchHint: searchHint,
        options: _hasGroups ? const [] : options,
        groups: _hasGroups ? groups : const [],
        selected: values,
        confirmLabel: confirmLabel,
      ),
    );
  }

  bool get _hasGroups => groups.isNotEmpty;

  List<AppMultiSelectOption<T>> get _allOptions {
    if (_hasGroups) {
      return groups.expand((g) => g.options).toList(growable: false);
    }
    return options;
  }

  String? _selectedDisplay() {
    if (values.isEmpty) return null;

    final labels = <String>[];
    for (final o in _allOptions) {
      if (values.contains(o.value)) labels.add(o.label);
    }
    if (labels.isEmpty) return null;
    return labels.join(', ');
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await _showSheet(context);
    if (!context.mounted || picked == null) return;
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final display = _selectedDisplay();
    final hasValue = display != null && display.isNotEmpty;
    final canOpen = _allOptions.isNotEmpty;

    final field = Material(
      color: colors.fieldBackground,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: canOpen ? () => _openSheet(context) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: colors.fieldBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? display : (emptySelectionHint ?? hint),
                  style: AppTextStyle.base(
                    16,
                    color: hasValue ? colors.textColor : colors.subTextColor.withValues(alpha: 0.65),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                AppIcons.arrowDown.icon,
                color: colors.subTextColor.withValues(alpha: 0.55),
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
            style: AppTextStyle.base(14, color: colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
        ],
        field,
      ],
    );
  }

  /// Открыть только шторку (без поля над формой).
  static Future<Set<T>?> showSheet<T>({
    required BuildContext context,
    required String title,
    List<AppMultiSelectOption<T>> options = const [],
    List<AppMultiSelectGroup<T>> groups = const [],
    Set<T> selected = const {},
    String searchHint = 'Поиск',
    String confirmLabel = 'Готово',
    AppServiceKind? service,
  }) async {
    assert(groups.isNotEmpty || options.isNotEmpty, 'Provide options or groups');

    return AppBottomSheet.show<Set<T>>(
      context: context,
      title: title,
      upperCaseTitle: false,
      showCloseButton: true,
      contentHeight: _contentHeight(context),
      contentBottomSpacing: 12,
      service: service,
      content: AppMultiSelectSheetContent<T>(
        searchHint: searchHint,
        options: groups.isNotEmpty ? const [] : options,
        groups: groups,
        selected: selected,
        confirmLabel: confirmLabel,
        service: service,
      ),
    );
  }
}

/// Контент шторки: поиск + список (плоский или с группами) + «Готово».
class AppMultiSelectSheetContent<T> extends StatefulWidget {
  const AppMultiSelectSheetContent({
    super.key,
    required this.searchHint,
    required this.options,
    required this.groups,
    required this.selected,
    required this.confirmLabel,
    this.service,
  });

  final String searchHint;
  final List<AppMultiSelectOption<T>> options;
  final List<AppMultiSelectGroup<T>> groups;
  final Set<T> selected;
  final String confirmLabel;
  final AppServiceKind? service;

  @override
  State<AppMultiSelectSheetContent<T>> createState() => _AppMultiSelectSheetContentState<T>();
}

class _AppMultiSelectSheetContentState<T> extends State<AppMultiSelectSheetContent<T>> {
  late final TextEditingController _search;
  late Set<T> _selected;
  String _query = '';

  bool get _hasGroups => widget.groups.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController();
    _selected = Set<T>.of(widget.selected);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _normalizedQuery => _query.trim().toLowerCase();

  bool _matchesQuery(String label) {
    final q = _normalizedQuery;
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q);
  }

  List<AppMultiSelectOption<T>> get _filteredFlat {
    return widget.options.where((e) => _matchesQuery(e.label)).toList(growable: false);
  }

  List<AppMultiSelectGroup<T>> get _filteredGroups {
    if (!_hasGroups) return const [];

    return widget.groups
        .map((group) {
          final items = group.options.where((e) => _matchesQuery(e.label)).toList(growable: false);
          if (items.isEmpty) return null;
          return AppMultiSelectGroup<T>(title: group.title, options: items);
        })
        .whereType<AppMultiSelectGroup<T>>()
        .toList(growable: false);
  }

  bool get _isEmpty {
    if (_hasGroups) return _filteredGroups.isEmpty;
    return _filteredFlat.isEmpty;
  }

  void _toggle(T value) {
    setState(() {
      if (_selected.contains(value)) {
        _selected.remove(value);
      } else {
        _selected.add(value);
      }
    });
  }

  void _confirm() => Navigator.pop(context, _selected);

  Widget _optionTile(AppMultiSelectOption<T> option, AppPalette colors) {
    final isSelected = _selected.contains(option.value);
    final accent = option.service != null ? colors.serviceAccent(option.service!) : null;
    final checkColor = accent?.icon ??
        (widget.service != null
            ? colors.serviceAccent(widget.service!).icon
            : colors.btnBackground);
    final titleColor = accent?.icon ?? colors.textColor;

    return Material(
      color: accent != null && isSelected
          ? accent.soft
          : (accent != null ? accent.soft.withValues(alpha: 0.35) : Colors.transparent),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          option.label,
          style: AppTextStyle.base(
            16,
            color: titleColor,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        trailing: isSelected ? Icon(AppIcons.checkRounded.icon, color: checkColor, size: 22) : null,
        onTap: () => _toggle(option.value),
      ),
    );
  }

  Widget _groupHeader(String title, AppPalette colors, {required bool isFirst}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4, isFirst ? 4 : 20, 4, 8),
      child: Text(
        title,
        style: AppTextStyle.base(13, color: colors.subTextColor, fontWeight: FontWeight.w600, height: 1.2),
      ),
    );
  }

  List<Widget> _buildGroupedListItems(AppPalette colors) {
    final items = <Widget>[];
    for (var i = 0; i < _filteredGroups.length; i++) {
      final group = _filteredGroups[i];
      items.add(_groupHeader(group.title, colors, isFirst: i == 0));
      for (var j = 0; j < group.options.length; j++) {
        items.add(_optionTile(group.options[j], colors));
        if (j < group.options.length - 1) {
          items.add(Divider(height: 1, color: colors.border.withValues(alpha: 0.6)));
        }
      }
    }
    return items;
  }

  List<Widget> _buildFlatListItems(AppPalette colors) {
    final filtered = _filteredFlat;
    final items = <Widget>[];
    for (var i = 0; i < filtered.length; i++) {
      items.add(_optionTile(filtered[i], colors));
      if (i < filtered.length - 1) {
        items.add(Divider(height: 1, color: colors.border.withValues(alpha: 0.6)));
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          hintText: widget.searchHint,
          controller: _search,
          prefixIcon: AppIcons.searchRounded.icon,
          textInputAction: TextInputAction.search,
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Ничего не найдено',
                      style: AppTextStyle.base(14, color: colors.subTextColor),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 8),
                  children: _hasGroups ? _buildGroupedListItems(colors) : _buildFlatListItems(colors),
                ),
        ),
        const SizedBox(height: 8),
        AppButton(
          text: widget.confirmLabel,
          isExpanded: true,
          service: widget.service,
          onTap: _confirm,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
