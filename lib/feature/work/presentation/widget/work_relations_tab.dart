import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_tab.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
import 'package:clover/feature/work/data/models/work_relation_model.dart';
import 'package:clover/feature/work/data/models/work_relation_status.dart';
import 'package:clover/feature/work/presentation/widget/work_member_tile.dart';
import 'package:clover/feature/work/presentation/widget/work_relation_tile.dart';
import 'package:flutter/material.dart';

class WorkRelationsTab extends StatefulWidget {
  const WorkRelationsTab({
    super.key,
    required this.incoming,
    required this.outgoing,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  final List<WorkRelationModel> incoming;
  final List<WorkRelationModel> outgoing;
  final ValueChanged<WorkRelationModel> onAccept;
  final ValueChanged<WorkRelationModel> onDecline;
  final ValueChanged<WorkRelationModel> onCancel;

  @override
  State<WorkRelationsTab> createState() => _WorkRelationsTabState();
}

class _WorkRelationsTabState extends State<WorkRelationsTab> {
  int _outgoingStatusTab = 0;

  static const _outgoingStatuses = [
    WorkRelationStatus.pending,
    WorkRelationStatus.active,
    WorkRelationStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    if (widget.incoming.isEmpty && widget.outgoing.isEmpty) {
      return const WorkRequestsEmpty();
    }

    final outgoingStatus = _outgoingStatuses[_outgoingStatusTab.clamp(0, _outgoingStatuses.length - 1)];
    final filteredOutgoing = widget.outgoing.where((r) => r.status == outgoingStatus).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, SettingsScreenShell.scrollBottomGap(context)),
      children: [
        if (widget.incoming.isNotEmpty) ...[
          const WorkSectionTitle('Входящие'),
          for (final relation in widget.incoming) ...[
            WorkRelationTile(
              relation: relation,
              onAccept: () => widget.onAccept(relation),
              onDecline: () => widget.onDecline(relation),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
        ],
        if (widget.outgoing.isNotEmpty) ...[
          const WorkSectionTitle('Исходящие'),
          AppTab(
            tabs: [
              'Ожидает (${_count(WorkRelationStatus.pending)})',
              'Принято (${_count(WorkRelationStatus.active)})',
              'Отклонено (${_count(WorkRelationStatus.rejected)})',
            ],
            currentIndex: _outgoingStatusTab,
            onTabChanged: (i) => setState(() => _outgoingStatusTab = i),
          ),
          const SizedBox(height: 12),
          if (filteredOutgoing.isEmpty)
            _OutgoingStatusEmpty(status: outgoingStatus)
          else
            for (final relation in filteredOutgoing) ...[
              WorkRelationTile(
                relation: relation,
                onCancel: relation.status == WorkRelationStatus.pending ? () => widget.onCancel(relation) : null,
              ),
              const SizedBox(height: 8),
            ],
        ],
      ],
    );
  }

  int _count(WorkRelationStatus status) => widget.outgoing.where((r) => r.status == status).length;
}

class _OutgoingStatusEmpty extends StatelessWidget {
  const _OutgoingStatusEmpty({required this.status});

  final WorkRelationStatus status;

  @override
  Widget build(BuildContext context) {
    final message = switch (status) {
      WorkRelationStatus.pending => 'Нет заявок в ожидании',
      WorkRelationStatus.active => 'Нет принятых заявок',
      WorkRelationStatus.rejected => 'Нет отклонённых заявок',
      WorkRelationStatus.terminated => 'Нет завершённых заявок',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTextStyle.base(14, color: AppColors.subTextColor),
      ),
    );
  }
}

class WorkRequestsEmpty extends StatelessWidget {
  const WorkRequestsEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    return const WorkEmptyState(message: 'Заявок пока нет');
  }
}
