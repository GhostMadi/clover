import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message_attachment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_manager/photo_manager.dart';

/// Полноэкранный просмотр фото чата: fade + Hero, pinch-zoom, скачать в галерею.
class ChatPhotoViewer {
  ChatPhotoViewer._();

  static Future<void> open(
    BuildContext context, {
    required List<ChatMessageAttachment> attachments,
    int initialIndex = 0,
  }) {
    final images = attachments
        .where((a) {
          final url = a.url?.trim() ?? '';
          return url.isNotEmpty && (a.isImage || _looksLikeImageUrl(url));
        })
        .toList(growable: false);
    if (images.isEmpty) return Future.value();

    final index = initialIndex.clamp(0, images.length - 1);

    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0xEB000000),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ChatPhotoViewerPage(
            attachments: images,
            initialIndex: index,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  static bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp') ||
        lower.contains('.gif') ||
        lower.contains('.heic');
  }

  static String heroTag(ChatMessageAttachment attachment) {
    final id = attachment.id.trim();
    if (id.isNotEmpty) return 'chat_photo_$id';
    return 'chat_photo_${attachment.url ?? attachment.path}';
  }
}

class _ChatPhotoViewerPage extends StatefulWidget {
  const _ChatPhotoViewerPage({
    required this.attachments,
    required this.initialIndex,
  });

  final List<ChatMessageAttachment> attachments;
  final int initialIndex;

  @override
  State<_ChatPhotoViewerPage> createState() => _ChatPhotoViewerPageState();
}

class _ChatPhotoViewerPageState extends State<_ChatPhotoViewerPage> {
  late final PageController _pageController;
  late int _index;
  bool _saving = false;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  ChatMessageAttachment get _current => widget.attachments[_index];

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset = (_dragOffset + details.delta.dy).clamp(-40, 220));
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > 96 || velocity > 900) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _dragOffset = 0);
  }

  Future<void> _download() async {
    if (_saving) return;
    final url = _current.url?.trim();
    if (url == null || url.isEmpty) return;

    setState(() => _saving = true);
    try {
      final permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth && !permission.hasAccess) {
        if (!mounted) return;
        AppSnackBar.show(
          context,
          message: 'Разрешите доступ к фото, чтобы сохранить',
          kind: AppSnackBarKind.error,
        );
        return;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}');
      }

      final bytes = Uint8List.fromList(response.bodyBytes);
      final name = _current.displayName;
      final filename = name.contains('.') ? name : 'clover_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await PhotoManager.editor.saveImage(bytes, filename: filename);
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Сохранено в Галерею',
        kind: AppSnackBarKind.success,
      );
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: 'Не удалось скачать фото',
        kind: AppSnackBarKind.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dismissProgress = (_dragOffset / 180).clamp(0.0, 1.0);
    final contentOpacity = 1 - dismissProgress * 0.35;

    return Scaffold(
      backgroundColor: Color.lerp(
        const Color(0xEB000000),
        const Color(0x00000000),
        dismissProgress,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: const ColoredBox(color: Color(0x00000000)),
          ),
          Opacity(
            opacity: contentOpacity,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: GestureDetector(
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.attachments.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, index) {
                    final attachment = widget.attachments[index];
                    final url = attachment.url!.trim();
                    return Center(
                      child: InteractiveViewer(
                        minScale: 1,
                        maxScale: 4,
                        child: Hero(
                          tag: ChatPhotoViewer.heroTag(attachment),
                          child: Material(
                            type: MaterialType.transparency,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => SizedBox(
                                width: 36,
                                height: 36,
                                child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                              ),
                              errorWidget: (_, __, ___) => Icon(
                                AppIcons.imageOutlined.icon,
                                color: colors.iconMuted,
                                size: 48,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Opacity(
                opacity: contentOpacity,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: Icon(AppIcons.close.icon, color: colors.textInverse),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.shadowDark.withValues(alpha: 0.35),
                      ),
                    ),
                    const Spacer(),
                    if (widget.attachments.length > 1)
                      Text(
                        '${_index + 1} / ${widget.attachments.length}',
                        style: AppTextStyle.base(14, color: colors.textInverse, fontWeight: FontWeight.w600),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: _saving ? null : _download,
                      tooltip: 'Скачать',
                      icon: _saving
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: colors.textInverse),
                            )
                          : Icon(AppIcons.download.icon, color: colors.textInverse),
                      style: IconButton.styleFrom(
                        backgroundColor: colors.shadowDark.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Opacity(
                  opacity: contentOpacity,
                  child: Material(
                    color: colors.shadowDark.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _saving ? null : _download,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(AppIcons.download.icon, color: colors.textInverse, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Скачать',
                              style: AppTextStyle.base(
                                15,
                                color: colors.textInverse,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
