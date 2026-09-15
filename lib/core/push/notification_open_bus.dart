import 'dart:async';

import 'package:injectable/injectable.dart';

/// Pending / live opens from FCM tray, cold start, or Android foreground snack.
@lazySingleton
class NotificationOpenBus {
  final _controller = StreamController<NotificationOpenRequest>.broadcast();

  Stream<NotificationOpenRequest> get stream => _controller.stream;

  NotificationOpenRequest? _pending;

  void emit(NotificationOpenRequest request) {
    if (_controller.hasListener) {
      _controller.add(request);
      return;
    }
    _pending = request;
  }

  NotificationOpenRequest? takePending() {
    final p = _pending;
    _pending = null;
    return p;
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

class NotificationOpenRequest {
  const NotificationOpenRequest({
    required this.kind,
    required this.data,
    this.autoOpen = true,
    this.title,
    this.body,
  });

  final String kind;
  final Map<String, dynamic> data;

  /// `true` — navigate now (tray / cold). `false` — show snack, open on tap.
  final bool autoOpen;

  final String? title;
  final String? body;
}
