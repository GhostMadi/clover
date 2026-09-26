import 'package:clover/core/locale/app_locale.dart';
import 'package:clover/core/locale/app_locale_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AppLocaleCubit extends Cubit<AppLocale> {
  AppLocaleCubit(this._store) : super(AppLocale.ru);

  final AppLocaleStore _store;

  Future<void> load() async {
    final saved = await _store.read();
    emit(saved ?? AppLocale.ru);
  }

  Future<void> setLocale(AppLocale locale) async {
    if (locale == state) return;
    await _store.write(locale);
    HapticFeedback.selectionClick();
    emit(locale);
  }
}
