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

import '../../feature/_bonus_/bonus_history/data/repository/bonus_history_repository.dart'
    as _i1054;
import '../../feature/_bonus_/bonus_history/presentation/cubit/bonus_history_cubit.dart'
    as _i654;
import '../../feature/_bonus_/bonus_settings/data/repository/bonus_program_repository.dart'
    as _i502;
import '../../feature/_bonus_/my_bonuses/data/repository/my_bonuses_repository.dart'
    as _i1031;
import '../../feature/_bonus_/my_bonuses/presentation/cubit/my_bonuses_cubit.dart'
    as _i981;
import '../../feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart'
    as _i627;
import '../../feature/_booking_/booking_analytics/presentation/cubit/booking_analytics_cubit.dart'
    as _i74;
import '../../feature/_booking_/booking_client/data/repository/booking_client_repository.dart'
    as _i350;
import '../../feature/_booking_/booking_client/presentation/cubit/booking_client_cubit.dart'
    as _i978;
import '../../feature/_booking_/booking_create/data/repository/booking_services_repository.dart'
    as _i202;
import '../../feature/_booking_/booking_create/data/repository/booking_staff_repository.dart'
    as _i462;
import '../../feature/_booking_/booking_create/presentation/cubit/booking_service_editor_cubit.dart'
    as _i1020;
import '../../feature/_booking_/booking_create/presentation/cubit/booking_services_cubit.dart'
    as _i1049;
import '../../feature/_booking_/booking_list/data/repository/booking_host_list_repository.dart'
    as _i152;
import '../../feature/_booking_/booking_list/presentation/cubit/booking_list_cubit.dart'
    as _i314;
import '../../feature/_booking_/booking_settings/data/repository/booking_schedule_repository.dart'
    as _i361;
import '../../feature/_booking_/booking_settings/presentation/cubit/booking_schedule_settings_cubit.dart'
    as _i633;
import '../../feature/_booking_/my_bookings/data/repository/my_bookings_repository.dart'
    as _i528;
import '../../feature/_booking_/my_bookings/presentation/cubit/my_bookings_cubit.dart'
    as _i536;
import '../../feature/_booking_/shared/data/booking_local_cache.dart' as _i984;
import '../../feature/archive/event_archive/data/repository/event_archive_repository.dart'
    as _i468;
import '../../feature/archive/event_archive/presentation/cubit/event_archive_cubit.dart'
    as _i897;
import '../../feature/archive/post_archive/data/repository/post_archive_repository.dart'
    as _i464;
import '../../feature/archive/post_archive/presentation/cubit/post_archive_cubit.dart'
    as _i771;
import '../../feature/chat/data/repository/chat_local_cache.dart' as _i369;
import '../../feature/chat/data/repository/chat_repository.dart' as _i425;
import '../../feature/chat_page/presentation/cubit/chat_thread_cubit.dart'
    as _i360;
import '../../feature/cities/data/repository/cities_repository.dart' as _i969;
import '../../feature/cities/data/repository/cities_repository_impl.dart'
    as _i656;
import '../../feature/cities/presentation/cubit/cities_cubit.dart' as _i744;
import '../../feature/cluster/data/repository/cluster_repository.dart' as _i312;
import '../../feature/cluster/presentation/cubit/archived_clusters_cubit.dart'
    as _i684;
import '../../feature/cluster/presentation/cubit/clusters_list_cubit.dart'
    as _i402;
import '../../feature/cluster_create/data/repository/cluster_create_repository.dart'
    as _i342;
import '../../feature/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart'
    as _i91;
import '../../feature/countries/data/repository/countries_repository.dart'
    as _i641;
import '../../feature/countries/data/repository/countries_repository_impl.dart'
    as _i646;
import '../../feature/countries/presentation/cubit/countries_cubit.dart'
    as _i1024;
import '../../feature/currencies/data/repository/currencies_repository.dart'
    as _i425;
import '../../feature/currencies/data/repository/currencies_repository_impl.dart'
    as _i268;
import '../../feature/dashboard_page/data/dashboard_home_mode_store.dart'
    as _i501;
import '../../feature/dashboard_page/presentation/cubit/dashboard_home_mode_cubit.dart'
    as _i4;
import '../../feature/edit_profile/data/repository/edit_profile_repository.dart'
    as _i1059;
