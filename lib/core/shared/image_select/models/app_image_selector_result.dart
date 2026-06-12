import 'package:photo_manager/photo_manager.dart';

/// Результат экрана выбора фото.
class AppImageSelectorResult {
  const AppImageSelectorResult({required this.assets});

  final List<AssetEntity> assets;
}
