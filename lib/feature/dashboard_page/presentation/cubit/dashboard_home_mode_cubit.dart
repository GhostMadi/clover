import 'package:clover/feature/dashboard_page/data/dashboard_home_mode_store.dart';
import 'package:clover/feature/dashboard_page/data/models/dashboard_home_mode.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

@injectable
class DashboardHomeModeCubit extends Cubit<DashboardHomeMode> {
  DashboardHomeModeCubit(this._store) : super(DashboardHomeMode.events);

  final DashboardHomeModeStore _store;

  Future<void> load() async {
    emit(await _store.read());
  }

  Future<void> toggle() async {
    final next = state == DashboardHomeMode.events ? DashboardHomeMode.map : DashboardHomeMode.events;
    await _store.write(next);
    HapticFeedback.mediumImpact();
    emit(next);
  }
}
