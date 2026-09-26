// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_done => 'Done';

  @override
  String get common_close => 'Close';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_continue => 'Continue';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_error => 'Error';

  @override
  String get common_loading => 'Loading…';

  @override
  String get common_yes => 'Yes';

  @override
  String get common_no => 'No';

  @override
  String get common_ok => 'OK';

  @override
  String get common_show => 'Show';

  @override
  String get common_hide => 'Hide';

  @override
  String get common_or => 'or';

  @override
  String get common_search => 'Search';

  @override
  String get common_empty => 'Nothing here yet';

  @override
  String get common_share => 'Share';

  @override
  String get common_copy => 'Copy';

  @override
  String get common_send => 'Send';

  @override
  String get common_add => 'Add';

  @override
  String get common_remove => 'Remove';

  @override
  String get common_create => 'Create';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_start => 'Get started';

  @override
  String get common_logout => 'Log out';

  @override
  String get common_password => 'Password';

  @override
  String get common_checking => 'Checking…';

  @override
  String get common_user => 'User';

  @override
  String common_version(String version) {
    return 'Version $version';
  }

  @override
  String get common_theme_system => 'System';

  @override
  String get common_theme_light => 'Light';

  @override
  String get common_theme_dark => 'Dark';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_section_services => 'Services';

  @override
  String get settings_section_archives => 'Archives';

  @override
  String get settings_section_account => 'Account';

  @override
  String get settings_section_about => 'About';

  @override
  String get settings_guide_title => 'Guide';

  @override
  String get settings_guide_subtitle => 'How to enable and use services';

  @override
  String get settings_booking_title => 'Booking';

  @override
  String get settings_booking_subtitle => 'Services, inbox and schedule';

  @override
  String get settings_attendance_title => 'Attendance';

  @override
  String get settings_attendance_subtitle => 'Companies, geofence and workers';

  @override
  String get settings_resources_title => 'Resources';

  @override
  String get settings_resources_subtitle => 'Locations and filters';

  @override
  String get settings_archives_title => 'Archives';

  @override
  String get settings_archives_subtitle => 'Posts and clusters';

  @override
  String get settings_saved_posts_title => 'Saved posts';

  @override
  String get settings_saved_posts_subtitle => 'Posts you saved';

  @override
  String get settings_account_title => 'Account';

  @override
  String get settings_account_subtitle => 'Language, theme and sign out';

  @override
  String get settings_blocked_title => 'Blocked';

  @override
  String get settings_blocked_subtitle => 'People you blocked';

  @override
  String get settings_about_title => 'About';

  @override
  String get settings_about_subtitle => 'Version and onboarding';

  @override
  String get settings_account_page_title => 'Account';

  @override
  String get settings_account_section_general => 'General';

  @override
  String get settings_account_section_security => 'Security';

  @override
  String get settings_account_section_session => 'Session';

  @override
  String get settings_account_language => 'Language';

  @override
  String get settings_account_theme => 'Theme';

  @override
  String get settings_account_reset_password => 'Reset password';

  @override
  String get settings_account_set_password => 'Set password';

  @override
  String get settings_account_password_reset_hint =>
      'Email code → new password';

  @override
  String get settings_account_password_set_hint =>
      'Set a password for email or username sign-in';

  @override
  String get settings_account_password_check_failed =>
      'Couldn’t check password status';

  @override
  String get settings_account_logout_title => 'Sign out';

  @override
  String get settings_account_logout_confirm => 'Sign out of this device?';

  @override
  String get settings_account_logout_action => 'Sign out';

  @override
  String get settings_account_hibernate_title => 'Sleep account';

  @override
  String get settings_account_hibernate_body =>
      'Your profile and posts are hidden from feeds and search. This is not deletion — signing in again wakes the account. Sleep again at most once every 30 days.';

  @override
  String get settings_account_hibernate_action => 'Sleep';

  @override
  String get settings_account_hibernate_subtitle =>
      'Hide profile and posts. Not deletion.';

  @override
  String get settings_account_deactivate_title => 'Deactivate account?';

  @override
  String get settings_account_deactivate_body =>
      'Your profile and posts will be hidden from feeds and search. This is not permanent deletion: signing in again wakes the account.\n\nTo permanently delete your account and data, contact support at clover.com.kz/delete-account.';

  @override
  String get settings_account_deactivate_action => 'Deactivate';

  @override
  String get settings_account_deactivate_tile => 'Deactivate account';

  @override
  String get settings_account_deactivate_subtitle =>
      'Hide profile. Permanent delete via support.';

  @override
  String get settings_about_page_title => 'About';

  @override
  String get settings_about_tagline =>
      'Events, map, chat and business services — brighter life, simpler work.';

  @override
  String get settings_about_section_help => 'Help';

  @override
  String get settings_about_onboarding_title => 'Onboarding';

  @override
  String get settings_about_onboarding_subtitle =>
      'Show the app introduction again';

  @override
  String get settings_blocked_page_title => 'Blocked';

  @override
  String get settings_blocked_unblock_title => 'Unblock?';

  @override
  String settings_blocked_unblock_confirm(String name) {
    return 'Unblock $name?';
  }

  @override
  String get auth_login_terms_required => 'Accept the terms to continue';

  @override
  String get auth_login_identifier_label => 'Username or email';

  @override
  String get auth_login_identifier_hint => '@username or email';

  @override
  String get auth_login_forgot_password => 'Forgot password?';

  @override
  String get auth_login_submit => 'Sign in';

  @override
  String get auth_login_no_account => 'No account?';

  @override
  String get auth_login_create => 'Create';

  @override
  String get auth_terms_prefix => 'I agree to the ';

  @override
  String get auth_terms_terms => 'Terms of Use';

  @override
  String get auth_terms_and => ' and ';

  @override
  String get auth_terms_privacy => 'Privacy Policy';

  @override
  String get auth_register_title => 'Sign up';

  @override
  String get auth_register_password_title => 'Create a password';

  @override
  String get auth_register_password_subtitle =>
      'Then you can sign in with email or username.';

  @override
  String get auth_register_password_mismatch => 'Passwords don’t match';

  @override
  String get auth_register_email_hint =>
      'We’ll send a code only if this email isn’t registered yet.';

  @override
  String get auth_register_get_code => 'Get code';

  @override
  String get auth_register_code_already_sent =>
      'Code already sent — enter it from the email';

  @override
  String get auth_email_welcome_from => 'Email from welcome@clover.com.kz';

  @override
  String get auth_email_code_label => 'Code from email';

  @override
  String auth_email_resend_countdown(String countdown) {
    return 'Resend in $countdown';
  }

  @override
  String get auth_email_resend => 'Send code again';

  @override
  String auth_email_password_hint(int count) {
    return 'at least $count characters';
  }

  @override
  String get auth_email_password_repeat => 'Confirm password';

  @override
  String get auth_email_save_password => 'Save password';

  @override
  String get auth_forgot_title => 'Reset password';

  @override
  String get onboarding_skip => 'Skip';

  @override
  String get onboarding_path_title => 'Who are you in Clover?';

  @override
  String get onboarding_path_subtitle => 'A short tour tailored to you';

  @override
  String get onboarding_path_feed => 'Feed';

  @override
  String get onboarding_path_business => 'Business';

  @override
  String get onboarding_path_both => 'Both feed and business';

  @override
  String get onboarding_tip_booking_title => 'Online booking';

  @override
  String get onboarding_tip_booking_body =>
      'Services, staff, inbox and clients from your profile — in one place.';

  @override
  String get onboarding_tip_booking_tip =>
      'The “Accept booking” super-tag opens the hub.';

  @override
  String get onboarding_tip_attendance_title => 'Attendance';

  @override
  String get onboarding_tip_attendance_body =>
      'Companies, shifts and team check-ins. Workers punch in the app.';

  @override
  String get onboarding_tip_attendance_tip =>
      'The “Attendance” super-tag opens management.';

  @override
  String get onboarding_tip_resources_title => 'Resources';

  @override
  String get onboarding_tip_resources_body =>
      'Your places for posts and profile showcase filters — a personal directory.';

  @override
  String get onboarding_tip_resources_tip => 'Not the same as the feed city.';

  @override
  String get onboarding_tip_bonus_title => 'Bonuses';

  @override
  String get onboarding_tip_bonus_body =>
      'Earn and spend where the host enabled bonuses on a service.';

  @override
  String get onboarding_tip_bonus_tip => 'Details are in the services guide.';

  @override
  String get onboarding_tip_feed_map_title => 'Feed and map';

  @override
  String get onboarding_tip_feed_map_body =>
      'Double-tap Home to switch between the city feed and map.';

  @override
  String get onboarding_tip_feed_map_tip =>
      'Filters on the left, notifications on the right.';

  @override
  String get onboarding_slide_feed_1_title => 'What’s happening';

  @override
  String get onboarding_slide_feed_1_body =>
      'Events, news, the city’s rhythm — close and calm.';

  @override
  String get onboarding_slide_feed_1_tip => 'Feed and map in one Clover.';

  @override
  String get onboarding_slide_feed_2_title => 'Places nearby';

  @override
  String get onboarding_slide_feed_2_body =>
      'Peek into a salon, café or shop — gently discover their world.';

  @override
  String get onboarding_slide_feed_2_tip => 'Place pages in Clover.';

  @override
  String get onboarding_slide_feed_3_title => 'Booking and bonuses';

  @override
  String get onboarding_slide_feed_3_body =>
      'Book services. Earn and spend bonuses where available.';

  @override
  String get onboarding_slide_feed_3_tip =>
      'Everything for you — without extra steps.';

  @override
  String get onboarding_slide_feed_4_title => 'Share with people close to you';

  @override
  String get onboarding_slide_feed_4_body =>
      'Message a friend. Invite to an event. Warm chat nearby.';

  @override
  String get onboarding_slide_feed_4_tip => 'Conversation without fuss.';

  @override
  String get onboarding_slide_feed_5_title => 'Find your own';

  @override
  String get onboarding_slide_feed_5_body =>
      'Filters cut the noise and leave what resonates.';

  @override
  String get onboarding_slide_feed_5_tip => 'Quiet. Precise. Yours.';

  @override
  String get onboarding_slide_feed_6_body =>
      'Browse · book · chat · earn bonuses. Easy and warm.';

  @override
  String get onboarding_slide_feed_6_tip =>
      'Replay the tour: Settings → About.';

  @override
  String get onboarding_slide_biz_1_title => 'For business';

  @override
  String get onboarding_slide_biz_1_body =>
      'One account — showcase and services. Calm and practical.';

  @override
  String get onboarding_slide_biz_1_tip => 'Face first, tools next.';

  @override
  String get onboarding_slide_biz_2_title => 'Super-tags';

  @override
  String get onboarding_slide_biz_2_body =>
      'Turn on a tag — unlock power. Booking, team, locations.';

  @override
  String get onboarding_slide_biz_2_tip => 'Few tags — clear focus.';

  @override
  String get onboarding_slide_biz_3_title => 'Living showcase';

  @override
  String get onboarding_slide_biz_3_body =>
      'A profile people want to return to. Trust without shouting.';

  @override
  String get onboarding_slide_biz_3_tip => 'Beauty and clarity.';

  @override
  String get onboarding_slide_biz_4_title => 'Services at hand';

  @override
  String get onboarding_slide_biz_4_body =>
      'Booking, service bonuses — all nearby.';

  @override
  String get onboarding_slide_biz_4_tip =>
      'Guides live in Settings → Services.';

  @override
  String get onboarding_slide_biz_5_title => 'Clients find you';

  @override
  String get onboarding_slide_biz_5_body =>
      'In the feed, on the map, through booking. You’re already in Clover.';

  @override
  String get onboarding_slide_biz_5_tip => 'A gentle path to people.';

  @override
  String get onboarding_slide_both_1_title => 'Both feed and business';

  @override
  String get onboarding_slide_both_1_body =>
      'For you — city and booking. For work — showcase and services.';

  @override
  String get onboarding_slide_both_1_tip => 'One Clover. Two rhythms.';

  @override
  String get onboarding_slide_both_2_title => 'Like for yourself';

  @override
  String get onboarding_slide_both_2_body =>
      'Events, places, booking, bonuses, filters — all open.';

  @override
  String get onboarding_slide_both_2_tip => 'Live the city calmly.';

  @override
  String get onboarding_slide_both_3_title => 'When you run a business';

  @override
  String get onboarding_slide_both_3_body =>
      'Super-tags turn on booking and other services.';

  @override
  String get onboarding_slide_both_3_tip => 'Enable as you need.';

  @override
  String get onboarding_slide_both_4_title => 'One showcase';

  @override
  String get onboarding_slide_both_4_body =>
      'Your profile is both face and entry point for clients.';

  @override
  String get onboarding_slide_both_4_tip => 'Soft and clear.';

  @override
  String get onboarding_slide_both_5_title => 'A small start';

  @override
  String get onboarding_slide_both_5_body =>
      'Set up yourself. Browse the feed. Enable a service when ready.';

  @override
  String get onboarding_slide_both_5_tip =>
      'Replay the tour: Settings → About.';

  @override
  String get error_auth_unknown => 'Something went wrong. Please try again.';

  @override
  String get error_auth_check_failed =>
      'Couldn’t restore the session. Sign in again.';

  @override
  String get error_auth_sign_in_canceled => 'Sign-in canceled.';

  @override
  String get error_auth_google_token_missing =>
      'Couldn’t sign in with Google. Please try again.';

  @override
  String get error_auth_google_failed =>
      'Couldn’t sign in with Google. Please try again.';

  @override
  String get error_auth_google_misconfigured =>
      'Google Sign-In isn’t configured: check the Web Client ID in Google Cloud and Supabase.';

  @override
  String get error_auth_apple_token_missing =>
      'Couldn’t sign in with Apple. Please try again.';

  @override
  String get error_auth_apple_failed =>
      'Couldn’t sign in with Apple. Please try again.';

  @override
  String get error_auth_apple_unavailable =>
      'Sign in with Apple isn’t available on this device.';

  @override
  String get error_auth_supabase_sign_in_failed =>
      'Couldn’t sign in. Try again later.';

  @override
  String get error_auth_supabase_user_missing =>
      'Couldn’t load the profile after sign-in.';

  @override
  String get error_auth_sign_out_failed =>
      'Couldn’t sign out. Please try again.';

  @override
  String get error_auth_network =>
      'Network error. Check your connection and try again.';

  @override
  String get error_auth_email_invalid => 'Enter a valid email.';

  @override
  String get error_auth_email_otp_send_failed =>
      'Couldn’t send the email code. Try again later.';

  @override
  String get error_auth_email_otp_verify_failed =>
      'Invalid or expired code. Request a new one.';

  @override
  String get error_auth_email_otp_rate_limited =>
      'Too many emails. Wait and try again.';

  @override
  String error_auth_email_otp_wait(String countdown) {
    return 'Wait $countdown before sending again.';
  }

  @override
  String get error_auth_email_already_registered =>
      'This email is already registered. Sign in or reset your password.';

  @override
  String get error_auth_email_not_registered =>
      'No account with this email. Create one.';

  @override
  String get error_auth_invalid_credentials => 'Wrong username or password.';

  @override
  String get error_auth_password_invalid =>
      'Password is too short. Minimum 8 characters.';

  @override
  String get error_auth_password_mismatch => 'Passwords don’t match.';

  @override
  String get error_auth_password_update_failed =>
      'Couldn’t save the password. Please try again.';

  @override
  String get error_auth_identifier_invalid => 'Enter a username or email.';

  @override
  String get error_auth_hibernate_failed =>
      'Couldn’t sleep the account. Please try again.';

  @override
  String get error_auth_hibernate_rate_limited =>
      'Sleep can be enabled at most once every 30 days.';

  @override
  String get error_auth_delete_account_failed =>
      'Couldn’t deactivate the account. Please try again.';

  @override
  String get push_chat_fallback_title => 'Chat';

  @override
  String get catalog_country_kz => 'Kazakhstan';

  @override
  String get catalog_country_ru => 'Russia';

  @override
  String get catalog_city_almaty => 'Almaty';

  @override
  String get catalog_city_astana => 'Astana';

  @override
  String get catalog_city_shymkent => 'Shymkent';

  @override
  String get catalog_city_kazan => 'Kazan';

  @override
  String get catalog_city_moscow => 'Moscow';

  @override
  String get catalog_city_saint_petersburg => 'Saint Petersburg';

  @override
  String get catalog_tag_business => 'Business';

  @override
  String get catalog_tag_individual => 'Individual';

  @override
  String get catalog_tag_community => 'Community';

  @override
  String get catalog_tag_brand => 'Brand';

  @override
  String get catalog_tag_salon => 'Salon';

  @override
  String get catalog_tag_barbershop => 'Barbershop';

  @override
  String get catalog_tag_music => 'Music';

  @override
  String get catalog_tag_sports => 'Sports';

  @override
  String get catalog_tag_food => 'Food';

  @override
  String get catalog_tag_tech => 'Tech';

  @override
  String get catalog_tag_store => 'Store';

  @override
  String get catalog_tag_kids => 'Kids';

  @override
  String get catalog_tag_teens => 'Teens';

  @override
  String get catalog_tag_adults => 'Adults';

  @override
  String get catalog_tag_seniors => 'Seniors';

  @override
  String get catalog_tag_families => 'Families';

  @override
  String get catalog_tag_couples => 'Couples';

  @override
  String get catalog_tag_students => 'Students';

  @override
  String get catalog_tag_professionals => 'Professionals';

  @override
  String get catalog_tag_men_only => 'Men only';

  @override
  String get catalog_tag_women_only => 'Women only';

  @override
  String get catalog_tag_restaurant => 'Restaurant';

  @override
  String get catalog_tag_cafe => 'Café';

  @override
  String get catalog_tag_bar => 'Bar';

  @override
  String get catalog_tag_cinema => 'Cinema';

  @override
  String get catalog_tag_club => 'Club';

  @override
  String get catalog_tag_shop => 'Shop';

  @override
  String get catalog_tag_beauty => 'Beauty';

  @override
  String get catalog_tag_fitness => 'Fitness';

  @override
  String get catalog_tag_medical => 'Medical';

  @override
  String get catalog_tag_education => 'Education';

  @override
  String get catalog_tag_coworking => 'Coworking';

  @override
  String get catalog_tag_hotel => 'Hotel';

  @override
  String get catalog_tag_mall => 'Mall';

  @override
  String get catalog_tag_party => 'Party';

  @override
  String get catalog_tag_networking => 'Networking';

  @override
  String get catalog_tag_workshop => 'Workshop';

  @override
  String get catalog_tag_lecture => 'Lecture';

  @override
  String get catalog_tag_festival => 'Festival';

  @override
  String get catalog_tag_concert => 'Concert';

  @override
  String get catalog_tag_exhibition => 'Exhibition';

  @override
  String get catalog_tag_movie_night => 'Movie night';

  @override
  String get catalog_tag_game_night => 'Game night';

  @override
  String get catalog_tag_dating => 'Dating';

  @override
  String get catalog_tag_kids_event => 'Kids event';

  @override
  String get catalog_tag_sport_event => 'Sport event';

  @override
  String get catalog_tag_sale => 'Sale';

  @override
  String get catalog_tag_grand_opening => 'Grand opening';

  @override
  String get catalog_tag_indoor => 'Indoor';

  @override
  String get catalog_tag_outdoor => 'Outdoor';

  @override
  String get catalog_tag_online => 'Online';

  @override
  String get catalog_tag_active => 'Active';

  @override
  String get catalog_tag_chill => 'Chill';

  @override
  String get catalog_tag_extreme => 'Extreme';

  @override
  String get catalog_tag_creative => 'Creative';

  @override
  String get catalog_tag_educational => 'Educational';

  @override
  String get catalog_tag_entertainment => 'Entertainment';

  @override
  String get catalog_tag_free => 'Free';

  @override
  String get catalog_tag_paid => 'Paid';

  @override
  String get catalog_tag_reservation => 'By appointment';

  @override
  String get catalog_tag_limited_spots => 'Limited spots';

  @override
  String get catalog_tag_pet_friendly => 'Pet-friendly';

  @override
  String get catalog_tag_eco => 'Eco';

  @override
  String get catalog_tag_plus18 => '18+';

  @override
  String get catalog_tag_night => 'Night';

  @override
  String get catalog_tag_new_event => 'New';

  @override
  String get catalog_tag_popular => 'Popular';

  @override
  String get catalog_tag_booking => 'Accept booking';

  @override
  String get catalog_tag_attendance => 'Run attendance';

  @override
  String get catalog_tag_resources => 'Run resources';

  @override
  String get catalog_tag_feedback => 'Showcase reviews';

  @override
  String get catalog_tag_booking_calendar => 'Order calendar';

  @override
  String get catalog_tag_attendance_work => 'My check-ins';

  @override
  String get ugc_report_spam => 'Spam';

  @override
  String get ugc_report_harassment => 'Harassment';

  @override
  String get ugc_report_hate => 'Hate';

  @override
  String get ugc_report_violence => 'Violence';

  @override
  String get ugc_report_nudity => 'Nudity';

  @override
  String get ugc_report_scam => 'Scam';

  @override
  String get ugc_report_other => 'Other';

  @override
  String get feed_events_title => 'Events';

  @override
  String get feed_map_title => 'Map';

  @override
  String get feed_notifications_title => 'Notifications';

  @override
  String get profile_title => 'Profile';

  @override
  String get profile_edit_title => 'Edit profile';

  @override
  String get chat_title => 'Chats';

  @override
  String get chat_empty => 'No conversations yet';

  @override
  String get chat_input_hint => 'Message';

  @override
  String get booking_hub_title => 'Booking';

  @override
  String get booking_inbox_title => 'Inbox';

  @override
  String get attendance_hub_title => 'Attendance';

  @override
  String get resources_hub_title => 'Resources';

  @override
  String get bonus_hub_title => 'Bonuses';

  @override
  String get archive_hub_title => 'Archives';

  @override
  String get venue_hub_title => 'Venue';

  @override
  String get auth_terms_suffix =>
      '. Unacceptable content and abusive behavior are not allowed.';

  @override
  String get settings_blocked_unblock_action => 'Unblock';

  @override
  String get onboarding_slide_feed_6_title => 'Clover with you';

  @override
  String auth_email_code_sent_to(String email) {
    return 'Code sent to $email';
  }

  @override
  String get auth_forgot_email_hint =>
      'We’ll send a code only to an already registered email.';

  @override
  String get auth_forgot_send_code => 'Send code';

  @override
  String get auth_forgot_new_password_title => 'New password';

  @override
  String get auth_forgot_new_password_subtitle =>
      'Choose a new password for sign-in.';

  @override
  String get settings_password_set_toast => 'Password set';

  @override
  String get settings_password_reset_toast => 'Password reset';

  @override
  String get settings_password_enter_code => 'Enter the code from the email';

  @override
  String get settings_password_entry_title => 'Sign-in password';

  @override
  String get settings_password_entry_subtitle =>
      'Needed if you signed in with Google — then you can also sign in with a password.';

  @override
  String get settings_password_reset_section => 'Reset password';

  @override
  String get settings_password_no_email =>
      'This account has no email — code reset isn’t available.';

  @override
  String settings_password_send_to_email(String email) {
    return 'We’ll send a code to $email. After confirming, you’ll set a new password.';
  }

  @override
  String get ugc_report_objectionable => 'Objectionable content';

  @override
  String get ugc_report_abusive => 'Abusive behavior';

  @override
  String get ugc_report_harassment_threats => 'Harassment / threats';

  @override
  String get catalog_group_who => 'Who';

  @override
  String get catalog_group_type => 'Type';

  @override
  String get catalog_group_for => 'For whom';

  @override
  String get catalog_group_place => 'Place';

  @override
  String get catalog_group_event => 'Event';

  @override
  String get catalog_group_format => 'Format';

  @override
  String get catalog_group_conditions => 'Conditions';

  @override
  String get catalog_group_admin => 'Admin';

  @override
  String get catalog_group_worker => 'Worker';

  @override
  String get catalog_city_search_hint => 'Search city';

  @override
  String get catalog_city_pick_country_first => 'Select a country first';

  @override
  String get catalog_city_sheet_title => 'City';

  @override
  String get catalog_country_search_hint => 'Search country';

  @override
  String get catalog_country_sheet_title => 'Country';

  @override
  String get ugc_report_title => 'Report';

  @override
  String get ugc_report_sent => 'Report sent. We’ll review it within 24 hours.';

  @override
  String get ugc_report_failed => 'Couldn’t send the report';

  @override
  String get ugc_block_title => 'Block?';

  @override
  String get ugc_block_body =>
      'This user’s content will disappear from your feed immediately. We’ll be notified and review within 24 hours.';

  @override
  String get ugc_block_confirm => 'Block';

  @override
  String get ugc_block_success => 'User blocked';

  @override
  String get ugc_block_failed => 'Couldn’t block the user';

  @override
  String get chat_action_reply => 'Reply';

  @override
  String get chat_action_forward => 'Forward';

  @override
  String get chat_action_star => 'Star';

  @override
  String get chat_action_more => 'More';

  @override
  String get chat_reply_bar_title => 'Reply';

  @override
  String get chat_edit_bar_title => 'Edit';

  @override
  String get chat_preview_photo => 'Photo';

  @override
  String get chat_preview_file => 'File';

  @override
  String get chat_preview_post => 'Post';

  @override
  String get chat_preview_system => 'System';

  @override
  String get chat_preview_message => 'Message';

  @override
  String get profile_fallback_name => 'Profile';

  @override
  String get common_cancel_action => 'Cancel';

  @override
  String get booking_services_label => 'Services';

  @override
  String get booking_analytics_label => 'Analytics';

  @override
  String get attendance_punch_clock_in => 'Clock in';

  @override
  String get attendance_punch_clock_out => 'Clock out';

  @override
  String get nav_tab_events => 'Event';

  @override
  String get nav_tab_map => 'Map';

  @override
  String get nav_tab_chat => 'Chat';

  @override
  String get nav_tab_profile => 'Profile';

  @override
  String get common_date => 'Date';

  @override
  String get common_today => 'Today';

  @override
  String get common_yesterday => 'Yesterday';

  @override
  String get common_tomorrow => 'Tomorrow';

  @override
  String get common_start_label => 'Start';

  @override
  String get common_end_label => 'End';

  @override
  String common_duration(String duration) {
    return 'Duration: $duration';
  }

  @override
  String get common_event_period => 'Event period';

  @override
  String get common_end_after_start => 'End must be after start';

  @override
  String common_max_duration(String duration) {
    return 'Maximum $duration';
  }

  @override
  String get booking_rest_days => 'Days off';

  @override
  String get booking_days => 'Days';

  @override
  String get booking_select => 'Select';

  @override
  String get booking_horizon => 'Horizon';

  @override
  String get booking_horizon_mode => 'Mode';

  @override
  String get booking_horizon_days_ahead => 'For a period';

  @override
  String get booking_horizon_until_date => 'Until date';

  @override
  String get booking_horizon_how_far => 'How far ahead';

  @override
  String get booking_horizon_period => 'Period';

  @override
  String get booking_horizon_forward => 'Book ahead';

  @override
  String get booking_until_date => 'Until date';

  @override
  String get booking_hours_title => 'Working hours';

  @override
  String get booking_from => 'From';

  @override
  String get booking_to => 'To';

  @override
  String get booking_to_inclusive => 'Until';

  @override
  String get booking_more_settings => 'More settings';

  @override
  String get booking_cancel_visits_title => 'Cancel & visits';

  @override
  String get booking_client_cancel => 'Client cancellation';

  @override
  String get booking_cancel_before_start => 'Until start';

  @override
  String booking_hours_before(int hours) {
    return '${hours}h before';
  }

  @override
  String get booking_auto_no_show => 'Auto no-show';

  @override
  String get booking_auto_status => 'Auto status';

  @override
  String get booking_off => 'Off';

  @override
  String booking_after_hours(int hours) {
    return 'After ${hours}h';
  }

  @override
  String get booking_absences_title => 'Time off / absences';

  @override
  String get booking_master => 'Specialist';

  @override
  String get booking_comment => 'Comment';

  @override
  String get booking_optional => 'Optional';

  @override
  String get booking_week_1 => '1 week';

  @override
  String booking_weeks_n(int count) {
    return '$count weeks';
  }

  @override
  String get booking_month_1 => '1 month';

  @override
  String booking_months_n(int count) {
    return '$count months';
  }

  @override
  String get booking_inbox_now => 'Now';

  @override
  String get booking_inbox_upcoming => 'Upcoming';

  @override
  String get booking_inbox_archive => 'Archive';

  @override
  String get booking_inbox_now_chair => 'In chair now';

  @override
  String get booking_inbox_past_archive => 'Past & archive';

  @override
  String get booking_range_this_week => 'This week';

  @override
  String get booking_range_next_week => 'Next week';

  @override
  String get booking_range_this_month => 'This month';

  @override
  String get booking_range_next_month => 'Next month';

  @override
  String get booking_range_all => 'All bookings';

  @override
  String get booking_range_recent => 'Recent';

  @override
  String get booking_my_bookings => 'My bookings';

  @override
  String get booking_no_bookings => 'No bookings yet';

  @override
  String get booking_no_bookings_hint =>
      'When you book with a specialist, visits will appear here by day';

  @override
  String get booking_my_bookings_hint =>
      'Your visits with specialists. Pick a day — open a card to reschedule or cancel.';

  @override
  String booking_day_none(String label) {
    return '$label · no bookings';
  }

  @override
  String booking_day_one(String label) {
    return '$label · 1 booking';
  }

  @override
  String booking_day_few(String label, int count) {
    return '$label · $count bookings';
  }

  @override
  String booking_day_many(String label, int count) {
    return '$label · $count bookings';
  }

  @override
  String get booking_no_day_bookings => 'No bookings this day';

  @override
  String get booking_pick_another_day => 'Pick another day on the calendar';

  @override
  String get booking_client => 'Client';

  @override
  String get booking_service => 'Service';

  @override
  String get booking_services => 'Services';

  @override
  String get booking_team => 'Team';

  @override
  String get booking_schedule => 'Schedule';

  @override
  String get booking_price => 'Price';

  @override
  String get booking_duration => 'Duration';

  @override
  String booking_minutes(int count) {
    return '$count min';
  }

  @override
  String get booking_cancel_booking => 'Cancel booking';

  @override
  String get booking_reschedule => 'Reschedule';

  @override
  String get booking_reschedule_done => 'Booking rescheduled';

  @override
  String get booking_reschedule_action => 'Reschedule';

  @override
  String get booking_time => 'Time';

  @override
  String get booking_day => 'Day';

  @override
  String get booking_pick_day => 'Pick a day';

  @override
  String get booking_note => 'Note';

  @override
  String get booking_reason => 'Reason';

  @override
  String get booking_executor => 'Assignee';

  @override
  String get booking_executors => 'Assignees';

  @override
  String get booking_name => 'Name';

  @override
  String get booking_point => 'Point';

  @override
  String get booking_order => 'Order';

  @override
  String get booking_load_failed => 'Failed to load';

  @override
  String get booking_chat_open_failed => 'Could not open chat';

  @override
  String get booking_empty => 'Nothing here yet';

  @override
  String get booking_account => 'Account';

  @override
  String get booking_clover_account => 'Clover account';

  @override
  String get booking_waiting_chat => 'Waiting for a chat reply';

  @override
  String get booking_in_team => 'On the team';

  @override
  String get booking_request_cancelled => 'Request cancelled';

  @override
  String get booking_cancel_service => 'Cancel service';

  @override
  String get booking_master_already_added => 'This specialist is already added';

  @override
  String get booking_date_and_start => 'Date and start';

  @override
  String get booking_created_at => 'Created';

  @override
  String get common_back_arrow => '← Back';

  @override
  String get common_follow => 'Follow';

  @override
  String get common_unfollow => 'Unfollow';

  @override
  String get common_following => 'Following';

  @override
  String get common_apply => 'Apply';

  @override
  String get common_reset => 'Reset';

  @override
  String get common_accept => 'Accept';

  @override
  String get common_reject => 'Decline';

  @override
  String get common_archive => 'Archive';

  @override
  String get common_unarchive => 'Unarchive';

  @override
  String get common_download => 'Download';

  @override
  String get common_name => 'Name';

  @override
  String get common_description => 'Description';

  @override
  String get common_active => 'Active';

  @override
  String get common_address => 'Address';

  @override
  String get common_filters => 'Filters';

  @override
  String get common_copied => 'Copied';

  @override
  String get common_just_now => 'just now';

  @override
  String common_minutes_short(int count) {
    return '$count min';
  }

  @override
  String common_hours_short(int count) {
    return '$count h';
  }

  @override
  String common_days_short(int count) {
    return '$count d';
  }

  @override
  String common_days_plural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String common_minutes_unit(int count) {
    return '$count min';
  }

  @override
  String common_hours_unit(int count) {
    return '$count h';
  }

  @override
  String common_hours_minutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get common_zero_minutes => '0 min';

  @override
  String get common_nothing_found => 'Nothing found';

  @override
  String get common_try_other_query => 'Try a different query';

  @override
  String get common_try_change_filter => 'Try changing the filter';

  @override
  String get common_sign_in_required => 'Sign in';

  @override
  String get common_no_one_found => 'No one found';

  @override
  String get common_and => 'and';

  @override
  String common_and_more(int count) {
    return 'and $count more';
  }

  @override
  String get common_someone => 'Someone';

  @override
  String get common_saving => 'Saving…';

  @override
  String get common_actions => 'Actions';

  @override
  String get common_messages => 'Messages';

  @override
  String get common_publications => 'Posts';

  @override
  String get common_country => 'Country';

  @override
  String get common_city => 'City';

  @override
  String get common_pick_country => 'Select a country';

  @override
  String get common_pick_city => 'Select a city';

  @override
  String get common_from => 'From';

  @override
  String get common_to => 'To';

  @override
  String get common_day_after_tomorrow => 'Day after tomorrow';

  @override
  String get common_week => 'Week';

  @override
  String get common_month => 'Month';

  @override
  String get common_inactive_suffix => 'inactive';

  @override
  String common_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String get common_delete_confirm_irreversible => 'This can’t be undone.';

  @override
  String get common_could_not_save => 'Couldn’t save';

  @override
  String get common_could_not_delete => 'Couldn’t delete';

  @override
  String get common_could_not_load => 'Couldn’t load';

  @override
  String get common_new_notification => 'New notification';

  @override
  String get common_new_message => 'New message';

  @override
  String get common_location_permission => 'Allow location access in Settings';

  @override
  String get common_location_failed => 'Couldn’t determine location';

  @override
  String get feed_notif_empty => 'No notifications';

  @override
  String get feed_notif_last_30_days =>
      'Showing notifications from the last 30 days';

  @override
  String get feed_notif_section_last7 => 'Last 7 days';

  @override
  String get feed_notif_section_last30 => 'Last 30 days';

  @override
  String get feed_notif_login_its_me => 'It’s me';

  @override
  String get feed_notif_login_revoke => 'Revoke';

  @override
  String get feed_notif_login_change_password => 'Change password';

  @override
  String get feed_notif_login_confirmed => 'Marked: it’s you';

  @override
  String get feed_notif_login_revoked => 'Session revoked';

  @override
  String get feed_notif_login_resolved => 'Handled';

  @override
  String get feed_notif_followed_you => ' followed you';

  @override
  String get feed_notif_you_followed => 'You followed ';

  @override
  String get feed_notif_mutual_follow =>
      ' followed you. You’re following each other';

  @override
  String get feed_notif_verb_liked => 'liked';

  @override
  String get feed_notif_verb_disliked => 'disliked';

  @override
  String get feed_notif_verb_replied => 'replied';

  @override
  String get feed_notif_verb_commented => 'commented on';

  @override
  String get feed_notif_target_your_post => 'your post';

  @override
  String get feed_notif_target_your_comment => 'your comment';

  @override
  String get feed_notif_target_on_your_comment => 'to your comment';

  @override
  String feed_notif_booking_created_host(String service, String when) {
    return ' booked: $service$when';
  }

  @override
  String get feed_notif_booking_booked_client_prefix => 'You’re booked: ';

  @override
  String feed_notif_booking_reminder_at_host(String host, String when) {
    return ' with $host$when';
  }

  @override
  String get feed_notif_visit_started_prefix => 'Visit in progress — ';

  @override
  String feed_notif_visit_started_suffix(String when) {
    return '$when. Mark whether the client arrived';
  }

  @override
  String get feed_notif_visit_close_prefix => 'Close the visit — ';

  @override
  String feed_notif_cancelled_host(String service, String when) {
    return ' cancelled the booking: $service$when';
  }

  @override
  String feed_notif_cancelled_client(String service, String when) {
    return ' cancelled your booking: $service$when';
  }

  @override
  String get feed_notif_completed_prefix => 'Visit completed: ';

  @override
  String feed_notif_bonus_earn(int amount) {
    return ' · +$amount bonuses';
  }

  @override
  String get feed_notif_no_show_prefix => 'Visit marked as no-show: ';

  @override
  String get feed_notif_rescheduled => ' rescheduled the booking: ';

  @override
  String get feed_notif_assigned_staff_prefix => 'New booking for you: ';

  @override
  String get feed_notif_attendance_invite =>
      ' invited you to the attendance team';

  @override
  String get feed_notif_attendance_rules => 'New company rules — please accept';

  @override
  String get feed_notif_attendance_duty => 'Duty roster updated';

  @override
  String get feed_notif_attendance_correction => 'Correction request';

  @override
  String get feed_notif_login_prefix => 'Account sign-in from ';

  @override
  String get feed_notif_login_new_device => 'a new device';

  @override
  String get feed_notif_service_fallback => 'booking';

  @override
  String get feed_notif_host_fallback => 'the host';

  @override
  String get feed_notif_reminder_tomorrow => 'Booking tomorrow: ';

  @override
  String get feed_notif_reminder_3h => 'In 3 hours: ';

  @override
  String get feed_notif_reminder_2h => 'In 2 hours: ';

  @override
  String get feed_notif_reminder_1h => 'In an hour: ';

  @override
  String get feed_notif_reminder_30m => 'In 30 min: ';

  @override
  String get feed_notif_reminder_15m => 'In 15 min: ';

  @override
  String feed_notif_reminder_minutes(int minutes) {
    return 'In $minutes min: ';
  }

  @override
  String get feed_notif_reminder_default => 'Reminder: ';

  @override
  String feed_notif_punch_clock_out(String place) {
    return 'Time to clock out$place';
  }

  @override
  String feed_notif_punch_auto_closed(String place) {
    return 'Shift closed automatically$place';
  }

  @override
  String feed_notif_punch_clock_in(String place) {
    return 'Time to clock in$place';
  }

  @override
  String get feed_map_no_post => 'This marker has no post';

  @override
  String get feed_map_empty_posts => 'No posts';

  @override
  String get feed_events_empty_title => 'Nothing found';

  @override
  String get feed_events_empty_subtitle => 'Try changing the filter';

  @override
  String get feed_events_no_more => 'No more posts';

  @override
  String get feed_filter_title => 'Filter';

  @override
  String get feed_filter_map_title => 'Map filter';

  @override
  String get feed_filter_event_days => 'Event days';

  @override
  String get feed_filter_emoji_label => 'Event emoji';

  @override
  String get feed_filter_emoji_hint => 'Any — leave empty';

  @override
  String get feed_filter_tags_label => 'Marker tags';

  @override
  String get feed_filter_tags_hint => 'Any — leave empty';

  @override
  String get feed_filter_tags_search => 'Search tags';

  @override
  String get feed_filter_start_hint => 'Start';

  @override
  String get feed_filter_end_hint => 'End';

  @override
  String get booking_point_label => 'Point';

  @override
  String get booking_point_not_found => 'Point not found';

  @override
  String get booking_point_default_name => 'Main';

  @override
  String get booking_point_new_title => 'New point';

  @override
  String get booking_point_new_subtitle => 'Salon, branch, or room';

  @override
  String get booking_point_card_subtitle => 'Services, schedule, bookings';

  @override
  String get booking_point_create_failed => 'Couldn’t create point';

  @override
  String get booking_point_name_label => 'Name';

  @override
  String get booking_my_bookings_title => 'My bookings';

  @override
  String get booking_my_bookings_subtitle => 'Calendar and visits';

  @override
  String get booking_services_subtitle => 'Prices and duration';

  @override
  String get booking_team_title => 'Team';

  @override
  String get booking_team_subtitle => 'Staff and invites';

  @override
  String get booking_chat_title => 'Chat';

  @override
  String get booking_chat_subtitle => 'Point team';

  @override
  String get booking_analytics_subtitle => 'Bookings and services';

  @override
  String get booking_schedule_title => 'Schedule';

  @override
  String get booking_schedule_subtitle => 'Hours and absences';

  @override
  String get booking_master_label => 'Specialist';

  @override
  String get booking_masters_label => 'Specialists';

  @override
  String get booking_all_masters => 'All specialists';

  @override
  String get booking_client_label => 'Client';

  @override
  String get booking_executor_label => 'Assignee';

  @override
  String get booking_executors_label => 'Assignees';

  @override
  String get booking_service_label => 'Service';

  @override
  String get booking_price_label => 'Price';

  @override
  String get booking_price_tenge_label => 'Price ₸';

  @override
  String get booking_duration_label => 'Duration';

  @override
  String booking_minutes_short(int count) {
    return '$count min';
  }

  @override
  String get booking_note_label => 'Note';

  @override
  String get booking_client_note_title => 'Client note';

  @override
  String get booking_salon_label => 'Salon';

  @override
  String get booking_comment_label => 'Comment';

  @override
  String get booking_reason_label => 'Reason';

  @override
  String get booking_reason_optional_label => 'Reason (optional)';

  @override
  String get booking_name_label => 'Name';

  @override
  String get booking_username_label => 'Username';

  @override
  String get booking_phone_label => 'Phone';

  @override
  String get booking_status_label => 'Status';

  @override
  String get booking_when_label => 'When';

  @override
  String get booking_time_label => 'Time';

  @override
  String get booking_day_label => 'Day';

  @override
  String get booking_days_label => 'Days';

  @override
  String get booking_hour_label => 'Hour';

  @override
  String get booking_period_label => 'Period';

  @override
  String get booking_start_label => 'Start';

  @override
  String get booking_end_label => 'End';

  @override
  String get booking_from_label => 'From';

  @override
  String get booking_to_label => 'To';

  @override
  String get booking_until_label => 'Until';

  @override
  String get booking_until_date_label => 'Until date';

  @override
  String get booking_description_label => 'Description';

  @override
  String get booking_emoji_label => 'Emoji';

  @override
  String get booking_method_label => 'Method';

  @override
  String get booking_optional_hint => 'Optional';

  @override
  String get booking_pick_hint => 'Select';

  @override
  String get booking_pick_day_hint => 'Pick a day';

  @override
  String get booking_apply => 'Apply';

  @override
  String get booking_select_action => 'Select';

  @override
  String get booking_all => 'All';

  @override
  String get booking_inactive => 'inactive';

  @override
  String get booking_on_site => 'on site';

  @override
  String get booking_empty_yet => 'Nothing yet';

  @override
  String get booking_back_arrow => '← Back';

  @override
  String get booking_inbox_tab_now_short => 'Now';

  @override
  String get booking_inbox_tab_upcoming_short => 'Upcoming';

  @override
  String get booking_inbox_tab_archive_short => 'Archive';

  @override
  String get booking_inbox_tab_now => 'In chair now';

  @override
  String get booking_inbox_tab_upcoming => 'Upcoming';

  @override
  String get booking_inbox_tab_archive => 'Past and archive';

  @override
  String booking_point_chat_title(String name) {
    return 'Booking · $name';
  }

  @override
  String get booking_open_chat_failed => 'Couldn’t open chat';

  @override
  String get booking_my_empty_title => 'No bookings yet';

  @override
  String get booking_my_empty_subtitle =>
      'When you book a specialist, visits will show up here by day';

  @override
  String get booking_my_intro =>
      'Your visits with specialists. Pick a day — open a card to reschedule or cancel.';

  @override
  String get booking_my_day_empty_title => 'No bookings on this day';

  @override
  String get booking_my_day_empty_subtitle =>
      'Pick another day in the calendar';

  @override
  String booking_count_none(String label) {
    return '$label · no bookings';
  }

  @override
  String booking_count_one(String label) {
    return '$label · 1 booking';
  }

  @override
  String booking_count_few(String label, int count) {
    return '$label · $count bookings';
  }

  @override
  String booking_count_many(String label, int count) {
    return '$label · $count bookings';
  }

  @override
  String get booking_cancel_booking_title => 'Cancel booking';

  @override
  String get booking_cancel_too_late => 'Too close to the visit to cancel';

  @override
  String get booking_cancel_success => 'Booking cancelled';

  @override
  String get booking_reschedule_too_late =>
      'Too close to the visit to reschedule';

  @override
  String get booking_reschedule_missing_parties =>
      'Can’t reschedule: missing service, specialist, or booking owner';

  @override
  String get booking_reschedule_title => 'Reschedule booking';

  @override
  String get booking_reschedule_success => 'Booking rescheduled';

  @override
  String get booking_cancel_preset_plans => 'Plans changed — I can’t make it';

  @override
  String get booking_cancel_preset_wrong_time => 'Wrong time or date';

  @override
  String get booking_cancel_preset_other_time => 'I’ll book another time';

  @override
  String get booking_cancel_preset_not_needed =>
      'I no longer need this service';

  @override
  String booking_cancel_body(String service, String host) {
    return '“$service” with $host will be cancelled. The slot will free up for other clients.';
  }

  @override
  String get booking_ready_messages => 'Quick messages';

  @override
  String get booking_reason_hint => 'Write your own message or pick one above';

  @override
  String get booking_available_times => 'Available times';

  @override
  String get booking_no_free_times_day => 'No free times on this day';

  @override
  String get booking_book_action => 'Book';

  @override
  String get booking_confirmed_toast => 'Booking confirmed';

  @override
  String get booking_day_unavailable_rest =>
      'Booking unavailable this day — day off';

  @override
  String booking_day_unavailable_executor(String name) {
    return '$name is unavailable this day';
  }

  @override
  String get booking_day_unavailable => 'Booking unavailable this day';

  @override
  String get booking_slot_conflict_self =>
      'This time overlaps another of your bookings';

  @override
  String booking_slot_taken_by(String name) {
    return 'This time is already taken with $name';
  }

  @override
  String get booking_conflict_with_yours => 'Conflicts with your booking';

  @override
  String get booking_busy => 'Busy';

  @override
  String get booking_no_free_slots_day => 'No free slots on this day';

  @override
  String get booking_slots_for_day => 'Free slots for the selected day';

  @override
  String get booking_pick_visit_day => 'Pick a visit day';

  @override
  String get booking_review_before_book => 'Review before booking';

  @override
  String get booking_who_does_service => 'Who will do the service';

  @override
  String get booking_comment_hint => 'Optional — notes for the specialist';

  @override
  String get booking_comment_example_hint => 'E.g. short on the sides';

  @override
  String get booking_pay_with_bonuses => 'Pay with bonuses';

  @override
  String get booking_no_bonus_spend => 'No bonus spend';

  @override
  String booking_bonus_balance_no_spend(String balance) {
    return 'Balance $balance. We won’t spend bonuses on this visit.';
  }

  @override
  String booking_bonus_balance_spend(String balance, String spend) {
    return 'Balance $balance. After the visit we’ll spend up to $spend';
  }

  @override
  String get booking_bonus_spend_zero => 'Spend 0 (insufficient balance)';

  @override
  String booking_bonus_spend_amount(String amount, String word) {
    return 'Spend −$amount $word';
  }

  @override
  String booking_bonus_earn_amount(String amount, String word) {
    return 'Earn +$amount $word';
  }

  @override
  String booking_bonus_percent_of_price(int percent) {
    return '($percent% of price). Rest on site.';
  }

  @override
  String booking_max_people_short(int count) {
    return 'up to $count people';
  }

  @override
  String booking_time_range_minutes(String start, String end, int minutes) {
    return '$start–$end · $minutes min';
  }

  @override
  String booking_master_with_name(String name) {
    return 'Specialist: $name';
  }

  @override
  String booking_comment_with_text(String text) {
    return 'Comment: $text';
  }

  @override
  String get booking_service_new_title => 'New service';

  @override
  String get booking_service_edit_title => 'Edit';

  @override
  String get booking_service_added => 'Service added';

  @override
  String get booking_service_saved => 'Service saved';

  @override
  String get booking_service_active => 'Service active';

  @override
  String get booking_service_hidden => 'Hidden from booking';

  @override
  String get booking_show_to_clients => 'Show to clients';

  @override
  String get booking_add_service => 'Add service';

  @override
  String get booking_services_empty_title => 'No services yet';

  @override
  String get booking_services_empty_subtitle =>
      'Add the first — name, duration, and price';

  @override
  String get booking_my_services_title => 'My services';

  @override
  String get booking_service_title_hint => 'Men’s haircut';

  @override
  String get booking_buffer_after_min => 'Buffer after, min';

  @override
  String get booking_buffer_create_only =>
      'Buffer can only be changed when creating';

  @override
  String get booking_max_participants => 'Max participants';

  @override
  String get booking_bonuses_per_visit => 'Bonuses per visit';

  @override
  String get booking_bonus_pay_percent => 'Pay with bonuses, %';

  @override
  String get booking_minutes_field => 'Minutes';

  @override
  String get booking_add_executor => 'Add assignee';

  @override
  String booking_executors_count(int count) {
    return '$count specialist(s)';
  }

  @override
  String get booking_executor_already_added =>
      'This specialist is already added';

  @override
  String get booking_cancel_service_title => 'Cancel service';

  @override
  String booking_cancel_service_body(String service) {
    return '“$service” will stop showing to clients. New bookings won’t be available.';
  }

  @override
  String get booking_cancel_service_preset_plans =>
      'Plans changed — service temporarily unavailable';

  @override
  String get booking_cancel_service_preset_master => 'Specialist unavailable';

  @override
  String get booking_cancel_service_preset_stopped =>
      'We no longer offer this service';

  @override
  String get booking_cancel_service_preset_updating =>
      'Updating schedule and prices';

  @override
  String get booking_team_empty_title => 'Team is empty';

  @override
  String get booking_team_empty_subtitle =>
      'Invite a Clover account or add a name for slots';

  @override
  String get booking_find_account => 'Find account';

  @override
  String get booking_already_in_team => 'Already on the team';

  @override
  String get booking_invited => 'Invited';

  @override
  String get booking_invite_sent_chat => 'Invite sent to chat';

  @override
  String get booking_invite_cancelled => 'Request cancelled';

  @override
  String get booking_removed_from_team => 'Removed from team';

  @override
  String get booking_remove_from_team => 'Remove from team';

  @override
  String get booking_cancel_invite => 'Cancel request';

  @override
  String get booking_team_empty_hint =>
      'Nobody yet — invite a Clover account or add a name.';

  @override
  String get booking_team_invite_or_name =>
      'Invite from Clover or add a name-only for slots.';

  @override
  String get booking_pending_replies => 'Awaiting reply';

  @override
  String get booking_pending_short => 'Pending';

  @override
  String get booking_waiting_plural => 'Waiting';

  @override
  String get booking_invite_from_clover => 'Invite from Clover';

  @override
  String get booking_add_name_only => 'Add name only';

  @override
  String get booking_invite_chat_hint =>
      'We’ll send a request to DMs. After Accept you can assign to a service.';

  @override
  String get booking_search_user_hint => 'Search by username or name';

  @override
  String get booking_nobody_found => 'Nobody found';

  @override
  String get booking_invite_action => 'Invite';

  @override
  String get booking_name_only_hint =>
      'Without a Clover account — name only in slots. No calendar for the assignee.';

  @override
  String get booking_executor_name_hint => 'Assignee name';

  @override
  String get booking_account_clover => 'Clover account';

  @override
  String get booking_account_label => 'Account';

  @override
  String get booking_name_only_short => 'Name only';

  @override
  String get booking_name_only_slots => 'Name only in slots';

  @override
  String get booking_waiting_chat_reply => 'Waiting for chat reply';

  @override
  String booking_waiting_chat_reply_user(String username) {
    return '@$username · waiting for chat reply';
  }

  @override
  String get booking_add_masters_first => 'Add specialists in services first';

  @override
  String get booking_rest_days_title => 'Days off';

  @override
  String get booking_horizon_title => 'Horizon';

  @override
  String get booking_book_ahead_title => 'Book ahead';

  @override
  String get booking_cancel_and_visits_title => 'Cancel & visits';

  @override
  String get booking_master_schedule => 'Specialist schedule';

  @override
  String get booking_time_blocks_title => 'Time blocks';

  @override
  String get booking_time_block_title => 'Time block';

  @override
  String get booking_no_blocks => 'No blocks';

  @override
  String get booking_block_time => 'Block';

  @override
  String get booking_time_blocked => 'Time blocked';

  @override
  String get booking_end_after_start => 'End must be after start';

  @override
  String get booking_settings_saved => 'Settings saved';

  @override
  String get booking_system_section => 'System';

  @override
  String get booking_client_cancel_label => 'Client cancel';

  @override
  String get booking_auto_no_show_label => 'Auto no-show';

  @override
  String get booking_auto_status_sheet => 'Auto status';

  @override
  String get booking_how_far_ahead => 'How far ahead';

  @override
  String get booking_ending_label => 'End';

  @override
  String get booking_before_start => 'Before start';

  @override
  String booking_hours_after(int hours) {
    return '$hours h after';
  }

  @override
  String booking_weeks_count(int count) {
    return '$count weeks';
  }

  @override
  String get booking_week_one => '1 week';

  @override
  String get booking_weeks_two => '2 weeks';

  @override
  String get booking_weeks_three => '3 weeks';

  @override
  String get booking_month_one => '1 month';

  @override
  String get booking_months_two => '2 months';

  @override
  String get booking_months_three => '3 months';

  @override
  String get booking_block_reason_hint => 'Lunch, meeting…';

  @override
  String get booking_week_label => 'Week';

  @override
  String get booking_month_label => 'Month';

  @override
  String get booking_assigned_label => 'Assigned';

  @override
  String get booking_created_label => 'Created';

  @override
  String get booking_participants_label => 'Participants';

  @override
  String get booking_complete_visit_q => 'Complete visit?';

  @override
  String get booking_complete_action => 'Complete';

  @override
  String get booking_complete_visit_now => 'Complete visit now';

  @override
  String get booking_complete_body =>
      'The booking will be closed and the slot freed for other clients.';

  @override
  String get booking_no_show_q => 'Client no-show?';

  @override
  String get booking_no_show_action => 'Client no-show';

  @override
  String get booking_no_show_short => 'No-show';

  @override
  String get booking_no_show_body =>
      'The slot will free up. You can cancel anytime, even if the service already started.';

  @override
  String get booking_undo_last_step_q => 'Undo last step?';

  @override
  String get booking_undo_action => 'Undo';

  @override
  String get booking_undo_body =>
      'The booking will go back one step — e.g. if you marked “Client arrived” by mistake.';

  @override
  String get booking_host_closes_only =>
      'Only you mark the service as completed. The system won’t do it automatically.';

  @override
  String get booking_cancel_visit_q => 'Cancel visit?';

  @override
  String get booking_cancel_visit_action => 'Cancel visit';

  @override
  String get booking_reschedule_missing_service =>
      'Can’t reschedule: missing service or assignee. Refresh the list.';

  @override
  String get booking_reschedule_no_session =>
      'Can’t reschedule: session not found. Sign in again.';

  @override
  String get booking_status_updated => 'Status updated';

  @override
  String get booking_status_reverted => 'Status reverted';

  @override
  String get booking_status_update_failed => 'Couldn’t update status';

  @override
  String get booking_visit_ended_unmarked =>
      'Visit ended, status not marked yet';

  @override
  String get booking_visit_ended_hint =>
      'Booking time has passed. Complete the visit or mark no-show — the system won’t close it as done.';

  @override
  String get booking_client_already_arrived =>
      'Client already arrived (unconfirmed)';

  @override
  String get booking_visit_marks_title => 'Visit marks';

  @override
  String get booking_marked_arrived => 'Marked: showed up';

  @override
  String get booking_marked_no_show => 'Marked: no-show';

  @override
  String get booking_was_short => 'Showed up';

  @override
  String get booking_view_only_status =>
      'View only. Visit status is changed by the account that runs the booking.';

  @override
  String get booking_client_profile => 'Client profile';

  @override
  String get booking_client_profile_unavailable => 'Client profile unavailable';

  @override
  String get booking_what_to_do => 'What do you want to do';

  @override
  String get booking_order_label => 'Order';

  @override
  String get booking_create_booking => 'Create booking';

  @override
  String get booking_book_with => 'Book with';

  @override
  String get booking_all_bookings => 'All bookings';

  @override
  String get booking_search_bookings_hint => 'Client, service, phone…';

  @override
  String get booking_filter_by_date => 'Filter by date';

  @override
  String get booking_quick_pick => 'Quick pick';

  @override
  String get booking_or_custom_period => 'Or custom period';

  @override
  String get booking_this_week => 'This week';

  @override
  String get booking_next_week => 'Next week';

  @override
  String get booking_this_month => 'This month';

  @override
  String get booking_next_month => 'Next month';

  @override
  String get booking_start_date => 'Start date';

  @override
  String get booking_end_date => 'End date';

  @override
  String get booking_archive_empty => 'Archive is empty';

  @override
  String get booking_no_completed_yet => 'No completed visits yet';

  @override
  String get booking_no_cancelled => 'No cancelled bookings';

  @override
  String get booking_cancelled_section => 'Cancelled';

  @override
  String get booking_need_closing => 'Need closing';

  @override
  String get booking_history_title => 'Booking history';

  @override
  String get booking_no_upcoming => 'No upcoming bookings';

  @override
  String get booking_upcoming_empty_hint =>
      'Confirmed future visits will appear here';

  @override
  String get booking_create_first_hint =>
      'Create the first booking — it will show up here';

  @override
  String get booking_now_empty_title => 'Nobody in chair now';

  @override
  String get booking_now_empty_subtitle =>
      'A client will appear here when their visit starts';

  @override
  String get booking_pick_other_day_feed =>
      'Pick another day in the feed or open the calendar';

  @override
  String get booking_day_orders_empty => 'No orders on this day';

  @override
  String get booking_orders_title => 'Orders';

  @override
  String get booking_orders_for_you => 'Orders for you';

  @override
  String get booking_orders_empty => 'No orders yet';

  @override
  String get booking_orders_empty_hint =>
      'When you’re added as assignee on another account’s booking, it will show here';

  @override
  String get booking_orders_calendar => 'Orders calendar';

  @override
  String get booking_no_sources_yet => 'No sources yet';

  @override
  String get booking_when_booked_to_you =>
      'When someone books with you, visits will show here';

  @override
  String get booking_analytics_empty_period => 'No bookings in this period';

  @override
  String get booking_revenue_label => 'Revenue';

  @override
  String get booking_avg_check_label => 'Average check';

  @override
  String booking_analytics_summary(int total, int completed) {
    return '$total bookings · $completed completed';
  }

  @override
  String booking_analytics_cancelled_part(int count) {
    return ' · $count cancelled';
  }

  @override
  String booking_analytics_pending_part(int count) {
    return ' · $count pending';
  }

  @override
  String booking_staff_completed_line(int bookings, int completed) {
    return '$bookings · $completed completed';
  }

  @override
  String get booking_rate_visit => 'Rate visit';

  @override
  String get booking_thanks_review => 'Thanks for the review';

  @override
  String get booking_review_mock_hint =>
      'In mock it goes nowhere — UI only. In prod it will show on the point and profile summary.';

  @override
  String get booking_review_demo_title => 'Haircut · Salon on Abay · 21 Mar';

  @override
  String booking_reviews_count(int count) {
    return '$count reviews';
  }

  @override
  String get booking_reviews_strip_subtitle =>
      'Across booking points · feedback tag';

  @override
  String get booking_reviews_title => 'Reviews';

  @override
  String get booking_how_was_it => 'How was it?';

  @override
  String get booking_review_optional_hint => 'Tell us how it went (optional)';

  @override
  String get booking_send_review => 'Send review';

  @override
  String get booking_demo_leave_review => 'Demo: leave a review';

  @override
  String get booking_point_reply_title => 'Reply as the point';

  @override
  String get booking_point_reply_label => 'Point reply';

  @override
  String get booking_save_reply => 'Save reply';

  @override
  String get booking_edit_reply => 'Edit reply';

  @override
  String get booking_delete_reply => 'Delete reply';

  @override
  String get booking_mock_no_backend => 'Mock · not saved to backend';

  @override
  String get booking_mock_host_reply => 'Mock · host reply';

  @override
  String get booking_reply_action => 'Reply';

  @override
  String get common_open => 'Open';

  @override
  String get common_refresh => 'Refresh';

  @override
  String get common_you => 'You';

  @override
  String get common_not_found => 'Not found';

  @override
  String get common_time => 'Time';

  @override
  String get common_later => 'Later';

  @override
  String get common_details => 'Details';

  @override
  String get common_got_it => 'Got it';

  @override
  String get common_approve => 'Approve';

  @override
  String get common_approved => 'Approved';

  @override
  String get common_rejected => 'Rejected';

  @override
  String get common_pending => 'Pending';

  @override
  String get common_type => 'Type';

  @override
  String get common_chat => 'Chat';

  @override
  String get common_rules => 'Rules';

  @override
  String get common_settings => 'Settings';

  @override
  String get common_saved => 'Saved';

  @override
  String get common_save_failed => 'Could not save';

  @override
  String get common_day => 'Day';

  @override
  String get common_team => 'Team';

  @override
  String get common_hours => 'Hours';

  @override
  String get common_no_data => 'No data';

  @override
  String get attendance_day_status_full => 'Full shift';

  @override
  String get attendance_day_status_late => 'Late';

  @override
  String get attendance_day_status_partial => 'Partial';

  @override
  String get attendance_day_status_absent => 'Absent';

  @override
  String get attendance_day_status_excused => 'Excused';

  @override
  String get attendance_day_status_off => 'Day off';

  @override
  String get attendance_day_status_full_short => 'Full';

  @override
  String get attendance_day_status_late_short => 'Late';

  @override
  String get attendance_day_status_partial_short => 'Partial';

  @override
  String get attendance_absence_kind_day_off => 'Day off';

  @override
  String get attendance_absence_kind_vacation => 'Vacation';

  @override
  String get attendance_absence_kind_sick => 'Sick leave';

  @override
  String get attendance_worker_status_accepted => 'Accepted';

  @override
  String get attendance_worker_status_pending => 'Pending invite';

  @override
  String get attendance_worker_status_archived => 'Archived';

  @override
  String get attendance_worker_status_declined => 'Declined';

  @override
  String get attendance_overtime_status_pending => 'Pending';

  @override
  String get attendance_overtime_status_approved => 'Approved';

  @override
  String get attendance_overtime_status_rejected => 'Rejected';

  @override
  String get attendance_correction_status_pending => 'Pending';

  @override
  String get attendance_correction_status_approved => 'Approved';

  @override
  String get attendance_correction_status_rejected => 'Rejected';

  @override
  String get attendance_saved_locally => 'Saved locally';

  @override
  String get attendance_saved_locally_syncing => 'Saved locally, syncing';

  @override
  String get attendance_company_not_found => 'Company not found';

  @override
  String get attendance_company_default_name => 'Company';

  @override
  String get attendance_company_fallback => 'the company';

  @override
  String get attendance_hub_admin_tag_required =>
      'Enable the “Manage attendance” tag in your profile';

  @override
  String get attendance_hub_new_company => 'New company';

  @override
  String get attendance_hub_company_created => 'Company created';

  @override
  String get attendance_hub_company_create_failed => 'Could not create company';

  @override
  String get attendance_hub_companies => 'Companies';

  @override
  String get attendance_hub_empty_hint =>
      'Create a company: geofence, workers, and punches. Use “+” above.';

  @override
  String get attendance_hub_shifts => 'Shifts';

  @override
  String get attendance_hub_my_attendance => 'My attendance';

  @override
  String get attendance_hub_my_attendance_subtitle => 'Punches and shifts';

  @override
  String get attendance_hub_empty_admin =>
      'Create a company: geofence, workers, and punches. Profile button — “Manage attendance” tag.';

  @override
  String get attendance_company_team_invites => 'Team and invites';

  @override
  String get attendance_company_geofence_punches => 'Geofence and punches';

  @override
  String get attendance_company_duty_queue => 'Daily duty queue';

  @override
  String get attendance_company_leave_sick => 'Leave and sick days';

  @override
  String get attendance_company_ot_approval => 'Overtime approval';

  @override
  String get attendance_company_punch_edits => 'Punch corrections';

  @override
  String get attendance_company_export_month => 'Monthly export';

  @override
  String get attendance_company_hours_team => 'Hours and team';

  @override
  String get attendance_company_invite_rules => 'Invites and rules';

  @override
  String get attendance_punch_title => 'Punch';

  @override
  String get attendance_punch_admin_disabled_system =>
      'Admin has not enabled Clock in/out. Only custom punches below.';

  @override
  String get attendance_punch_custom_types => 'Custom punches';

  @override
  String get attendance_punch_cancel_last => 'Cancel last punch';

  @override
  String get attendance_punch_sim_out_of_zone => 'Simulate out of zone';

  @override
  String get attendance_punch_sim_in_zone => 'Simulate in zone';

  @override
  String get attendance_punch_sim_gps_off => 'Simulate GPS off';

  @override
  String get attendance_punch_sim_gps_on => 'Simulate GPS on';

  @override
  String get attendance_punch_history => 'Punch history';

  @override
  String get attendance_punch_history_empty => 'No punches yet';

  @override
  String attendance_punch_saved(String type) {
    return '$type — saved';
  }

  @override
  String get attendance_punch_save_failed => 'Could not save punch';

  @override
  String get attendance_punch_cancel_title => 'Cancel punch';

  @override
  String get attendance_punch_cancel_hint =>
      'Comment optional — e.g. punched by mistake.';

  @override
  String get attendance_punch_cancel_comment => 'Comment (optional)';

  @override
  String get attendance_punch_cancelled => 'Punch cancelled';

  @override
  String get attendance_punch_request_correction => 'Request correction';

  @override
  String get attendance_punch_no_correction_target => 'No punch to correct';

  @override
  String get attendance_punch_correction_sent => 'Correction request sent';

  @override
  String get attendance_punch_request_failed => 'Could not send request';

  @override
  String attendance_punch_accept_rules(int version) {
    return 'Accept rules v$version via the company chat card.';
  }

  @override
  String get attendance_punch_cancelled_suffix => ' · cancelled';

  @override
  String attendance_punch_clock_in_at(String time) {
    return 'Clock in $time';
  }

  @override
  String attendance_punch_clock_out_at(String time) {
    return 'Clock out $time';
  }

  @override
  String get attendance_punch_types_not_configured => 'Types not configured';

  @override
  String attendance_punch_types_enabled(String list) {
    return 'Enabled: $list';
  }

  @override
  String get attendance_punch_locating => 'Getting location…';

  @override
  String get attendance_punch_gps_unavailable => 'GPS unavailable';

  @override
  String attendance_punch_in_zone(int radiusM) {
    return 'You are in the zone ($radiusM m)';
  }

  @override
  String get attendance_punch_out_of_zone => 'You are out of the zone';

  @override
  String get attendance_punch_refresh_gps => 'Refresh GPS';

  @override
  String get attendance_punch_shift_already_open =>
      'Shift already open — clock out first';

  @override
  String get attendance_punch_open_chat => 'Open chat';

  @override
  String get attendance_pending_out_of_zone =>
      'Out of zone — open the punch screen';

  @override
  String get attendance_pending_locating => 'Getting GPS…';

  @override
  String attendance_pending_in_zone(int radiusM) {
    return 'In zone · $radiusM m';
  }

  @override
  String attendance_pending_out_zone_radius(int radiusM) {
    return 'Out of zone · $radiusM m';
  }

  @override
  String get attendance_pending_expected_in => 'Expected at';

  @override
  String get attendance_pending_new_rules => 'New rules';

  @override
  String attendance_pending_accept_update(String workplace, int version) {
    return '$workplace: accept update v$version via the company chat card.';
  }

  @override
  String get attendance_punch_types_title => 'Punches';

  @override
  String get attendance_punch_types_shift => 'Shift';

  @override
  String get attendance_punch_types_enable_system =>
      'Enable Clock in or Clock out';

  @override
  String get attendance_punch_types_custom => 'Custom';

  @override
  String get attendance_punch_types_custom_empty =>
      'No custom punches. Use “+” above.';

  @override
  String get attendance_punch_types_add_title => 'Custom punch';

  @override
  String get attendance_punch_types_hint_lunch => 'Lunch';

  @override
  String get attendance_punch_types_already_exists => 'Already exists';

  @override
  String attendance_punch_types_at_time(String time) {
    return 'at $time';
  }

  @override
  String get attendance_analytics_title => 'Analytics';

  @override
  String get attendance_analytics_no_period_data => 'No data for this period';

  @override
  String get attendance_analytics_calendar => 'Calendar';

  @override
  String get attendance_analytics_calendar_legend =>
      'Color = status · ✓ punched · ✗ no show';

  @override
  String get attendance_analytics_avg => 'Average';

  @override
  String attendance_analytics_people_count(int count) {
    return '$count ppl';
  }

  @override
  String attendance_analytics_late_abbr(int count) {
    return '$count late';
  }

  @override
  String attendance_analytics_missed_abbr(int count) {
    return '$count missed';
  }

  @override
  String attendance_analytics_late_suffix(int count) {
    return ' · $count late';
  }

  @override
  String attendance_analytics_missed_suffix(int count) {
    return ' · $count missed';
  }

  @override
  String get attendance_analytics_swipe_weeks => 'Swipe by week';

  @override
  String get attendance_analytics_worked_today => 'Worked today';

  @override
  String get attendance_analytics_excused_absence => 'Excused absence';

  @override
  String get attendance_analytics_punches => 'Punches';

  @override
  String get attendance_analytics_no_punches => 'No punches';

  @override
  String get attendance_analytics_excused_not_miss =>
      'Absence is excused — not a miss';

  @override
  String get attendance_analytics_day_off => 'Day off';

  @override
  String attendance_analytics_today_marked(int marked, int total) {
    return 'Today · $marked / $total';
  }

  @override
  String get attendance_analytics_not_punched => 'Not punched';

  @override
  String attendance_analytics_total(String total) {
    return 'Total $total';
  }

  @override
  String get attendance_analytics_journal => 'Journal';

  @override
  String get attendance_analytics_journal_subtitle =>
      'Quick day overview — tap a row';

  @override
  String get attendance_analytics_today_suffix => '· today';

  @override
  String get attendance_analytics_employee => 'Employee';

  @override
  String get attendance_analytics_absences => 'Absences';

  @override
  String get attendance_analytics_absences_subtitle =>
      'Excused periods · not counted as misses';

  @override
  String get attendance_analytics_history_subtitle =>
      'Latest events from device';

  @override
  String get attendance_analytics_worked_month => 'worked this month';

  @override
  String get attendance_analytics_shifts => 'Shifts';

  @override
  String get attendance_analytics_lates => 'Lates';

  @override
  String get attendance_analytics_misses => 'Misses';

  @override
  String get attendance_analytics_payroll => 'Payroll';

  @override
  String get attendance_analytics_payroll_subtitle => 'Period calculation';

  @override
  String get attendance_analytics_base_salary => 'Base salary';

  @override
  String get attendance_analytics_deductions => 'Deductions';

  @override
  String get attendance_analytics_bonuses => 'Bonuses';

  @override
  String get attendance_analytics_payout => 'Payout';

  @override
  String get attendance_worker_no_companies =>
      'No active companies. Accept an invite in chat.';

  @override
  String attendance_worker_accept_rules(String workplace, int version) {
    return '$workplace: accept rules v$version';
  }

  @override
  String get attendance_worker_on_shift => 'on shift';

  @override
  String get attendance_worker_off_shift => 'off shift';

  @override
  String attendance_worker_last_punch(String label) {
    return 'Last: $label';
  }

  @override
  String get attendance_worker_tag_required =>
      'To punch, enable the “My punches” tag in your profile.';

  @override
  String get attendance_worker_punch_cta => 'Punch in';

  @override
  String get attendance_worker_my_details => 'My details';

  @override
  String get attendance_worker_lates_abbr => 'Late';

  @override
  String get attendance_workers_title => 'Workers';

  @override
  String get attendance_workers_archived_toast => 'Archived';

  @override
  String get attendance_workers_archive_failed => 'Could not archive';

  @override
  String get attendance_workers_invite_sent => 'Invite sent';

  @override
  String get attendance_workers_invite_failed => 'Could not send invite';

  @override
  String get attendance_workers_waiting => 'Pending';

  @override
  String attendance_workers_waiting_reply(String user) {
    return '$user · awaiting reply';
  }

  @override
  String get attendance_workers_in_team => 'In team';

  @override
  String attendance_workers_no_tag(String user) {
    return '$user · no tag';
  }

  @override
  String attendance_workers_in_archive(String user) {
    return '$user · archived';
  }

  @override
  String get attendance_workers_search_failed => 'Could not find people';

  @override
  String get attendance_workers_search_hint => 'Username or name';

  @override
  String get attendance_workers_search_empty => 'No one found';

  @override
  String get attendance_workers_empty_title => 'No one yet';

  @override
  String get attendance_workers_empty_subtitle =>
      'Invite a Clover account — the request goes to chat';

  @override
  String get attendance_workers_clover_account => 'Clover account';

  @override
  String attendance_workers_no_work_tag(String user) {
    return '$user · no worker tag';
  }

  @override
  String get attendance_workers_to_archive => 'Archive';

  @override
  String attendance_workers_waiting_chat(String user) {
    return '$user · awaiting reply in chat';
  }

  @override
  String attendance_workers_not_in_shifts(String user) {
    return '$user · not in shifts';
  }

  @override
  String get attendance_workers_reinvite => 'Invite again';

  @override
  String get attendance_timesheet_title => 'Timesheet';

  @override
  String get attendance_timesheet_export_subject => 'Attendance timesheet';

  @override
  String get attendance_timesheet_no_export_data => 'No data to export';

  @override
  String get attendance_timesheet_export_failed => 'Could not export';

  @override
  String get attendance_timesheet_export_csv => 'Export CSV';

  @override
  String get attendance_chat_title => 'Company chat';

  @override
  String attendance_chat_title_named(String name) {
    return 'Attendance · $name';
  }

  @override
  String get attendance_chat_system_intro =>
      'Company group chat. Invites and rules — cards only.';

  @override
  String get attendance_chat_no_cards =>
      'No active cards. Add a worker or simulate a rules update.';

  @override
  String attendance_chat_accepted(String name) {
    return '$name accepted · in active team and chat';
  }

  @override
  String get attendance_chat_declined => 'Declined · out of team';

  @override
  String attendance_chat_rules_accepted(int version) {
    return 'Rules v$version accepted';
  }

  @override
  String get attendance_chat_join_team => 'Join the team';

  @override
  String attendance_chat_invite_body(String name, String username) {
    return 'Invite for $name ($username). After accepting — shifts, hours, and company chat.';
  }

  @override
  String attendance_chat_rules_updated(int version) {
    return 'Rules updated · v$version';
  }

  @override
  String get attendance_chat_rules_body =>
      'Geofence or punch types changed. Until you accept — punching is unavailable.';

  @override
  String get attendance_chat_rules_accept_cta => 'Got it, I accept';

  @override
  String get attendance_chat_open_failed => 'Could not open chat';

  @override
  String get attendance_corrections_title => 'Corrections';

  @override
  String get attendance_corrections_load_failed => 'Could not load requests';

  @override
  String get attendance_corrections_empty => 'No correction requests';

  @override
  String get attendance_corrections_approved_section => 'Approved';

  @override
  String get attendance_corrections_rejected_section => 'Rejected';

  @override
  String attendance_corrections_current_time(String time) {
    return 'now $time';
  }

  @override
  String get attendance_geofence_title => 'Geofence';

  @override
  String get attendance_geofence_permission =>
      'Allow location access in Settings';

  @override
  String get attendance_geofence_locate_failed =>
      'Could not determine location';

  @override
  String get attendance_geofence_saved => 'Geofence saved';

  @override
  String get attendance_geofence_hint =>
      'Tap the map to move the center. Circle is the punch zone.';

  @override
  String get attendance_geofence_radius => 'Radius';

  @override
  String attendance_geofence_radius_m(int radius) {
    return '$radius m';
  }

  @override
  String attendance_geofence_radius_m_named(int radius) {
    return 'Radius $radius m';
  }

  @override
  String get attendance_geofence_point_unset => 'Point not set';

  @override
  String get attendance_overtime_title => 'Overtime';

  @override
  String get attendance_overtime_empty => 'No overtime requests';

  @override
  String get attendance_overtime_pending_section => 'Pending';

  @override
  String get attendance_overtime_in_payroll => 'In payroll';

  @override
  String get attendance_overtime_rejected_section => 'Rejected';

  @override
  String attendance_overtime_hours_line(String date, String hours) {
    return '$date · $hours h';
  }

  @override
  String attendance_overtime_suggestion(String hours) {
    return 'Left after schedule · ~$hours h';
  }

  @override
  String get attendance_overtime_create_request => 'Create request';

  @override
  String get attendance_overtime_created => 'Request created';

  @override
  String get attendance_overtime_create_failed => 'Could not create request';

  @override
  String get attendance_payroll_title => 'Payroll';

  @override
  String get attendance_payroll_no_workers => 'No workers to calculate';

  @override
  String get attendance_payroll_lates => 'Lates';

  @override
  String get attendance_payroll_overtime => 'Overtime';

  @override
  String get attendance_payroll_misses => 'Misses';

  @override
  String get attendance_payroll_partial_day => 'Partial day';

  @override
  String get attendance_payroll_per_min => '₸ / min';

  @override
  String get attendance_payroll_per_hour => '₸ / hour';

  @override
  String get attendance_payroll_per_day => '₸ / day';

  @override
  String get attendance_payroll_percent_day => '% of day';

  @override
  String get attendance_payroll_enter_salary => 'Enter salary in ₸';

  @override
  String get attendance_payroll_salary_saved => 'Salary saved';

  @override
  String get attendance_payroll_salary_save_failed => 'Could not save salary';

  @override
  String get attendance_payroll_salary_label => 'Salary, ₸';

  @override
  String get attendance_payroll_save_salary => 'Save salary';

  @override
  String attendance_payroll_for_period(String period) {
    return 'For $period';
  }

  @override
  String get attendance_payroll_no_adjustments => 'No adjustments';

  @override
  String attendance_payroll_summary_line(String period, int count) {
    return '$period · $count ppl';
  }

  @override
  String get attendance_payroll_rules_hint => 'Payroll rules';

  @override
  String get attendance_absences_title => 'Absences';

  @override
  String get attendance_absences_empty => 'No absences';

  @override
  String get attendance_absences_add_hint => 'Day off, vacation, or sick leave';

  @override
  String get attendance_absences_no_workers => 'No active workers';

  @override
  String get attendance_absences_worker => 'Worker';

  @override
  String get attendance_absences_added => 'Added';

  @override
  String get attendance_absence_title => 'Absence';

  @override
  String get attendance_duty_title => 'Duty roster';

  @override
  String get attendance_duty_not_today => 'Not a duty day today';

  @override
  String get attendance_duty_punch_unavailable =>
      'Punch unavailable today — no duty worker scheduled.';

  @override
  String get attendance_duty_queue_not_workday =>
      'There is a queue, but today is not a working day.';

  @override
  String get attendance_duty_you_today => 'You are on duty today';

  @override
  String attendance_duty_today_names(String names) {
    return 'On duty today: $names';
  }

  @override
  String get attendance_duty_mode_only_you =>
      'Duty-only mode: punching is available to you.';

  @override
  String get attendance_duty_mode_only_others_blocked =>
      'Duty-only mode: punching is unavailable to others today.';

  @override
  String get attendance_duty_info_notify =>
      'Info + team notification. Punching works as usual — duty is not a lock.';

  @override
  String get attendance_duty_info_anyone =>
      'Info for the team. Any accepted worker can punch.';

  @override
  String get attendance_duty_only_duty_punches => 'Only duty worker punches';

  @override
  String get attendance_duty_workdays => 'Working days';

  @override
  String get attendance_duty_queue => 'Queue';

  @override
  String get attendance_duty_add_workers_first => 'Add workers first';

  @override
  String get attendance_duty_none => 'No one on duty';

  @override
  String get attendance_duty_punch_only_duty => 'Only duty worker can punch';

  @override
  String get attendance_duty_team_hint => 'Team hint';

  @override
  String get attendance_settings_not_configured => 'Not configured';

  @override
  String attendance_settings_custom_count(int count) {
    return '$count custom';
  }

  @override
  String get attendance_settings_pick_time => 'Pick a time';

  @override
  String get bonus_history_title => 'Bonus history';

  @override
  String get bonus_history_operations => 'Activity';

  @override
  String get bonus_history_empty_title => 'History is empty';

  @override
  String get bonus_history_empty_subtitle =>
      'Earns and spends appear after completed visits';

  @override
  String get bonus_balance => 'Balance';

  @override
  String get bonus_redeem_hint =>
      'You can redeem on your next booking with this host';

  @override
  String get bonus_my_title => 'My bonuses';

  @override
  String get bonus_my_subtitle =>
      'Balance is per host. Open a card to see history.';

  @override
  String get bonus_my_empty_title => 'No bonuses yet';

  @override
  String get bonus_my_empty_subtitle =>
      'After visits with hosts who have loyalty, balances appear here';

  @override
  String get profile_edit_action => 'Edit';

  @override
  String get profile_add_post => 'Add post';

  @override
  String get profile_add_cluster => 'Add cluster';

  @override
  String get profile_manage => 'Manage';

  @override
  String get profile_cluster_created => 'Cluster created';

  @override
  String get profile_cluster_create_failed => 'Couldn’t create cluster';

  @override
  String get profile_post_published => 'Published successfully';

  @override
  String get profile_post_publish_failed => 'Couldn’t publish';

  @override
  String get profile_followers => 'Followers';

  @override
  String get profile_following => 'Following';

  @override
  String get profile_posts_empty_own => 'Add your first post';

  @override
  String get profile_posts_sign_in => 'Sign in to see posts';

  @override
  String get profile_empty_bio => 'empty';

  @override
  String get profile_more_suffix => ' more';

  @override
  String get profile_username_saved => 'Username saved';

  @override
  String get profile_saved => 'Profile saved';

  @override
  String get profile_section_main => 'Main';

  @override
  String get profile_name_hint => 'Your name';

  @override
  String get profile_section_location => 'Location';

  @override
  String get profile_banner_title => 'Profile cover';

  @override
  String get profile_cover => 'Cover';

  @override
  String get profile_avatar => 'Avatar';

  @override
  String get profile_username_unset => 'Not set';

  @override
  String get profile_username_unavailable =>
      'Username change is unavailable right now';

  @override
  String get profile_username_charset =>
      'Username may only contain Latin letters, digits, “_” and “.”';

  @override
  String get profile_account_tags => 'Account tags';

  @override
  String get profile_pick_tags => 'Select tags';

  @override
  String get profile_about => 'About';

  @override
  String get profile_about_hint => 'Tell about yourself';

  @override
  String get profile_change_cover => 'Change cover';

  @override
  String get profile_add_cover => 'Add cover';

  @override
  String get profile_invalid => 'Invalid profile';

  @override
  String get profile_not_found => 'Profile not found';

  @override
  String get profile_following_empty => 'No following yet';

  @override
  String get profile_followers_empty => 'No followers yet';

  @override
  String get profile_unfollow_padded => '  Unfollow  ';

  @override
  String get profile_follow_padded => '  Follow  ';

  @override
  String get chat_sign_in_to_see => 'Sign in to see messages';

  @override
  String get chat_load_failed => 'Couldn’t load chats';

  @override
  String get chat_search_hint => 'Search chats and messages';

  @override
  String get chat_list_empty_title => 'No chats yet';

  @override
  String get chat_list_empty_subtitle => 'Start a chat from another profile';

  @override
  String get chat_search_in_messages => 'In messages';

  @override
  String get chat_search_no_message_hits => 'No matches in message text';

  @override
  String get chat_new_group => 'New group';

  @override
  String get chat_group_name_required => 'Enter a group name';

  @override
  String get chat_group_members_required => 'Select members';

  @override
  String get chat_group_name_hint => 'Group name';

  @override
  String get chat_group_search_members => 'Search members';

  @override
  String get chat_group_from_following => 'Members from following';

  @override
  String get chat_group_create => 'Create group';

  @override
  String get chat_forward_search => 'Search recipient';

  @override
  String get chat_members_load_failed => 'Couldn’t load members';

  @override
  String get chat_not_ready => 'Chat isn’t ready yet';

  @override
  String get chat_not_created => 'Chat isn’t created yet';

  @override
  String get chat_wallpaper_save_failed => 'Couldn’t save wallpaper';

  @override
  String get chat_info_title => 'Info';

  @override
  String get chat_wallpaper => 'Chat wallpaper';

  @override
  String get chat_dm_subtitle => 'Direct message';

  @override
  String get chat_members => 'Members';

  @override
  String get chat_members_empty => 'No members yet';

  @override
  String get chat_group => 'Group';

  @override
  String get chat_invalid_user => 'Invalid user';

  @override
  String get chat_invalid => 'Invalid chat';

  @override
  String get chat_no_access => 'No access to this chat';

  @override
  String get chat_blocked => 'Messaging unavailable — user is blocked';

  @override
  String get chat_action_failed => 'Couldn’t complete the action';

  @override
  String get chat_star_soon => 'Starred messages — coming soon';

  @override
  String get chat_photo_read_failed => 'Couldn’t read the photo';

  @override
  String get chat_file_read_failed => 'Couldn’t read the document';

  @override
  String get chat_typing => 'typing…';

  @override
  String get chat_thread_search_hint => 'Search messages';

  @override
  String get chat_opening => 'Opening chat…';

  @override
  String get chat_first_message => 'Send the first message';

  @override
  String get chat_failed => 'Couldn’t complete';

  @override
  String chat_wallpaper_with_emojis(String emojis) {
    return 'Chat wallpaper · $emojis';
  }

  @override
  String chat_member_you(String handle) {
    return '$handle (you)';
  }

  @override
  String chat_members_one(int count) {
    return '$count member';
  }

  @override
  String chat_members_few(int count) {
    return '$count members';
  }

  @override
  String chat_members_many(int count) {
    return '$count members';
  }

  @override
  String get catalog_locations_load_failed => 'Couldn’t load locations';

  @override
  String get catalog_locations_title => 'Locations';

  @override
  String get catalog_location_new => 'New location';

  @override
  String get catalog_locations_empty => 'Empty — add your first location';

  @override
  String get catalog_location_save_failed => 'Couldn’t save changes';

  @override
  String get catalog_location_delete_title => 'Delete location?';

  @override
  String get catalog_location => 'Location';

  @override
  String get catalog_location_not_found => 'Location not found';

  @override
  String get catalog_address_cyrillic => 'Address (Cyrillic)';

  @override
  String get catalog_address_hint => 'Abay St. 150, Almaty (optional)';

  @override
  String get catalog_binding => 'Binding';

  @override
  String get catalog_bound_yes => 'Country and city are linked to this address';

  @override
  String get catalog_bound_no => 'Select a country and city for this address';

  @override
  String get catalog_location_active_on => 'Location is visible and available';

  @override
  String get catalog_location_active_off =>
      'Location is hidden and unavailable';

  @override
  String get catalog_accept_changes => 'Accept changes';

  @override
  String get catalog_location_added => 'Location added';

  @override
  String get catalog_address_search => 'Search address';

  @override
  String get catalog_locations_none_active => 'No active locations';

  @override
  String get catalog_address_tap => 'Address · tap to enter';

  @override
  String get catalog_tags_none => 'No tags available';

  @override
  String booking_minutes_plain(int count) {
    return '$count min';
  }

  @override
  String booking_stats_line(int total, int completed) {
    return '$total bookings · $completed completed';
  }

  @override
  String booking_stats_cancelled(int count) {
    return ' · $count cancelled';
  }

  @override
  String booking_stats_pending(int count) {
    return ' · $count pending';
  }

  @override
  String booking_staff_completed(int bookings, int completed) {
    return '$bookings · $completed completed';
  }

  @override
  String booking_slot_taken(String name) {
    return 'This time is already taken with $name';
  }

  @override
  String booking_executor_absent(String name) {
    return '$name is unavailable this day';
  }

  @override
  String booking_bonus_will_spend(String balance, String spend, int percent) {
    return 'Balance $balance. After the visit we’ll deduct up to $spend ($percent% of price). Pay the rest on site.';
  }

  @override
  String booking_bonus_no_spend(String balance) {
    return 'Balance $balance. Bonuses won’t be deducted for this visit.';
  }

  @override
  String booking_bonus_spend(String amount, String word) {
    return 'Deduct −$amount $word';
  }

  @override
  String booking_bonus_earn(String amount, String word) {
    return 'Earn +$amount $word';
  }

  @override
  String booking_comment_prefix(String text) {
    return 'Comment: $text';
  }

  @override
  String booking_service_cancel_body(String title) {
    return '“$title” will no longer show to clients. New bookings will be unavailable.';
  }

  @override
  String booking_masters_count(int count) {
    return '$count specialist(s)';
  }

  @override
  String booking_max_people(int count) {
    return 'up to $count people';
  }

  @override
  String booking_master_prefix(String name) {
    return 'Specialist: $name';
  }

  @override
  String booking_ops_slot_line(String name, String start, String end) {
    return '$name · $start–$end';
  }

  @override
  String booking_invite_waiting(String username) {
    return '@$username · waiting for a chat reply';
  }

  @override
  String booking_cancel_visit_body(String title, String host) {
    return '“$title” with $host will be cancelled. The slot will free up for others.';
  }

  @override
  String booking_chat_title_named(String name) {
    return 'Booking · $name';
  }

  @override
  String booking_time_duration(String range, int minutes) {
    return '$range · $minutes min';
  }

  @override
  String get post_booking_service => 'Booking service';

  @override
  String get post_unavailable => 'Post unavailable';

  @override
  String get post_invalid_id => 'Invalid post id';

  @override
  String get post_not_found => 'Post not found';

  @override
  String get post_create_cluster_first => 'Create a cluster first';

  @override
  String get post_untitled => 'Untitled';

  @override
  String get post_linked_to_cluster => 'Post linked to cluster';

  @override
  String get post_link_failed => 'Couldn’t link the post';

  @override
  String get post_unlinked_from_cluster => 'Post unlinked from cluster';

  @override
  String get post_unlink_failed => 'Couldn’t unlink the post';

  @override
  String get post_archive_event_title => 'Archive event?';

  @override
  String get post_archive_publication_title => 'Archive post?';

  @override
  String get post_archive_event_body =>
      'The event will disappear from the feed and map.';

  @override
  String get post_archive_publication_body =>
      'The post will disappear from your profile.';

  @override
  String get post_event_archived => 'Event archived';

  @override
  String get post_publication_archived => 'Post archived';

  @override
  String get post_unarchive_event_title => 'Unarchive event?';

  @override
  String get post_unarchive_publication_title => 'Unarchive post?';

  @override
  String get post_unarchive_event_body =>
      'The event will reappear in the feed and on the map.';

  @override
  String get post_unarchive_publication_body =>
      'The post will reappear on your profile.';

  @override
  String get post_event_unarchived => 'Event unarchived';

  @override
  String get post_publication_unarchived => 'Post unarchived';

  @override
  String get post_unarchive_failed => 'Couldn’t unarchive';

  @override
  String get post_delete_event_title => 'Delete event?';

  @override
  String get post_delete_publication_title => 'Delete post?';

  @override
  String get post_delete_event_body =>
      'The event, post, and media will be permanently deleted.';

  @override
  String get post_delete_publication_body =>
      'The post and media will be permanently deleted.';

  @override
  String get post_event_deleted => 'Event deleted';

  @override
  String get post_publication_deleted => 'Post deleted';

  @override
  String get post_unlink_cluster => 'Unlink from cluster';

  @override
  String get post_link_cluster => 'Link to cluster';

  @override
  String get post_author => 'Author';

  @override
  String get post_service_loading => 'Loading service…';

  @override
  String get post_book_service => 'Book a service';

  @override
  String get post_book_this_service => 'Book this service';

  @override
  String get post_host => 'Host';

  @override
  String post_likes_count(int count) {
    return '$count likes';
  }

  @override
  String post_dislikes_count(int count) {
    return '$count dislikes';
  }

  @override
  String get post_datetime_section => 'DATE & TIME';

  @override
  String get post_completed => 'Completed';

  @override
  String get post_now => 'now';

  @override
  String get post_hide_replies => 'Hide replies';

  @override
  String post_view_replies(int count) {
    return 'View replies ($count)';
  }

  @override
  String get post_comments_title => 'Comments';

  @override
  String get post_comment_send_failed => 'Couldn’t send comment';

  @override
  String get post_comments_empty => 'No comments yet.\nBe the first!';

  @override
  String post_reply_for(String username) {
    return 'Reply to $username';
  }

  @override
  String get post_comment_hint => 'Add a comment…';

  @override
  String post_reply_hint(String username) {
    return 'Reply to $username…';
  }

  @override
  String get post_create_title => 'New post';

  @override
  String get post_publication => 'Post';

  @override
  String get post_publish => 'Publish';

  @override
  String get post_title_label => 'Title';

  @override
  String get post_title_hint => 'Add a title';

  @override
  String get post_emoji_hint => 'Add an emoji';

  @override
  String get post_tags => 'Tags';

  @override
  String get post_pick_location => 'Select a location';

  @override
  String get post_event_period_required => 'Map event — set start and end';

  @override
  String get post_period_optional =>
      'Optional — without a period it’s a regular post';

  @override
  String get post_body_hint => 'Tell about the post';

  @override
  String get post_create_service_first => 'Create a service in bookings first';

  @override
  String get post_no_service => 'No service';

  @override
  String get post_service_unlinked => 'Not linked';

  @override
  String get post_shared => 'Post sent';

  @override
  String get post_share_no_following => 'No following to send to';

  @override
  String get post_share_message_hint => 'Write a message…';

  @override
  String get post_address_section => 'ADDRESS & LANDMARK';

  @override
  String get cluster_delete_title => 'Delete cluster?';

  @override
  String get cluster_delete_body => 'The cover will be deleted too.';

  @override
  String get cluster_deleted => 'Cluster deleted';

  @override
  String get cluster_title => 'Cluster';

  @override
  String get cluster_archive_title => 'Archive cluster?';

  @override
  String get cluster_archive_body => 'It will disappear from the profile list.';

  @override
  String get cluster_archived => 'Cluster archived';

  @override
  String get cluster_archive_hub_title => 'Cluster archive';

  @override
  String get cluster_archive_empty => 'Cluster archive is empty';

  @override
  String get cluster_unarchive_title => 'Unarchive cluster?';

  @override
  String get cluster_unarchive_body => 'It will reappear on the profile.';

  @override
  String get cluster_unarchived => 'Cluster unarchived';

  @override
  String get cluster_name_label => 'Cluster name';

  @override
  String get cluster_desc_hint => 'Short description (optional)';

  @override
  String get cluster_create_action => 'Create cluster';

  @override
  String get cluster_cover => 'Cluster cover';

  @override
  String get cluster_new => 'New cluster';

  @override
  String get cluster_tab => 'Clusters';

  @override
  String get archive_events_title => 'Event archive';

  @override
  String get archive_events_empty => 'Event archive is empty';

  @override
  String get archive_posts_title => 'Post archive';

  @override
  String get archive_posts_empty => 'Post archive is empty';

  @override
  String get archive_content => 'Content';

  @override
  String get archive_posts_events_subtitle => 'Archived posts and events';

  @override
  String get archive_clusters_subtitle => 'Archived collections';

  @override
  String get chat_invite_team => 'Team invite';

  @override
  String get chat_company_rules => 'Company rules';

  @override
  String get chat_invite_declined => 'Invite declined';

  @override
  String get chat_invite_booking => 'Booking invite';

  @override
  String get chat_on_team => 'You’re on the team';

  @override
  String get chat_accept_rules => 'Accept rules';

  @override
  String get chat_rules_accepted => 'Rules accepted';

  @override
  String get chat_you_are_staff => 'You’re staff';

  @override
  String get chat_attachment => 'Attachment';

  @override
  String get chat_document => 'Document';

  @override
  String get chat_wallpaper_hint =>
      'Add emojis — everyone in this chat will see the wallpaper';

  @override
  String get chat_wallpaper_preview => 'Wallpaper preview';

  @override
  String get chat_wallpaper_example => 'E.g. 🍀✨💬';

  @override
  String get chat_edited_short => 'edited';

  @override
  String get chat_photo_permission => 'Allow photo access to save';

  @override
  String get chat_saved_to_gallery => 'Saved to Gallery';

  @override
  String get chat_photo_download_failed => 'Couldn’t download photo';

  @override
  String chat_members_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String chat_member_you_label(String handle) {
    return '$handle (you)';
  }

  @override
  String chat_wallpaper_emojis(String emojis) {
    return 'Chat wallpaper · $emojis';
  }

  @override
  String get settings_filters_load_failed => 'Couldn’t load filters';

  @override
  String get settings_filters_search => 'Search filters';

  @override
  String get settings_filters_values_word => 'values';

  @override
  String get settings_wait_loading => 'Please wait for loading';

  @override
  String get settings_guide_topic_missing => 'Guide topic not found';

  @override
  String get settings_companies_load_failed => 'Couldn’t load companies';

  @override
  String get settings_companies_empty => 'No companies yet. Tap “Add”.';

  @override
  String get settings_post_filters_title => 'Post filters';

  @override
  String get settings_pick_filters => 'Select filters';

  @override
  String get settings_filters_selected => 'Filters selected';

  @override
  String get settings_filters_categories_hint =>
      'Size, color, brand and other categories';

  @override
  String get settings_filter_value_one => 'value';

  @override
  String get settings_filter_value_few => 'values';

  @override
  String get settings_location_filter_own_only =>
      'Location filter is available on your own profile';

  @override
  String get settings_places_load_failed => 'Couldn’t load places';

  @override
  String get settings_all_places => 'All places';

  @override
  String get settings_no_address_filter => 'No address filter';

  @override
  String get settings_add_place_hint =>
      'Add a place in Resources → Locations to filter posts.';

  @override
  String get settings_no_session => 'No session';

  @override
  String get settings_new_category => 'New category';

  @override
  String get settings_category => 'Category';

  @override
  String get settings_category_name => 'Category name';

  @override
  String get settings_category_name_hint => 'E.g. Size, Color, Brand';

  @override
  String get settings_values => 'Values';

  @override
  String get settings_values_hint => 'XS, Black, Nike…';

  @override
  String get settings_add_one_value => 'Add at least one value';

  @override
  String get settings_save_category => 'Save category';

  @override
  String get settings_save_changes => 'Save changes';

  @override
  String get settings_deletion => 'Deletion';

  @override
  String get settings_filter_categories_title => 'Filter categories';

  @override
  String get settings_filter_categories_intro =>
      'Create a category, name it, and add value options. After the first category, the filter appears on the profile.';

  @override
  String get settings_create_category => 'Create category';

  @override
  String get settings_no_categories => 'No categories yet';

  @override
  String get settings_categories_example =>
      'E.g. Size → XS, S, M\nColor → Black, White';

  @override
  String get settings_create_first_category => 'Create first category';

  @override
  String get settings_guide_services_intro =>
      'A short guide to Clover services. You can activate the host tag right away.';

  @override
  String get settings_activate => 'Activate';

  @override
  String get settings_service_enabled => 'Service enabled on profile';

  @override
  String get settings_activate_failed => 'Couldn’t activate';

  @override
  String get settings_resources_addresses => 'Addresses and map points';

  @override
  String get settings_resources_showcase => 'Profile showcase categories';

  @override
  String get settings_resources_what => 'What are resources';

  @override
  String get settings_saved_posts_empty => 'No saved posts yet';

  @override
  String get settings_saved_posts_tile => 'Saved posts';

  @override
  String get venue_my_bookings => 'My reservations';

  @override
  String get venue_guests => 'Guests';

  @override
  String get venue_establishment => 'Venue';

  @override
  String get venue_tickets_fares => 'Tickets / fares';

  @override
  String get venue_places_list => 'Places as list';

  @override
  String get venue_plan_schema => 'Plan / layout';

  @override
  String get venue_sessions_slots => 'Sessions / slots';

  @override
  String get venue_hub_mock_subtitle =>
      'Mocks · tickets, seats and layout. Plan editor is on the website.';

  @override
  String get venue_establishments => 'Venues';

  @override
  String get venue_requests_confirmed => 'Requests and confirmed (mock)';

  @override
  String get venue_process_doc => 'Process: docs/business/venue-seating.md';

  @override
  String get venue_mocks_no_backend => 'Mocks · no backend';

  @override
  String get venue_client_requests_mock => 'Client request list (mock).';

  @override
  String get venue_client_schema_hint =>
      'Client sees the site layout (JSON) · select and request only.';

  @override
  String get venue_client_flow =>
      'Client: layout and/or list → request, not payment.';

  @override
  String get venue_session => 'Session';

  @override
  String get venue_pick_place => 'Select a seat';

  @override
  String get venue_send_request => 'Send request';

  @override
  String get venue_mock_request_sent => 'Mock: request sent · soft-hold';

  @override
  String get venue_not_found => 'Venue not found';

  @override
  String get venue_catalog => 'Catalog';

  @override
  String get venue_level_a => 'Level A';

  @override
  String get venue_level_b => 'Level B';

  @override
  String get venue_level_c_preview => 'Level C · preview';

  @override
  String get venue_no_schema_hint => 'No layout · hint';

  @override
  String get venue_when_bookable => 'When you can book';

  @override
  String get venue_requests_to_confirm => 'Requests → confirmation';

  @override
  String get venue_client_view => 'How the client sees it';

  @override
  String get venue_request_preview => 'Booking request preview';

  @override
  String get venue_request => 'Request';

  @override
  String get venue_request_not_found => 'Request not found';

  @override
  String get venue_actions_mock => 'Actions are mocked — no backend.';

  @override
  String get venue_mock_confirmed => 'Mock: confirmed';

  @override
  String get venue_mock_rejected => 'Mock: rejected';

  @override
  String get venue_extra_pay => 'Extra payment needed (outside Clover)';

  @override
  String get venue_mock_extra_pay => 'Mock: extra payment condition';

  @override
  String get venue_soft_hold_flow =>
      'Request → soft-hold → admin decides. Not auto-confirm.';

  @override
  String get venue_tab_empty => 'Empty in this tab';

  @override
  String get venue_plan_load_failed => 'Couldn’t load plan';

  @override
  String get venue_plan_load_error => 'Plan load error';

  @override
  String get venue_plan_site_only =>
      'Site draws → mobile only views (JSON from site, mock).';

  @override
  String get venue_plan_preview =>
      'Layout preview. Draw and edit only on the website.';

  @override
  String get venue_no_schema_tickets =>
      'No layout. Host can stay on tickets / list.';

  @override
  String get venue_empty_canvas =>
      'Empty canvas. A Figma-like editor will appear on the site.';

  @override
  String get venue_level_b_bookable =>
      'Level B · same bookables as on the layout.';

  @override
  String get venue_no_seats_tickets_only =>
      'This venue has no seats yet — tickets only.';

  @override
  String get venue_occasion_hint =>
      'Occasion: movie session or restaurant slot.';

  @override
  String get venue_no_sessions => 'No sessions';

  @override
  String get venue_level_a_no_schema =>
      'Level A · no layout. Client picks fare and qty.';

  @override
  String get venue_mock_badge => 'mock';

  @override
  String get settings_attendance_enable_tag =>
      'Enable the “I manage attendance” tag on your profile';

  @override
  String get settings_attendance_company => 'Company';

  @override
  String get settings_attendance_new_company => 'New company';

  @override
  String get settings_attendance_company_created => 'Company created';

  @override
  String get settings_attendance_company_create_failed =>
      'Couldn’t create company';

  @override
  String get settings_attendance_companies => 'Companies';

  @override
  String get settings_attendance_shifts => 'Shifts';

  @override
  String get settings_attendance_my_title => 'My attendance';

  @override
  String get settings_attendance_my_subtitle => 'Punches and shifts';

  @override
  String settings_filter_delete_confirm(String name) {
    return 'Tap to delete “$name”';
  }

  @override
  String settings_filter_deleted(String name) {
    return '“$name” deleted';
  }

  @override
  String settings_saved_categories_count(int count) {
    return 'Saved categories ($count)';
  }

  @override
  String get settings_venue_client => 'Client';

  @override
  String get venue_when => 'When';

  @override
  String get venue_status => 'Status';

  @override
  String get venue_empty_for_now => 'Empty for now';

  @override
  String venue_seat_capacity(int count) {
    return 'up to $count guests';
  }

  @override
  String venue_session_free(String when, int free, int total) {
    return '$when · free $free/$total';
  }

  @override
  String venue_ticket_remaining(String price, int remaining) {
    return '$price · $remaining left';
  }

  @override
  String post_share_sent_to(int count) {
    return 'Post sent to $count recipients';
  }

  @override
  String post_in_days(String label) {
    return 'in $label';
  }

  @override
  String catalog_total_count(int count) {
    return 'Total: $count';
  }

  @override
  String catalog_inactive_dot(String subtitle) {
    return '$subtitle · inactive';
  }

  @override
  String get common_from_short => 'From';

  @override
  String attendance_rules_accepted(String version) {
    return 'Rules v$version accepted';
  }

  @override
  String attendance_invite_body(String name, String username) {
    return 'Invite for $name ($username). After accept — shift, hours, and company chat.';
  }

  @override
  String attendance_rules_updated(String version) {
    return 'Rules updated · v$version';
  }

  @override
  String get attendance_rules_changed_body =>
      'Geofence or punch types changed. Until you accept, clock-in is unavailable.';

  @override
  String attendance_correction_now(String time) {
    return 'now $time';
  }

  @override
  String attendance_meters(int meters) {
    return '$meters m';
  }

  @override
  String attendance_in_zone(int meters) {
    return 'You’re in the zone · $meters m';
  }

  @override
  String attendance_out_zone(int meters) {
    return 'You’re outside the zone · $meters m';
  }

  @override
  String attendance_in_zone_paren(int meters) {
    return 'You’re in the zone ($meters m)';
  }

  @override
  String attendance_enabled_types(String list) {
    return 'Enabled: $list';
  }

  @override
  String attendance_at_time(String time) {
    return 'at $time';
  }

  @override
  String attendance_radius_label(int meters) {
    return 'Radius $meters m';
  }

  @override
  String attendance_clock_in_at(String time) {
    return 'Clock-in $time';
  }

  @override
  String attendance_clock_out_at(String time) {
    return 'Clock-out $time';
  }

  @override
  String attendance_custom_count(int count) {
    return '$count custom';
  }

  @override
  String attendance_duty_today_named(String names) {
    return 'On duty today: $names';
  }

  @override
  String attendance_pending_accept(String workplace, String version) {
    return '$workplace: accept update v$version via the company chat card.';
  }

  @override
  String common_days_one(int count) {
    return '$count day';
  }

  @override
  String common_days_few(int count) {
    return '$count days';
  }

  @override
  String common_days_many(int count) {
    return '$count days';
  }

  @override
  String get post_archive_failed => 'Could not archive';

  @override
  String get post_empty => 'No posts';

  @override
  String post_relative_minutes(int count) {
    return '$count min';
  }

  @override
  String post_relative_hours(int count) {
    return '$count h';
  }

  @override
  String post_relative_days(int count) {
    return '$count d';
  }

  @override
  String get post_emoji_label => 'Emoji';

  @override
  String post_shared_to(int count) {
    return 'Post sent to $count recipients';
  }

  @override
  String get chat_create_group => 'Create group';

  @override
  String chat_wallpaper_label(String preview) {
    return 'Chat wallpaper · $preview';
  }

  @override
  String chat_you_suffix(String handle) {
    return '$handle (you)';
  }

  @override
  String chat_join_workplace(String name) {
    return 'Join “$name”';
  }

  @override
  String chat_join_booking_staff(String name) {
    return 'Become staff · “$name”';
  }

  @override
  String get profile_name_label => 'Name';

  @override
  String get profile_section_account => 'Account';

  @override
  String get profile_username => 'Username';

  @override
  String get profile_book => 'Book';

  @override
  String get profile_calendar => 'Calendar';

  @override
  String get venue_operations => 'Operations';

  @override
  String get venue_comment => 'Comment';

  @override
  String settings_filters_count(int count) {
    return 'Filters ($count)';
  }

  @override
  String get common_nothing_here => 'Nothing here';

  @override
  String get common_something_wrong => 'Something went wrong';

  @override
  String get common_options => 'Options';

  @override
  String get common_emoji_hint => 'Pick or type an emoji';
}
