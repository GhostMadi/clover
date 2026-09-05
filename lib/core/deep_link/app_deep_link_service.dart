import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:auto_route/auto_route.dart';
import 'package:clover/core/deep_link/app_deep_link_navigator.dart';
import 'package:clover/core/deep_link/app_deep_link_parser.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens for cold/warm app links and navigates when the user is authenticated.
@lazySingleton
class AppDeepLinkService {
  AppDeepLinkService(this._navigator, this._client);

  final AppDeepLinkNavigator _navigator;
  final SupabaseClient _client;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  Uri? _pendingUri;
  StackRouter? _router;

  Future<void> init() async {
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _pendingUri = initial;
    }

    await _subscription?.cancel();
    _subscription = _appLinks.uriLinkStream.listen(_onUri);
  }

  void bindRouter(StackRouter router) {
    _router = router;
  }

  Future<void> flushPending() async {
    final router = _router;
    final uri = _pendingUri;
    if (router == null || uri == null) return;
    if (!_isAuthenticated) return;

    _pendingUri = null;
    await _handleUri(router, uri);
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onUri(Uri uri) {
    if (!_isAuthenticated) {
      _pendingUri = uri;
      return;
    }

    final router = _router;
    if (router == null) {
      _pendingUri = uri;
      return;
    }

    unawaited(_handleUri(router, uri));
  }

  Future<void> _handleUri(StackRouter router, Uri uri) async {
    final intent = AppDeepLinkParser.tryParse(uri);
    if (intent == null) return;
    await _navigator.navigate(router, intent);
  }

  bool get _isAuthenticated => _client.auth.currentSession != null;
}
