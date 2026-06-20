import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/work/data/models/work_relation_status.dart';
import 'package:flutter/material.dart';

class WorkRelationStatusBadge extends StatelessWidget {
  const WorkRelationStatusBadge({super.key, required this.status, this.compact = false});

  final WorkRelationStatus status;
  final bool compact;

  static _StatusStyle _style(WorkRelationStatus status) => switch (status) {
    WorkRelationStatus.pending => const _StatusStyle(
      dotColor: Color(0xFFF5A623),
      textColor: Color(0xFF9A6700),
      backgroundColor: Color(0xFFFFF8E8),
      borderColor: Color(0xFFF5D78E),
    ),
    WorkRelationStatus.active => const _StatusStyle(
      dotColor: Color(0xFF6FBF3C),
      textColor: Color(0xFF3F7A1E),
      backgroundColor: Color(0xFFF1FAEA),
      borderColor: Color(0xFFBFE59A),
    ),
    WorkRelationStatus.rejected => const _StatusStyle(
      dotColor: Color(0xFFE57373),
      textColor: Color(0xFFB71C1C),
      backgroundColor: Color(0xFFFFF0F0),
      borderColor: Color(0xFFF5BDBD),
    ),
    WorkRelationStatus.terminated => const _StatusStyle(
      dotColor: Color(0xFF9E9E9E),
      textColor: Color(0xFF616161),
      backgroundColor: Color(0xFFF5F5F5),
      borderColor: Color(0xFFE0E0E0),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final style = _style(status);
    final fontSize = compact ? 11.0 : 12.0;
    final hPad = compact ? 8.0 : 10.0;
    final vPad = compact ? 4.0 : 5.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.borderColor.withValues(alpha: 0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.dotColor,
              boxShadow: [
                BoxShadow(
                  color: style.dotColor.withValues(alpha: 0.35),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            status.label,
            style: AppTextStyle.base(fontSize, color: style.textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.dotColor,
    required this.textColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final Color dotColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;
}