import '../../feature/edit_profile/presentation/cubit/edit_profile_cubit.dart'
    as _i764;
import '../../feature/events_page/data/events_filter_location_store.dart'
    as _i956;
import '../../feature/events_page/data/repository/events_feed_repository.dart'
    as _i840;
import '../../feature/events_page/presentation/cubit/events_feed_cubit.dart'
    as _i53;
import '../../feature/followers_and_followings/data/repository/followers_and_followings_repository.dart'
    as _i389;
import '../../feature/followers_and_followings/presentation/cubit/followers_and_followings_cubit.dart'
    as _i17;
import '../../feature/location/data/repository/location_repository.dart'
    as _i391;
import '../../feature/map_page/data/repository/map_markers_repository.dart'
    as _i1033;
import '../../feature/map_page/presentation/cubit/map_markers_cubit.dart'
    as _i669;
import '../../feature/marker_create/data/repository/marker_create_repository.dart'
    as _i492;
import '../../feature/marker_create/presentation/cubit/marker_create_upload_cubit.dart'
    as _i763;
import '../../feature/marker_tags/data/repository/marker_tags_repository.dart'
    as _i202;
import '../../feature/message_page/presentation/cubit/message_list_cubit.dart'
    as _i260;
import '../../feature/notification_page/data/repository/notifications_repository.dart'
    as _i932;
import '../../feature/notification_page/presentation/cubit/notifications_cubit.dart'
    as _i492;
import '../../feature/post/data/repository/post_local_cache.dart' as _i1045;
import '../../feature/post/data/repository/post_repository.dart' as _i467;
import '../../feature/post/presentation/cubit/post_detail_cubit.dart' as _i430;
import '../../feature/post/presentation/cubit/post_feed_cubit.dart' as _i211;
import '../../feature/post_comment/data/repository/post_comment_local_cache.dart'
    as _i356;
import '../../feature/post_comment/data/repository/post_comment_repository.dart'
    as _i741;
import '../../feature/post_comment/presentation/cubit/post_comments_cubit.dart'
    as _i184;
import '../../feature/post_create/data/repository/post_create_repository.dart'
    as _i603;
import '../../feature/post_create/presentation/cubit/post_create_upload_cubit.dart'
    as _i346;
import '../../feature/post_share/data/repository/post_share_local_cache.dart'
    as _i416;
import '../../feature/post_share/data/repository/post_share_repository.dart'
    as _i608;
import '../../feature/post_share/presentation/cubit/post_share_recipients_cubit.dart'
    as _i659;
import '../../feature/profile_categories/data/repository/profile_categories_repository.dart'
    as _i775;
import '../../feature/profile_categories/data/repository/profile_categories_repository_impl.dart'
    as _i394;
import '../../feature/profile_categories/presentation/cubit/profile_categories_cubit.dart'
    as _i122;
import '../../feature/profile_page/data/repository/profile_repository.dart'
    as _i950;
import '../../feature/profile_page/presentation/cubit/guest_profile_cubit.dart'
    as _i911;
import '../../feature/profile_page/presentation/cubit/profile_cubit.dart'
    as _i961;
import '../../feature/settings_filter/data/repository/filter_repository.dart'
    as _i920;
import '../../feature/settings_filter/presentation/profile/cubit/profile_filter_cubit.dart'
    as _i465;
import '../../feature/settings_filter/presentation/settings/cubit/settings_filters_cubit.dart'
    as _i954;
import '../../feature/settings_saved_post/data/repository/saved_posts_repository.dart'
    as _i969;
import '../../feature/settings_saved_post/presentation/cubit/saved_posts_cubit.dart'
    as _i679;
import '../../feature/social_graph/data/repository/social_graph_repository.dart'
    as _i576;
