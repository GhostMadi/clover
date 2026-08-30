import 'package:clover/core/theme/app_theme_mode.dart';
import 'package:clover/core/theme/app_theme_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppThemeCubit extends Cubit<AppThemeMode> {
  AppThemeCubit(this._store) : super(AppThemeMode.system);

  final AppThemeStore _store;

  Future<void> load() async {
    emit(await _store.read());
  }

  Future<void> setMode(AppThemeMode mode) async {
    if (mode == state) return;
    await _store.write(mode);
    HapticFeedback.selectionClick();
    emit(mode);
  }
}
