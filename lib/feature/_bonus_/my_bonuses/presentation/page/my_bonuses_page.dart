import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_bonus_/my_bonuses/presentation/cubit/my_bonuses_cubit.dart';
import 'package:clover/feature/_bonus_/my_bonuses/presentation/widget/bonus_account_tile.dart';
import 'package:clover/feature/_bonus_/my_bonuses/presentation/widget/my_bonuses_empty_state.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class MyBonusesPage extends StatefulWidget {
  const MyBonusesPage({super.key});

  @override
  State<MyBonusesPage> createState() => _MyBonusesPageState();
}

class _MyBonusesPageState extends State<MyBonusesPage> {
  late final MyBonusesCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<MyBonusesCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyBonusesCubit, MyBonusesState>(
      bloc: _cubit,
      builder: (context, state) {
        return SettingsScreenShell(
          title: 'Мои бонусы',
          service: kBonusService,
          body: switch (state) {
            MyBonusesLoading() => const Center(child: CircularProgressIndicator()),
            MyBonusesError(:final message) => _MyBonusesErrorBody(message: message, onRetry: _cubit.load),
            MyBonusesLoaded(:final items, :final isRefreshing) => RefreshIndicator(
              onRefresh: _cubit.refresh,
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                        const MyBonusesEmptyState(),
                      ],
                    )
                  : _MyBonusesListBody(items: items, isRefreshing: isRefreshing),
            ),
            MyBonusesInitial() => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}

class _MyBonusesListBody extends StatelessWidget {
  const _MyBonusesListBody({required this.items, required this.isRefreshing});

  final List<BonusAccountItem> items;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
      itemCount: items.length + 1,
      separatorBuilder: (_, index) => SizedBox(height: index == 0 ? 14 : 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Баланс у каждого мастера отдельно. Откройте карточку, чтобы увидеть историю.',
            style: AppTextStyle.base(
              13,
              color: context.colors.subTextColor,
              height: 1.4,
            ),
          );
        }
        return Opacity(
          opacity: isRefreshing ? 0.7 : 1,
          child: BonusAccountTile(item: items[index - 1]),
        );
      },
    );
  }
}

class _MyBonusesErrorBody extends StatelessWidget {
  const _MyBonusesErrorBody({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(14, color: context.colors.subTextColor),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
