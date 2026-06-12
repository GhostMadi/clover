import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

extension AssetEntityListExtension on List<AssetEntity> {
  Future<List<File?>> loadFiles() => Future.wait(map((asset) => asset.file));
}
