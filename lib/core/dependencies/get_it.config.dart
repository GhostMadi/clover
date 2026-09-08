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

import '../../feature/_archive_/event_archive/data/repository/event_archive_repository.dart'
    as _i74;
import '../../feature/_archive_/event_archive/presentation/cubit/event_archive_cubit.dart'
    as _i68;
import '../../feature/_archive_/post_archive/data/repository/post_archive_repository.dart'
    as _i381;
import '../../feature/_archive_/post_archive/presentation/cubit/post_archive_cubit.dart'
    as _i643;
import '../../feature/_attendance_/attendance_absences/presentation/cubit/attendance_absences_cubit.dart'
    as _i967;
import '../../feature/_attendance_/attendance_analytics/data/attendance_analytics_loader.dart'
    as _i522;
import '../../feature/_attendance_/attendance_analytics/presentation/cubit/attendance_analytics_cubit.dart'
    as _i604;
import '../../feature/_attendance_/attendance_company/presentation/cubit/attendance_company_cubit.dart'
    as _i971;
import '../../feature/_attendance_/attendance_company_chat/presentation/cubit/attendance_company_chat_cubit.dart'
    as _i322;
import '../../feature/_attendance_/attendance_corrections/presentation/cubit/attendance_corrections_cubit.dart'
    as _i1009;
import '../../feature/_attendance_/attendance_hub/presentation/cubit/attendance_hub_cubit.dart'
    as _i190;
import '../../feature/_attendance_/attendance_overtime/presentation/cubit/attendance_overtime_cubit.dart'
    as _i532;
import '../../feature/_attendance_/attendance_payroll_rules/presentation/cubit/attendance_payroll_rules_cubit.dart'
    as _i456;
import '../../feature/_attendance_/attendance_punch/presentation/cubit/attendance_punch_cubit.dart'
    as _i534;
import '../../feature/_attendance_/attendance_timesheet/presentation/cubit/attendance_timesheet_cubit.dart'
    as _i426;
import '../../feature/_attendance_/attendance_worker/presentation/cubit/attendance_worker_hub_cubit.dart'
    as _i905;
import '../../feature/_attendance_/attendance_workers/presentation/cubit/attendance_workers_cubit.dart'
    as _i72;
import '../../feature/_attendance_/attendance_workplace_settings/presentation/cubit/attendance_workplace_settings_cubit.dart'
    as _i381;
import '../../feature/_attendance_/shared/data/attendance_context_store.dart'
    as _i865;
import '../../feature/_attendance_/shared/data/attendance_outbox.dart' as _i352;
import '../../feature/_attendance_/shared/data/attendance_remote_repository.dart'
    as _i75;
import '../../feature/_attendance_/shared/data/profile_attendance_admin_shortcut_store.dart'
    as _i274;
import '../../feature/_bonus_/bonus_history/data/repository/bonus_history_repository.dart'
    as _i1054;
import '../../feature/_bonus_/bonus_history/presentation/cubit/bonus_history_cubit.dart'
    as _i654;
import '../../feature/_bonus_/my_bonuses/data/repository/my_bonuses_repository.dart'
    as _i1031;
import '../../feature/_bonus_/my_bonuses/presentation/cubit/my_bonuses_cubit.dart'
    as _i981;
import '../../feature/_booking_/booking_analytics/data/repository/booking_analytics_repository.dart'
    as _i627;
import '../../feature/_booking_/booking_analytics/presentation/cubit/booking_analytics_cubit.dart'
    as _i74;
import '../../feature/_booking_/booking_calendar/data/repository/booking_calendar_repository.dart'
    as _i299;
import '../../feature/_booking_/booking_calendar/presentation/cubit/booking_calendar_bookings_cubit.dart'
    as _i497;
import '../../feature/_booking_/booking_calendar/presentation/cubit/booking_calendar_hosts_cubit.dart'
    as _i104;
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
import '../../feature/_booking_/booking_create/presentation/cubit/booking_staff_search_cubit.dart'
    as _i91;
import '../../feature/_booking_/booking_list/data/models/booking_list_item.dart'
    as _i381;
import '../../feature/_booking_/booking_list/data/repository/booking_host_list_repository.dart'
    as _i152;
