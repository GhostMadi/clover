import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/session/app_session.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:flutter/material.dart';

/// Выбор местоположения для фильтра сетки постов (Ресурсы).
abstract final class ProfileLocationFilterSheet {
  /// Возвращает id места, `''` = сброс («Все»), `null` = закрыли без изменений.
  static Future<String?> show(
    BuildContext context, {
    required String profileId,
    String? selectedLocationId,
  }) {
    return AppBottomSheet.show<String>(
      context: context,
      title: 'Местоположение',
      contentHeight: MediaQuery.sizeOf(context).height * 0.55,
      service: kResourcesService,
      content: _ProfileLocationFilterBody(
        profileId: profileId,
        selectedLocationId: selectedLocationId,
      ),
    );
  }
}

class _ProfileLocationFilterBody extends StatefulWidget {
  const _ProfileLocationFilterBody({
    required this.profileId,
    this.selectedLocationId,
  });

  final String profileId;
  final String? selectedLocationId;

  @override
  State<_ProfileLocationFilterBody> createState() => _ProfileLocationFilterBodyState();
}

class _ProfileLocationFilterBodyState extends State<_ProfileLocationFilterBody> {
  bool _loading = true;
  String? _error;
  List<LocationModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final me = sl<AppSession>().userId?.trim();
    final profileId = widget.profileId.trim();
    final isOwn = me != null && me.isNotEmpty && me == profileId;

    if (!isOwn) {
      setState(() {
        _loading = false;
        _items = const [];
        _error = 'Фильтр по местам доступен на своём профиле';
      });
      return;
    }

    try {
      final all = await sl<LocationRepository>().listMine();
      final active = all.where((e) => e.isActive).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _items = active;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить места';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.serviceAccent(kResourcesService);
    final selected = widget.selectedLocationId?.trim();

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: accent.icon));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[
          Text(
            _error!,
            style: AppTextStyle.base(14, color: colors.subTextColor),
          ),
          const SizedBox(height: 12),
        ],
        Expanded(
          child: ListView(
            children: [
              _LocationTile(
                title: 'Все места',
                subtitle: 'Без фильтра по адресу',
                selected: selected == null || selected.isEmpty,
                onTap: () => Navigator.of(context).pop(''),
              ),
              ..._items.map(
                (loc) => _LocationTile(
                  title: loc.displayTitle,
                  subtitle: loc.addressPrimary,
                  selected: selected == loc.id,
                  onTap: () => Navigator.of(context).pop(loc.id),
                ),
              ),
              if (_items.isEmpty && _error == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'Добавьте место в Ресурсы → Местоположения — тогда можно фильтровать посты.',
                    style: AppTextStyle.base(14, color: colors.subTextColor),
                  ),
                ),
            ],
          ),
        ),
        if (selected != null && selected.isNotEmpty) ...[
          const SizedBox(height: 8),
          AppButton(
            text: 'Сбросить',
            isExpanded: true,
            service: kResourcesService,
            onTap: () => Navigator.of(context).pop(''),
          ),
        ],
      ],
    );
  }
}

class _LocationTile extends StatelessWidget {
  const _LocationTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = colors.serviceAccent(kResourcesService);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? AppIcons.locationOn.icon : AppIcons.locationOn.icon,
        color: selected ? accent.icon : colors.iconMuted,
      ),
      title: Text(
        title,
        style: AppTextStyle.base(
          15,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: colors.textColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.base(12, color: colors.subTextColor),
      ),
      trailing: selected
          ? Icon(AppIcons.checkRounded.icon, color: accent.icon, size: 22)
          : null,
      onTap: onTap,
    );
  }
}
