import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_attachment.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_photo_viewer.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatAttachmentBubble extends StatelessWidget {
  const ChatAttachmentBubble({
    super.key,
    required this.message,
    required this.background,
    required this.textColor,
    required this.metaColor,
    required this.borderRadius,
    required this.timeLabel,
    required this.isMine,
    this.reactions,
  });

  final ChatMessage message;
  final Color background;
  final Color textColor;
  final Color metaColor;
  final BorderRadius borderRadius;
  final String timeLabel;
  final bool isMine;
  final Widget? reactions;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final attachments = message.attachments;
    final caption = message.text.trim();

    return Column(
      crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: borderRadius,
            border: isMine ? null : Border.all(color: colors.border.withValues(alpha: 0.75)),
            boxShadow: [
              BoxShadow(
                color: (isMine ? colors.shadowPrimary : colors.shadowDark).withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: message.isPending
                      ? const _PendingAttachments()
                      : message.isMedia
                      ? _MediaGrid(attachments: attachments)
                      : _FileList(attachments: attachments, textColor: textColor, metaColor: metaColor),
                ),
                if (caption.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 2, 10, 0),
                    child: Text(caption, style: AppTextStyle.base(15, color: textColor, height: 1.3)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
                  child: _AttachmentTimeRow(
                    timeLabel: timeLabel,
                    metaColor: metaColor,
                    isMine: isMine,
                    message: message,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (reactions != null) ...[const SizedBox(height: 4), reactions!],
      ],
    );
  }
}

class _PendingAttachments extends StatelessWidget {
  const _PendingAttachments();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.colors.surfaceSoft, borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
      ),
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({required this.attachments});

  final List<ChatMessageAttachment> attachments;

  static const double _gap = 3;
  static const double _radius = 10;

  void _open(BuildContext context, int index) {
    ChatPhotoViewer.open(context, attachments: attachments, initialIndex: index);
  }

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const _PlaceholderMedia();
    }

    if (attachments.length == 1) {
      return _SingleImage(
        attachment: attachments.first,
        onTap: () => _open(context, 0),
      );
    }

    final items = attachments.take(4).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 240.0;

        if (items.length == 2) {
          final cell = (width - _gap) / 2;
          return SizedBox(
            width: width,
            height: cell,
            child: Row(
              children: [
                Expanded(child: _gridCell(context, items[0], 0)),
                const SizedBox(width: _gap),
                Expanded(child: _gridCell(context, items[1], 1)),
              ],
            ),
          );
        }

        final cell = (width - _gap) / 2;
        final rows = <Widget>[
          SizedBox(
            height: cell,
            child: Row(
              children: [
                Expanded(child: _gridCell(context, items[0], 0)),
                const SizedBox(width: _gap),
                Expanded(child: _gridCell(context, items[1], 1)),
              ],
            ),
          ),
        ];

        if (items.length == 3) {
          rows.add(const SizedBox(height: _gap));
          rows.add(
            SizedBox(
              height: cell,
              child: Row(
                children: [
                  Expanded(child: _gridCell(context, items[2], 2)),
                  const SizedBox(width: _gap),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
          );
        } else if (items.length >= 4) {
          rows.add(const SizedBox(height: _gap));
          rows.add(
            SizedBox(
              height: cell,
              child: Row(
                children: [
                  Expanded(child: _gridCell(context, items[2], 2)),
                  const SizedBox(width: _gap),
                  Expanded(child: _gridCell(context, items[3], 3)),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          width: width,
          child: Column(mainAxisSize: MainAxisSize.min, children: rows),
        );
      },
    );
  }

  Widget _gridCell(BuildContext context, ChatMessageAttachment attachment, int index) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: Material(
        color: const Color(0x00000000),
        child: InkWell(
          onTap: () => _open(context, index),
          child: _AttachmentImage(attachment: attachment, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Одно фото в чате: max 260×320, cover — как было.
class _SingleImage extends StatelessWidget {
  const _SingleImage({required this.attachment, required this.onTap});

  final ChatMessageAttachment attachment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260, maxHeight: 320),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: const Color(0x00000000),
          child: InkWell(
            onTap: onTap,
            child: _AttachmentImage(attachment: attachment, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _AttachmentImage extends StatelessWidget {
  const _AttachmentImage({required this.attachment, required this.fit});

  final ChatMessageAttachment attachment;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = attachment.url?.trim();
    if (url == null || url.isEmpty) {
      return const _PlaceholderMedia();
    }

    return Hero(
      tag: ChatPhotoViewer.heroTag(attachment),
      child: Material(
        type: MaterialType.transparency,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => ColoredBox(
            color: context.colors.surfaceSoft,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
              ),
            ),
          ),
          errorWidget: (_, __, ___) => const _PlaceholderMedia(),
        ),
      ),
    );
  }
}

class _PlaceholderMedia extends StatelessWidget {
  const _PlaceholderMedia();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 120,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: context.colors.surfaceSoft, borderRadius: BorderRadius.circular(14)),
      child: Icon(AppIcons.imageOutlined.icon, color: context.colors.iconMuted, size: 32),
    );
  }
}

class _FileList extends StatelessWidget {
  const _FileList({required this.attachments, required this.textColor, required this.metaColor});

  final List<ChatMessageAttachment> attachments;
  final Color textColor;
  final Color metaColor;

  @override
  Widget build(BuildContext context) {
    final items = attachments.isEmpty
        ? [
            ChatMessageAttachment(
              id: '',
              bucket: 'chat_media',
              path: 'file',
              mime: 'application/octet-stream',
            ),
          ]
        : attachments;

    return Column(
      children: [
        for (final attachment in items)
          _FileTile(attachment: attachment, textColor: textColor, metaColor: metaColor),
      ],
    );
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.attachment, required this.textColor, required this.metaColor});

  final ChatMessageAttachment attachment;
  final Color textColor;
  final Color metaColor;

  @override
  Widget build(BuildContext context) {
    final sizeLabel = _formatSize(attachment.sizeBytes);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAttachment(context, attachment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colors.surfaceSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(AppIcons.description.icon, color: context.colors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.base(14, color: textColor, fontWeight: FontWeight.w600),
                    ),
                    if (sizeLabel != null) Text(sizeLabel, style: AppTextStyle.base(12, color: metaColor)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return null;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _openAttachment(BuildContext context, ChatMessageAttachment attachment) async {
    final url = attachment.url?.trim();
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _AttachmentTimeRow extends StatelessWidget {
  const _AttachmentTimeRow({
    required this.timeLabel,
    required this.metaColor,
    required this.isMine,
    required this.message,
  });

  final String timeLabel;
  final Color metaColor;
  final bool isMine;
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            timeLabel,
            style: AppTextStyle.base(11, color: metaColor, fontWeight: FontWeight.w500),
          ),
          if (isMine) ...[
            const SizedBox(width: 4),
            Icon(
              message.isPending
                  ? AppIcons.schedule.icon
                  : (message.isRead ? AppIcons.doneAll.icon : AppIcons.done.icon),
              size: 14,
              color: metaColor,
            ),
          ],
        ],
      ),
    );
  }
}