import '../../feature/_booking_/booking_list/presentation/cubit/booking_list_cubit.dart'
    as _i314;
import '../../feature/_booking_/booking_list/presentation/cubit/booking_list_detail_cubit.dart'
    as _i788;
import '../../feature/_booking_/booking_settings/data/repository/booking_ops_repository.dart'
    as _i239;
import '../../feature/_booking_/booking_settings/data/repository/booking_schedule_repository.dart'
    as _i361;
import '../../feature/_booking_/booking_settings/presentation/cubit/booking_schedule_ops_cubit.dart'
    as _i545;
import '../../feature/_booking_/booking_settings/presentation/cubit/booking_schedule_settings_cubit.dart'
    as _i633;
import '../../feature/_booking_/my_bookings/data/models/my_booking_item.dart'
    as _i56;
import '../../feature/_booking_/my_bookings/data/repository/my_bookings_repository.dart'
    as _i528;
import '../../feature/_booking_/my_bookings/presentation/cubit/my_booking_detail_cubit.dart'
    as _i140;
import '../../feature/_booking_/my_bookings/presentation/cubit/my_bookings_cubit.dart'
    as _i536;
import '../../feature/_booking_/shared/data/booking_local_cache.dart' as _i984;
import '../../feature/_booking_/shared/data/repository/booking_deep_link_repository.dart'
    as _i324;
import '../../feature/_booking_/shared/presentation/cubit/booking_reschedule_cubit.dart'
    as _i635;
import '../../feature/_catalog_/location/data/repository/location_repository.dart'
    as _i634;
import '../../feature/_catalog_/location/presentation/cubit/location_cubit.dart'
    as _i339;
import '../../feature/_catalog_/marker_tags/data/repository/marker_tags_repository.dart'
    as _i34;
import '../../feature/_catalog_/social_graph/data/repository/social_graph_repository.dart'
    as _i469;
import '../../feature/_chat_/chat/data/repository/chat_local_cache.dart'
    as _i325;
import '../../feature/_chat_/chat/data/repository/chat_repository.dart'
    as _i233;
import '../../feature/_chat_/chat_page/presentation/cubit/chat_thread_cubit.dart'
    as _i719;
import '../../feature/_chat_/message_page/presentation/cubit/message_list_cubit.dart'
    as _i122;
import '../../feature/_cluster_/cluster/data/repository/cluster_repository.dart'
    as _i347;
import '../../feature/_cluster_/cluster/presentation/cubit/archived_clusters_cubit.dart'
    as _i350;
import '../../feature/_cluster_/cluster/presentation/cubit/clusters_list_cubit.dart'
    as _i1006;
import '../../feature/_cluster_/cluster_create/data/repository/cluster_create_repository.dart'
    as _i220;
import '../../feature/_cluster_/cluster_create/presentation/cubit/cluster_create_upload_cubit.dart'
    as _i16;
import '../../feature/_feed_/events_page/data/events_filter_location_store.dart'
    as _i566;
import '../../feature/_feed_/events_page/data/repository/events_feed_repository.dart'
    as _i885;
import '../../feature/_feed_/events_page/presentation/cubit/events_feed_cubit.dart'
    as _i359;
import '../../feature/_feed_/map_page/data/repository/map_markers_repository.dart'
    as _i232;
import '../../feature/_feed_/map_page/presentation/cubit/map_markers_cubit.dart'
    as _i1010;
import '../../feature/_feed_/notification_page/data/repository/notifications_repository.dart'
    as _i194;
import '../../feature/_feed_/notification_page/presentation/cubit/notifications_cubit.dart'
    as _i996;
import '../../feature/_feed_/notification_page/presentation/cubit/notifications_unread_cubit.dart'
    as _i138;
import '../../feature/_post_/post/data/repository/post_local_cache.dart'
    as _i737;
import '../../feature/_post_/post/data/repository/post_repository.dart'
    as _i984;
import '../../feature/_post_/post/presentation/cubit/post_detail_cubit.dart'
    as _i213;
import '../../feature/_post_/post/presentation/cubit/post_feed_cubit.dart'
    as _i656;
import '../../feature/_post_/post_comment/data/repository/post_comment_local_cache.dart'
    as _i753;
import '../../feature/_post_/post_comment/data/repository/post_comment_repository.dart'
    as _i454;
