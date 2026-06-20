import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/work/data/models/work_relation_model.dart';
import 'package:clover/feature/work/data/models/work_relation_status.dart';
import 'package:clover/feature/work/presentation/widget/work_member_tile.dart';
import 'package:clover/feature/work/presentation/widget/work_relation_status_badge.dart';
import 'package:flutter/material.dart';

class WorkRelationTile extends StatelessWidget {
  const WorkRelationTile({
    super.key,
    required this.relation,
    this.onAccept,
    this.onDecline,
    this.onCancel,
  });

  final WorkRelationModel relation;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;

  static const double _figmaPadding = 16;
  static const double _figmaGap = 12;
  static const double _figmaRadius = 18;
  static const double _figmaBorderWidth = 0.85;
  static const double _buttonHeight = 40;
  static const double _buttonRadius = 12;

  bool get _showIncomingActions =>
      relation.isIncoming && relation.status == WorkRelationStatus.pending;

  bool get _showCancelAction =>
      !relation.isIncoming && relation.status == WorkRelationStatus.pending;

  bool get _showStatusBadge => !_showIncomingActions;

  String get _title {
    final name = relation.peer.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return relation.peer.displayUsername;
  }

  String? get _subtitle {
    if (_showIncomingActions) return relation.actionSubtitle;
    if (_showCancelAction) return relation.outgoingPendingSubtitle;
    if (!relation.isIncoming) return relation.outgoingResolvedSubtitle;
    return relation.actionSubtitle;
  }

  @override
  Widget build(BuildContext context) {
    final padding = context.widthByContext(_figmaPadding);
    final gap = context.widthByContext(_figmaGap);
    final radius = context.widthByContext(_figmaRadius);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.55),
          width: context.widthByContext(_figmaBorderWidth),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WorkMemberAvatar(member: relation.peer),
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(15, color: AppColors.textColor, fontWeight: FontWeight.w600),
                      ),
                      if (_subtitle != null) ...[
                        SizedBox(height: context.heightByContext(2)),
                        Text(
                          _subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(13, color: AppColors.subTextColor),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_showStatusBadge) ...[
                  SizedBox(width: gap),
                  WorkRelationStatusBadge(status: relation.status),
                ],
              ],
            ),
            if (_showIncomingActions) ...[
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      text: 'Отклонить',
                      height: _buttonHeight,
                      borderRadius: _buttonRadius,
                      onTap: onDecline,
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: AppButton(
                      text: 'Принять',
                      height: _buttonHeight,
                      borderRadius: _buttonRadius,
                      onTap: onAccept,
                    ),
                  ),
                ],
              ),
            ],
            if (_showCancelAction) ...[
              SizedBox(height: gap),
              AppOutlinedButton(
                text: 'Отменить заявку',
                height: _buttonHeight,
                borderRadius: _buttonRadius,
                isExpanded: true,
                onTap: onCancel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
