import 'package:clover/feature/_feed_/notification_page/data/repository/notifications_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class NotificationsUnreadCubit extends Cubit<int> {
  NotificationsUnreadCubit(this._repository) : super(0);

  final NotificationsRepository _repository;

  Future<void> refresh() async {
    if (isClosed) return;
    try {
      final count = await _repository.countUnread();
      if (isClosed) return;
      emit(count);
    } catch (_) {
      // Keep previous badge state on transient errors.
    }
  }
}
