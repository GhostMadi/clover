import 'dart:async';
import 'dart:ui';

import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_reaction_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Действия контекстного меню сообщения (WhatsApp / Telegram style).
enum ChatMessageAction {
  reply,
  forward,
  copy,
  star,
  edit,
  delete,
}

/// Результат закрытия [ChatMessageContextMenu].
class ChatMessageContextResult {
  const ChatMessageContextResult.emoji(this.emoji) : action = null;
  const ChatMessageContextResult.action(this.action) : emoji = null;

  final String? emoji;
  final ChatMessageAction? action;
}

/// Long-press overlay: blur + bubble на месте + реакции + меню действий.
abstract final class ChatMessageContextMenu {
  static Future<ChatMessageContextResult?> show({
    required BuildContext context,
    required Rect messageRect,
    required ChatMessage message,
    required Widget messageBubble,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    final completer = Completer<ChatMessageContextResult?>();
    late OverlayEntry entry;

    void finish(ChatMessageContextResult? result) {
      if (completer.isCompleted) return;
      entry.remove();
      completer.complete(result);
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        return _ChatMessageContextMenuLayer(
          messageRect: messageRect,
          message: message,
          messageBubble: messageBubble,
          onResult: finish,
        );
      },
    );

    overlay.insert(entry);
    return completer.future;
  }

  static List<ChatMessageAction> actionsFor(ChatMessage message) {
    final actions = <ChatMessageAction>[
      ChatMessageAction.reply,
      ChatMessageAction.forward,
    ];
    if (message.text.trim().isNotEmpty) {
      actions.add(ChatMessageAction.copy);
    }
    actions.add(ChatMessageAction.star);
    if (message.isMine && message.kind == 'text' && !message.isPending) {
      actions.add(ChatMessageAction.edit);
    }
    if (message.isMine && !message.isPending) {
      actions.add(ChatMessageAction.delete);
    }
    return actions;
  }
}

class _ChatMessageContextMenuLayer extends StatefulWidget {
  const _ChatMessageContextMenuLayer({
    required this.messageRect,
    required this.message,
    required this.messageBubble,
    required this.onResult,
  });

  final Rect messageRect;
  final ChatMessage message;
  final Widget messageBubble;
  final ValueChanged<ChatMessageContextResult?> onResult;

  @override
  State<_ChatMessageContextMenuLayer> createState() => _ChatMessageContextMenuLayerState();
}

