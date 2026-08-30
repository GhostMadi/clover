import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_single_selctor.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:flutter/material.dart';

/// Одиночный выбор активного местоположения пользователя.
class LocationSingleSelectField extends StatefulWidget {
  const LocationSingleSelectField({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
    this.searchHint = 'Поиск адреса',
    this.sheetTitle,
    this.enabled = true,
  });

  final String? label;
  final String hint;

  /// Id местоположения (`locations.id`).
  final String? value;
  final ValueChanged<LocationModel> onChanged;
  final String searchHint;
  final String? sheetTitle;
  final bool enabled;

  @override
  State<LocationSingleSelectField> createState() => _LocationSingleSelectFieldState();
}

class _LocationSingleSelectFieldState extends State<LocationSingleSelectField> {
  final _repository = sl<LocationRepository>();

  List<LocationModel> _locations = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _repository.listMine();
      if (!mounted) return;

      setState(() {
        _locations = items.where((item) => item.isActive).toList(growable: false);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить местоположения';
      });
    }
  }

  List<AppSingleSelectOption<String>> get _options {
    return _locations
        .map(
          (location) => AppSingleSelectOption<String>(
            value: location.id,
            label: _optionLabel(location),
          ),
        )
        .toList(growable: false);
  }

  String _optionLabel(LocationModel location) {
    final title = location.displayTitle;
    final subtitle = location.displaySubtitle.trim();
    if (subtitle.isEmpty || subtitle == title) return title;
    return '$title · $subtitle';
  }

  String? _normalizeValue(String? id) {
    final trimmed = id?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    for (final location in _locations) {
      if (location.id == trimmed) return trimmed;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2)),
            ),
          ),
        ],
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Text(
              widget.label!,
              style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
          ],
          Text(_error!, style: AppTextStyle.base(13, color: context.colors.subTextColor)),
        ],
      );
    }

    final emptyHint = _locations.isEmpty ? 'Нет активных местоположений' : widget.hint;

    return AbsorbPointer(
      absorbing: !widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.55,
        child: AppSingleSelect<String>(
          label: widget.label,
          hint: emptyHint,
          sheetTitle: widget.sheetTitle ?? widget.label ?? 'Местоположение',
          searchHint: widget.searchHint,
          options: _options,
          value: _normalizeValue(widget.value),
          onChanged: (id) {
            for (final location in _locations) {
              if (location.id == id) {
                widget.onChanged(location);
                return;
              }
            }
          },
        ),
      ),
    );
  }
}
