import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/data/repository/location_repository.dart';
import 'package:clover/feature/_catalog_/location/presentation/widget/location_detail_sheet.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';

@RoutePage()
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final _repository = sl<LocationRepository>();

  List<LocationModel>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await _repository.listMine();
      if (!mounted) return;
      setState(() {
        _items = items;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items ??= const [];
        _error = 'Не удалось загрузить местоположения';
      });
    }
  }

  Future<void> _refresh() => _loadItems();

  Future<void> _openCreate() async {
    final created = await context.router.push<bool>(const LocationCreateRoute());
    if (created == true && mounted) {
      await _refresh();
    }
  }

  Future<void> _openDetail(LocationModel item) async {
    final changed = await LocationDetailSheet.show(context, location: item);
    if (changed == true && mounted) {
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return SettingsScreenShell(
      title: 'Местоположения',
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : AppRefresh(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: AppColors.subTextColor),
                        ),
                      ),
                    AppTileGroup(
                      children: [
                        AppTile(
                          title: 'Добавить',
                          subtitle: 'Новое местоположение',
                          icon: Icons.add_rounded,
                          iconColor: AppColors.primary,
                          iconBackgroundColor: AppColors.primary.withValues(alpha: 0.12),
                          showChevron: true,
                          onTap: _openCreate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SettingsTileSectionTitle('Всего: ${items.length}'),
                    if (items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          'Пока пусто — добавьте первое местоположение',
                          textAlign: TextAlign.center,
                          style: AppTextStyle.base(14, color: AppColors.subTextColor),
                        ),
                      )
                    else
                      AppTileGroup(
                        children: [
                          for (final item in items)
                            AppTile(
                              title: item.displayTitle,
                              subtitle: item.isActive
                                  ? item.displaySubtitle
                                  : '${item.displaySubtitle} · неактивно',
                              icon: Icons.location_on_outlined,
                              iconColor: item.hasGeoBinding ? AppColors.primary : AppColors.iconMuted,
                              enabled: item.isActive,
                              showChevron: true,
                              onTap: item.isActive ? () => _openDetail(item) : null,
                            ),
                        ],
                      ),
                    SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
                  ],
                ),
              ),
            ),
    );
  }
}
