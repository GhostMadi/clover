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
import 'package:clover/feature/work/presentation/cubit/employer_work_cubit.dart';
import 'package:clover/feature/work/presentation/widget/work_invite_bottom_sheet.dart';
import 'package:clover/feature/work/presentation/widget/work_member_tile.dart';
import 'package:clover/feature/work/presentation/widget/work_relations_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class EmployerWorkPage extends StatefulWidget {
  const EmployerWorkPage({super.key});

  @override
  State<EmployerWorkPage> createState() => _EmployerWorkPageState();
}

class _EmployerWorkPageState extends State<EmployerWorkPage> {
  late final EmployerWorkCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EmployerWorkCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openInviteSheet() async {
    final member = await WorkInviteBottomSheet.show(
      context,
      mode: WorkInviteSheetMode.employerInviteEmployee,
      repository: sl<WorkRepository>(),
      excludePeerIds: _cubit.inviteExcludePeerIds,
    );
    if (member == null || !mounted) return;

    try {
      await _cubit.invite(member.id);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Приглашение отправлено ${member.displayUsername}',
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
      message: 'Приглашение для ${relation.peer.displayUsername} будет отозвано.',
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
        title: 'Работодатель',
        extraButtons: [
          FunctionalButtonItem(
            icon: Icons.add_rounded,
            keepWhenCollapsed: true,
            onTap: _openInviteSheet,
          ),
        ],
        body: BlocBuilder<EmployerWorkCubit, EmployerWorkState>(
          builder: (context, state) {
            return state.when(
              initial: () => const Center(child: CircularProgressIndicator()),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (message) => _ErrorBody(message: message, onRetry: _cubit.load),
              loaded: (relations, mainTabIndex) {
                final loadedState = EmployerWorkLoaded(
                  relations: relations,
                  mainTabIndex: mainTabIndex,
                );
                final employees = _cubit.employeesFor(loadedState);
                final incoming = _cubit.incomingRequestsFor(loadedState);
                final outgoing = _cubit.outgoingRequestsFor(loadedState);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: AppTab(
                        tabs: ['Работники (${employees.length})', 'Заявки'],
                        currentIndex: mainTabIndex,
                        onTabChanged: _cubit.setMainTab,
                      ),
                    ),
                    Expanded(
                      child: AppRefresh(
                        onRefresh: _cubit.refresh,
                        child: mainTabIndex == 0
                            ? _EmployeesTab(
                                employees: employees,
                                onInvite: _openInviteSheet,
                                onFire: (r) => _run(
                                  () => _cubit.terminate(r),
                                  success: '${r.peer.displayUsername} уволен',
                                  kind: AppSnackBarKind.success,
                                ),
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

class _EmployeesTab extends StatelessWidget {
  const _EmployeesTab({
    required this.employees,
    required this.onInvite,
    required this.onFire,
  });

  final List<WorkRelationModel> employees;
  final VoidCallback onInvite;
  final ValueChanged<WorkRelationModel> onFire;

  @override
  Widget build(BuildContext context) {
    if (employees.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: SettingsScreenShell.scrollBottomGap(context)),
        children: [
          WorkEmptyState(
            message: 'У вас пока нет работников',
            actionLabel: '➕ Пригласить работника',
            onAction: onInvite,
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 0, 16, SettingsScreenShell.scrollBottomGap(context)),
      children: [
        AppTileGroup(
          children: [
            for (final relation in employees)
              WorkMemberTile(
                member: relation.peer,
                trailing: WorkFireButton(onTap: () => onFire(relation)),
              ),
          ],
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
