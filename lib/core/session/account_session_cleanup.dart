import 'package:clover/core/storage/domain/repositories/i_app_storage.dart';
import 'package:clover/feature/post/data/repository/post_repository.dart';
import 'package:clover/feature/profile_page/presentation/cubit/profile_cubit.dart';
import 'package:injectable/injectable.dart';

/// Очистка локальных данных аккаунта при выходе (справочники не затрагиваются).
@lazySingleton
class AccountSessionCleanup {
  AccountSessionCleanup(
    this._storage,
    this._postRepository,
    this._profileCubit,
  );

  final IAppStorage _storage;
  final PostRepository _postRepository;
  final ProfileCubit _profileCubit;

  Future<void> clear() async {
    _postRepository.clearMemoryCache();
    _profileCubit.reset();
    await _storage.clearAccountData();
  }
}