import '../auth/cubit/auth_cubit.dart' as _i575;
import '../auth/repositories/auth_repository.dart' as _i964;
import '../catalog_sync/data/dictionary_local_cache.dart' as _i253;
import '../catalog_sync/data/dictionary_network_source.dart' as _i392;
import '../catalog_sync/domain/catalog_sync_manager.dart' as _i301;
import '../network/supabase_edge_functions_invoker.dart' as _i460;
import '../session/account_session_cleanup.dart' as _i191;
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
    gh.lazySingleton<_i392.DictionaryNetworkSource>(
      () => _i392.DictionaryNetworkSource(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i460.SupabaseEdgeFunctionsInvoker>(
      () => _i460.SupabaseEdgeFunctionsInvoker(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i627.BookingAnalyticsRepository>(
      () => _i627.BookingAnalyticsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i361.BookingScheduleRepository>(
      () => _i361.BookingScheduleRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i202.BookingServicesRepository>(
      () => _i202.BookingServicesRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i464.PostArchiveRepository>(
      () => _i464.PostArchiveRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i425.ChatRepository>(
      () => _i425.ChatRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i312.ClusterRepository>(
      () => _i312.ClusterRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i608.PostShareRepository>(
      () => _i608.PostShareRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i741.PostCommentRepository>(
      () => _i741.PostCommentRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i920.FilterRepository>(
      () => _i920.FilterRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i576.SocialGraphRepository>(
      () => _i576.SocialGraphRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i969.SavedPostsRepository>(
      () => _i969.SavedPostsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i350.BookingClientRepository>(
      () => _i350.BookingClientRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i202.BookingServicesRepository>(),
        gh<_i361.BookingScheduleRepository>(),
      ),
    );
    gh.lazySingleton<_i1054.BonusHistoryRepository>(
      () => _i1054.BonusHistoryRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i468.EventArchiveRepository>(
      () => _i468.EventArchiveRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i462.BookingStaffRepository>(
      () => _i462.BookingStaffRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i152.BookingHostListRepository>(
      () => _i152.BookingHostListRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i528.MyBookingsRepository>(
      () => _i528.MyBookingsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i502.BonusProgramRepository>(
      () => _i502.BonusProgramRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1031.MyBonusesRepository>(
      () => _i1031.MyBonusesRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i391.LocationRepository>(
      () => _i391.LocationRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i389.FollowersAndFollowingsRepository>(
      () => _i389.FollowersAndFollowingsRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i576.SocialGraphRepository>(),
      ),
    );
    gh.lazySingleton<_i932.NotificationsRepository>(
      () => _i932.NotificationsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i633.BookingScheduleSettingsCubit>(
      () => _i633.BookingScheduleSettingsCubit(
        gh<_i361.BookingScheduleRepository>(),
        gh<_i462.BookingStaffRepository>(),
      ),
    );
    gh.factory<_i17.FollowersAndFollowingsCubit>(
      () => _i17.FollowersAndFollowingsCubit(
        gh<_i389.FollowersAndFollowingsRepository>(),
        gh<_i576.SocialGraphRepository>(),
      ),
    );
    gh.factory<_i679.SavedPostsCubit>(
      () => _i679.SavedPostsCubit(gh<_i969.SavedPostsRepository>()),
    );
    gh.factory<_i465.ProfileFilterCubit>(
      () => _i465.ProfileFilterCubit(gh<_i920.FilterRepository>()),
    );
    gh.lazySingleton<_i253.DictionaryLocalCache>(
      () => _i253.DictionaryLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i984.BookingLocalCache>(
      () => _i984.BookingLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i369.ChatLocalCache>(
      () => _i369.ChatLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i501.DashboardHomeModeStore>(
      () => _i501.DashboardHomeModeStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i956.EventsFilterLocationStore>(
      () => _i956.EventsFilterLocationStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i1045.PostLocalCache>(
      () => _i1045.PostLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i356.PostCommentLocalCache>(
      () => _i356.PostCommentLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i416.PostShareLocalCache>(
      () => _i416.PostShareLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.factory<_i684.ArchivedClustersCubit>(
      () => _i684.ArchivedClustersCubit(gh<_i312.ClusterRepository>()),
    );
    gh.factory<_i402.ClustersListCubit>(
      () => _i402.ClustersListCubit(gh<_i312.ClusterRepository>()),
    );
    gh.lazySingleton<_i342.ClusterCreateRepository>(
      () => _i342.ClusterCreateRepositoryImpl(gh<_i312.ClusterRepository>()),
    );
    gh.factory<_i1049.BookingServicesCubit>(
      () => _i1049.BookingServicesCubit(
        gh<_i202.BookingServicesRepository>(),
        gh<_i462.BookingStaffRepository>(),
        gh<_i984.BookingLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i659.PostShareRecipientsCubit>(
      () => _i659.PostShareRecipientsCubit(
        gh<_i608.PostShareRepository>(),
        gh<_i416.PostShareLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i74.BookingAnalyticsCubit>(
      () => _i74.BookingAnalyticsCubit(
        gh<_i627.BookingAnalyticsRepository>(),
        gh<_i462.BookingStaffRepository>(),
      ),
    );
    gh.factory<_i314.BookingListCubit>(
      () => _i314.BookingListCubit(
        gh<_i152.BookingHostListRepository>(),
        gh<_i984.BookingLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i360.ChatThreadCubit>(
      () => _i360.ChatThreadCubit(
        gh<_i425.ChatRepository>(),
        gh<_i369.ChatLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i260.MessageListCubit>(
      () => _i260.MessageListCubit(
        gh<_i425.ChatRepository>(),
        gh<_i369.ChatLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i981.MyBonusesCubit>(
      () => _i981.MyBonusesCubit(gh<_i1031.MyBonusesRepository>()),
    );
    gh.factory<_i536.MyBookingsCubit>(
      () => _i536.MyBookingsCubit(
        gh<_i528.MyBookingsRepository>(),
        gh<_i984.BookingLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i492.NotificationsCubit>(
      () => _i492.NotificationsCubit(gh<_i932.NotificationsRepository>()),
    );
    gh.factory<_i897.EventArchiveCubit>(
      () => _i897.EventArchiveCubit(gh<_i468.EventArchiveRepository>()),
    );
    gh.factory<_i771.PostArchiveCubit>(
      () => _i771.PostArchiveCubit(gh<_i464.PostArchiveRepository>()),
    );
    gh.factory<_i978.BookingClientCubit>(
      () => _i978.BookingClientCubit(gh<_i350.BookingClientRepository>()),
    );
    gh.lazySingleton<_i467.PostRepository>(
      () => _i467.PostRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i1045.PostLocalCache>(),
      ),
    );
    gh.factory<_i654.BonusHistoryCubit>(
      () => _i654.BonusHistoryCubit(gh<_i1054.BonusHistoryRepository>()),
    );
    gh.lazySingleton<_i301.CatalogSyncManager>(
      () => _i301.CatalogSyncManager(
        gh<_i253.DictionaryLocalCache>(),
        gh<_i392.DictionaryNetworkSource>(),
      ),
    );
    gh.lazySingleton<_i775.ProfileCategoriesRepository>(
      () =>
          _i394.ProfileCategoriesRepositoryImpl(gh<_i301.CatalogSyncManager>()),
    );
    gh.factory<_i1020.BookingServiceEditorCubit>(
      () => _i1020.BookingServiceEditorCubit(
        gh<_i202.BookingServicesRepository>(),
        gh<_i462.BookingStaffRepository>(),
      ),
    );
    gh.lazySingleton<_i641.CountriesRepository>(
      () => _i646.CountriesRepositoryImpl(gh<_i301.CatalogSyncManager>()),
    );
    gh.lazySingleton<_i425.CurrenciesRepository>(
      () => _i268.CurrenciesRepositoryImpl(gh<_i301.CatalogSyncManager>()),
    );
    gh.factory<_i4.DashboardHomeModeCubit>(
      () => _i4.DashboardHomeModeCubit(gh<_i501.DashboardHomeModeStore>()),
    );
    gh.factory<_i184.PostCommentsCubit>(
      () => _i184.PostCommentsCubit(
        gh<_i741.PostCommentRepository>(),
        gh<_i356.PostCommentLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i211.PostFeedCubit>(
      () => _i211.PostFeedCubit(
        gh<_i467.PostRepository>(),
        gh<_i1045.PostLocalCache>(),
      ),
    );
    gh.lazySingleton<_i202.MarkerTagsRepository>(
      () => _i202.MarkerTagsRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i301.CatalogSyncManager>(),
      ),
    );
    gh.lazySingleton<_i122.ProfileCategoriesCubit>(
      () =>
          _i122.ProfileCategoriesCubit(gh<_i775.ProfileCategoriesRepository>()),
    );
    gh.lazySingleton<_i1033.MapMarkersRepository>(
      () => _i1033.MapMarkersRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i202.MarkerTagsRepository>(),
      ),
    );
    gh.factory<_i950.ProfileNewRepository>(
      () => _i950.ProfileNewRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i301.CatalogSyncManager>(),
      ),
    );
    gh.lazySingleton<_i1059.EditProfileRepository>(
      () => _i1059.EditProfileRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i950.ProfileNewRepository>(),
      ),
    );
    gh.lazySingleton<_i91.ClusterCreateUploadCubit>(
      () => _i91.ClusterCreateUploadCubit(gh<_i342.ClusterCreateRepository>()),
    );
    gh.lazySingleton<_i1024.CountriesCubit>(
      () => _i1024.CountriesCubit(gh<_i641.CountriesRepository>()),
    );
    gh.lazySingleton<_i840.EventsFeedRepository>(
      () => _i840.EventsFeedRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i467.PostRepository>(),
        gh<_i202.MarkerTagsRepository>(),
      ),
    );
    gh.factory<_i764.EditProfileCubit>(
      () => _i764.EditProfileCubit(gh<_i1059.EditProfileRepository>()),
    );
    gh.singleton<_i961.ProfileCubit>(
      () => _i961.ProfileCubit(gh<_i950.ProfileNewRepository>()),
    );
    gh.lazySingleton<_i492.MarkerCreateRepository>(
      () => _i492.MarkerCreateRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i202.MarkerTagsRepository>(),
        gh<_i920.FilterRepository>(),
      ),
    );
    gh.lazySingleton<_i969.CitiesRepository>(
      () => _i656.CitiesRepositoryImpl(gh<_i301.CatalogSyncManager>()),
    );
    gh.factory<_i911.GuestProfileCubit>(
      () => _i911.GuestProfileCubit(
        gh<_i950.ProfileNewRepository>(),
        gh<_i576.SocialGraphRepository>(),
      ),
    );
    gh.factory<_i430.PostDetailCubit>(
      () => _i430.PostDetailCubit(
        gh<_i467.PostRepository>(),
        gh<_i576.SocialGraphRepository>(),
        gh<_i202.MarkerTagsRepository>(),
      ),
    );
    gh.factory<_i669.MapMarkersCubit>(
      () => _i669.MapMarkersCubit(gh<_i1033.MapMarkersRepository>()),
    );
    gh.lazySingleton<_i191.AccountSessionCleanup>(
      () => _i191.AccountSessionCleanup(
        gh<_i1029.IAppStorage>(),
        gh<_i467.PostRepository>(),
        gh<_i961.ProfileCubit>(),
      ),
    );
    gh.lazySingleton<_i603.PostCreateRepository>(
      () => _i603.PostCreateRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i920.FilterRepository>(),
        gh<_i202.MarkerTagsRepository>(),
      ),
    );
    gh.lazySingleton<_i744.CitiesCubit>(
      () => _i744.CitiesCubit(gh<_i969.CitiesRepository>()),
    );
    gh.lazySingleton<_i964.AuthRepository>(
      () => _i964.AuthRepository(
        gh<_i454.SupabaseClient>(),
        gh<_i1029.IAppStorage>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i191.AccountSessionCleanup>(),
      ),
    );
    gh.lazySingleton<_i763.MarkerCreateUploadCubit>(
      () => _i763.MarkerCreateUploadCubit(gh<_i492.MarkerCreateRepository>()),
    );
    gh.factory<_i53.EventsFeedCubit>(
      () => _i53.EventsFeedCubit(
        gh<_i840.EventsFeedRepository>(),
        gh<_i467.PostRepository>(),
        gh<_i576.SocialGraphRepository>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i954.SettingsFiltersCubit>(
      () => _i954.SettingsFiltersCubit(
        gh<_i920.FilterRepository>(),
        gh<_i454.SupabaseClient>(),
        gh<_i961.ProfileCubit>(),
      ),
    );
    gh.lazySingleton<_i346.PostCreateUploadCubit>(
      () => _i346.PostCreateUploadCubit(
        gh<_i492.MarkerCreateRepository>(),
        gh<_i603.PostCreateRepository>(),
      ),
    );
    gh.factory<_i575.AuthCubit>(
      () => _i575.AuthCubit(gh<_i964.AuthRepository>()),
    );
    return this;
  }
}

class _$AppModule extends _i946.AppModule {}
