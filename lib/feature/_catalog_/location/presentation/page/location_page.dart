import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_catalog_/location/data/models/location_model.dart';
import 'package:clover/feature/_catalog_/location/presentation/cubit/location_cubit.dart';
import 'package:clover/feature/_catalog_/location/presentation/widget/location_detail_sheet.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_tile_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  Future<void> _openCreate(BuildContext context, LocationCubit cubit) async {
    final created = await context.router.push<bool>(const LocationCreateRoute());
    if (created == true && context.mounted) {
      await cubit.load();
    }
  }

  Future<void> _openDetail(BuildContext context, LocationCubit cubit, LocationModel item) async {
    final changed = await LocationDetailSheet.show(context, location: item);
    if (changed == true && context.mounted) {
      await cubit.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<LocationCubit>()..load(),
      child: SettingsScreenShell(
        title: 'Местоположения',
        body: BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => AppRefresh(
                onRefresh: () => context.read<LocationCubit>().load(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: SettingsScreenShell.scrollBottomGap(context)),
                  child: SizedBox(
                    height: 240,
                    child: Center(
                      child: Text(message, style: AppTextStyle.base(14, color: context.colors.subTextColor)),
                    ),
                  ),
                ),
              ),
              loaded: (items) {
                final cubit = context.read<LocationCubit>();
                return AppRefresh(
                  onRefresh: cubit.load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppTileGroup(
                          children: [
                            AppTile(
                              title: 'Добавить',
                              subtitle: 'Новое местоположение',
                              icon: AppIcons.addRounded.icon,
                              iconColor: context.colors.primary,
                              iconBackgroundColor: context.colors.primary.withValues(alpha: 0.12),
                              showChevron: true,
                              onTap: () => _openCreate(context, cubit),
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
                              style: AppTextStyle.base(14, color: context.colors.subTextColor),
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
                                  icon: AppIcons.locationOn.icon,
                                  iconColor: item.hasGeoBinding ? context.colors.primary : context.colors.iconMuted,
                                  enabled: item.isActive,
                                  showChevron: true,
                                  onTap: item.isActive ? () => _openDetail(context, cubit, item) : null,
                                ),
                            ],
                          ),
                        SizedBox(height: SettingsScreenShell.scrollBottomGap(context)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