class _ChatMessageContextMenuLayerState extends State<_ChatMessageContextMenuLayer>
    with SingleTickerProviderStateMixin {
  static const double _gap = 10;
  static const double _reactionHeight = 56;
  static const double _menuItemHeight = 48;
  static const double _menuWidth = 248;
  static const double _menuRadius = 16;
  static const double _edgePad = 12;
  static const _moreEmojis = [
    '🔥', '👏', '😍', '🤔', '🙌', '💯',
    '😁', '😅', '🥲', '😎', '🤩', '😘',
    '💔', '✨', '🎉', '🤝', '👀', '🫡',
  ];

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  bool _showMoreEmojis = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.86, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close([ChatMessageContextResult? result]) async {
    await _controller.reverse();
    if (!mounted) return;
    widget.onResult(result);
  }

  void _toggleMoreEmojis() {
    HapticFeedback.selectionClick();
    setState(() => _showMoreEmojis = !_showMoreEmojis);
  }

  _MenuLayout _layout(Size screen, EdgeInsets padding, List<ChatMessageAction> actions) {
    final menuHeight = actions.length * _menuItemHeight + 12;
    final safeTop = padding.top + _edgePad;
    final safeBottom = screen.height - padding.bottom - _edgePad;

    final spaceBelow = safeBottom - widget.messageRect.bottom;
    final spaceAbove = widget.messageRect.top - safeTop;
    final needBelow = menuHeight + _gap;
    final placeMenuAbove = spaceBelow < needBelow && spaceAbove > spaceBelow;

    double reactionTop;
    double menuTop;

    if (placeMenuAbove) {
      // [reactions] → [menu] → [bubble]
      menuTop = widget.messageRect.top - _gap - menuHeight;
      reactionTop = menuTop - _gap - _reactionHeight;
      if (reactionTop < safeTop) {
        reactionTop = safeTop;
        menuTop = reactionTop + _reactionHeight + _gap;
      }
    } else {
      // [reactions] → [bubble] → [menu]
      reactionTop = widget.messageRect.top - _gap - _reactionHeight;
      if (reactionTop < safeTop) {
        reactionTop = widget.messageRect.bottom + _gap;
        menuTop = reactionTop + _reactionHeight + _gap;
      } else {
        menuTop = widget.messageRect.bottom + _gap;
        if (menuTop + menuHeight > safeBottom) {
          menuTop = (safeBottom - menuHeight).clamp(safeTop, safeBottom - menuHeight);
        }
      }
    }

    final reactionWidth = _estimateReactionWidth();
    var reactionLeft = widget.messageRect.center.dx - reactionWidth / 2;
    reactionLeft = reactionLeft.clamp(_edgePad, screen.width - reactionWidth - _edgePad);

    var menuLeft = widget.message.isMine
        ? widget.messageRect.right - _menuWidth
        : widget.messageRect.left;
    menuLeft = menuLeft.clamp(_edgePad, screen.width - _menuWidth - _edgePad);

    return _MenuLayout(
      reactionTop: reactionTop,
      reactionLeft: reactionLeft,
      reactionWidth: reactionWidth,
      menuTop: menuTop,
      menuLeft: menuLeft,
      menuHeight: menuHeight,
    );
  }

  double _estimateReactionWidth() {
    // 6 emoji + «+» + paddings
    return (ChatReactionBar.quickEmojis.length + 1) * 44.0 + 28;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final media = MediaQuery.of(context);
    final actions = ChatMessageContextMenu.actionsFor(widget.message);
    final layout = _layout(media.size, media.padding, actions);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _close(),
              child: FadeTransition(
                opacity: _fade,
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: ColoredBox(
                      color: colors.shadowDark.withValues(alpha: 0.42),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: widget.messageRect.left,
            top: widget.messageRect.top,
            width: widget.messageRect.width,
            height: widget.messageRect.height,
            child: IgnorePointer(child: widget.messageBubble),
          ),
          Positioned(
            left: layout.reactionLeft,
            top: layout.reactionTop,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.bottomCenter,
                child: ChatReactionBar(
                  message: widget.message,
                  onEmojiSelected: (emoji) {
                    HapticFeedback.selectionClick();
                    _close(ChatMessageContextResult.emoji(emoji));
                  },
                  onAddEmoji: _toggleMoreEmojis,
                ),
              ),
            ),
          ),
          if (_showMoreEmojis)
            Positioned(
              left: _edgePad,
              right: _edgePad,
              top: layout.reactionTop + _reactionHeight + 8,
              child: FadeTransition(
                opacity: _fade,
                child: Material(
                  color: colors.surface,
                  elevation: 8,
                  shadowColor: colors.shadowDark.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        for (final emoji in _moreEmojis)
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _close(ChatMessageContextResult.emoji(emoji));
                            },
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (!_showMoreEmojis)
            Positioned(
              left: layout.menuLeft,
              top: layout.menuTop,
              width: _menuWidth,
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: widget.message.isMine ? Alignment.topRight : Alignment.topLeft,
                  child: _ContextActionMenu(
                    actions: actions,
                    onAction: (action) {
                      HapticFeedback.selectionClick();
                      _close(ChatMessageContextResult.action(action));
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuLayout {
  const _MenuLayout({
    required this.reactionTop,
    required this.reactionLeft,
    required this.reactionWidth,
    required this.menuTop,
    required this.menuLeft,
    required this.menuHeight,
  });

  final double reactionTop;
  final double reactionLeft;
  final double reactionWidth;
  final double menuTop;
  final double menuLeft;
  final double menuHeight;
}

class _ContextActionMenu extends StatelessWidget {
  const _ContextActionMenu({
    required this.actions,
    required this.onAction,
  });

  final List<ChatMessageAction> actions;
  final ValueChanged<ChatMessageAction> onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      elevation: 10,
      shadowColor: colors.shadowDark.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(_ChatMessageContextMenuLayerState._menuRadius),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: colors.border.withValues(alpha: 0.55)),
            _ContextActionTile(
              action: actions[i],
              onTap: () => onAction(actions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ContextActionTile extends StatelessWidget {
  const _ContextActionTile({
    required this.action,
    required this.onTap,
  });

  final ChatMessageAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final destructive = action == ChatMessageAction.delete;
    final color = destructive ? colors.destructive : colors.textColor;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: _ChatMessageContextMenuLayerState._menuItemHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _label(action),
                  style: AppTextStyle.base(16, color: color, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(_icon(action), color: color, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(ChatMessageAction action) {
    return switch (action) {
      ChatMessageAction.reply => 'Ответить',
      ChatMessageAction.forward => 'Переслать',
      ChatMessageAction.copy => 'Копировать',
      ChatMessageAction.star => 'В Избранные',
      ChatMessageAction.edit => 'Изменить',
      ChatMessageAction.delete => 'Удалить',
    };
  }

  static IconData _icon(ChatMessageAction action) {
    return switch (action) {
      ChatMessageAction.reply => AppIcons.replyOutlined.icon,
      ChatMessageAction.forward => AppIcons.arrowForward.icon,
      ChatMessageAction.copy => AppIcons.copy.icon,
      ChatMessageAction.star => AppIcons.bookmark.icon,
      ChatMessageAction.edit => AppIcons.editOutlined.icon,
      ChatMessageAction.delete => AppIcons.delete.icon,
    };
  }
}
