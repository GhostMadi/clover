import 'dart:typed_data';

import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat/data/models/chat_attachment_upload.dart';
import 'package:flutter/material.dart';

/// Превью выбранных вложений над композером (до отправки).
class ChatComposerAttachmentsPreview extends StatelessWidget {
  const ChatComposerAttachmentsPreview({
    super.key,
    required this.attachments,
    required this.onRemove,
  });

  final List<ChatAttachmentUpload> attachments;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: context.colors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.65)),
      ),
      child: SizedBox(
        height: 76,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: attachments.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            final isImage = attachment.mime.startsWith('image/');
            return _AttachmentPreviewTile(
              attachment: attachment,
              isImage: isImage,
              onRemove: () => onRemove(index),
            );
          },
        ),
      ),
    );
  }
}

class _AttachmentPreviewTile extends StatelessWidget {
  const _AttachmentPreviewTile({
    required this.attachment,
    required this.isImage,
    required this.onRemove,
  });

  final ChatAttachmentUpload attachment;
  final bool isImage;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: isImage
              ? Image.memory(
                  Uint8List.fromList(attachment.bytes),
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 180,
                  height: 76,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: context.colors.surfaceSoft,
                  child: Row(
                    children: [
                      Icon(AppIcons.description.icon, color: context.colors.primary, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          attachment.filename,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyle.base(13, color: context.colors.textColor, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: Material(
            color: context.colors.surface,
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(AppIcons.close.icon, size: 16, color: context.colors.subTextColor),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