import '../../feature/_post_/post_comment/presentation/cubit/post_comments_cubit.dart'
    as _i685;
import '../../feature/_post_/post_create/data/repository/post_create_repository.dart'
    as _i317;
import '../../feature/_post_/post_create/presentation/cubit/post_create_upload_cubit.dart'
    as _i614;
import '../../feature/_post_/post_share/data/repository/post_share_local_cache.dart'
    as _i824;
import '../../feature/_post_/post_share/data/repository/post_share_repository.dart'
    as _i350;
import '../../feature/_post_/post_share/presentation/cubit/post_share_recipients_cubit.dart'
    as _i671;
import '../../feature/_profile_/edit_profile/data/repository/edit_profile_repository.dart'
    as _i252;
import '../../feature/_profile_/edit_profile/presentation/cubit/edit_profile_cubit.dart'
    as _i19;
import '../../feature/_profile_/followers_and_followings/data/repository/followers_and_followings_repository.dart'
    as _i986;
import '../../feature/_profile_/followers_and_followings/presentation/cubit/followers_and_followings_cubit.dart'
    as _i776;
import '../../feature/_profile_/profile_page/data/profile_resources_shortcut_store.dart'
    as _i461;
import '../../feature/_profile_/profile_page/data/repository/profile_repository.dart'
    as _i57;
import '../../feature/_profile_/profile_page/presentation/cubit/guest_profile_cubit.dart'
    as _i554;
import '../../feature/_profile_/profile_page/presentation/cubit/profile_cubit.dart'
    as _i95;
import '../../feature/_settings_/settings_filter/data/repository/filter_repository.dart'
    as _i858;
import '../../feature/_settings_/settings_filter/presentation/profile/cubit/profile_filter_cubit.dart'
    as _i121;
import '../../feature/_settings_/settings_filter/presentation/settings/cubit/settings_filters_cubit.dart'
    as _i1052;
import '../../feature/_settings_/settings_saved_post/data/repository/saved_posts_repository.dart'
    as _i15;
import '../../feature/_settings_/settings_saved_post/presentation/cubit/saved_posts_cubit.dart'
    as _i1053;
import '../../feature/dashboard_page/data/dashboard_home_mode_store.dart'
    as _i501;
import '../../feature/dashboard_page/presentation/cubit/dashboard_home_mode_cubit.dart'
    as _i4;
