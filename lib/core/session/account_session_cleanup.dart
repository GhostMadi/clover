import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/_attendance_/shared/data/attendance_context_store.dart';
import 'package:clover/feature/_post_/post/data/repository/post_repository.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:injectable/injectable.dart';

/// Очистка локальных данных аккаунта при выходе (справочники не затрагиваются).
@lazySingleton
class AccountSessionCleanup {
  AccountSessionCleanup(
    this._storage,
    this._postRepository,
    this._profileCubit,
    this._attendanceStore,
  );

  final IAppStorage _storage;
  final PostRepository _postRepository;
  final ProfileCubit _profileCubit;
  final AttendanceContextStore _attendanceStore;

  Future<void> clear() async {
    _postRepository.clearMemoryCache();
    _profileCubit.reset();
    await _attendanceStore.clearForSignOut();
    await _storage.clearAccountData();
  }
}
