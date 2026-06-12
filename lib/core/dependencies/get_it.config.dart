// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_sign_in/google_sign_in.dart' as _i116;
import 'package:injectable/injectable.dart' as _i526;
import 'package:supabase_flutter/supabase_flutter.dart' as _i454;

import '../../feature/cities/data/repository/cities_repository.dart' as _i969;
import '../../feature/cities/data/repository/cities_repository_impl.dart'
    as _i656;
import '../../feature/cities/presentation/cubit/cities_cubit.dart' as _i744;
import '../../feature/cluster/data/repository/cluster_repository.dart' as _i312;
import '../../feature/cluster/presentation/cubit/archived_clusters_cubit.dart'
    as _i684;
import '../../feature/cluster/presentation/cubit/clusters_list_cubit.dart'
    as _i402;
import '../../feature/countries/data/repository/countries_repository.dart'
    as _i641;
import '../../feature/countries/data/repository/countries_repository_impl.dart'
    as _i646;
import '../../feature/countries/presentation/cubit/countries_cubit.dart'
    as _i1024;
import '../../feature/post/data/repository/post_local_cache.dart' as _i1045;
import '../../feature/post/data/repository/post_repository.dart' as _i467;
import '../../feature/post/presentation/cubit/post_detail_cubit.dart' as _i430;
import '../../feature/post/presentation/cubit/post_feed_cubit.dart' as _i211;
import '../../feature/post_create/data/repository/post_create_repository.dart'
    as _i603;
import '../../feature/post_create/presentation/cubit/post_create_upload_cubit.dart'
    as _i346;
import '../../feature/profile_categories/data/repository/profile_categories_repository.dart'
    as _i775;
import '../../feature/profile_categories/data/repository/profile_categories_repository_impl.dart'
    as _i394;
import '../../feature/profile_categories/presentation/cubit/profile_categories_cubit.dart'
    as _i122;
import '../../feature/profile_page/data/repository/profile_repository.dart'
    as _i950;
import '../../feature/profile_page/presentation/cubit/profile_cubit.dart'
    as _i961;
import '../auth/cubit/auth_cubit.dart' as _i575;
import '../auth/repositories/auth_repository.dart' as _i964;
import '../network/supabase_edge_functions_invoker.dart' as _i460;
import '../storage/data/repositories/isar_app_storage_impl.dart' as _i814;
import '../storage/domain/repositories/i_app_storage.dart' as _i1029;
import 'module.dart' as _i946;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.lazySingleton<_i454.SupabaseClient>(() => appModule.supabaseClient);
    gh.lazySingleton<_i116.GoogleSignIn>(() => appModule.googleSignIn);
    gh.lazySingleton<_i1029.IAppStorage>(() => _i814.IsarAppStorageImpl());
    gh.lazySingleton<_i964.AuthRepository>(
      () => _i964.AuthRepository(
        gh<_i454.SupabaseClient>(),
        gh<_i1029.IAppStorage>(),
        gh<_i116.GoogleSignIn>(),
      ),
    );
    gh.lazySingleton<_i467.PostRepository>(
      () => _i467.PostRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i460.SupabaseEdgeFunctionsInvoker>(
      () => _i460.SupabaseEdgeFunctionsInvoker(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i603.PostCreateRepository>(
      () => _i603.PostCreateRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i950.ProfileNewRepository>(
      () => _i950.ProfileNewRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i969.CitiesRepository>(
      () => _i656.CitiesRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i312.ClusterRepository>(
      () => _i312.ClusterRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i775.ProfileCategoriesRepository>(
      () => _i394.ProfileCategoriesRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i641.CountriesRepository>(
      () => _i646.CountriesRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i575.AuthCubit>(
      () => _i575.AuthCubit(gh<_i964.AuthRepository>()),
    );
    gh.lazySingleton<_i122.ProfileCategoriesCubit>(
      () =>
          _i122.ProfileCategoriesCubit(gh<_i775.ProfileCategoriesRepository>()),
    );
    gh.lazySingleton<_i744.CitiesCubit>(
      () => _i744.CitiesCubit(gh<_i969.CitiesRepository>()),
    );
    gh.lazySingleton<_i1045.PostLocalCache>(
      () => _i1045.PostLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.factory<_i684.ArchivedClustersCubit>(
      () => _i684.ArchivedClustersCubit(gh<_i312.ClusterRepository>()),
    );
    gh.factory<_i402.ClustersListCubit>(
      () => _i402.ClustersListCubit(gh<_i312.ClusterRepository>()),
    );
    gh.lazySingleton<_i1024.CountriesCubit>(
      () => _i1024.CountriesCubit(gh<_i641.CountriesRepository>()),
    );
    gh.factory<_i430.PostDetailCubit>(
      () => _i430.PostDetailCubit(gh<_i467.PostRepository>()),
    );
    gh.lazySingleton<_i346.PostCreateUploadCubit>(
      () => _i346.PostCreateUploadCubit(gh<_i603.PostCreateRepository>()),
    );
    gh.singleton<_i961.ProfileCubit>(
      () => _i961.ProfileCubit(gh<_i950.ProfileNewRepository>()),
    );
    gh.factory<_i211.PostFeedCubit>(
      () => _i211.PostFeedCubit(
        gh<_i467.PostRepository>(),
        gh<_i1045.PostLocalCache>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i946.AppModule {}
