import 'dart:io';

import 'package:clover/core/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app_images assets test', () {
    expect(File(AppImages.logo).existsSync(), isTrue);
  });
}
