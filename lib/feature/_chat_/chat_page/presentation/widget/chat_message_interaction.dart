import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Свайп в сторону ответа + long-press для реакций.
class ChatMessageInteraction extends StatefulWidget {
  const ChatMessageInteraction({
    super.key,
    required this.message,
    required this.child,
    this.onLongPressReaction,
    this.onSwipeReply,
  });

  final ChatMessage message;
  final Widget child;
  final VoidCallback? onLongPressReaction;
  final VoidCallback? onSwipeReply;

  static const double _replyTriggerDx = 56;

  @override
  State<ChatMessageInteraction> createState() => _ChatMessageInteractionState();
}

class _ChatMessageInteractionState extends State<ChatMessageInteraction> {
  double _dragDx = 0;
  bool _replyTriggered = false;

  bool get _isMine => widget.message.isMine;

  bool get _canInteract => !widget.message.isPending;

  double get _effectiveDx {
    if (!_canInteract) return 0;
    if (_isMine) {
      return _dragDx.clamp(-80.0, 0.0);
    }
    return _dragDx.clamp(0.0, 80.0);
  }

  double get _replyIconOpacity {
    final progress = (_effectiveDx.abs() / ChatMessageInteraction._replyTriggerDx).clamp(0.0, 1.0);
    return progress;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_canInteract) return;
    setState(() {
      _dragDx += details.delta.dx;
      if (_isMine && _dragDx > 0) _dragDx = 0;
      if (!_isMine && _dragDx < 0) _dragDx = 0;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_canInteract) return;

    final shouldReply = _effectiveDx.abs() >= ChatMessageInteraction._replyTriggerDx;
    if (shouldReply && !_replyTriggered) {
      _replyTriggered = true;
      HapticFeedback.mediumImpact();
      widget.onSwipeReply?.call();
    }

    setState(() {
      _dragDx = 0;
      _replyTriggered = false;
    });
  }

  void _onLongPress() {
    if (!_canInteract) return;
    HapticFeedback.mediumImpact();
    widget.onLongPressReaction?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isMine = _isMine;
    final replyIcon = AppIcons.replyOutlined.icon;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            if (_replyIconOpacity > 0)
              Positioned(
                left: isMine ? null : 4,
                right: isMine ? 4 : null,
                child: Opacity(
                  opacity: _replyIconOpacity,
                  child: Icon(replyIcon, size: 20, color: context.colors.primary),
                ),
              ),
            GestureDetector(
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: _onDragEnd,
              onLongPress: _onLongPress,
              child: Transform.translate(
                offset: Offset(_effectiveDx, 0),
                child: widget.child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
