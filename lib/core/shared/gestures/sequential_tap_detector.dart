import 'dart:async';

/// Считает быстрые последовательные тапы в окне [window].
///
/// По истечении окна вызывает [onWindowEnd] с числом тапов за серию.
class SequentialTapDetector {
  SequentialTapDetector({this.window = const Duration(milliseconds: 300)});

  final Duration window;

  int _tapCount = 0;
  Timer? _timer;

  void registerTap(void Function(int tapCount) onWindowEnd) {
    _tapCount++;
    _timer?.cancel();
    _timer = Timer(window, () {
      final count = _tapCount;
      _tapCount = 0;
      onWindowEnd(count);
    });
  }

  void dispose() {
    _timer?.cancel();
    _tapCount = 0;
  }
}
