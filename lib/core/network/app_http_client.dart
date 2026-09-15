import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Shared HTTP for Supabase: короткие TCP timeouts.
/// Иначе после resume мёртвый сокет висит минуты → `Bad file descriptor`.
http.Client createAppHttpClient() {
  final io = HttpClient()
    ..connectionTimeout = const Duration(seconds: 12)
    ..idleTimeout = const Duration(seconds: 20);
  return IOClient(io);
}
