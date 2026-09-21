import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_bonus_/bonus_history/data/models/bonus_history_entry.dart';
import 'package:clover/feature/_bonus_/bonus_history/presentation/cubit/bonus_history_cubit.dart';
import 'package:clover/feature/_bonus_/bonus_history/presentation/widget/bonus_history_account_header.dart';
import 'package:clover/feature/_bonus_/bonus_history/presentation/widget/bonus_history_empty_state.dart';
import 'package:clover/feature/_bonus_/bonus_history/presentation/widget/bonus_history_entry_tile.dart';
import 'package:clover/feature/_bonus_/my_bonuses/data/models/bonus_account_item.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class BonusHistoryPage extends StatefulWidget {
  const BonusHistoryPage({super.key, required this.account});

  final BonusAccountItem account;

  @override
  State<BonusHistoryPage> createState() => _BonusHistoryPageState();
}

class _BonusHistoryPageState extends State<BonusHistoryPage> {
  late final BonusHistoryCubit _cubit;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BonusHistoryCubit>()..load(widget.account);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      _cubit.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BonusHistoryCubit, BonusHistoryState>(
      bloc: _cubit,
      builder: (context, state) {
        return SettingsScreenShell(
          title: 'История бонусов',
          service: kBonusService,
          body: switch (state) {
            BonusHistoryInitial() => const SizedBox.shrink(),
            BonusHistoryLoading(:final account) => _BonusHistoryLoadingBody(account: account),
            BonusHistoryError(:final account, :final message) => _BonusHistoryErrorBody(
              account: account,
              message: message,
              onRetry: () => _cubit.load(account),
            ),
            BonusHistoryLoaded(
              :final account,
              :final entries,
              :final isRefreshing,
              :final isLoadingMore,
            ) =>
              RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: ListView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
                  children: [
                    Opacity(
                      opacity: isRefreshing ? 0.7 : 1,
                      child: BonusHistoryAccountHeader(account: account),
                    ),
                    const SizedBox(height: 20),
                    if (entries.isEmpty)
                      const BonusHistoryEmptyState()
                    else ...[
                      Text(
                        'Операции',
                        style: AppTextStyle.base(
                          13,
                          color: context.colors.subTextColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _HistoryListCard(entries: entries),
                      if (isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ],
                ),
              ),
          },
        );
      },
    );
  }
}

class _HistoryListCard extends StatelessWidget {
  const _HistoryListCard({required this.entries});

  final List<BonusHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            BonusHistoryEntryTile(
              entry: entries[i],
              showDivider: i < entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _BonusHistoryLoadingBody extends StatelessWidget {
  const _BonusHistoryLoadingBody({required this.account});

  final BonusAccountItem account;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
      children: [
        BonusHistoryAccountHeader(account: account),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _BonusHistoryErrorBody extends StatelessWidget {
  const _BonusHistoryErrorBody({
    required this.account,
    required this.message,
    required this.onRetry,
  });

  final BonusAccountItem account;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
      children: [
        BonusHistoryAccountHeader(account: account),
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.15),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyle.base(14, color: context.colors.subTextColor),
        ),
        const SizedBox(height: 16),
        Center(child: FilledButton(onPressed: onRetry, child: const Text('Повторить'))),
      ],
    );
  }
}
