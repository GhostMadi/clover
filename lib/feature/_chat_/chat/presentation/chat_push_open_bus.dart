import 'dart:async';

import 'package:injectable/injectable.dart';

/// Open a chat from FCM tap / in-app banner (Realtime inbox or FCM foreground).
@lazySingleton
class ChatPushOpenBus {
  final _controller = StreamController<ChatPushOpenRequest>.broadcast();

  Stream<ChatPushOpenRequest> get stream => _controller.stream;

  ChatPushOpenRequest? _pending;
  String? _lastBannerKey;
  DateTime? _lastBannerAt;

  void emit(ChatPushOpenRequest request) {
    if (!request.autoOpen && _isDuplicateBanner(request)) return;

    if (_controller.hasListener) {
      _controller.add(request);
      return;
    }
    // Keep latest until dashboard binds (open-from-push and in-app banner).
    _pending = request;
  }

  bool _isDuplicateBanner(ChatPushOpenRequest request) {
    final key = request.messageId?.trim().isNotEmpty == true
        ? 'm:${request.messageId}'
        : 'c:${request.conversationId}:${request.preview ?? ''}';
    final now = DateTime.now();
    if (_lastBannerKey == key &&
        _lastBannerAt != null &&
        now.difference(_lastBannerAt!) < const Duration(seconds: 4)) {
      return true;
    }
    _lastBannerKey = key;
    _lastBannerAt = now;
    return false;
  }

  ChatPushOpenRequest? takePending() {
    final p = _pending;
    _pending = null;
    return p;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class ChatPushOpenRequest {
  const ChatPushOpenRequest({
    required this.conversationId,
    this.peerUsername,
    this.isGroup = false,
    this.autoOpen = true,
    this.preview,
    this.messageId,
  });

  final String conversationId;
  final String? peerUsername;
  final bool isGroup;

  /// `true` — navigate now (notification tap). `false` — Instagram-style top banner.
  final bool autoOpen;

  final String? preview;
  final String? messageId;
}
