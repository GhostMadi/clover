import 'dart:async';

import 'package:injectable/injectable.dart';

/// In-memory authors hidden after block this session (instant feed filter).
@lazySingleton
class UgcBlockSession {
  final Set<String> _blockedAuthorIds = {};
  final _controller = StreamController<String>.broadcast();

  Stream<String> get onBlocked => _controller.stream;

  void markBlocked(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return;
    _blockedAuthorIds.add(id);
    _controller.add(id);
  }

  bool isBlocked(String userId) => _blockedAuthorIds.contains(userId.trim());

  bool shouldHideAuthor(String userId) => isBlocked(userId);
}
