import 'dart:async';
import 'dart:math' as math;

import 'package:clover/core/debug/app_log.dart';
import 'package:clover/core/debug/app_shake_logger_config.dart';
import 'package:clover/core/debug/app_talker.dart';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Встряска → [TalkerScreen] (логи talker).
class AppShakeLoggerHost extends StatefulWidget {
  const AppShakeLoggerHost({
    super.key,
    required this.child,
    required this.navigatorKey,
  });

  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<AppShakeLoggerHost> createState() => _AppShakeLoggerHostState();
}

class _AppShakeLoggerHostState extends State<AppShakeLoggerHost> {
  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime _lastOpen = DateTime.fromMillisecondsSinceEpoch(0);
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    if (!AppShakeLoggerConfig.enabled) return;
    _sub = accelerometerEventStream().listen(_onAccel, onError: (_) {});
    AppLog.i('Shake logger ready · встряхни устройство', tag: 'Shake');
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  void _onAccel(AccelerometerEvent e) {
    final g = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (g < AppShakeLoggerConfig.shakeThreshold) return;

    final now = DateTime.now();
    if (now.difference(_lastOpen) < AppShakeLoggerConfig.shakeCooldown) return;
    if (_opening) return;
    _lastOpen = now;
    unawaited(_openLogs());
  }

  Future<void> _openLogs() async {
    if (_opening) return;
    final nav = widget.navigatorKey.currentState;
    if (nav == null) return;
    _opening = true;
    try {
      await nav.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => TalkerScreen(
            talker: appTalker,
            appBarTitle: 'Clover · логи',
          ),
        ),
      );
    } finally {
      _opening = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
