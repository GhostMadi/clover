import 'package:flutter/material.dart';

/// Мягкое появление исходящего сообщения в списке.
class ChatMessageEntrance extends StatefulWidget {
  const ChatMessageEntrance({super.key, required this.animate, required this.child});

  final bool animate;
  final Widget child;

  @override
  State<ChatMessageEntrance> createState() => _ChatMessageEntranceState();
}

class _ChatMessageEntranceState extends State<ChatMessageEntrance> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final bool _play;

  @override
  void initState() {
    super.initState();
    _play = widget.animate;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.85, curve: Curves.easeOut),
      ),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(curved);

    if (_play) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_play) return widget.child;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