import '../../feature/onboarding/data/onboarding_store.dart' as _i643;
import '../auth/cubit/auth_cubit.dart' as _i575;
import '../auth/repositories/auth_repository.dart' as _i964;
import '../deep_link/app_deep_link_navigator.dart' as _i79;
import '../deep_link/app_deep_link_service.dart' as _i856;
import '../network/supabase_edge_functions_invoker.dart' as _i460;
import '../push/app_push_messaging_service.dart' as _i86;
import '../push/push_device_token_repository.dart' as _i516;
import '../session/account_session_cleanup.dart' as _i191;
import '../session/app_session.dart' as _i819;
import '../storage/data/repositories/isar_app_storage_impl.dart' as _i814;
import '../storage/domain/repositories/i_app_storage.dart' as _i1029;
import '../theme/app_theme_cubit.dart' as _i678;
import '../theme/app_theme_store.dart' as _i980;
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
    gh.lazySingleton<_i347.ClusterRepository>(
      () => _i347.ClusterRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i460.SupabaseEdgeFunctionsInvoker>(
      () => _i460.SupabaseEdgeFunctionsInvoker(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i516.PushDeviceTokenRepository>(
      () => _i516.PushDeviceTokenRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i819.AppSession>(
      () => _i819.AppSession(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i75.AttendanceRemoteRepository>(
      () => _i75.AttendanceRemoteRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i627.BookingAnalyticsRepository>(
      () => _i627.BookingAnalyticsRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i299.BookingCalendarRepository>(
      () => _i299.BookingCalendarRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i202.BookingServicesRepository>(
      () => _i202.BookingServicesRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i462.BookingStaffRepository>(
      () => _i462.BookingStaffRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i152.BookingHostListRepository>(
      () => _i152.BookingHostListRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i239.BookingOpsRepository>(
      () => _i239.BookingOpsRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i361.BookingScheduleRepository>(
      () => _i361.BookingScheduleRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i528.MyBookingsRepository>(
      () => _i528.MyBookingsRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i324.BookingDeepLinkRepository>(
      () => _i324.BookingDeepLinkRepository(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i86.AppPushMessagingService>(
      () => _i86.AppPushMessagingService(
        gh<_i454.SupabaseClient>(),
        gh<_i516.PushDeviceTokenRepository>(),
      ),
    );
    gh.lazySingleton<_i15.SavedPostsRepository>(
      () => _i15.SavedPostsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i1009.AttendanceCorrectionsCubit>(
      () => _i1009.AttendanceCorrectionsCubit(
        gh<_i75.AttendanceRemoteRepository>(),
      ),
    );
    gh.lazySingleton<_i34.MarkerTagsRepository>(
      () => _i34.MarkerTagsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factoryParam<_i140.MyBookingDetailCubit, _i56.MyBookingItem, dynamic>(
      (item, _) =>
          _i140.MyBookingDetailCubit(gh<_i528.MyBookingsRepository>(), item),
    );
    gh.lazySingleton<_i634.LocationRepository>(
      () => _i634.LocationRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i1020.BookingServiceEditorCubit>(
      () => _i1020.BookingServiceEditorCubit(
        gh<_i202.BookingServicesRepository>(),
        gh<_i462.BookingStaffRepository>(),
      ),
    );
    gh.lazySingleton<_i858.FilterRepository>(
      () => _i858.FilterRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i1054.BonusHistoryRepository>(
      () => _i1054.BonusHistoryRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i454.PostCommentRepository>(
      () => _i454.PostCommentRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i57.ProfileNewRepository>(
      () => _i57.ProfileNewRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i233.ChatRepository>(
      () => _i233.ChatRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i460.SupabaseEdgeFunctionsInvoker>(),
      ),
    );
    gh.lazySingleton<_i381.PostArchiveRepository>(
      () => _i381.PostArchiveRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i74.EventArchiveRepository>(
      () => _i74.EventArchiveRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i350.BookingClientRepository>(
      () => _i350.BookingClientRepository(
        gh<_i454.SupabaseClient>(),
        gh<_i202.BookingServicesRepository>(),
        gh<_i361.BookingScheduleRepository>(),
      ),
    );
    gh.lazySingleton<_i1031.MyBonusesRepository>(
      () => _i1031.MyBonusesRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i232.MapMarkersRepository>(
      () => _i232.MapMarkersRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i79.AppDeepLinkNavigator>(
      () => _i79.AppDeepLinkNavigator(gh<_i324.BookingDeepLinkRepository>()),
    );
    gh.lazySingleton<_i350.PostShareRepository>(
      () => _i350.PostShareRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i469.SocialGraphRepository>(
      () => _i469.SocialGraphRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.factory<_i1053.SavedPostsCubit>(
      () => _i1053.SavedPostsCubit(gh<_i15.SavedPostsRepository>()),
    );
    gh.lazySingleton<_i194.NotificationsRepository>(
      () => _i194.NotificationsRepositoryImpl(gh<_i454.SupabaseClient>()),
    );
    gh.lazySingleton<_i138.NotificationsUnreadCubit>(
      () => _i138.NotificationsUnreadCubit(gh<_i194.NotificationsRepository>()),
    );
    gh.factory<_i339.LocationCubit>(
      () => _i339.LocationCubit(gh<_i634.LocationRepository>()),
    );
    gh.factory<_i633.BookingScheduleSettingsCubit>(
      () => _i633.BookingScheduleSettingsCubit(
        gh<_i361.BookingScheduleRepository>(),
        gh<_i462.BookingStaffRepository>(),
      ),
    );
    gh.factory<_i350.ArchivedClustersCubit>(
      () => _i350.ArchivedClustersCubit(gh<_i347.ClusterRepository>()),
    );
    gh.factory<_i1006.ClustersListCubit>(
      () => _i1006.ClustersListCubit(gh<_i347.ClusterRepository>()),
    );
    gh.factory<_i545.BookingScheduleOpsCubit>(
      () => _i545.BookingScheduleOpsCubit(gh<_i239.BookingOpsRepository>()),
    );
    gh.lazySingleton<_i980.AppThemeStore>(
      () => _i980.AppThemeStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i274.ProfileAttendanceAdminShortcutStore>(
      () => _i274.ProfileAttendanceAdminShortcutStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i984.BookingLocalCache>(
      () => _i984.BookingLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i325.ChatLocalCache>(
      () => _i325.ChatLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i566.EventsFilterLocationStore>(
      () => _i566.EventsFilterLocationStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i737.PostLocalCache>(
      () => _i737.PostLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i753.PostCommentLocalCache>(
      () => _i753.PostCommentLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i824.PostShareLocalCache>(
      () => _i824.PostShareLocalCache(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i461.ProfileResourcesShortcutStore>(
      () => _i461.ProfileResourcesShortcutStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i501.DashboardHomeModeStore>(
      () => _i501.DashboardHomeModeStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i643.OnboardingStore>(
      () => _i643.OnboardingStore(gh<_i1029.IAppStorage>()),
    );
    gh.lazySingleton<_i352.AttendanceOutbox>(
      () => _i352.AttendanceOutbox(
        gh<_i1029.IAppStorage>(),
        gh<_i75.AttendanceRemoteRepository>(),
      ),
    );
    gh.lazySingleton<_i317.PostCreateRepository>(
      () => _i317.PostCreateRepository(
        gh<_i454.SupabaseClient>(),
        gh<_i858.FilterRepository>(),
        gh<_i34.MarkerTagsRepository>(),
      ),
    );
    gh.lazySingleton<_i220.ClusterCreateRepository>(
      () => _i220.ClusterCreateRepositoryImpl(gh<_i347.ClusterRepository>()),
    );
    gh.lazySingleton<_i678.AppThemeCubit>(
      () => _i678.AppThemeCubit(gh<_i980.AppThemeStore>()),
    );
    gh.lazySingleton<_i984.PostRepository>(
      () => _i984.PostRepository(
        gh<_i454.SupabaseClient>(),
        gh<_i737.PostLocalCache>(),
      ),
    );
    gh.factory<_i719.ChatThreadCubit>(
      () => _i719.ChatThreadCubit(
        gh<_i233.ChatRepository>(),
        gh<_i325.ChatLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i122.MessageListCubit>(
      () => _i122.MessageListCubit(
        gh<_i233.ChatRepository>(),
        gh<_i325.ChatLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.lazySingleton<_i885.EventsFeedRepository>(
      () => _i885.EventsFeedRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i984.PostRepository>(),
      ),
    );
    gh.singleton<_i95.ProfileCubit>(
      () => _i95.ProfileCubit(gh<_i57.ProfileNewRepository>()),
    );
    gh.factory<_i74.BookingAnalyticsCubit>(
      () => _i74.BookingAnalyticsCubit(
        gh<_i627.BookingAnalyticsRepository>(),
        gh<_i462.BookingStaffRepository>(),
      ),
    );
    gh.factory<_i497.BookingCalendarBookingsCubit>(
      () => _i497.BookingCalendarBookingsCubit(
        gh<_i299.BookingCalendarRepository>(),
      ),
    );
    gh.factory<_i104.BookingCalendarHostsCubit>(
      () => _i104.BookingCalendarHostsCubit(
        gh<_i299.BookingCalendarRepository>(),
      ),
    );
    gh.factoryParam<
      _i788.BookingListDetailCubit,
      _i381.BookingListItem,
      dynamic
    >(
      (item, _) => _i788.BookingListDetailCubit(
        gh<_i152.BookingHostListRepository>(),
        item,
      ),
    );
    gh.factory<_i554.GuestProfileCubit>(
      () => _i554.GuestProfileCubit(
        gh<_i57.ProfileNewRepository>(),
        gh<_i469.SocialGraphRepository>(),
      ),
    );
    gh.factory<_i91.BookingStaffSearchCubit>(
      () => _i91.BookingStaffSearchCubit(gh<_i462.BookingStaffRepository>()),
    );
    gh.factory<_i981.MyBonusesCubit>(
      () => _i981.MyBonusesCubit(gh<_i1031.MyBonusesRepository>()),
    );
    gh.lazySingleton<_i986.FollowersAndFollowingsRepository>(
      () => _i986.FollowersAndFollowingsRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i469.SocialGraphRepository>(),
      ),
    );
    gh.factory<_i536.MyBookingsCubit>(
      () => _i536.MyBookingsCubit(
        gh<_i528.MyBookingsRepository>(),
        gh<_i984.BookingLocalCache>(),
        gh<_i819.AppSession>(),
      ),
    );
    gh.factory<_i121.ProfileFilterCubit>(
      () => _i121.ProfileFilterCubit(gh<_i858.FilterRepository>()),
    );
    gh.lazySingleton<_i614.PostCreateUploadCubit>(
      () => _i614.PostCreateUploadCubit(gh<_i317.PostCreateRepository>()),
    );
    gh.factory<_i643.PostArchiveCubit>(
      () => _i643.PostArchiveCubit(
        gh<_i381.PostArchiveRepository>(),
        gh<_i74.EventArchiveRepository>(),
      ),
    );
    gh.factory<_i68.EventArchiveCubit>(
      () => _i68.EventArchiveCubit(gh<_i74.EventArchiveRepository>()),
    );
    gh.factory<_i1049.BookingServicesCubit>(
      () => _i1049.BookingServicesCubit(
        gh<_i202.BookingServicesRepository>(),
        gh<_i462.BookingStaffRepository>(),
        gh<_i984.BookingLocalCache>(),
        gh<_i819.AppSession>(),
      ),
    );
    gh.factory<_i996.NotificationsCubit>(
      () => _i996.NotificationsCubit(
        gh<_i194.NotificationsRepository>(),
        gh<_i469.SocialGraphRepository>(),
        gh<_i138.NotificationsUnreadCubit>(),
      ),
    );
    gh.factory<_i1010.MapMarkersCubit>(
      () => _i1010.MapMarkersCubit(gh<_i232.MapMarkersRepository>()),
    );
    gh.factory<_i978.BookingClientCubit>(
      () => _i978.BookingClientCubit(gh<_i350.BookingClientRepository>()),
    );
    gh.factory<_i635.BookingRescheduleCubit>(
      () => _i635.BookingRescheduleCubit(gh<_i350.BookingClientRepository>()),
    );
    gh.factory<_i213.PostDetailCubit>(
      () => _i213.PostDetailCubit(
        gh<_i984.PostRepository>(),
        gh<_i469.SocialGraphRepository>(),
      ),
    );
    gh.factory<_i671.PostShareRecipientsCubit>(
      () => _i671.PostShareRecipientsCubit(
        gh<_i350.PostShareRepository>(),
        gh<_i824.PostShareLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i654.BonusHistoryCubit>(
      () => _i654.BonusHistoryCubit(gh<_i1054.BonusHistoryRepository>()),
    );
    gh.lazySingleton<_i856.AppDeepLinkService>(
      () => _i856.AppDeepLinkService(
        gh<_i79.AppDeepLinkNavigator>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i656.PostFeedCubit>(
      () => _i656.PostFeedCubit(
        gh<_i984.PostRepository>(),
        gh<_i737.PostLocalCache>(),
      ),
    );
    gh.lazySingleton<_i252.EditProfileRepository>(
      () => _i252.EditProfileRepositoryImpl(
        gh<_i454.SupabaseClient>(),
        gh<_i57.ProfileNewRepository>(),
        gh<_i34.MarkerTagsRepository>(),
      ),
    );
    gh.factory<_i685.PostCommentsCubit>(
      () => _i685.PostCommentsCubit(
        gh<_i454.PostCommentRepository>(),
        gh<_i753.PostCommentLocalCache>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.lazySingleton<_i16.ClusterCreateUploadCubit>(
      () => _i16.ClusterCreateUploadCubit(gh<_i220.ClusterCreateRepository>()),
    );
    gh.factory<_i359.EventsFeedCubit>(
      () => _i359.EventsFeedCubit(
        gh<_i885.EventsFeedRepository>(),
        gh<_i984.PostRepository>(),
        gh<_i469.SocialGraphRepository>(),
        gh<_i454.SupabaseClient>(),
      ),
    );
    gh.factory<_i776.FollowersAndFollowingsCubit>(
      () => _i776.FollowersAndFollowingsCubit(
        gh<_i986.FollowersAndFollowingsRepository>(),
        gh<_i469.SocialGraphRepository>(),
      ),
    );
    gh.factory<_i4.DashboardHomeModeCubit>(
      () => _i4.DashboardHomeModeCubit(gh<_i501.DashboardHomeModeStore>()),
    );
    gh.lazySingleton<_i865.AttendanceContextStore>(
      () => _i865.AttendanceContextStore(
        gh<_i1029.IAppStorage>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i352.AttendanceOutbox>(),
      ),
    );
    gh.factory<_i314.BookingListCubit>(
      () => _i314.BookingListCubit(
        gh<_i152.BookingHostListRepository>(),
        gh<_i984.BookingLocalCache>(),
        gh<_i819.AppSession>(),
      ),
    );
    gh.lazySingleton<_i191.AccountSessionCleanup>(
      () => _i191.AccountSessionCleanup(
        gh<_i1029.IAppStorage>(),
        gh<_i984.PostRepository>(),
        gh<_i95.ProfileCubit>(),
        gh<_i865.AttendanceContextStore>(),
      ),
    );
    gh.factory<_i19.EditProfileCubit>(
      () => _i19.EditProfileCubit(gh<_i252.EditProfileRepository>()),
    );
    gh.factory<_i1052.SettingsFiltersCubit>(
      () => _i1052.SettingsFiltersCubit(
        gh<_i858.FilterRepository>(),
        gh<_i454.SupabaseClient>(),
        gh<_i95.ProfileCubit>(),
      ),
    );
    gh.lazySingleton<_i522.AttendanceAnalyticsLoader>(
      () => _i522.AttendanceAnalyticsLoader(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
      ),
    );
    gh.factory<_i322.AttendanceCompanyChatCubit>(
      () => _i322.AttendanceCompanyChatCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
      ),
    );
    gh.factory<_i190.AttendanceHubCubit>(
      () => _i190.AttendanceHubCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
      ),
    );
    gh.factory<_i72.AttendanceWorkersCubit>(
      () => _i72.AttendanceWorkersCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i233.ChatRepository>(),
      ),
    );
    gh.factory<_i905.AttendanceWorkerHubCubit>(
      () => _i905.AttendanceWorkerHubCubit(gh<_i865.AttendanceContextStore>()),
    );
    gh.lazySingleton<_i964.AuthRepository>(
      () => _i964.AuthRepository(
        gh<_i454.SupabaseClient>(),
        gh<_i1029.IAppStorage>(),
        gh<_i116.GoogleSignIn>(),
        gh<_i191.AccountSessionCleanup>(),
        gh<_i86.AppPushMessagingService>(),
      ),
    );
    gh.factory<_i967.AttendanceAbsencesCubit>(
      () => _i967.AttendanceAbsencesCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i352.AttendanceOutbox>(),
      ),
    );
    gh.factory<_i532.AttendanceOvertimeCubit>(
      () => _i532.AttendanceOvertimeCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i352.AttendanceOutbox>(),
      ),
    );
    gh.factory<_i456.AttendancePayrollRulesCubit>(
      () => _i456.AttendancePayrollRulesCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i352.AttendanceOutbox>(),
      ),
    );
    gh.factory<_i534.AttendancePunchCubit>(
      () => _i534.AttendancePunchCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i352.AttendanceOutbox>(),
      ),
    );
    gh.factory<_i381.AttendanceWorkplaceSettingsCubit>(
      () => _i381.AttendanceWorkplaceSettingsCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i352.AttendanceOutbox>(),
      ),
    );
    gh.factory<_i426.AttendanceTimesheetCubit>(
      () => _i426.AttendanceTimesheetCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i75.AttendanceRemoteRepository>(),
        gh<_i522.AttendanceAnalyticsLoader>(),
      ),
    );
    gh.factory<_i575.AuthCubit>(
      () => _i575.AuthCubit(gh<_i964.AuthRepository>()),
    );
    gh.factory<_i604.AttendanceAnalyticsCubit>(
      () => _i604.AttendanceAnalyticsCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i522.AttendanceAnalyticsLoader>(),
      ),
    );
    gh.factory<_i971.AttendanceCompanyCubit>(
      () => _i971.AttendanceCompanyCubit(
        gh<_i865.AttendanceContextStore>(),
        gh<_i522.AttendanceAnalyticsLoader>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i946.AppModule {}
