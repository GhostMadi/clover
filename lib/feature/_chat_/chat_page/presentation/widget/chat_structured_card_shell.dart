import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_geometry.dart';
import 'package:flutter/material.dart';

/// Surface-карточка, пока payload чинится с бэка (не candy text-bubble).
class ChatStructuredCardShell extends StatelessWidget {
  const ChatStructuredCardShell({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * ChatGeometry.bubbleMaxWidthFactor,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ],
        ],
      ),
    );
  }
}
