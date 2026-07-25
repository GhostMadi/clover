import 'package:clover/core/shared/gestures/sequential_tap_detector.dart';

/// Логика тапов по табам навбара.
///
/// Обычный тап по неактивному табу — [onSelect].
/// Повторный тап по уже активному табу из [doubleTapReselectIndices] —
/// серия быстрых тапов; при [doubleTapThreshold] и более вызывается [onDoubleTapReselect].
class AppTabReselectTapLogic {
  AppTabReselectTapLogic({
    this.doubleTapWindow = const Duration(milliseconds: 300),
    this.doubleTapThreshold = 2,
  });

  final Duration doubleTapWindow;
  final int doubleTapThreshold;

  final Map<int, SequentialTapDetector> _detectors = {};

  void handleTap({
    required int index,
    required int activeIndex,
    required Set<int> doubleTapReselectIndices,
    required void Function(int index) onSelect,
    void Function(int index)? onDoubleTapReselect,
  }) {
    if (index != activeIndex) {
      onSelect(index);
      return;
    }

    if (onDoubleTapReselect == null || !doubleTapReselectIndices.contains(index)) {
      return;
    }

    _detectors
        .putIfAbsent(index, () => SequentialTapDetector(window: doubleTapWindow))
        .registerTap((tapCount) {
          if (tapCount >= doubleTapThreshold) {
            onDoubleTapReselect(index);
          }
        });
  }

  void dispose() {
    for (final detector in _detectors.values) {
      detector.dispose();
    }
    _detectors.clear();
  }
}
