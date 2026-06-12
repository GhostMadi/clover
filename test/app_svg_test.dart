import 'dart:io';

import 'package:clover/core/resources/resources.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app_svg assets test', () {
    expect(File(AppSvg.google).existsSync(), isTrue);
  });
}
