import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/shared/app_dialog.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/work/data/models/work_relation_model.dart';
import 'package:clover/feature/work/data/repository/work_repository.dart';
import 'package:clover/feature/work/presentation/cubit/worker_work_cubit.dart';
import 'package:clover/feature/work/presentation/widget/work_invite_bottom_sheet.dart';
import 'package:clover/feature/work/presentation/widget/work_member_tile.dart';
import 'package:clover/feature/work/presentation/widget/work_relations_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class WorkerWorkPage extends StatefulWidget {
  const WorkerWorkPage({super.key});

  @override
  State<WorkerWorkPage> createState() => _WorkerWorkPageState();
}

class _WorkerWorkPageState extends State<WorkerWorkPage> {
  late final WorkerWorkCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<WorkerWorkCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openFindSheet() async {
    final member = await WorkInviteBottomSheet.show(
      context,
      mode: WorkInviteSheetMode.workerFindEmployer,
      repository: sl<WorkRepository>(),
      excludePeerIds: _cubit.inviteExcludePeerIds,
    );
    if (member == null || !mounted) return;

    try {
      await _cubit.apply(member.id);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Заявка отправлена ${member.displayUsername}',
        kind: AppSnackBarKind.success,
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    required String success,
    required AppSnackBarKind kind,
  }) async {
    try {
      await action();
      if (!mounted) return;
      AppSnackBar.show(context, message: success, kind: kind);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    }
  }

  Future<void> _cancelRelation(WorkRelationModel relation) async {
    final ok = await AppDialog.showConfirm(
      context: context,
      title: 'Отменить заявку?',
      message: 'Заявка для ${relation.peer.displayUsername} будет отозвана.',
      confirmLabel: 'Отменить',
      upperCaseTitle: false,
    );
    if (ok != true || !mounted) return;

    await _run(
      () => _cubit.withdraw(relation),
      success: 'Заявка отменена',
      kind: AppSnackBarKind.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: 'Работник',
        extraButtons: [
          FunctionalButtonItem(
            icon: Icons.add_rounded,
            keepWhenCollapsed: true,
            onTap: _openFindSheet,
          ),
        ],
        body: BlocBuilder<WorkerWorkCubit, WorkerWorkState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => _ErrorBody(message: message, onRetry: _cubit.load),
              loaded: (relations, mainTabIndex) {
                final employers = _cubit.employersFor(
                  WorkerWorkLoaded(relations: relations, mainTabIndex: mainTabIndex),
                );
                final incoming = _cubit.incomingRequestsFor(
                  WorkerWorkLoaded(relations: relations, mainTabIndex: mainTabIndex),
                );
                final outgoing = _cubit.outgoingRequestsFor(
                  WorkerWorkLoaded(relations: relations, mainTabIndex: mainTabIndex),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: AppTab(
                        tabs: ['Работодатели (${employers.length})', 'Заявки'],
                        currentIndex: mainTabIndex,
                        onTabChanged: _cubit.setMainTab,
                      ),
                    ),
                    Expanded(
                      child: AppRefresh(
                        onRefresh: _cubit.refresh,
                        child: mainTabIndex == 0
                            ? _EmployersTab(
                                employers: employers,
                                onFind: _openFindSheet,
                              )
                            : WorkRelationsTab(
                                incoming: incoming,
                                outgoing: outgoing,
                                onAccept: (r) => _run(
                                  () => _cubit.accept(r),
                                  success: 'Заявка принята',
                                  kind: AppSnackBarKind.success,
                                ),
                                onDecline: (r) => _run(
                                  () => _cubit.decline(r),
                                  success: 'Заявка отклонена',
                                  kind: AppSnackBarKind.info,
                                ),
                                onCancel: _cancelRelation,
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmployersTab extends StatelessWidget {
  const _EmployersTab({required this.employers, required this.onFind});

  final List<WorkRelationModel> employers;
  final VoidCallback onFind;

  @override
  Widget build(BuildContext context) {
    if (employers.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: SettingsScreenShell.scrollBottomGap(context)),
        children: [
          WorkEmptyState(
            message: 'Вы пока ни на кого не работаете',
            actionLabel: '➕ Найти работодателя',
            onAction: onFind,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
      children: [
        AppTileGroup(
          children: [for (final relation in employers) WorkMemberTile(member: relation.peer)],
        ),
      ],
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});

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
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
