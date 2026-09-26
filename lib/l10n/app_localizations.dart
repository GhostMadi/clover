import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_kk.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('kk'),
    Locale('ru'),
  ];

  /// No description provided for @common_save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get common_cancel;

  /// No description provided for @common_edit.
  ///
  /// In ru, this message translates to:
  /// **'Изменить'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get common_delete;

  /// No description provided for @common_back.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In ru, this message translates to:
  /// **'Далее'**
  String get common_next;

  /// No description provided for @common_done.
  ///
  /// In ru, this message translates to:
  /// **'Готово'**
  String get common_done;

  /// No description provided for @common_close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get common_close;

  /// No description provided for @common_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get common_confirm;

  /// No description provided for @common_continue.
  ///
  /// In ru, this message translates to:
  /// **'Продолжить'**
  String get common_continue;

  /// No description provided for @common_retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get common_retry;

  /// No description provided for @common_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка'**
  String get common_error;

  /// No description provided for @common_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка…'**
  String get common_loading;

  /// No description provided for @common_yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get common_yes;

  /// No description provided for @common_no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get common_no;

  /// No description provided for @common_ok.
  ///
  /// In ru, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_show.
  ///
  /// In ru, this message translates to:
  /// **'Показать'**
  String get common_show;

  /// No description provided for @common_hide.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть'**
  String get common_hide;

  /// No description provided for @common_or.
  ///
  /// In ru, this message translates to:
  /// **'или'**
  String get common_or;

  /// No description provided for @common_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск'**
  String get common_search;

  /// No description provided for @common_empty.
  ///
  /// In ru, this message translates to:
  /// **'Список пуст'**
  String get common_empty;

  /// No description provided for @common_share.
  ///
  /// In ru, this message translates to:
  /// **'Поделиться'**
  String get common_share;

  /// No description provided for @common_copy.
  ///
  /// In ru, this message translates to:
  /// **'Копировать'**
  String get common_copy;

  /// No description provided for @common_send.
  ///
  /// In ru, this message translates to:
  /// **'Отправить'**
  String get common_send;

  /// No description provided for @common_add.
  ///
  /// In ru, this message translates to:
  /// **'Добавить'**
  String get common_add;

  /// No description provided for @common_remove.
  ///
  /// In ru, this message translates to:
  /// **'Убрать'**
  String get common_remove;

  /// No description provided for @common_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get common_create;

  /// No description provided for @common_skip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get common_skip;

  /// No description provided for @common_start.
  ///
  /// In ru, this message translates to:
  /// **'Начать'**
  String get common_start;

  /// No description provided for @common_logout.
  ///
  /// In ru, this message translates to:
  /// **'Выйти'**
  String get common_logout;

  /// No description provided for @common_password.
  ///
  /// In ru, this message translates to:
  /// **'Пароль'**
  String get common_password;

  /// No description provided for @common_checking.
  ///
  /// In ru, this message translates to:
  /// **'Проверяем…'**
  String get common_checking;

  /// No description provided for @common_user.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь'**
  String get common_user;

  /// No description provided for @common_version.
  ///
  /// In ru, this message translates to:
  /// **'Версия {version}'**
  String common_version(String version);

  /// No description provided for @common_theme_system.
  ///
  /// In ru, this message translates to:
  /// **'Системная'**
  String get common_theme_system;

  /// No description provided for @common_theme_light.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get common_theme_light;

  /// No description provided for @common_theme_dark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get common_theme_dark;

  /// No description provided for @settings_title.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settings_title;

  /// No description provided for @settings_section_services.
  ///
  /// In ru, this message translates to:
  /// **'Сервисы'**
  String get settings_section_services;

  /// No description provided for @settings_section_archives.
  ///
  /// In ru, this message translates to:
  /// **'Архивы'**
  String get settings_section_archives;

  /// No description provided for @settings_section_account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get settings_section_account;

  /// No description provided for @settings_section_about.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settings_section_about;

  /// No description provided for @settings_guide_title.
  ///
  /// In ru, this message translates to:
  /// **'Гайд'**
  String get settings_guide_title;

  /// No description provided for @settings_guide_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Как включить и пользоваться сервисами'**
  String get settings_guide_subtitle;

  /// No description provided for @settings_booking_title.
  ///
  /// In ru, this message translates to:
  /// **'Запись'**
  String get settings_booking_title;

  /// No description provided for @settings_booking_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Услуги, inbox и расписание'**
  String get settings_booking_subtitle;

  /// No description provided for @settings_attendance_title.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость'**
  String get settings_attendance_title;

  /// No description provided for @settings_attendance_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Компании, геозона и работники'**
  String get settings_attendance_subtitle;

  /// No description provided for @settings_resources_title.
  ///
  /// In ru, this message translates to:
  /// **'Ресурсы'**
  String get settings_resources_title;

  /// No description provided for @settings_resources_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Местоположения и фильтры'**
  String get settings_resources_subtitle;

  /// No description provided for @settings_archives_title.
  ///
  /// In ru, this message translates to:
  /// **'Архивы'**
  String get settings_archives_title;

  /// No description provided for @settings_archives_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Публикации и кластеры'**
  String get settings_archives_subtitle;

  /// No description provided for @settings_saved_posts_title.
  ///
  /// In ru, this message translates to:
  /// **'Сохраненные посты'**
  String get settings_saved_posts_title;

  /// No description provided for @settings_saved_posts_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Посты, которые вы сохранили'**
  String get settings_saved_posts_subtitle;

  /// No description provided for @settings_account_title.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get settings_account_title;

  /// No description provided for @settings_account_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Язык, тема и выход'**
  String get settings_account_subtitle;

  /// No description provided for @settings_blocked_title.
  ///
  /// In ru, this message translates to:
  /// **'Заблокированные'**
  String get settings_blocked_title;

  /// No description provided for @settings_blocked_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Кого вы закрыли'**
  String get settings_blocked_subtitle;

  /// No description provided for @settings_about_title.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settings_about_title;

  /// No description provided for @settings_about_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Версия и онбординг'**
  String get settings_about_subtitle;

  /// No description provided for @settings_account_page_title.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get settings_account_page_title;

  /// No description provided for @settings_account_section_general.
  ///
  /// In ru, this message translates to:
  /// **'Общее'**
  String get settings_account_section_general;

  /// No description provided for @settings_account_section_security.
  ///
  /// In ru, this message translates to:
  /// **'Безопасность'**
  String get settings_account_section_security;

  /// No description provided for @settings_account_section_session.
  ///
  /// In ru, this message translates to:
  /// **'Сессия'**
  String get settings_account_section_session;

  /// No description provided for @settings_account_language.
  ///
  /// In ru, this message translates to:
  /// **'Язык'**
  String get settings_account_language;

  /// No description provided for @settings_account_theme.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get settings_account_theme;

  /// No description provided for @settings_account_reset_password.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить пароль'**
  String get settings_account_reset_password;

  /// No description provided for @settings_account_set_password.
  ///
  /// In ru, this message translates to:
  /// **'Установить пароль'**
  String get settings_account_set_password;

  /// No description provided for @settings_account_password_reset_hint.
  ///
  /// In ru, this message translates to:
  /// **'Код на email → новый пароль'**
  String get settings_account_password_reset_hint;

  /// No description provided for @settings_account_password_set_hint.
  ///
  /// In ru, this message translates to:
  /// **'Задать пароль для входа по email или нику'**
  String get settings_account_password_set_hint;

  /// No description provided for @settings_account_password_check_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось проверить статус пароля'**
  String get settings_account_password_check_failed;

  /// No description provided for @settings_account_logout_title.
  ///
  /// In ru, this message translates to:
  /// **'Выход'**
  String get settings_account_logout_title;

  /// No description provided for @settings_account_logout_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта на этом устройстве?'**
  String get settings_account_logout_confirm;

  /// No description provided for @settings_account_logout_action.
  ///
  /// In ru, this message translates to:
  /// **'Выйти из аккаунта'**
  String get settings_account_logout_action;

  /// No description provided for @settings_account_hibernate_title.
  ///
  /// In ru, this message translates to:
  /// **'Усыпить аккаунт'**
  String get settings_account_hibernate_title;

  /// No description provided for @settings_account_hibernate_body.
  ///
  /// In ru, this message translates to:
  /// **'Профиль и посты скрываются из лент и поиска. Это не удаление — при следующем входе аккаунт снова активен. Повторный сон — не чаще раза в 30 дней.'**
  String get settings_account_hibernate_body;

  /// No description provided for @settings_account_hibernate_action.
  ///
  /// In ru, this message translates to:
  /// **'Усыпить'**
  String get settings_account_hibernate_action;

  /// No description provided for @settings_account_hibernate_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть профиль и посты. Не удаление.'**
  String get settings_account_hibernate_subtitle;

  /// No description provided for @settings_account_deactivate_title.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать аккаунт?'**
  String get settings_account_deactivate_title;

  /// No description provided for @settings_account_deactivate_body.
  ///
  /// In ru, this message translates to:
  /// **'Профиль и посты скроются из лент и поиска. Это не безвозвратное удаление: при следующем входе аккаунт снова активен.\n\nЧтобы навсегда удалить аккаунт и связанные данные, напишите в поддержку на clover.com.kz/delete-account.'**
  String get settings_account_deactivate_body;

  /// No description provided for @settings_account_deactivate_action.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать'**
  String get settings_account_deactivate_action;

  /// No description provided for @settings_account_deactivate_tile.
  ///
  /// In ru, this message translates to:
  /// **'Деактивировать аккаунт'**
  String get settings_account_deactivate_tile;

  /// No description provided for @settings_account_deactivate_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть профиль. Полное удаление — через поддержку.'**
  String get settings_account_deactivate_subtitle;

  /// No description provided for @settings_about_page_title.
  ///
  /// In ru, this message translates to:
  /// **'О приложении'**
  String get settings_about_page_title;

  /// No description provided for @settings_about_tagline.
  ///
  /// In ru, this message translates to:
  /// **'События, карта, чат и сервисы для бизнеса — чтобы жизнь была ярче, а работа проще.'**
  String get settings_about_tagline;

  /// No description provided for @settings_about_section_help.
  ///
  /// In ru, this message translates to:
  /// **'Помощь'**
  String get settings_about_section_help;

  /// No description provided for @settings_about_onboarding_title.
  ///
  /// In ru, this message translates to:
  /// **'Онбординг'**
  String get settings_about_onboarding_title;

  /// No description provided for @settings_about_onboarding_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Показать знакомство с приложением'**
  String get settings_about_onboarding_subtitle;

  /// No description provided for @settings_blocked_page_title.
  ///
  /// In ru, this message translates to:
  /// **'Заблокированные'**
  String get settings_blocked_page_title;

  /// No description provided for @settings_blocked_unblock_title.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать?'**
  String get settings_blocked_unblock_title;

  /// No description provided for @settings_blocked_unblock_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать {name}?'**
  String settings_blocked_unblock_confirm(String name);

  /// No description provided for @auth_login_terms_required.
  ///
  /// In ru, this message translates to:
  /// **'Примите условия использования, чтобы продолжить'**
  String get auth_login_terms_required;

  /// No description provided for @auth_login_identifier_label.
  ///
  /// In ru, this message translates to:
  /// **'Ник или email'**
  String get auth_login_identifier_label;

  /// No description provided for @auth_login_identifier_hint.
  ///
  /// In ru, this message translates to:
  /// **'@username или email'**
  String get auth_login_identifier_hint;

  /// No description provided for @auth_login_forgot_password.
  ///
  /// In ru, this message translates to:
  /// **'Забыли пароль?'**
  String get auth_login_forgot_password;

  /// No description provided for @auth_login_submit.
  ///
  /// In ru, this message translates to:
  /// **'Войти'**
  String get auth_login_submit;

  /// No description provided for @auth_login_no_account.
  ///
  /// In ru, this message translates to:
  /// **'Нет аккаунта?'**
  String get auth_login_no_account;

  /// No description provided for @auth_login_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get auth_login_create;

  /// No description provided for @auth_terms_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Я соглашаюсь с '**
  String get auth_terms_prefix;

  /// No description provided for @auth_terms_terms.
  ///
  /// In ru, this message translates to:
  /// **'условиями использования'**
  String get auth_terms_terms;

  /// No description provided for @auth_terms_and.
  ///
  /// In ru, this message translates to:
  /// **' и '**
  String get auth_terms_and;

  /// No description provided for @auth_terms_privacy.
  ///
  /// In ru, this message translates to:
  /// **'политикой конфиденциальности'**
  String get auth_terms_privacy;

  /// No description provided for @auth_register_title.
  ///
  /// In ru, this message translates to:
  /// **'Регистрация'**
  String get auth_register_title;

  /// No description provided for @auth_register_password_title.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте пароль'**
  String get auth_register_password_title;

  /// No description provided for @auth_register_password_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'После этого сможете входить по email или нику.'**
  String get auth_register_password_subtitle;

  /// No description provided for @auth_register_password_mismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают'**
  String get auth_register_password_mismatch;

  /// No description provided for @auth_register_email_hint.
  ///
  /// In ru, this message translates to:
  /// **'Код отправим только если email ещё не зарегистрирован.'**
  String get auth_register_email_hint;

  /// No description provided for @auth_register_get_code.
  ///
  /// In ru, this message translates to:
  /// **'Получить код'**
  String get auth_register_get_code;

  /// No description provided for @auth_register_code_already_sent.
  ///
  /// In ru, this message translates to:
  /// **'Код уже отправлен — введите его из письма'**
  String get auth_register_code_already_sent;

  /// No description provided for @auth_email_welcome_from.
  ///
  /// In ru, this message translates to:
  /// **'Письмо с welcome@clover.com.kz'**
  String get auth_email_welcome_from;

  /// No description provided for @auth_email_code_label.
  ///
  /// In ru, this message translates to:
  /// **'Код из письма'**
  String get auth_email_code_label;

  /// No description provided for @auth_email_resend_countdown.
  ///
  /// In ru, this message translates to:
  /// **'Повторная отправка через {countdown}'**
  String auth_email_resend_countdown(String countdown);

  /// No description provided for @auth_email_resend.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код снова'**
  String get auth_email_resend;

  /// No description provided for @auth_email_password_hint.
  ///
  /// In ru, this message translates to:
  /// **'минимум {count} символов'**
  String auth_email_password_hint(int count);

  /// No description provided for @auth_email_password_repeat.
  ///
  /// In ru, this message translates to:
  /// **'Повтор пароля'**
  String get auth_email_password_repeat;

  /// No description provided for @auth_email_save_password.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить пароль'**
  String get auth_email_save_password;

  /// No description provided for @auth_forgot_title.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get auth_forgot_title;

  /// No description provided for @onboarding_skip.
  ///
  /// In ru, this message translates to:
  /// **'Пропустить'**
  String get onboarding_skip;

  /// No description provided for @onboarding_path_title.
  ///
  /// In ru, this message translates to:
  /// **'Кто ты в Clover?'**
  String get onboarding_path_title;

  /// No description provided for @onboarding_path_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Короткий тур под тебя'**
  String get onboarding_path_subtitle;

  /// No description provided for @onboarding_path_feed.
  ///
  /// In ru, this message translates to:
  /// **'Лента'**
  String get onboarding_path_feed;

  /// No description provided for @onboarding_path_business.
  ///
  /// In ru, this message translates to:
  /// **'Бизнес и предприятия'**
  String get onboarding_path_business;

  /// No description provided for @onboarding_path_both.
  ///
  /// In ru, this message translates to:
  /// **'И лента, и дело'**
  String get onboarding_path_both;

  /// No description provided for @onboarding_tip_booking_title.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн-запись'**
  String get onboarding_tip_booking_title;

  /// No description provided for @onboarding_tip_booking_body.
  ///
  /// In ru, this message translates to:
  /// **'Услуги, мастера, inbox и клиент с вашего профиля — в одном сервисе.'**
  String get onboarding_tip_booking_body;

  /// No description provided for @onboarding_tip_booking_tip.
  ///
  /// In ru, this message translates to:
  /// **'Супер-тег «Принимаю запись» включает хаб.'**
  String get onboarding_tip_booking_tip;

  /// No description provided for @onboarding_tip_attendance_title.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость'**
  String get onboarding_tip_attendance_title;

  /// No description provided for @onboarding_tip_attendance_body.
  ///
  /// In ru, this message translates to:
  /// **'Компании, смены и отметки команды. Работник отмечает в приложении.'**
  String get onboarding_tip_attendance_body;

  /// No description provided for @onboarding_tip_attendance_tip.
  ///
  /// In ru, this message translates to:
  /// **'Супер-тег «Посещаемость» открывает управление.'**
  String get onboarding_tip_attendance_tip;

  /// No description provided for @onboarding_tip_resources_title.
  ///
  /// In ru, this message translates to:
  /// **'Ресурсы'**
  String get onboarding_tip_resources_title;

  /// No description provided for @onboarding_tip_resources_body.
  ///
  /// In ru, this message translates to:
  /// **'Ваши места для постов и фильтры витрины профиля — личный справочник.'**
  String get onboarding_tip_resources_body;

  /// No description provided for @onboarding_tip_resources_tip.
  ///
  /// In ru, this message translates to:
  /// **'Не путать с городом ленты.'**
  String get onboarding_tip_resources_tip;

  /// No description provided for @onboarding_tip_bonus_title.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get onboarding_tip_bonus_title;

  /// No description provided for @onboarding_tip_bonus_body.
  ///
  /// In ru, this message translates to:
  /// **'Копите и тратьте там, где хозяин включил бонусы на услуге.'**
  String get onboarding_tip_bonus_body;

  /// No description provided for @onboarding_tip_bonus_tip.
  ///
  /// In ru, this message translates to:
  /// **'Подробности — в гайде сервисов.'**
  String get onboarding_tip_bonus_tip;

  /// No description provided for @onboarding_tip_feed_map_title.
  ///
  /// In ru, this message translates to:
  /// **'Лента и карта'**
  String get onboarding_tip_feed_map_title;

  /// No description provided for @onboarding_tip_feed_map_body.
  ///
  /// In ru, this message translates to:
  /// **'Двойной тап по Home — переключение ленты и карты города.'**
  String get onboarding_tip_feed_map_body;

  /// No description provided for @onboarding_tip_feed_map_tip.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры слева, уведомления справа.'**
  String get onboarding_tip_feed_map_tip;

  /// No description provided for @onboarding_slide_feed_1_title.
  ///
  /// In ru, this message translates to:
  /// **'Что происходит'**
  String get onboarding_slide_feed_1_title;

  /// No description provided for @onboarding_slide_feed_1_body.
  ///
  /// In ru, this message translates to:
  /// **'Ивенты, новости, живой ритм города — мягко и рядом.'**
  String get onboarding_slide_feed_1_body;

  /// No description provided for @onboarding_slide_feed_1_tip.
  ///
  /// In ru, this message translates to:
  /// **'Лента и карта в одном Clover.'**
  String get onboarding_slide_feed_1_tip;

  /// No description provided for @onboarding_slide_feed_2_title.
  ///
  /// In ru, this message translates to:
  /// **'Места рядом'**
  String get onboarding_slide_feed_2_title;

  /// No description provided for @onboarding_slide_feed_2_body.
  ///
  /// In ru, this message translates to:
  /// **'Загляни к салону, кафе или магазину — мягко узнай их мир.'**
  String get onboarding_slide_feed_2_body;

  /// No description provided for @onboarding_slide_feed_2_tip.
  ///
  /// In ru, this message translates to:
  /// **'Страница места в Clover.'**
  String get onboarding_slide_feed_2_tip;

  /// No description provided for @onboarding_slide_feed_3_title.
  ///
  /// In ru, this message translates to:
  /// **'Запись и бонусы'**
  String get onboarding_slide_feed_3_title;

  /// No description provided for @onboarding_slide_feed_3_body.
  ///
  /// In ru, this message translates to:
  /// **'Записывайся на услуги. Копи и трать бонусы там, где это доступно.'**
  String get onboarding_slide_feed_3_body;

  /// No description provided for @onboarding_slide_feed_3_tip.
  ///
  /// In ru, this message translates to:
  /// **'Всё для тебя — без лишних шагов.'**
  String get onboarding_slide_feed_3_tip;

  /// No description provided for @onboarding_slide_feed_4_title.
  ///
  /// In ru, this message translates to:
  /// **'Поделись с близкими'**
  String get onboarding_slide_feed_4_title;

  /// No description provided for @onboarding_slide_feed_4_body.
  ///
  /// In ru, this message translates to:
  /// **'Напиши другу. Позови на ивент. Тёплый чат — просто рядом.'**
  String get onboarding_slide_feed_4_body;

  /// No description provided for @onboarding_slide_feed_4_tip.
  ///
  /// In ru, this message translates to:
  /// **'Общение без суеты.'**
  String get onboarding_slide_feed_4_tip;

  /// No description provided for @onboarding_slide_feed_5_title.
  ///
  /// In ru, this message translates to:
  /// **'Найди своё'**
  String get onboarding_slide_feed_5_title;

  /// No description provided for @onboarding_slide_feed_5_body.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры помогут отсеять шум и оставить только то, что откликается.'**
  String get onboarding_slide_feed_5_body;

  /// No description provided for @onboarding_slide_feed_5_tip.
  ///
  /// In ru, this message translates to:
  /// **'Тихо. Точно. По-твоему.'**
  String get onboarding_slide_feed_5_tip;

  /// No description provided for @onboarding_slide_feed_6_body.
  ///
  /// In ru, this message translates to:
  /// **'Смотри · записывайся · пиши своим · копи бонусы. Легко и тепло.'**
  String get onboarding_slide_feed_6_body;

  /// No description provided for @onboarding_slide_feed_6_tip.
  ///
  /// In ru, this message translates to:
  /// **'Повторить тур: Настройки → О приложении.'**
  String get onboarding_slide_feed_6_tip;

  /// No description provided for @onboarding_slide_biz_1_title.
  ///
  /// In ru, this message translates to:
  /// **'Для бизнеса'**
  String get onboarding_slide_biz_1_title;

  /// No description provided for @onboarding_slide_biz_1_body.
  ///
  /// In ru, this message translates to:
  /// **'Один аккаунт — витрина и сервисы. Спокойно и по делу.'**
  String get onboarding_slide_biz_1_body;

  /// No description provided for @onboarding_slide_biz_1_tip.
  ///
  /// In ru, this message translates to:
  /// **'Сначала лицо, потом инструменты.'**
  String get onboarding_slide_biz_1_tip;

  /// No description provided for @onboarding_slide_biz_2_title.
  ///
  /// In ru, this message translates to:
  /// **'Супер-теги'**
  String get onboarding_slide_biz_2_title;

  /// No description provided for @onboarding_slide_biz_2_body.
  ///
  /// In ru, this message translates to:
  /// **'Включаешь тег — открывается сила. Запись, команда, точки.'**
  String get onboarding_slide_biz_2_body;

  /// No description provided for @onboarding_slide_biz_2_tip.
  ///
  /// In ru, this message translates to:
  /// **'Мало тегов — ясный фокус.'**
  String get onboarding_slide_biz_2_tip;

  /// No description provided for @onboarding_slide_biz_3_title.
  ///
  /// In ru, this message translates to:
  /// **'Живая витрина'**
  String get onboarding_slide_biz_3_title;

  /// No description provided for @onboarding_slide_biz_3_body.
  ///
  /// In ru, this message translates to:
  /// **'Профиль, к которому хочется вернуться. Доверие без крика.'**
  String get onboarding_slide_biz_3_body;

  /// No description provided for @onboarding_slide_biz_3_tip.
  ///
  /// In ru, this message translates to:
  /// **'Красота и ясность.'**
  String get onboarding_slide_biz_3_tip;

  /// No description provided for @onboarding_slide_biz_4_title.
  ///
  /// In ru, this message translates to:
  /// **'Сервисы рядом'**
  String get onboarding_slide_biz_4_title;

  /// No description provided for @onboarding_slide_biz_4_body.
  ///
  /// In ru, this message translates to:
  /// **'Запись, бонусы на услугах, всё под рукой.'**
  String get onboarding_slide_biz_4_body;

  /// No description provided for @onboarding_slide_biz_4_tip.
  ///
  /// In ru, this message translates to:
  /// **'Гайды — в Настройки → Сервисы.'**
  String get onboarding_slide_biz_4_tip;

  /// No description provided for @onboarding_slide_biz_5_title.
  ///
  /// In ru, this message translates to:
  /// **'Клиент находит тебя'**
  String get onboarding_slide_biz_5_title;

  /// No description provided for @onboarding_slide_biz_5_body.
  ///
  /// In ru, this message translates to:
  /// **'В ленте, на карте, через запись. Вы уже в Clover.'**
  String get onboarding_slide_biz_5_body;

  /// No description provided for @onboarding_slide_biz_5_tip.
  ///
  /// In ru, this message translates to:
  /// **'Мягкий путь к людям.'**
  String get onboarding_slide_biz_5_tip;

  /// No description provided for @onboarding_slide_both_1_title.
  ///
  /// In ru, this message translates to:
  /// **'И лента, и дело'**
  String get onboarding_slide_both_1_title;

  /// No description provided for @onboarding_slide_both_1_body.
  ///
  /// In ru, this message translates to:
  /// **'Для себя — город и запись. Для дела — витрина и сервисы.'**
  String get onboarding_slide_both_1_body;

  /// No description provided for @onboarding_slide_both_1_tip.
  ///
  /// In ru, this message translates to:
  /// **'Один Clover. Два ритма.'**
  String get onboarding_slide_both_1_tip;

  /// No description provided for @onboarding_slide_both_2_title.
  ///
  /// In ru, this message translates to:
  /// **'Как для себя'**
  String get onboarding_slide_both_2_title;

  /// No description provided for @onboarding_slide_both_2_body.
  ///
  /// In ru, this message translates to:
  /// **'Ивенты, места, запись, бонусы, фильтры — всё открыто.'**
  String get onboarding_slide_both_2_body;

  /// No description provided for @onboarding_slide_both_2_tip.
  ///
  /// In ru, this message translates to:
  /// **'Живи в городе спокойно.'**
  String get onboarding_slide_both_2_tip;

  /// No description provided for @onboarding_slide_both_3_title.
  ///
  /// In ru, this message translates to:
  /// **'Когда ведёшь дело'**
  String get onboarding_slide_both_3_title;

  /// No description provided for @onboarding_slide_both_3_body.
  ///
  /// In ru, this message translates to:
  /// **'Супер-теги включают запись и другие сервисы.'**
  String get onboarding_slide_both_3_body;

  /// No description provided for @onboarding_slide_both_3_tip.
  ///
  /// In ru, this message translates to:
  /// **'Включай по мере надобности.'**
  String get onboarding_slide_both_3_tip;

  /// No description provided for @onboarding_slide_both_4_title.
  ///
  /// In ru, this message translates to:
  /// **'Одна витрина'**
  String get onboarding_slide_both_4_title;

  /// No description provided for @onboarding_slide_both_4_body.
  ///
  /// In ru, this message translates to:
  /// **'Профиль — и лицо, и точка входа для клиентов.'**
  String get onboarding_slide_both_4_body;

  /// No description provided for @onboarding_slide_both_4_tip.
  ///
  /// In ru, this message translates to:
  /// **'Мягко и понятно.'**
  String get onboarding_slide_both_4_tip;

  /// No description provided for @onboarding_slide_both_5_title.
  ///
  /// In ru, this message translates to:
  /// **'Маленький старт'**
  String get onboarding_slide_both_5_title;

  /// No description provided for @onboarding_slide_both_5_body.
  ///
  /// In ru, this message translates to:
  /// **'Оформи себя. Посмотри ленту. Включи сервис, когда будешь готов.'**
  String get onboarding_slide_both_5_body;

  /// No description provided for @onboarding_slide_both_5_tip.
  ///
  /// In ru, this message translates to:
  /// **'Повторить тур: Настройки → О приложении.'**
  String get onboarding_slide_both_5_tip;

  /// No description provided for @error_auth_unknown.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так. Попробуйте ещё раз.'**
  String get error_auth_unknown;

  /// No description provided for @error_auth_check_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось восстановить сессию. Войдите снова.'**
  String get error_auth_check_failed;

  /// No description provided for @error_auth_sign_in_canceled.
  ///
  /// In ru, this message translates to:
  /// **'Вход отменён.'**
  String get error_auth_sign_in_canceled;

  /// No description provided for @error_auth_google_token_missing.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти через Google. Попробуйте ещё раз.'**
  String get error_auth_google_token_missing;

  /// No description provided for @error_auth_google_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти через Google. Попробуйте ещё раз.'**
  String get error_auth_google_failed;

  /// No description provided for @error_auth_google_misconfigured.
  ///
  /// In ru, this message translates to:
  /// **'Google Sign-In не настроен: проверьте Web Client ID в Google Cloud и Supabase.'**
  String get error_auth_google_misconfigured;

  /// No description provided for @error_auth_apple_token_missing.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти через Apple. Попробуйте ещё раз.'**
  String get error_auth_apple_token_missing;

  /// No description provided for @error_auth_apple_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось войти через Apple. Попробуйте ещё раз.'**
  String get error_auth_apple_failed;

  /// No description provided for @error_auth_apple_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Вход через Apple недоступен на этом устройстве.'**
  String get error_auth_apple_unavailable;

  /// No description provided for @error_auth_supabase_sign_in_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить вход. Попробуйте позже.'**
  String get error_auth_supabase_sign_in_failed;

  /// No description provided for @error_auth_supabase_user_missing.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить профиль после входа.'**
  String get error_auth_supabase_user_missing;

  /// No description provided for @error_auth_sign_out_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выйти из аккаунта. Попробуйте ещё раз.'**
  String get error_auth_sign_out_failed;

  /// No description provided for @error_auth_network.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка сети. Проверьте подключение и попробуйте снова.'**
  String get error_auth_network;

  /// No description provided for @error_auth_email_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите корректный email.'**
  String get error_auth_email_invalid;

  /// No description provided for @error_auth_email_otp_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить код на email. Попробуйте позже.'**
  String get error_auth_email_otp_send_failed;

  /// No description provided for @error_auth_email_otp_verify_failed.
  ///
  /// In ru, this message translates to:
  /// **'Неверный или просроченный код. Запросите новый.'**
  String get error_auth_email_otp_verify_failed;

  /// No description provided for @error_auth_email_otp_rate_limited.
  ///
  /// In ru, this message translates to:
  /// **'Слишком много писем. Подождите и попробуйте снова.'**
  String get error_auth_email_otp_rate_limited;

  /// No description provided for @error_auth_email_otp_wait.
  ///
  /// In ru, this message translates to:
  /// **'Подождите {countdown} перед повторной отправкой.'**
  String error_auth_email_otp_wait(String countdown);

  /// No description provided for @error_auth_email_already_registered.
  ///
  /// In ru, this message translates to:
  /// **'Этот email уже зарегистрирован. Войдите или сбросьте пароль.'**
  String get error_auth_email_already_registered;

  /// No description provided for @error_auth_email_not_registered.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт с этим email не найден. Создайте аккаунт.'**
  String get error_auth_email_not_registered;

  /// No description provided for @error_auth_invalid_credentials.
  ///
  /// In ru, this message translates to:
  /// **'Неверный логин или пароль.'**
  String get error_auth_invalid_credentials;

  /// No description provided for @error_auth_password_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Пароль слишком короткий. Минимум 8 символов.'**
  String get error_auth_password_invalid;

  /// No description provided for @error_auth_password_mismatch.
  ///
  /// In ru, this message translates to:
  /// **'Пароли не совпадают.'**
  String get error_auth_password_mismatch;

  /// No description provided for @error_auth_password_update_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить пароль. Попробуйте ещё раз.'**
  String get error_auth_password_update_failed;

  /// No description provided for @error_auth_identifier_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Введите ник или email.'**
  String get error_auth_identifier_invalid;

  /// No description provided for @error_auth_hibernate_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось усыпить аккаунт. Попробуйте ещё раз.'**
  String get error_auth_hibernate_failed;

  /// No description provided for @error_auth_hibernate_rate_limited.
  ///
  /// In ru, this message translates to:
  /// **'Сон можно включать не чаще раза в 30 дней.'**
  String get error_auth_hibernate_rate_limited;

  /// No description provided for @error_auth_delete_account_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось деактивировать аккаунт. Попробуйте ещё раз.'**
  String get error_auth_delete_account_failed;

  /// No description provided for @push_chat_fallback_title.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get push_chat_fallback_title;

  /// No description provided for @catalog_country_kz.
  ///
  /// In ru, this message translates to:
  /// **'Казахстан'**
  String get catalog_country_kz;

  /// No description provided for @catalog_country_ru.
  ///
  /// In ru, this message translates to:
  /// **'Россия'**
  String get catalog_country_ru;

  /// No description provided for @catalog_city_almaty.
  ///
  /// In ru, this message translates to:
  /// **'Алматы'**
  String get catalog_city_almaty;

  /// No description provided for @catalog_city_astana.
  ///
  /// In ru, this message translates to:
  /// **'Астана'**
  String get catalog_city_astana;

  /// No description provided for @catalog_city_shymkent.
  ///
  /// In ru, this message translates to:
  /// **'Шымкент'**
  String get catalog_city_shymkent;

  /// No description provided for @catalog_city_kazan.
  ///
  /// In ru, this message translates to:
  /// **'Казань'**
  String get catalog_city_kazan;

  /// No description provided for @catalog_city_moscow.
  ///
  /// In ru, this message translates to:
  /// **'Москва'**
  String get catalog_city_moscow;

  /// No description provided for @catalog_city_saint_petersburg.
  ///
  /// In ru, this message translates to:
  /// **'Санкт-Петербург'**
  String get catalog_city_saint_petersburg;

  /// No description provided for @catalog_tag_business.
  ///
  /// In ru, this message translates to:
  /// **'Бизнес'**
  String get catalog_tag_business;

  /// No description provided for @catalog_tag_individual.
  ///
  /// In ru, this message translates to:
  /// **'Частное лицо'**
  String get catalog_tag_individual;

  /// No description provided for @catalog_tag_community.
  ///
  /// In ru, this message translates to:
  /// **'Сообщество'**
  String get catalog_tag_community;

  /// No description provided for @catalog_tag_brand.
  ///
  /// In ru, this message translates to:
  /// **'Бренд'**
  String get catalog_tag_brand;

  /// No description provided for @catalog_tag_salon.
  ///
  /// In ru, this message translates to:
  /// **'Салон'**
  String get catalog_tag_salon;

  /// No description provided for @catalog_tag_barbershop.
  ///
  /// In ru, this message translates to:
  /// **'Барбершоп'**
  String get catalog_tag_barbershop;

  /// No description provided for @catalog_tag_music.
  ///
  /// In ru, this message translates to:
  /// **'Музыка'**
  String get catalog_tag_music;

  /// No description provided for @catalog_tag_sports.
  ///
  /// In ru, this message translates to:
  /// **'Спорт'**
  String get catalog_tag_sports;

  /// No description provided for @catalog_tag_food.
  ///
  /// In ru, this message translates to:
  /// **'Еда'**
  String get catalog_tag_food;

  /// No description provided for @catalog_tag_tech.
  ///
  /// In ru, this message translates to:
  /// **'Технологии'**
  String get catalog_tag_tech;

  /// No description provided for @catalog_tag_store.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get catalog_tag_store;

  /// No description provided for @catalog_tag_kids.
  ///
  /// In ru, this message translates to:
  /// **'Дети'**
  String get catalog_tag_kids;

  /// No description provided for @catalog_tag_teens.
  ///
  /// In ru, this message translates to:
  /// **'Подростки'**
  String get catalog_tag_teens;

  /// No description provided for @catalog_tag_adults.
  ///
  /// In ru, this message translates to:
  /// **'Взрослые'**
  String get catalog_tag_adults;

  /// No description provided for @catalog_tag_seniors.
  ///
  /// In ru, this message translates to:
  /// **'Пожилые'**
  String get catalog_tag_seniors;

  /// No description provided for @catalog_tag_families.
  ///
  /// In ru, this message translates to:
  /// **'Семьи'**
  String get catalog_tag_families;

  /// No description provided for @catalog_tag_couples.
  ///
  /// In ru, this message translates to:
  /// **'Пары'**
  String get catalog_tag_couples;

  /// No description provided for @catalog_tag_students.
  ///
  /// In ru, this message translates to:
  /// **'Студенты'**
  String get catalog_tag_students;

  /// No description provided for @catalog_tag_professionals.
  ///
  /// In ru, this message translates to:
  /// **'Профессионалы'**
  String get catalog_tag_professionals;

  /// No description provided for @catalog_tag_men_only.
  ///
  /// In ru, this message translates to:
  /// **'Только мужчины'**
  String get catalog_tag_men_only;

  /// No description provided for @catalog_tag_women_only.
  ///
  /// In ru, this message translates to:
  /// **'Только женщины'**
  String get catalog_tag_women_only;

  /// No description provided for @catalog_tag_restaurant.
  ///
  /// In ru, this message translates to:
  /// **'Ресторан'**
  String get catalog_tag_restaurant;

  /// No description provided for @catalog_tag_cafe.
  ///
  /// In ru, this message translates to:
  /// **'Кафе'**
  String get catalog_tag_cafe;

  /// No description provided for @catalog_tag_bar.
  ///
  /// In ru, this message translates to:
  /// **'Бар'**
  String get catalog_tag_bar;

  /// No description provided for @catalog_tag_cinema.
  ///
  /// In ru, this message translates to:
  /// **'Кино'**
  String get catalog_tag_cinema;

  /// No description provided for @catalog_tag_club.
  ///
  /// In ru, this message translates to:
  /// **'Клуб'**
  String get catalog_tag_club;

  /// No description provided for @catalog_tag_shop.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get catalog_tag_shop;

  /// No description provided for @catalog_tag_beauty.
  ///
  /// In ru, this message translates to:
  /// **'Красота'**
  String get catalog_tag_beauty;

  /// No description provided for @catalog_tag_fitness.
  ///
  /// In ru, this message translates to:
  /// **'Фитнес'**
  String get catalog_tag_fitness;

  /// No description provided for @catalog_tag_medical.
  ///
  /// In ru, this message translates to:
  /// **'Медицина'**
  String get catalog_tag_medical;

  /// No description provided for @catalog_tag_education.
  ///
  /// In ru, this message translates to:
  /// **'Образование'**
  String get catalog_tag_education;

  /// No description provided for @catalog_tag_coworking.
  ///
  /// In ru, this message translates to:
  /// **'Коворкинг'**
  String get catalog_tag_coworking;

  /// No description provided for @catalog_tag_hotel.
  ///
  /// In ru, this message translates to:
  /// **'Отель'**
  String get catalog_tag_hotel;

  /// No description provided for @catalog_tag_mall.
  ///
  /// In ru, this message translates to:
  /// **'Торговый центр'**
  String get catalog_tag_mall;

  /// No description provided for @catalog_tag_party.
  ///
  /// In ru, this message translates to:
  /// **'Вечеринка'**
  String get catalog_tag_party;

  /// No description provided for @catalog_tag_networking.
  ///
  /// In ru, this message translates to:
  /// **'Нетворкинг'**
  String get catalog_tag_networking;

  /// No description provided for @catalog_tag_workshop.
  ///
  /// In ru, this message translates to:
  /// **'Воркшоп'**
  String get catalog_tag_workshop;

  /// No description provided for @catalog_tag_lecture.
  ///
  /// In ru, this message translates to:
  /// **'Лекция'**
  String get catalog_tag_lecture;

  /// No description provided for @catalog_tag_festival.
  ///
  /// In ru, this message translates to:
  /// **'Фестиваль'**
  String get catalog_tag_festival;

  /// No description provided for @catalog_tag_concert.
  ///
  /// In ru, this message translates to:
  /// **'Концерт'**
  String get catalog_tag_concert;

  /// No description provided for @catalog_tag_exhibition.
  ///
  /// In ru, this message translates to:
  /// **'Выставка'**
  String get catalog_tag_exhibition;

  /// No description provided for @catalog_tag_movie_night.
  ///
  /// In ru, this message translates to:
  /// **'Киновечер'**
  String get catalog_tag_movie_night;

  /// No description provided for @catalog_tag_game_night.
  ///
  /// In ru, this message translates to:
  /// **'Игровой вечер'**
  String get catalog_tag_game_night;

  /// No description provided for @catalog_tag_dating.
  ///
  /// In ru, this message translates to:
  /// **'Знакомства'**
  String get catalog_tag_dating;

  /// No description provided for @catalog_tag_kids_event.
  ///
  /// In ru, this message translates to:
  /// **'Детское событие'**
  String get catalog_tag_kids_event;

  /// No description provided for @catalog_tag_sport_event.
  ///
  /// In ru, this message translates to:
  /// **'Спортивное событие'**
  String get catalog_tag_sport_event;

  /// No description provided for @catalog_tag_sale.
  ///
  /// In ru, this message translates to:
  /// **'Распродажа'**
  String get catalog_tag_sale;

  /// No description provided for @catalog_tag_grand_opening.
  ///
  /// In ru, this message translates to:
  /// **'Открытие'**
  String get catalog_tag_grand_opening;

  /// No description provided for @catalog_tag_indoor.
  ///
  /// In ru, this message translates to:
  /// **'В помещении'**
  String get catalog_tag_indoor;

  /// No description provided for @catalog_tag_outdoor.
  ///
  /// In ru, this message translates to:
  /// **'На улице'**
  String get catalog_tag_outdoor;

  /// No description provided for @catalog_tag_online.
  ///
  /// In ru, this message translates to:
  /// **'Онлайн'**
  String get catalog_tag_online;

  /// No description provided for @catalog_tag_active.
  ///
  /// In ru, this message translates to:
  /// **'Активный отдых'**
  String get catalog_tag_active;

  /// No description provided for @catalog_tag_chill.
  ///
  /// In ru, this message translates to:
  /// **'Релакс'**
  String get catalog_tag_chill;

  /// No description provided for @catalog_tag_extreme.
  ///
  /// In ru, this message translates to:
  /// **'Экстрим'**
  String get catalog_tag_extreme;

  /// No description provided for @catalog_tag_creative.
  ///
  /// In ru, this message translates to:
  /// **'Творчество'**
  String get catalog_tag_creative;

  /// No description provided for @catalog_tag_educational.
  ///
  /// In ru, this message translates to:
  /// **'Обучение'**
  String get catalog_tag_educational;

  /// No description provided for @catalog_tag_entertainment.
  ///
  /// In ru, this message translates to:
  /// **'Развлечения'**
  String get catalog_tag_entertainment;

  /// No description provided for @catalog_tag_free.
  ///
  /// In ru, this message translates to:
  /// **'Бесплатно'**
  String get catalog_tag_free;

  /// No description provided for @catalog_tag_paid.
  ///
  /// In ru, this message translates to:
  /// **'Платно'**
  String get catalog_tag_paid;

  /// No description provided for @catalog_tag_reservation.
  ///
  /// In ru, this message translates to:
  /// **'По записи'**
  String get catalog_tag_reservation;

  /// No description provided for @catalog_tag_limited_spots.
  ///
  /// In ru, this message translates to:
  /// **'Ограниченное число мест'**
  String get catalog_tag_limited_spots;

  /// No description provided for @catalog_tag_pet_friendly.
  ///
  /// In ru, this message translates to:
  /// **'Можно с питомцами'**
  String get catalog_tag_pet_friendly;

  /// No description provided for @catalog_tag_eco.
  ///
  /// In ru, this message translates to:
  /// **'Эко'**
  String get catalog_tag_eco;

  /// No description provided for @catalog_tag_plus18.
  ///
  /// In ru, this message translates to:
  /// **'18+'**
  String get catalog_tag_plus18;

  /// No description provided for @catalog_tag_night.
  ///
  /// In ru, this message translates to:
  /// **'Ночное'**
  String get catalog_tag_night;

  /// No description provided for @catalog_tag_new_event.
  ///
  /// In ru, this message translates to:
  /// **'Новинка'**
  String get catalog_tag_new_event;

  /// No description provided for @catalog_tag_popular.
  ///
  /// In ru, this message translates to:
  /// **'Популярное'**
  String get catalog_tag_popular;

  /// No description provided for @catalog_tag_booking.
  ///
  /// In ru, this message translates to:
  /// **'Принимаю запись'**
  String get catalog_tag_booking;

  /// No description provided for @catalog_tag_attendance.
  ///
  /// In ru, this message translates to:
  /// **'Веду посещаемость'**
  String get catalog_tag_attendance;

  /// No description provided for @catalog_tag_resources.
  ///
  /// In ru, this message translates to:
  /// **'Веду ресурсы'**
  String get catalog_tag_resources;

  /// No description provided for @catalog_tag_feedback.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы на витрине'**
  String get catalog_tag_feedback;

  /// No description provided for @catalog_tag_booking_calendar.
  ///
  /// In ru, this message translates to:
  /// **'Календарь заказов'**
  String get catalog_tag_booking_calendar;

  /// No description provided for @catalog_tag_attendance_work.
  ///
  /// In ru, this message translates to:
  /// **'Мои отметки'**
  String get catalog_tag_attendance_work;

  /// No description provided for @ugc_report_spam.
  ///
  /// In ru, this message translates to:
  /// **'Спам'**
  String get ugc_report_spam;

  /// No description provided for @ugc_report_harassment.
  ///
  /// In ru, this message translates to:
  /// **'Оскорбления'**
  String get ugc_report_harassment;

  /// No description provided for @ugc_report_hate.
  ///
  /// In ru, this message translates to:
  /// **'Ненависть'**
  String get ugc_report_hate;

  /// No description provided for @ugc_report_violence.
  ///
  /// In ru, this message translates to:
  /// **'Насилие'**
  String get ugc_report_violence;

  /// No description provided for @ugc_report_nudity.
  ///
  /// In ru, this message translates to:
  /// **'Интимный контент'**
  String get ugc_report_nudity;

  /// No description provided for @ugc_report_scam.
  ///
  /// In ru, this message translates to:
  /// **'Мошенничество'**
  String get ugc_report_scam;

  /// No description provided for @ugc_report_other.
  ///
  /// In ru, this message translates to:
  /// **'Другое'**
  String get ugc_report_other;

  /// No description provided for @feed_events_title.
  ///
  /// In ru, this message translates to:
  /// **'События'**
  String get feed_events_title;

  /// No description provided for @feed_map_title.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get feed_map_title;

  /// No description provided for @feed_notifications_title.
  ///
  /// In ru, this message translates to:
  /// **'Уведомления'**
  String get feed_notifications_title;

  /// No description provided for @profile_title.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile_title;

  /// No description provided for @profile_edit_title.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать профиль'**
  String get profile_edit_title;

  /// No description provided for @chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Чаты'**
  String get chat_title;

  /// No description provided for @chat_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет диалогов'**
  String get chat_empty;

  /// No description provided for @chat_input_hint.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chat_input_hint;

  /// No description provided for @booking_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Запись'**
  String get booking_hub_title;

  /// No description provided for @booking_inbox_title.
  ///
  /// In ru, this message translates to:
  /// **'Inbox'**
  String get booking_inbox_title;

  /// No description provided for @attendance_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость'**
  String get attendance_hub_title;

  /// No description provided for @resources_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Ресурсы'**
  String get resources_hub_title;

  /// No description provided for @bonus_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Бонусы'**
  String get bonus_hub_title;

  /// No description provided for @archive_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Архивы'**
  String get archive_hub_title;

  /// No description provided for @venue_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Бронь'**
  String get venue_hub_title;

  /// No description provided for @auth_terms_suffix.
  ///
  /// In ru, this message translates to:
  /// **'. Неприемлемый контент и оскорбительное поведение не допускаются.'**
  String get auth_terms_suffix;

  /// No description provided for @settings_blocked_unblock_action.
  ///
  /// In ru, this message translates to:
  /// **'Разблокировать'**
  String get settings_blocked_unblock_action;

  /// No description provided for @onboarding_slide_feed_6_title.
  ///
  /// In ru, this message translates to:
  /// **'Clover с тобой'**
  String get onboarding_slide_feed_6_title;

  /// No description provided for @auth_email_code_sent_to.
  ///
  /// In ru, this message translates to:
  /// **'Код отправлен на {email}'**
  String auth_email_code_sent_to(String email);

  /// No description provided for @auth_forgot_email_hint.
  ///
  /// In ru, this message translates to:
  /// **'Код отправим только на уже зарегистрированный email.'**
  String get auth_forgot_email_hint;

  /// No description provided for @auth_forgot_send_code.
  ///
  /// In ru, this message translates to:
  /// **'Отправить код'**
  String get auth_forgot_send_code;

  /// No description provided for @auth_forgot_new_password_title.
  ///
  /// In ru, this message translates to:
  /// **'Новый пароль'**
  String get auth_forgot_new_password_title;

  /// No description provided for @auth_forgot_new_password_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Придумайте новый пароль для входа.'**
  String get auth_forgot_new_password_subtitle;

  /// No description provided for @settings_password_set_toast.
  ///
  /// In ru, this message translates to:
  /// **'Пароль установлен'**
  String get settings_password_set_toast;

  /// No description provided for @settings_password_reset_toast.
  ///
  /// In ru, this message translates to:
  /// **'Пароль сброшен'**
  String get settings_password_reset_toast;

  /// No description provided for @settings_password_enter_code.
  ///
  /// In ru, this message translates to:
  /// **'Введите код из письма'**
  String get settings_password_enter_code;

  /// No description provided for @settings_password_entry_title.
  ///
  /// In ru, this message translates to:
  /// **'Пароль для входа'**
  String get settings_password_entry_title;

  /// No description provided for @settings_password_entry_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Нужен, если входили через Google — потом можно входить и по паролю.'**
  String get settings_password_entry_subtitle;

  /// No description provided for @settings_password_reset_section.
  ///
  /// In ru, this message translates to:
  /// **'Сброс пароля'**
  String get settings_password_reset_section;

  /// No description provided for @settings_password_no_email.
  ///
  /// In ru, this message translates to:
  /// **'У аккаунта нет email — сброс по коду недоступен.'**
  String get settings_password_no_email;

  /// No description provided for @settings_password_send_to_email.
  ///
  /// In ru, this message translates to:
  /// **'Отправим код на {email}. После подтверждения зададите новый пароль.'**
  String settings_password_send_to_email(String email);

  /// No description provided for @ugc_report_objectionable.
  ///
  /// In ru, this message translates to:
  /// **'Неприемлемый контент'**
  String get ugc_report_objectionable;

  /// No description provided for @ugc_report_abusive.
  ///
  /// In ru, this message translates to:
  /// **'Оскорбительное поведение'**
  String get ugc_report_abusive;

  /// No description provided for @ugc_report_harassment_threats.
  ///
  /// In ru, this message translates to:
  /// **'Травля / угрозы'**
  String get ugc_report_harassment_threats;

  /// No description provided for @catalog_group_who.
  ///
  /// In ru, this message translates to:
  /// **'Кто'**
  String get catalog_group_who;

  /// No description provided for @catalog_group_type.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get catalog_group_type;

  /// No description provided for @catalog_group_for.
  ///
  /// In ru, this message translates to:
  /// **'Для кого'**
  String get catalog_group_for;

  /// No description provided for @catalog_group_place.
  ///
  /// In ru, this message translates to:
  /// **'Место'**
  String get catalog_group_place;

  /// No description provided for @catalog_group_event.
  ///
  /// In ru, this message translates to:
  /// **'Событие'**
  String get catalog_group_event;

  /// No description provided for @catalog_group_format.
  ///
  /// In ru, this message translates to:
  /// **'Формат'**
  String get catalog_group_format;

  /// No description provided for @catalog_group_conditions.
  ///
  /// In ru, this message translates to:
  /// **'Условия'**
  String get catalog_group_conditions;

  /// No description provided for @catalog_group_admin.
  ///
  /// In ru, this message translates to:
  /// **'Админ'**
  String get catalog_group_admin;

  /// No description provided for @catalog_group_worker.
  ///
  /// In ru, this message translates to:
  /// **'Worker'**
  String get catalog_group_worker;

  /// No description provided for @catalog_city_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск города'**
  String get catalog_city_search_hint;

  /// No description provided for @catalog_city_pick_country_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала выберите страну'**
  String get catalog_city_pick_country_first;

  /// No description provided for @catalog_city_sheet_title.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get catalog_city_sheet_title;

  /// No description provided for @catalog_country_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск страны'**
  String get catalog_country_search_hint;

  /// No description provided for @catalog_country_sheet_title.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get catalog_country_sheet_title;

  /// No description provided for @ugc_report_title.
  ///
  /// In ru, this message translates to:
  /// **'Пожаловаться'**
  String get ugc_report_title;

  /// No description provided for @ugc_report_sent.
  ///
  /// In ru, this message translates to:
  /// **'Жалоба отправлена. Мы разберём её в течение 24 часов.'**
  String get ugc_report_sent;

  /// No description provided for @ugc_report_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить жалобу'**
  String get ugc_report_failed;

  /// No description provided for @ugc_block_title.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать?'**
  String get ugc_block_title;

  /// No description provided for @ugc_block_body.
  ///
  /// In ru, this message translates to:
  /// **'Контент пользователя сразу пропадёт из вашей ленты. Мы получим уведомление и разберём обращение в течение 24 часов.'**
  String get ugc_block_body;

  /// No description provided for @ugc_block_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get ugc_block_confirm;

  /// No description provided for @ugc_block_success.
  ///
  /// In ru, this message translates to:
  /// **'Пользователь заблокирован'**
  String get ugc_block_success;

  /// No description provided for @ugc_block_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось заблокировать'**
  String get ugc_block_failed;

  /// No description provided for @chat_action_reply.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get chat_action_reply;

  /// No description provided for @chat_action_forward.
  ///
  /// In ru, this message translates to:
  /// **'Переслать'**
  String get chat_action_forward;

  /// No description provided for @chat_action_star.
  ///
  /// In ru, this message translates to:
  /// **'В Избранные'**
  String get chat_action_star;

  /// No description provided for @chat_action_more.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get chat_action_more;

  /// No description provided for @chat_reply_bar_title.
  ///
  /// In ru, this message translates to:
  /// **'Ответ'**
  String get chat_reply_bar_title;

  /// No description provided for @chat_edit_bar_title.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование'**
  String get chat_edit_bar_title;

  /// No description provided for @chat_preview_photo.
  ///
  /// In ru, this message translates to:
  /// **'Фото'**
  String get chat_preview_photo;

  /// No description provided for @chat_preview_file.
  ///
  /// In ru, this message translates to:
  /// **'Файл'**
  String get chat_preview_file;

  /// No description provided for @chat_preview_post.
  ///
  /// In ru, this message translates to:
  /// **'Пост'**
  String get chat_preview_post;

  /// No description provided for @chat_preview_system.
  ///
  /// In ru, this message translates to:
  /// **'Системное'**
  String get chat_preview_system;

  /// No description provided for @chat_preview_message.
  ///
  /// In ru, this message translates to:
  /// **'Сообщение'**
  String get chat_preview_message;

  /// No description provided for @profile_fallback_name.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get profile_fallback_name;

  /// No description provided for @common_cancel_action.
  ///
  /// In ru, this message translates to:
  /// **'Отменить'**
  String get common_cancel_action;

  /// No description provided for @booking_services_label.
  ///
  /// In ru, this message translates to:
  /// **'Услуги'**
  String get booking_services_label;

  /// No description provided for @booking_analytics_label.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get booking_analytics_label;

  /// No description provided for @attendance_punch_clock_in.
  ///
  /// In ru, this message translates to:
  /// **'Пришёл'**
  String get attendance_punch_clock_in;

  /// No description provided for @attendance_punch_clock_out.
  ///
  /// In ru, this message translates to:
  /// **'Ушёл'**
  String get attendance_punch_clock_out;

  /// No description provided for @nav_tab_events.
  ///
  /// In ru, this message translates to:
  /// **'События'**
  String get nav_tab_events;

  /// No description provided for @nav_tab_map.
  ///
  /// In ru, this message translates to:
  /// **'Карта'**
  String get nav_tab_map;

  /// No description provided for @nav_tab_chat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get nav_tab_chat;

  /// No description provided for @nav_tab_profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль'**
  String get nav_tab_profile;

  /// No description provided for @common_date.
  ///
  /// In ru, this message translates to:
  /// **'Дата'**
  String get common_date;

  /// No description provided for @common_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня'**
  String get common_today;

  /// No description provided for @common_yesterday.
  ///
  /// In ru, this message translates to:
  /// **'Вчера'**
  String get common_yesterday;

  /// No description provided for @common_tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Завтра'**
  String get common_tomorrow;

  /// No description provided for @common_start_label.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get common_start_label;

  /// No description provided for @common_end_label.
  ///
  /// In ru, this message translates to:
  /// **'Конец'**
  String get common_end_label;

  /// No description provided for @common_duration.
  ///
  /// In ru, this message translates to:
  /// **'Длительность: {duration}'**
  String common_duration(String duration);

  /// No description provided for @common_event_period.
  ///
  /// In ru, this message translates to:
  /// **'Период события'**
  String get common_event_period;

  /// No description provided for @common_end_after_start.
  ///
  /// In ru, this message translates to:
  /// **'Конец должен быть позже начала'**
  String get common_end_after_start;

  /// No description provided for @common_max_duration.
  ///
  /// In ru, this message translates to:
  /// **'Максимум {duration}'**
  String common_max_duration(String duration);

  /// No description provided for @booking_rest_days.
  ///
  /// In ru, this message translates to:
  /// **'Выходные'**
  String get booking_rest_days;

  /// No description provided for @booking_days.
  ///
  /// In ru, this message translates to:
  /// **'Дни'**
  String get booking_days;

  /// No description provided for @booking_select.
  ///
  /// In ru, this message translates to:
  /// **'Выберите'**
  String get booking_select;

  /// No description provided for @booking_horizon.
  ///
  /// In ru, this message translates to:
  /// **'Горизонт'**
  String get booking_horizon;

  /// No description provided for @booking_horizon_mode.
  ///
  /// In ru, this message translates to:
  /// **'Способ'**
  String get booking_horizon_mode;

  /// No description provided for @booking_horizon_days_ahead.
  ///
  /// In ru, this message translates to:
  /// **'На период'**
  String get booking_horizon_days_ahead;

  /// No description provided for @booking_horizon_until_date.
  ///
  /// In ru, this message translates to:
  /// **'До даты'**
  String get booking_horizon_until_date;

  /// No description provided for @booking_horizon_how_far.
  ///
  /// In ru, this message translates to:
  /// **'На сколько вперёд'**
  String get booking_horizon_how_far;

  /// No description provided for @booking_horizon_period.
  ///
  /// In ru, this message translates to:
  /// **'Период'**
  String get booking_horizon_period;

  /// No description provided for @booking_horizon_forward.
  ///
  /// In ru, this message translates to:
  /// **'Запись вперёд'**
  String get booking_horizon_forward;

  /// No description provided for @booking_until_date.
  ///
  /// In ru, this message translates to:
  /// **'До даты'**
  String get booking_until_date;

  /// No description provided for @booking_hours_title.
  ///
  /// In ru, this message translates to:
  /// **'Часы работы'**
  String get booking_hours_title;

  /// No description provided for @booking_from.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get booking_from;

  /// No description provided for @booking_to.
  ///
  /// In ru, this message translates to:
  /// **'До'**
  String get booking_to;

  /// No description provided for @booking_to_inclusive.
  ///
  /// In ru, this message translates to:
  /// **'По'**
  String get booking_to_inclusive;

  /// No description provided for @booking_more_settings.
  ///
  /// In ru, this message translates to:
  /// **'Ещё настройки'**
  String get booking_more_settings;

  /// No description provided for @booking_cancel_visits_title.
  ///
  /// In ru, this message translates to:
  /// **'Отмена и визиты'**
  String get booking_cancel_visits_title;

  /// No description provided for @booking_client_cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена клиентом'**
  String get booking_client_cancel;

  /// No description provided for @booking_cancel_before_start.
  ///
  /// In ru, this message translates to:
  /// **'До начала'**
  String get booking_cancel_before_start;

  /// No description provided for @booking_hours_before.
  ///
  /// In ru, this message translates to:
  /// **'За {hours} ч'**
  String booking_hours_before(int hours);

  /// No description provided for @booking_auto_no_show.
  ///
  /// In ru, this message translates to:
  /// **'Авто «Не пришёл»'**
  String get booking_auto_no_show;

  /// No description provided for @booking_auto_status.
  ///
  /// In ru, this message translates to:
  /// **'Авто статус'**
  String get booking_auto_status;

  /// No description provided for @booking_off.
  ///
  /// In ru, this message translates to:
  /// **'Выкл'**
  String get booking_off;

  /// No description provided for @booking_after_hours.
  ///
  /// In ru, this message translates to:
  /// **'Через {hours} ч'**
  String booking_after_hours(int hours);

  /// No description provided for @booking_absences_title.
  ///
  /// In ru, this message translates to:
  /// **'Отпуска / отсутствия'**
  String get booking_absences_title;

  /// No description provided for @booking_master.
  ///
  /// In ru, this message translates to:
  /// **'Мастер'**
  String get booking_master;

  /// No description provided for @booking_comment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get booking_comment;

  /// No description provided for @booking_optional.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get booking_optional;

  /// No description provided for @booking_week_1.
  ///
  /// In ru, this message translates to:
  /// **'1 неделя'**
  String get booking_week_1;

  /// No description provided for @booking_weeks_n.
  ///
  /// In ru, this message translates to:
  /// **'{count} недели'**
  String booking_weeks_n(int count);

  /// No description provided for @booking_month_1.
  ///
  /// In ru, this message translates to:
  /// **'1 месяц'**
  String get booking_month_1;

  /// No description provided for @booking_months_n.
  ///
  /// In ru, this message translates to:
  /// **'{count} месяца'**
  String booking_months_n(int count);

  /// No description provided for @booking_inbox_now.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get booking_inbox_now;

  /// No description provided for @booking_inbox_upcoming.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие'**
  String get booking_inbox_upcoming;

  /// No description provided for @booking_inbox_archive.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get booking_inbox_archive;

  /// No description provided for @booking_inbox_now_chair.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас в кресле'**
  String get booking_inbox_now_chair;

  /// No description provided for @booking_inbox_past_archive.
  ///
  /// In ru, this message translates to:
  /// **'Прошедшие и архив'**
  String get booking_inbox_past_archive;

  /// No description provided for @booking_range_this_week.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get booking_range_this_week;

  /// No description provided for @booking_range_next_week.
  ///
  /// In ru, this message translates to:
  /// **'След. неделя'**
  String get booking_range_next_week;

  /// No description provided for @booking_range_this_month.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get booking_range_this_month;

  /// No description provided for @booking_range_next_month.
  ///
  /// In ru, this message translates to:
  /// **'След. месяц'**
  String get booking_range_next_month;

  /// No description provided for @booking_range_all.
  ///
  /// In ru, this message translates to:
  /// **'Все записи'**
  String get booking_range_all;

  /// No description provided for @booking_range_recent.
  ///
  /// In ru, this message translates to:
  /// **'Недавние'**
  String get booking_range_recent;

  /// No description provided for @booking_my_bookings.
  ///
  /// In ru, this message translates to:
  /// **'Мои записи'**
  String get booking_my_bookings;

  /// No description provided for @booking_no_bookings.
  ///
  /// In ru, this message translates to:
  /// **'Записей пока нет'**
  String get booking_no_bookings;

  /// No description provided for @booking_no_bookings_hint.
  ///
  /// In ru, this message translates to:
  /// **'Когда запишетесь к мастеру, визиты появятся здесь по дням'**
  String get booking_no_bookings_hint;

  /// No description provided for @booking_my_bookings_hint.
  ///
  /// In ru, this message translates to:
  /// **'Ваши визиты к мастерам. Выберите день — откройте карточку для переноса или отмены.'**
  String get booking_my_bookings_hint;

  /// No description provided for @booking_day_none.
  ///
  /// In ru, this message translates to:
  /// **'{label} · нет записей'**
  String booking_day_none(String label);

  /// No description provided for @booking_day_one.
  ///
  /// In ru, this message translates to:
  /// **'{label} · 1 запись'**
  String booking_day_one(String label);

  /// No description provided for @booking_day_few.
  ///
  /// In ru, this message translates to:
  /// **'{label} · {count} записи'**
  String booking_day_few(String label, int count);

  /// No description provided for @booking_day_many.
  ///
  /// In ru, this message translates to:
  /// **'{label} · {count} записей'**
  String booking_day_many(String label, int count);

  /// No description provided for @booking_no_day_bookings.
  ///
  /// In ru, this message translates to:
  /// **'На этот день записей нет'**
  String get booking_no_day_bookings;

  /// No description provided for @booking_pick_another_day.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другой день в календаре'**
  String get booking_pick_another_day;

  /// No description provided for @booking_client.
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get booking_client;

  /// No description provided for @booking_service.
  ///
  /// In ru, this message translates to:
  /// **'Услуга'**
  String get booking_service;

  /// No description provided for @booking_services.
  ///
  /// In ru, this message translates to:
  /// **'Услуги'**
  String get booking_services;

  /// No description provided for @booking_team.
  ///
  /// In ru, this message translates to:
  /// **'Команда'**
  String get booking_team;

  /// No description provided for @booking_schedule.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get booking_schedule;

  /// No description provided for @booking_price.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get booking_price;

  /// No description provided for @booking_duration.
  ///
  /// In ru, this message translates to:
  /// **'Длительность'**
  String get booking_duration;

  /// No description provided for @booking_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин'**
  String booking_minutes(int count);

  /// No description provided for @booking_cancel_booking.
  ///
  /// In ru, this message translates to:
  /// **'Отменить запись'**
  String get booking_cancel_booking;

  /// No description provided for @booking_reschedule.
  ///
  /// In ru, this message translates to:
  /// **'Перенести запись'**
  String get booking_reschedule;

  /// No description provided for @booking_reschedule_done.
  ///
  /// In ru, this message translates to:
  /// **'Запись перенесена'**
  String get booking_reschedule_done;

  /// No description provided for @booking_reschedule_action.
  ///
  /// In ru, this message translates to:
  /// **'Перенести'**
  String get booking_reschedule_action;

  /// No description provided for @booking_time.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get booking_time;

  /// No description provided for @booking_day.
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get booking_day;

  /// No description provided for @booking_pick_day.
  ///
  /// In ru, this message translates to:
  /// **'Выберите день'**
  String get booking_pick_day;

  /// No description provided for @booking_note.
  ///
  /// In ru, this message translates to:
  /// **'Заметка'**
  String get booking_note;

  /// No description provided for @booking_reason.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get booking_reason;

  /// No description provided for @booking_executor.
  ///
  /// In ru, this message translates to:
  /// **'Исполнитель'**
  String get booking_executor;

  /// No description provided for @booking_executors.
  ///
  /// In ru, this message translates to:
  /// **'Исполнители'**
  String get booking_executors;

  /// No description provided for @booking_name.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get booking_name;

  /// No description provided for @booking_point.
  ///
  /// In ru, this message translates to:
  /// **'Точка'**
  String get booking_point;

  /// No description provided for @booking_order.
  ///
  /// In ru, this message translates to:
  /// **'Заказ'**
  String get booking_order;

  /// No description provided for @booking_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get booking_load_failed;

  /// No description provided for @booking_chat_open_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат'**
  String get booking_chat_open_failed;

  /// No description provided for @booking_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто'**
  String get booking_empty;

  /// No description provided for @booking_account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get booking_account;

  /// No description provided for @booking_clover_account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт Clover'**
  String get booking_clover_account;

  /// No description provided for @booking_waiting_chat.
  ///
  /// In ru, this message translates to:
  /// **'Ждёт ответа в чате'**
  String get booking_waiting_chat;

  /// No description provided for @booking_in_team.
  ///
  /// In ru, this message translates to:
  /// **'В команде'**
  String get booking_in_team;

  /// No description provided for @booking_request_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отменена'**
  String get booking_request_cancelled;

  /// No description provided for @booking_cancel_service.
  ///
  /// In ru, this message translates to:
  /// **'Отменить услугу'**
  String get booking_cancel_service;

  /// No description provided for @booking_master_already_added.
  ///
  /// In ru, this message translates to:
  /// **'Этот мастер уже добавлен'**
  String get booking_master_already_added;

  /// No description provided for @booking_date_and_start.
  ///
  /// In ru, this message translates to:
  /// **'Дата и начало'**
  String get booking_date_and_start;

  /// No description provided for @booking_created_at.
  ///
  /// In ru, this message translates to:
  /// **'Создана'**
  String get booking_created_at;

  /// No description provided for @common_back_arrow.
  ///
  /// In ru, this message translates to:
  /// **'← Назад'**
  String get common_back_arrow;

  /// No description provided for @common_follow.
  ///
  /// In ru, this message translates to:
  /// **'Подписаться'**
  String get common_follow;

  /// No description provided for @common_unfollow.
  ///
  /// In ru, this message translates to:
  /// **'Отписаться'**
  String get common_unfollow;

  /// No description provided for @common_following.
  ///
  /// In ru, this message translates to:
  /// **'Подписаны'**
  String get common_following;

  /// No description provided for @common_apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get common_apply;

  /// No description provided for @common_reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get common_reset;

  /// No description provided for @common_accept.
  ///
  /// In ru, this message translates to:
  /// **'Принять'**
  String get common_accept;

  /// No description provided for @common_reject.
  ///
  /// In ru, this message translates to:
  /// **'Отклонить'**
  String get common_reject;

  /// No description provided for @common_archive.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать'**
  String get common_archive;

  /// No description provided for @common_unarchive.
  ///
  /// In ru, this message translates to:
  /// **'Разархивировать'**
  String get common_unarchive;

  /// No description provided for @common_download.
  ///
  /// In ru, this message translates to:
  /// **'Скачать'**
  String get common_download;

  /// No description provided for @common_name.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get common_name;

  /// No description provided for @common_description.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get common_description;

  /// No description provided for @common_active.
  ///
  /// In ru, this message translates to:
  /// **'Активно'**
  String get common_active;

  /// No description provided for @common_address.
  ///
  /// In ru, this message translates to:
  /// **'Адрес'**
  String get common_address;

  /// No description provided for @common_filters.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры'**
  String get common_filters;

  /// No description provided for @common_copied.
  ///
  /// In ru, this message translates to:
  /// **'Скопировано'**
  String get common_copied;

  /// No description provided for @common_just_now.
  ///
  /// In ru, this message translates to:
  /// **'только что'**
  String get common_just_now;

  /// No description provided for @common_minutes_short.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин.'**
  String common_minutes_short(int count);

  /// No description provided for @common_hours_short.
  ///
  /// In ru, this message translates to:
  /// **'{count} ч.'**
  String common_hours_short(int count);

  /// No description provided for @common_days_short.
  ///
  /// In ru, this message translates to:
  /// **'{count} д.'**
  String common_days_short(int count);

  /// No description provided for @common_days_plural.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} день} few{{count} дня} other{{count} дней}}'**
  String common_days_plural(int count);

  /// No description provided for @common_minutes_unit.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин'**
  String common_minutes_unit(int count);

  /// No description provided for @common_hours_unit.
  ///
  /// In ru, this message translates to:
  /// **'{count} ч'**
  String common_hours_unit(int count);

  /// No description provided for @common_hours_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{hours} ч {minutes} мин'**
  String common_hours_minutes(int hours, int minutes);

  /// No description provided for @common_zero_minutes.
  ///
  /// In ru, this message translates to:
  /// **'0 мин'**
  String get common_zero_minutes;

  /// No description provided for @common_nothing_found.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get common_nothing_found;

  /// No description provided for @common_try_other_query.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте другой запрос'**
  String get common_try_other_query;

  /// No description provided for @common_try_change_filter.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить фильтр'**
  String get common_try_change_filter;

  /// No description provided for @common_sign_in_required.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт'**
  String get common_sign_in_required;

  /// No description provided for @common_no_one_found.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено'**
  String get common_no_one_found;

  /// No description provided for @common_and.
  ///
  /// In ru, this message translates to:
  /// **'и'**
  String get common_and;

  /// No description provided for @common_and_more.
  ///
  /// In ru, this message translates to:
  /// **'и ещё {count}'**
  String common_and_more(int count);

  /// No description provided for @common_someone.
  ///
  /// In ru, this message translates to:
  /// **'Кто-то'**
  String get common_someone;

  /// No description provided for @common_saving.
  ///
  /// In ru, this message translates to:
  /// **'Сохранение…'**
  String get common_saving;

  /// No description provided for @common_actions.
  ///
  /// In ru, this message translates to:
  /// **'Действия'**
  String get common_actions;

  /// No description provided for @common_messages.
  ///
  /// In ru, this message translates to:
  /// **'Сообщения'**
  String get common_messages;

  /// No description provided for @common_publications.
  ///
  /// In ru, this message translates to:
  /// **'Публикации'**
  String get common_publications;

  /// No description provided for @common_country.
  ///
  /// In ru, this message translates to:
  /// **'Страна'**
  String get common_country;

  /// No description provided for @common_city.
  ///
  /// In ru, this message translates to:
  /// **'Город'**
  String get common_city;

  /// No description provided for @common_pick_country.
  ///
  /// In ru, this message translates to:
  /// **'Выберите страну'**
  String get common_pick_country;

  /// No description provided for @common_pick_city.
  ///
  /// In ru, this message translates to:
  /// **'Выберите город'**
  String get common_pick_city;

  /// No description provided for @common_from.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get common_from;

  /// No description provided for @common_to.
  ///
  /// In ru, this message translates to:
  /// **'По'**
  String get common_to;

  /// No description provided for @common_day_after_tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Послезавтра'**
  String get common_day_after_tomorrow;

  /// No description provided for @common_week.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get common_week;

  /// No description provided for @common_month.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get common_month;

  /// No description provided for @common_inactive_suffix.
  ///
  /// In ru, this message translates to:
  /// **'неактивно'**
  String get common_inactive_suffix;

  /// No description provided for @common_total_count.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String common_total_count(int count);

  /// No description provided for @common_delete_confirm_irreversible.
  ///
  /// In ru, this message translates to:
  /// **'Это действие нельзя отменить.'**
  String get common_delete_confirm_irreversible;

  /// No description provided for @common_could_not_save.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить'**
  String get common_could_not_save;

  /// No description provided for @common_could_not_delete.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось удалить'**
  String get common_could_not_delete;

  /// No description provided for @common_could_not_load.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить'**
  String get common_could_not_load;

  /// No description provided for @common_new_notification.
  ///
  /// In ru, this message translates to:
  /// **'Новое уведомление'**
  String get common_new_notification;

  /// No description provided for @common_new_message.
  ///
  /// In ru, this message translates to:
  /// **'Новое сообщение'**
  String get common_new_message;

  /// No description provided for @common_location_permission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к геолокации в настройках'**
  String get common_location_permission;

  /// No description provided for @common_location_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение'**
  String get common_location_failed;

  /// No description provided for @feed_notif_empty.
  ///
  /// In ru, this message translates to:
  /// **'Уведомлений нет'**
  String get feed_notif_empty;

  /// No description provided for @feed_notif_last_30_days.
  ///
  /// In ru, this message translates to:
  /// **'Показаны уведомления за последние 30 дней'**
  String get feed_notif_last_30_days;

  /// No description provided for @feed_notif_section_last7.
  ///
  /// In ru, this message translates to:
  /// **'Последние 7 дней'**
  String get feed_notif_section_last7;

  /// No description provided for @feed_notif_section_last30.
  ///
  /// In ru, this message translates to:
  /// **'Последние 30 дней'**
  String get feed_notif_section_last30;

  /// No description provided for @feed_notif_login_its_me.
  ///
  /// In ru, this message translates to:
  /// **'Это я'**
  String get feed_notif_login_its_me;

  /// No description provided for @feed_notif_login_revoke.
  ///
  /// In ru, this message translates to:
  /// **'Прервать'**
  String get feed_notif_login_revoke;

  /// No description provided for @feed_notif_login_change_password.
  ///
  /// In ru, this message translates to:
  /// **'Сменить пароль'**
  String get feed_notif_login_change_password;

  /// No description provided for @feed_notif_login_confirmed.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено: это вы'**
  String get feed_notif_login_confirmed;

  /// No description provided for @feed_notif_login_revoked.
  ///
  /// In ru, this message translates to:
  /// **'Сессия прервана'**
  String get feed_notif_login_revoked;

  /// No description provided for @feed_notif_login_resolved.
  ///
  /// In ru, this message translates to:
  /// **'Обработано'**
  String get feed_notif_login_resolved;

  /// No description provided for @feed_notif_followed_you.
  ///
  /// In ru, this message translates to:
  /// **' подписался(-ась) на вас'**
  String get feed_notif_followed_you;

  /// No description provided for @feed_notif_you_followed.
  ///
  /// In ru, this message translates to:
  /// **'Вы подписались на '**
  String get feed_notif_you_followed;

  /// No description provided for @feed_notif_mutual_follow.
  ///
  /// In ru, this message translates to:
  /// **' подписался(-ась) на вас. Вы подписаны друг на друга'**
  String get feed_notif_mutual_follow;

  /// No description provided for @feed_notif_verb_liked.
  ///
  /// In ru, this message translates to:
  /// **'лайкнули'**
  String get feed_notif_verb_liked;

  /// No description provided for @feed_notif_verb_disliked.
  ///
  /// In ru, this message translates to:
  /// **'дизлайкнули'**
  String get feed_notif_verb_disliked;

  /// No description provided for @feed_notif_verb_replied.
  ///
  /// In ru, this message translates to:
  /// **'ответил(а)'**
  String get feed_notif_verb_replied;

  /// No description provided for @feed_notif_verb_commented.
  ///
  /// In ru, this message translates to:
  /// **'прокомментировал(а)'**
  String get feed_notif_verb_commented;

  /// No description provided for @feed_notif_target_your_post.
  ///
  /// In ru, this message translates to:
  /// **'ваш пост'**
  String get feed_notif_target_your_post;

  /// No description provided for @feed_notif_target_your_comment.
  ///
  /// In ru, this message translates to:
  /// **'ваш комментарий'**
  String get feed_notif_target_your_comment;

  /// No description provided for @feed_notif_target_on_your_comment.
  ///
  /// In ru, this message translates to:
  /// **'на ваш комментарий'**
  String get feed_notif_target_on_your_comment;

  /// No description provided for @feed_notif_booking_created_host.
  ///
  /// In ru, this message translates to:
  /// **' записался(-ась): {service}{when}'**
  String feed_notif_booking_created_host(String service, String when);

  /// No description provided for @feed_notif_booking_booked_client_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Вы записаны: '**
  String get feed_notif_booking_booked_client_prefix;

  /// No description provided for @feed_notif_booking_reminder_at_host.
  ///
  /// In ru, this message translates to:
  /// **' у {host}{when}'**
  String feed_notif_booking_reminder_at_host(String host, String when);

  /// No description provided for @feed_notif_visit_started_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас визит — '**
  String get feed_notif_visit_started_prefix;

  /// No description provided for @feed_notif_visit_started_suffix.
  ///
  /// In ru, this message translates to:
  /// **'{when}. Отметьте, пришёл ли клиент'**
  String feed_notif_visit_started_suffix(String when);

  /// No description provided for @feed_notif_visit_close_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Закройте визит — '**
  String get feed_notif_visit_close_prefix;

  /// No description provided for @feed_notif_cancelled_host.
  ///
  /// In ru, this message translates to:
  /// **' отменил(а) запись: {service}{when}'**
  String feed_notif_cancelled_host(String service, String when);

  /// No description provided for @feed_notif_cancelled_client.
  ///
  /// In ru, this message translates to:
  /// **' отменил(а) вашу запись: {service}{when}'**
  String feed_notif_cancelled_client(String service, String when);

  /// No description provided for @feed_notif_completed_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Визит завершён: '**
  String get feed_notif_completed_prefix;

  /// No description provided for @feed_notif_bonus_earn.
  ///
  /// In ru, this message translates to:
  /// **' · +{amount} бонусов'**
  String feed_notif_bonus_earn(int amount);

  /// No description provided for @feed_notif_no_show_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Визит отмечен как «не пришёл»: '**
  String get feed_notif_no_show_prefix;

  /// No description provided for @feed_notif_rescheduled.
  ///
  /// In ru, this message translates to:
  /// **' перенёс(ла) запись: '**
  String get feed_notif_rescheduled;

  /// No description provided for @feed_notif_assigned_staff_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Новая запись на вас: '**
  String get feed_notif_assigned_staff_prefix;

  /// No description provided for @feed_notif_attendance_invite.
  ///
  /// In ru, this message translates to:
  /// **' пригласил(-а) в команду посещаемости'**
  String get feed_notif_attendance_invite;

  /// No description provided for @feed_notif_attendance_rules.
  ///
  /// In ru, this message translates to:
  /// **'Новые правила компании — нужно принять'**
  String get feed_notif_attendance_rules;

  /// No description provided for @feed_notif_attendance_duty.
  ///
  /// In ru, this message translates to:
  /// **'Обновлён список дежурных'**
  String get feed_notif_attendance_duty;

  /// No description provided for @feed_notif_attendance_correction.
  ///
  /// In ru, this message translates to:
  /// **'Запрос на исправление отметки'**
  String get feed_notif_attendance_correction;

  /// No description provided for @feed_notif_login_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Вход в аккаунт с '**
  String get feed_notif_login_prefix;

  /// No description provided for @feed_notif_login_new_device.
  ///
  /// In ru, this message translates to:
  /// **'нового устройства'**
  String get feed_notif_login_new_device;

  /// No description provided for @feed_notif_service_fallback.
  ///
  /// In ru, this message translates to:
  /// **'запись'**
  String get feed_notif_service_fallback;

  /// No description provided for @feed_notif_host_fallback.
  ///
  /// In ru, this message translates to:
  /// **'мастера'**
  String get feed_notif_host_fallback;

  /// No description provided for @feed_notif_reminder_tomorrow.
  ///
  /// In ru, this message translates to:
  /// **'Завтра запись: '**
  String get feed_notif_reminder_tomorrow;

  /// No description provided for @feed_notif_reminder_3h.
  ///
  /// In ru, this message translates to:
  /// **'Через 3 часа: '**
  String get feed_notif_reminder_3h;

  /// No description provided for @feed_notif_reminder_2h.
  ///
  /// In ru, this message translates to:
  /// **'Через 2 часа: '**
  String get feed_notif_reminder_2h;

  /// No description provided for @feed_notif_reminder_1h.
  ///
  /// In ru, this message translates to:
  /// **'Через час: '**
  String get feed_notif_reminder_1h;

  /// No description provided for @feed_notif_reminder_30m.
  ///
  /// In ru, this message translates to:
  /// **'Через 30 мин: '**
  String get feed_notif_reminder_30m;

  /// No description provided for @feed_notif_reminder_15m.
  ///
  /// In ru, this message translates to:
  /// **'Через 15 мин: '**
  String get feed_notif_reminder_15m;

  /// No description provided for @feed_notif_reminder_minutes.
  ///
  /// In ru, this message translates to:
  /// **'Через {minutes} мин: '**
  String feed_notif_reminder_minutes(int minutes);

  /// No description provided for @feed_notif_reminder_default.
  ///
  /// In ru, this message translates to:
  /// **'Напоминание: '**
  String get feed_notif_reminder_default;

  /// No description provided for @feed_notif_punch_clock_out.
  ///
  /// In ru, this message translates to:
  /// **'Пора отметиться на выход{place}'**
  String feed_notif_punch_clock_out(String place);

  /// No description provided for @feed_notif_punch_auto_closed.
  ///
  /// In ru, this message translates to:
  /// **'Смена закрыта автоматически{place}'**
  String feed_notif_punch_auto_closed(String place);

  /// No description provided for @feed_notif_punch_clock_in.
  ///
  /// In ru, this message translates to:
  /// **'Пора отметиться на вход{place}'**
  String feed_notif_punch_clock_in(String place);

  /// No description provided for @feed_map_no_post.
  ///
  /// In ru, this message translates to:
  /// **'У маркера нет поста'**
  String get feed_map_no_post;

  /// No description provided for @feed_map_empty_posts.
  ///
  /// In ru, this message translates to:
  /// **'Нет публикаций'**
  String get feed_map_empty_posts;

  /// No description provided for @feed_events_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено'**
  String get feed_events_empty_title;

  /// No description provided for @feed_events_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Попробуйте изменить фильтр'**
  String get feed_events_empty_subtitle;

  /// No description provided for @feed_events_no_more.
  ///
  /// In ru, this message translates to:
  /// **'Больше публикаций нет'**
  String get feed_events_no_more;

  /// No description provided for @feed_filter_title.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр'**
  String get feed_filter_title;

  /// No description provided for @feed_filter_map_title.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр карты'**
  String get feed_filter_map_title;

  /// No description provided for @feed_filter_event_days.
  ///
  /// In ru, this message translates to:
  /// **'Дни ивента'**
  String get feed_filter_event_days;

  /// No description provided for @feed_filter_emoji_label.
  ///
  /// In ru, this message translates to:
  /// **'Эмодзи ивента'**
  String get feed_filter_emoji_label;

  /// No description provided for @feed_filter_emoji_hint.
  ///
  /// In ru, this message translates to:
  /// **'Любое — оставьте пустым'**
  String get feed_filter_emoji_hint;

  /// No description provided for @feed_filter_tags_label.
  ///
  /// In ru, this message translates to:
  /// **'Теги маркера'**
  String get feed_filter_tags_label;

  /// No description provided for @feed_filter_tags_hint.
  ///
  /// In ru, this message translates to:
  /// **'Любые — оставьте пустым'**
  String get feed_filter_tags_hint;

  /// No description provided for @feed_filter_tags_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск тега'**
  String get feed_filter_tags_search;

  /// No description provided for @feed_filter_start_hint.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get feed_filter_start_hint;

  /// No description provided for @feed_filter_end_hint.
  ///
  /// In ru, this message translates to:
  /// **'Конец'**
  String get feed_filter_end_hint;

  /// No description provided for @booking_point_label.
  ///
  /// In ru, this message translates to:
  /// **'Точка'**
  String get booking_point_label;

  /// No description provided for @booking_point_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Точка не найдена'**
  String get booking_point_not_found;

  /// No description provided for @booking_point_default_name.
  ///
  /// In ru, this message translates to:
  /// **'Основная'**
  String get booking_point_default_name;

  /// No description provided for @booking_point_new_title.
  ///
  /// In ru, this message translates to:
  /// **'Новая точка'**
  String get booking_point_new_title;

  /// No description provided for @booking_point_new_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Салон, филиал или кабинет'**
  String get booking_point_new_subtitle;

  /// No description provided for @booking_point_card_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Услуги, расписание, записи'**
  String get booking_point_card_subtitle;

  /// No description provided for @booking_point_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать точку'**
  String get booking_point_create_failed;

  /// No description provided for @booking_point_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get booking_point_name_label;

  /// No description provided for @booking_my_bookings_title.
  ///
  /// In ru, this message translates to:
  /// **'Мои записи'**
  String get booking_my_bookings_title;

  /// No description provided for @booking_my_bookings_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Календарь и визиты'**
  String get booking_my_bookings_subtitle;

  /// No description provided for @booking_services_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Цены и длительность'**
  String get booking_services_subtitle;

  /// No description provided for @booking_team_title.
  ///
  /// In ru, this message translates to:
  /// **'Команда'**
  String get booking_team_title;

  /// No description provided for @booking_team_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Мастера и приглашения'**
  String get booking_team_subtitle;

  /// No description provided for @booking_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get booking_chat_title;

  /// No description provided for @booking_chat_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Команда точки'**
  String get booking_chat_subtitle;

  /// No description provided for @booking_analytics_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Записи и услуги'**
  String get booking_analytics_subtitle;

  /// No description provided for @booking_schedule_title.
  ///
  /// In ru, this message translates to:
  /// **'Расписание'**
  String get booking_schedule_title;

  /// No description provided for @booking_schedule_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Часы и отсутствия'**
  String get booking_schedule_subtitle;

  /// No description provided for @booking_master_label.
  ///
  /// In ru, this message translates to:
  /// **'Мастер'**
  String get booking_master_label;

  /// No description provided for @booking_masters_label.
  ///
  /// In ru, this message translates to:
  /// **'Мастера'**
  String get booking_masters_label;

  /// No description provided for @booking_all_masters.
  ///
  /// In ru, this message translates to:
  /// **'Все мастера'**
  String get booking_all_masters;

  /// No description provided for @booking_client_label.
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get booking_client_label;

  /// No description provided for @booking_executor_label.
  ///
  /// In ru, this message translates to:
  /// **'Исполнитель'**
  String get booking_executor_label;

  /// No description provided for @booking_executors_label.
  ///
  /// In ru, this message translates to:
  /// **'Исполнители'**
  String get booking_executors_label;

  /// No description provided for @booking_service_label.
  ///
  /// In ru, this message translates to:
  /// **'Услуга'**
  String get booking_service_label;

  /// No description provided for @booking_price_label.
  ///
  /// In ru, this message translates to:
  /// **'Цена'**
  String get booking_price_label;

  /// No description provided for @booking_price_tenge_label.
  ///
  /// In ru, this message translates to:
  /// **'Цена ₸'**
  String get booking_price_tenge_label;

  /// No description provided for @booking_duration_label.
  ///
  /// In ru, this message translates to:
  /// **'Длительность'**
  String get booking_duration_label;

  /// No description provided for @booking_minutes_short.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин'**
  String booking_minutes_short(int count);

  /// No description provided for @booking_note_label.
  ///
  /// In ru, this message translates to:
  /// **'Заметка'**
  String get booking_note_label;

  /// No description provided for @booking_client_note_title.
  ///
  /// In ru, this message translates to:
  /// **'Заметка клиента'**
  String get booking_client_note_title;

  /// No description provided for @booking_salon_label.
  ///
  /// In ru, this message translates to:
  /// **'Салон'**
  String get booking_salon_label;

  /// No description provided for @booking_comment_label.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get booking_comment_label;

  /// No description provided for @booking_reason_label.
  ///
  /// In ru, this message translates to:
  /// **'Причина'**
  String get booking_reason_label;

  /// No description provided for @booking_reason_optional_label.
  ///
  /// In ru, this message translates to:
  /// **'Причина (необяз.)'**
  String get booking_reason_optional_label;

  /// No description provided for @booking_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get booking_name_label;

  /// No description provided for @booking_username_label.
  ///
  /// In ru, this message translates to:
  /// **'Никнейм'**
  String get booking_username_label;

  /// No description provided for @booking_phone_label.
  ///
  /// In ru, this message translates to:
  /// **'Телефон'**
  String get booking_phone_label;

  /// No description provided for @booking_status_label.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get booking_status_label;

  /// No description provided for @booking_when_label.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get booking_when_label;

  /// No description provided for @booking_time_label.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get booking_time_label;

  /// No description provided for @booking_day_label.
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get booking_day_label;

  /// No description provided for @booking_days_label.
  ///
  /// In ru, this message translates to:
  /// **'Дни'**
  String get booking_days_label;

  /// No description provided for @booking_hour_label.
  ///
  /// In ru, this message translates to:
  /// **'Час'**
  String get booking_hour_label;

  /// No description provided for @booking_period_label.
  ///
  /// In ru, this message translates to:
  /// **'Период'**
  String get booking_period_label;

  /// No description provided for @booking_start_label.
  ///
  /// In ru, this message translates to:
  /// **'Начало'**
  String get booking_start_label;

  /// No description provided for @booking_end_label.
  ///
  /// In ru, this message translates to:
  /// **'Конец'**
  String get booking_end_label;

  /// No description provided for @booking_from_label.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get booking_from_label;

  /// No description provided for @booking_to_label.
  ///
  /// In ru, this message translates to:
  /// **'По'**
  String get booking_to_label;

  /// No description provided for @booking_until_label.
  ///
  /// In ru, this message translates to:
  /// **'До'**
  String get booking_until_label;

  /// No description provided for @booking_until_date_label.
  ///
  /// In ru, this message translates to:
  /// **'До даты'**
  String get booking_until_date_label;

  /// No description provided for @booking_description_label.
  ///
  /// In ru, this message translates to:
  /// **'Описание'**
  String get booking_description_label;

  /// No description provided for @booking_emoji_label.
  ///
  /// In ru, this message translates to:
  /// **'Эмодзи'**
  String get booking_emoji_label;

  /// No description provided for @booking_method_label.
  ///
  /// In ru, this message translates to:
  /// **'Способ'**
  String get booking_method_label;

  /// No description provided for @booking_optional_hint.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно'**
  String get booking_optional_hint;

  /// No description provided for @booking_pick_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите'**
  String get booking_pick_hint;

  /// No description provided for @booking_pick_day_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите день'**
  String get booking_pick_day_hint;

  /// No description provided for @booking_apply.
  ///
  /// In ru, this message translates to:
  /// **'Применить'**
  String get booking_apply;

  /// No description provided for @booking_select_action.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать'**
  String get booking_select_action;

  /// No description provided for @booking_all.
  ///
  /// In ru, this message translates to:
  /// **'Все'**
  String get booking_all;

  /// No description provided for @booking_inactive.
  ///
  /// In ru, this message translates to:
  /// **'неактивен'**
  String get booking_inactive;

  /// No description provided for @booking_on_site.
  ///
  /// In ru, this message translates to:
  /// **'на месте'**
  String get booking_on_site;

  /// No description provided for @booking_empty_yet.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто'**
  String get booking_empty_yet;

  /// No description provided for @booking_back_arrow.
  ///
  /// In ru, this message translates to:
  /// **'← Назад'**
  String get booking_back_arrow;

  /// No description provided for @booking_inbox_tab_now_short.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас'**
  String get booking_inbox_tab_now_short;

  /// No description provided for @booking_inbox_tab_upcoming_short.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие'**
  String get booking_inbox_tab_upcoming_short;

  /// No description provided for @booking_inbox_tab_archive_short.
  ///
  /// In ru, this message translates to:
  /// **'Архив'**
  String get booking_inbox_tab_archive_short;

  /// No description provided for @booking_inbox_tab_now.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас в кресле'**
  String get booking_inbox_tab_now;

  /// No description provided for @booking_inbox_tab_upcoming.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящие'**
  String get booking_inbox_tab_upcoming;

  /// No description provided for @booking_inbox_tab_archive.
  ///
  /// In ru, this message translates to:
  /// **'Прошедшие и архив'**
  String get booking_inbox_tab_archive;

  /// No description provided for @booking_point_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Запись · {name}'**
  String booking_point_chat_title(String name);

  /// No description provided for @booking_open_chat_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат'**
  String get booking_open_chat_failed;

  /// No description provided for @booking_my_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Записей пока нет'**
  String get booking_my_empty_title;

  /// No description provided for @booking_my_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Когда запишетесь к мастеру, визиты появятся здесь по дням'**
  String get booking_my_empty_subtitle;

  /// No description provided for @booking_my_intro.
  ///
  /// In ru, this message translates to:
  /// **'Ваши визиты к мастерам. Выберите день — откройте карточку для переноса или отмены.'**
  String get booking_my_intro;

  /// No description provided for @booking_my_day_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'На этот день записей нет'**
  String get booking_my_day_empty_title;

  /// No description provided for @booking_my_day_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другой день в календаре'**
  String get booking_my_day_empty_subtitle;

  /// No description provided for @booking_count_none.
  ///
  /// In ru, this message translates to:
  /// **'{label} · нет записей'**
  String booking_count_none(String label);

  /// No description provided for @booking_count_one.
  ///
  /// In ru, this message translates to:
  /// **'{label} · 1 запись'**
  String booking_count_one(String label);

  /// No description provided for @booking_count_few.
  ///
  /// In ru, this message translates to:
  /// **'{label} · {count} записи'**
  String booking_count_few(String label, int count);

  /// No description provided for @booking_count_many.
  ///
  /// In ru, this message translates to:
  /// **'{label} · {count} записей'**
  String booking_count_many(String label, int count);

  /// No description provided for @booking_cancel_booking_title.
  ///
  /// In ru, this message translates to:
  /// **'Отменить запись'**
  String get booking_cancel_booking_title;

  /// No description provided for @booking_cancel_too_late.
  ///
  /// In ru, this message translates to:
  /// **'Отменить запись уже нельзя — слишком близко к визиту'**
  String get booking_cancel_too_late;

  /// No description provided for @booking_cancel_success.
  ///
  /// In ru, this message translates to:
  /// **'Запись отменена'**
  String get booking_cancel_success;

  /// No description provided for @booking_reschedule_too_late.
  ///
  /// In ru, this message translates to:
  /// **'Перенести запись уже нельзя — слишком близко к визиту'**
  String get booking_reschedule_too_late;

  /// No description provided for @booking_reschedule_missing_parties.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя перенести: нет услуги, мастера или владельца записи'**
  String get booking_reschedule_missing_parties;

  /// No description provided for @booking_reschedule_title.
  ///
  /// In ru, this message translates to:
  /// **'Перенести запись'**
  String get booking_reschedule_title;

  /// No description provided for @booking_reschedule_success.
  ///
  /// In ru, this message translates to:
  /// **'Запись перенесена'**
  String get booking_reschedule_success;

  /// No description provided for @booking_cancel_preset_plans.
  ///
  /// In ru, this message translates to:
  /// **'Планы изменились — не смогу прийти'**
  String get booking_cancel_preset_plans;

  /// No description provided for @booking_cancel_preset_wrong_time.
  ///
  /// In ru, this message translates to:
  /// **'Перепутал время или дату'**
  String get booking_cancel_preset_wrong_time;

  /// No description provided for @booking_cancel_preset_other_time.
  ///
  /// In ru, this message translates to:
  /// **'Запишусь на другое время'**
  String get booking_cancel_preset_other_time;

  /// No description provided for @booking_cancel_preset_not_needed.
  ///
  /// In ru, this message translates to:
  /// **'Больше не нужна эта услуга'**
  String get booking_cancel_preset_not_needed;

  /// No description provided for @booking_cancel_body.
  ///
  /// In ru, this message translates to:
  /// **'«{service}» у {host} будет отменена. Слот освободится для других клиентов.'**
  String booking_cancel_body(String service, String host);

  /// No description provided for @booking_ready_messages.
  ///
  /// In ru, this message translates to:
  /// **'Готовые сообщения'**
  String get booking_ready_messages;

  /// No description provided for @booking_reason_hint.
  ///
  /// In ru, this message translates to:
  /// **'Напишите своё сообщение или выберите выше'**
  String get booking_reason_hint;

  /// No description provided for @booking_available_times.
  ///
  /// In ru, this message translates to:
  /// **'Доступное время'**
  String get booking_available_times;

  /// No description provided for @booking_no_free_times_day.
  ///
  /// In ru, this message translates to:
  /// **'На этот день нет свободного времени'**
  String get booking_no_free_times_day;

  /// No description provided for @booking_book_action.
  ///
  /// In ru, this message translates to:
  /// **'Записаться'**
  String get booking_book_action;

  /// No description provided for @booking_confirmed_toast.
  ///
  /// In ru, this message translates to:
  /// **'Запись подтверждена'**
  String get booking_confirmed_toast;

  /// No description provided for @booking_day_unavailable_rest.
  ///
  /// In ru, this message translates to:
  /// **'В этот день запись недоступна — выходной'**
  String get booking_day_unavailable_rest;

  /// No description provided for @booking_day_unavailable_executor.
  ///
  /// In ru, this message translates to:
  /// **'{name} недоступен в этот день'**
  String booking_day_unavailable_executor(String name);

  /// No description provided for @booking_day_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'В этот день запись недоступна'**
  String get booking_day_unavailable;

  /// No description provided for @booking_slot_conflict_self.
  ///
  /// In ru, this message translates to:
  /// **'Это время пересекается с вашей другой записью'**
  String get booking_slot_conflict_self;

  /// No description provided for @booking_slot_taken_by.
  ///
  /// In ru, this message translates to:
  /// **'Это время уже занято у {name}'**
  String booking_slot_taken_by(String name);

  /// No description provided for @booking_conflict_with_yours.
  ///
  /// In ru, this message translates to:
  /// **'Конфликт с вашей записью'**
  String get booking_conflict_with_yours;

  /// No description provided for @booking_busy.
  ///
  /// In ru, this message translates to:
  /// **'Занято'**
  String get booking_busy;

  /// No description provided for @booking_no_free_slots_day.
  ///
  /// In ru, this message translates to:
  /// **'На этот день свободных слотов нет'**
  String get booking_no_free_slots_day;

  /// No description provided for @booking_slots_for_day.
  ///
  /// In ru, this message translates to:
  /// **'Свободные слоты на выбранный день'**
  String get booking_slots_for_day;

  /// No description provided for @booking_pick_visit_day.
  ///
  /// In ru, this message translates to:
  /// **'Выберите день визита'**
  String get booking_pick_visit_day;

  /// No description provided for @booking_review_before_book.
  ///
  /// In ru, this message translates to:
  /// **'Проверьте перед записью'**
  String get booking_review_before_book;

  /// No description provided for @booking_who_does_service.
  ///
  /// In ru, this message translates to:
  /// **'Кто будет делать услугу'**
  String get booking_who_does_service;

  /// No description provided for @booking_comment_hint.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно — пожелания мастеру'**
  String get booking_comment_hint;

  /// No description provided for @booking_comment_example_hint.
  ///
  /// In ru, this message translates to:
  /// **'Например: коротко сбоку'**
  String get booking_comment_example_hint;

  /// No description provided for @booking_pay_with_bonuses.
  ///
  /// In ru, this message translates to:
  /// **'Оплатить бонусами'**
  String get booking_pay_with_bonuses;

  /// No description provided for @booking_no_bonus_spend.
  ///
  /// In ru, this message translates to:
  /// **'Без списания бонусов'**
  String get booking_no_bonus_spend;

  /// No description provided for @booking_bonus_balance_no_spend.
  ///
  /// In ru, this message translates to:
  /// **'На балансе {balance}. Бонусы за этот визит не списываем.'**
  String booking_bonus_balance_no_spend(String balance);

  /// No description provided for @booking_bonus_balance_spend.
  ///
  /// In ru, this message translates to:
  /// **'На балансе {balance}. После визита спишем до {spend}'**
  String booking_bonus_balance_spend(String balance, String spend);

  /// No description provided for @booking_bonus_spend_zero.
  ///
  /// In ru, this message translates to:
  /// **'Списать 0 (недостаточно на балансе)'**
  String get booking_bonus_spend_zero;

  /// No description provided for @booking_bonus_spend_amount.
  ///
  /// In ru, this message translates to:
  /// **'Списать −{amount} {word}'**
  String booking_bonus_spend_amount(String amount, String word);

  /// No description provided for @booking_bonus_earn_amount.
  ///
  /// In ru, this message translates to:
  /// **'Начислить +{amount} {word}'**
  String booking_bonus_earn_amount(String amount, String word);

  /// No description provided for @booking_bonus_percent_of_price.
  ///
  /// In ru, this message translates to:
  /// **'({percent}% цены). Остаток — на месте.'**
  String booking_bonus_percent_of_price(int percent);

  /// No description provided for @booking_max_people_short.
  ///
  /// In ru, this message translates to:
  /// **'до {count} чел.'**
  String booking_max_people_short(int count);

  /// No description provided for @booking_time_range_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{start}–{end} · {minutes} мин'**
  String booking_time_range_minutes(String start, String end, int minutes);

  /// No description provided for @booking_master_with_name.
  ///
  /// In ru, this message translates to:
  /// **'Мастер: {name}'**
  String booking_master_with_name(String name);

  /// No description provided for @booking_comment_with_text.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий: {text}'**
  String booking_comment_with_text(String text);

  /// No description provided for @booking_service_new_title.
  ///
  /// In ru, this message translates to:
  /// **'Новая услуга'**
  String get booking_service_new_title;

  /// No description provided for @booking_service_edit_title.
  ///
  /// In ru, this message translates to:
  /// **'Редактирование'**
  String get booking_service_edit_title;

  /// No description provided for @booking_service_added.
  ///
  /// In ru, this message translates to:
  /// **'Услуга добавлена'**
  String get booking_service_added;

  /// No description provided for @booking_service_saved.
  ///
  /// In ru, this message translates to:
  /// **'Услуга сохранена'**
  String get booking_service_saved;

  /// No description provided for @booking_service_active.
  ///
  /// In ru, this message translates to:
  /// **'Услуга активна'**
  String get booking_service_active;

  /// No description provided for @booking_service_hidden.
  ///
  /// In ru, this message translates to:
  /// **'Скрыта из записи'**
  String get booking_service_hidden;

  /// No description provided for @booking_show_to_clients.
  ///
  /// In ru, this message translates to:
  /// **'Показывать клиентам'**
  String get booking_show_to_clients;

  /// No description provided for @booking_add_service.
  ///
  /// In ru, this message translates to:
  /// **'Добавить услугу'**
  String get booking_add_service;

  /// No description provided for @booking_services_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Услуг пока нет'**
  String get booking_services_empty_title;

  /// No description provided for @booking_services_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте первую — название, длительность и цену'**
  String get booking_services_empty_subtitle;

  /// No description provided for @booking_my_services_title.
  ///
  /// In ru, this message translates to:
  /// **'Мои услуги'**
  String get booking_my_services_title;

  /// No description provided for @booking_service_title_hint.
  ///
  /// In ru, this message translates to:
  /// **'Стрижка мужская'**
  String get booking_service_title_hint;

  /// No description provided for @booking_buffer_after_min.
  ///
  /// In ru, this message translates to:
  /// **'Буфер после, мин'**
  String get booking_buffer_after_min;

  /// No description provided for @booking_buffer_create_only.
  ///
  /// In ru, this message translates to:
  /// **'Буфер меняется только при создании'**
  String get booking_buffer_create_only;

  /// No description provided for @booking_max_participants.
  ///
  /// In ru, this message translates to:
  /// **'Макс. участников'**
  String get booking_max_participants;

  /// No description provided for @booking_bonuses_per_visit.
  ///
  /// In ru, this message translates to:
  /// **'Бонусов за визит'**
  String get booking_bonuses_per_visit;

  /// No description provided for @booking_bonus_pay_percent.
  ///
  /// In ru, this message translates to:
  /// **'Оплата бонусами, %'**
  String get booking_bonus_pay_percent;

  /// No description provided for @booking_minutes_field.
  ///
  /// In ru, this message translates to:
  /// **'Минуты'**
  String get booking_minutes_field;

  /// No description provided for @booking_add_executor.
  ///
  /// In ru, this message translates to:
  /// **'Добавить исполнителя'**
  String get booking_add_executor;

  /// No description provided for @booking_executors_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} мастер(ов)'**
  String booking_executors_count(int count);

  /// No description provided for @booking_executor_already_added.
  ///
  /// In ru, this message translates to:
  /// **'Этот мастер уже добавлен'**
  String get booking_executor_already_added;

  /// No description provided for @booking_cancel_service_title.
  ///
  /// In ru, this message translates to:
  /// **'Отменить услугу'**
  String get booking_cancel_service_title;

  /// No description provided for @booking_cancel_service_body.
  ///
  /// In ru, this message translates to:
  /// **'«{service}» перестанет отображаться клиентам. Новые записи будут недоступны.'**
  String booking_cancel_service_body(String service);

  /// No description provided for @booking_cancel_service_preset_plans.
  ///
  /// In ru, this message translates to:
  /// **'Планы изменились — услуга временно недоступна'**
  String get booking_cancel_service_preset_plans;

  /// No description provided for @booking_cancel_service_preset_master.
  ///
  /// In ru, this message translates to:
  /// **'Мастер недоступен'**
  String get booking_cancel_service_preset_master;

  /// No description provided for @booking_cancel_service_preset_stopped.
  ///
  /// In ru, this message translates to:
  /// **'Больше не оказываем эту услугу'**
  String get booking_cancel_service_preset_stopped;

  /// No description provided for @booking_cancel_service_preset_updating.
  ///
  /// In ru, this message translates to:
  /// **'Обновляем расписание и прайс'**
  String get booking_cancel_service_preset_updating;

  /// No description provided for @booking_team_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Команда пустая'**
  String get booking_team_empty_title;

  /// No description provided for @booking_team_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Пригласите аккаунт Clover или добавьте имя для слотов'**
  String get booking_team_empty_subtitle;

  /// No description provided for @booking_find_account.
  ///
  /// In ru, this message translates to:
  /// **'Найти аккаунт'**
  String get booking_find_account;

  /// No description provided for @booking_already_in_team.
  ///
  /// In ru, this message translates to:
  /// **'Уже в команде'**
  String get booking_already_in_team;

  /// No description provided for @booking_invited.
  ///
  /// In ru, this message translates to:
  /// **'Приглашён'**
  String get booking_invited;

  /// No description provided for @booking_invite_sent_chat.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено в чат'**
  String get booking_invite_sent_chat;

  /// No description provided for @booking_invite_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Заявка отменена'**
  String get booking_invite_cancelled;

  /// No description provided for @booking_removed_from_team.
  ///
  /// In ru, this message translates to:
  /// **'Убрано из команды'**
  String get booking_removed_from_team;

  /// No description provided for @booking_remove_from_team.
  ///
  /// In ru, this message translates to:
  /// **'Убрать из команды'**
  String get booking_remove_from_team;

  /// No description provided for @booking_cancel_invite.
  ///
  /// In ru, this message translates to:
  /// **'Отменить заявку'**
  String get booking_cancel_invite;

  /// No description provided for @booking_team_empty_hint.
  ///
  /// In ru, this message translates to:
  /// **'Пока никого нет — пригласите аккаунт Clover или добавьте имя.'**
  String get booking_team_empty_hint;

  /// No description provided for @booking_team_invite_or_name.
  ///
  /// In ru, this message translates to:
  /// **'Пригласите из Clover или добавьте только имя для слотов.'**
  String get booking_team_invite_or_name;

  /// No description provided for @booking_pending_replies.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают ответа'**
  String get booking_pending_replies;

  /// No description provided for @booking_pending_short.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get booking_pending_short;

  /// No description provided for @booking_waiting_plural.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают'**
  String get booking_waiting_plural;

  /// No description provided for @booking_invite_from_clover.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить из Clover'**
  String get booking_invite_from_clover;

  /// No description provided for @booking_add_name_only.
  ///
  /// In ru, this message translates to:
  /// **'Добавить только имя'**
  String get booking_add_name_only;

  /// No description provided for @booking_invite_chat_hint.
  ///
  /// In ru, this message translates to:
  /// **'Отправим заявку в личный чат. После «Принять» можно назначить на услугу.'**
  String get booking_invite_chat_hint;

  /// No description provided for @booking_search_user_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по никнейму или имени'**
  String get booking_search_user_hint;

  /// No description provided for @booking_nobody_found.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено'**
  String get booking_nobody_found;

  /// No description provided for @booking_invite_action.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить'**
  String get booking_invite_action;

  /// No description provided for @booking_name_only_hint.
  ///
  /// In ru, this message translates to:
  /// **'Без аккаунта Clover — только имя в слотах. Календаря у исполнителя не будет.'**
  String get booking_name_only_hint;

  /// No description provided for @booking_executor_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Имя исполнителя'**
  String get booking_executor_name_hint;

  /// No description provided for @booking_account_clover.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт Clover'**
  String get booking_account_clover;

  /// No description provided for @booking_account_label.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get booking_account_label;

  /// No description provided for @booking_name_only_short.
  ///
  /// In ru, this message translates to:
  /// **'Только имя'**
  String get booking_name_only_short;

  /// No description provided for @booking_name_only_slots.
  ///
  /// In ru, this message translates to:
  /// **'Только имя в слотах'**
  String get booking_name_only_slots;

  /// No description provided for @booking_waiting_chat_reply.
  ///
  /// In ru, this message translates to:
  /// **'Ждёт ответа в чате'**
  String get booking_waiting_chat_reply;

  /// No description provided for @booking_waiting_chat_reply_user.
  ///
  /// In ru, this message translates to:
  /// **'@{username} · ждёт ответа в чате'**
  String booking_waiting_chat_reply_user(String username);

  /// No description provided for @booking_add_masters_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала добавьте мастеров в услугах'**
  String get booking_add_masters_first;

  /// No description provided for @booking_rest_days_title.
  ///
  /// In ru, this message translates to:
  /// **'Выходные'**
  String get booking_rest_days_title;

  /// No description provided for @booking_horizon_title.
  ///
  /// In ru, this message translates to:
  /// **'Горизонт'**
  String get booking_horizon_title;

  /// No description provided for @booking_book_ahead_title.
  ///
  /// In ru, this message translates to:
  /// **'Запись вперёд'**
  String get booking_book_ahead_title;

  /// No description provided for @booking_cancel_and_visits_title.
  ///
  /// In ru, this message translates to:
  /// **'Отмена и визиты'**
  String get booking_cancel_and_visits_title;

  /// No description provided for @booking_master_schedule.
  ///
  /// In ru, this message translates to:
  /// **'График мастера'**
  String get booking_master_schedule;

  /// No description provided for @booking_time_blocks_title.
  ///
  /// In ru, this message translates to:
  /// **'Блоки времени'**
  String get booking_time_blocks_title;

  /// No description provided for @booking_time_block_title.
  ///
  /// In ru, this message translates to:
  /// **'Блок времени'**
  String get booking_time_block_title;

  /// No description provided for @booking_no_blocks.
  ///
  /// In ru, this message translates to:
  /// **'Нет блоков'**
  String get booking_no_blocks;

  /// No description provided for @booking_block_time.
  ///
  /// In ru, this message translates to:
  /// **'Заблокировать'**
  String get booking_block_time;

  /// No description provided for @booking_time_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Время заблокировано'**
  String get booking_time_blocked;

  /// No description provided for @booking_end_after_start.
  ///
  /// In ru, this message translates to:
  /// **'Конец должен быть позже начала'**
  String get booking_end_after_start;

  /// No description provided for @booking_settings_saved.
  ///
  /// In ru, this message translates to:
  /// **'Настройки сохранены'**
  String get booking_settings_saved;

  /// No description provided for @booking_system_section.
  ///
  /// In ru, this message translates to:
  /// **'Системное'**
  String get booking_system_section;

  /// No description provided for @booking_client_cancel_label.
  ///
  /// In ru, this message translates to:
  /// **'Отмена клиентом'**
  String get booking_client_cancel_label;

  /// No description provided for @booking_auto_no_show_label.
  ///
  /// In ru, this message translates to:
  /// **'Авто «Не пришёл»'**
  String get booking_auto_no_show_label;

  /// No description provided for @booking_auto_status_sheet.
  ///
  /// In ru, this message translates to:
  /// **'Авто статус'**
  String get booking_auto_status_sheet;

  /// No description provided for @booking_how_far_ahead.
  ///
  /// In ru, this message translates to:
  /// **'На сколько вперёд'**
  String get booking_how_far_ahead;

  /// No description provided for @booking_ending_label.
  ///
  /// In ru, this message translates to:
  /// **'Окончание'**
  String get booking_ending_label;

  /// No description provided for @booking_before_start.
  ///
  /// In ru, this message translates to:
  /// **'До начала'**
  String get booking_before_start;

  /// No description provided for @booking_hours_after.
  ///
  /// In ru, this message translates to:
  /// **'Через {hours} ч'**
  String booking_hours_after(int hours);

  /// No description provided for @booking_weeks_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} недели'**
  String booking_weeks_count(int count);

  /// No description provided for @booking_week_one.
  ///
  /// In ru, this message translates to:
  /// **'1 неделя'**
  String get booking_week_one;

  /// No description provided for @booking_weeks_two.
  ///
  /// In ru, this message translates to:
  /// **'2 недели'**
  String get booking_weeks_two;

  /// No description provided for @booking_weeks_three.
  ///
  /// In ru, this message translates to:
  /// **'3 недели'**
  String get booking_weeks_three;

  /// No description provided for @booking_month_one.
  ///
  /// In ru, this message translates to:
  /// **'1 месяц'**
  String get booking_month_one;

  /// No description provided for @booking_months_two.
  ///
  /// In ru, this message translates to:
  /// **'2 месяца'**
  String get booking_months_two;

  /// No description provided for @booking_months_three.
  ///
  /// In ru, this message translates to:
  /// **'3 месяца'**
  String get booking_months_three;

  /// No description provided for @booking_block_reason_hint.
  ///
  /// In ru, this message translates to:
  /// **'Обед, совещание…'**
  String get booking_block_reason_hint;

  /// No description provided for @booking_week_label.
  ///
  /// In ru, this message translates to:
  /// **'Неделя'**
  String get booking_week_label;

  /// No description provided for @booking_month_label.
  ///
  /// In ru, this message translates to:
  /// **'Месяц'**
  String get booking_month_label;

  /// No description provided for @booking_assigned_label.
  ///
  /// In ru, this message translates to:
  /// **'Назначен'**
  String get booking_assigned_label;

  /// No description provided for @booking_created_label.
  ///
  /// In ru, this message translates to:
  /// **'Создана'**
  String get booking_created_label;

  /// No description provided for @booking_participants_label.
  ///
  /// In ru, this message translates to:
  /// **'Участников'**
  String get booking_participants_label;

  /// No description provided for @booking_complete_visit_q.
  ///
  /// In ru, this message translates to:
  /// **'Завершить визит?'**
  String get booking_complete_visit_q;

  /// No description provided for @booking_complete_action.
  ///
  /// In ru, this message translates to:
  /// **'Завершить'**
  String get booking_complete_action;

  /// No description provided for @booking_complete_visit_now.
  ///
  /// In ru, this message translates to:
  /// **'Завершить визит сейчас'**
  String get booking_complete_visit_now;

  /// No description provided for @booking_complete_body.
  ///
  /// In ru, this message translates to:
  /// **'Запись будет закрыта, слот освободится для других клиентов.'**
  String get booking_complete_body;

  /// No description provided for @booking_no_show_q.
  ///
  /// In ru, this message translates to:
  /// **'Клиент не пришёл?'**
  String get booking_no_show_q;

  /// No description provided for @booking_no_show_action.
  ///
  /// In ru, this message translates to:
  /// **'Клиент не пришёл'**
  String get booking_no_show_action;

  /// No description provided for @booking_no_show_short.
  ///
  /// In ru, this message translates to:
  /// **'Не пришёл'**
  String get booking_no_show_short;

  /// No description provided for @booking_no_show_body.
  ///
  /// In ru, this message translates to:
  /// **'Слот освободится. Отменить можно в любой момент, даже если услуга уже началась.'**
  String get booking_no_show_body;

  /// No description provided for @booking_undo_last_step_q.
  ///
  /// In ru, this message translates to:
  /// **'Отменить последний шаг?'**
  String get booking_undo_last_step_q;

  /// No description provided for @booking_undo_action.
  ///
  /// In ru, this message translates to:
  /// **'Вернуть'**
  String get booking_undo_action;

  /// No description provided for @booking_undo_body.
  ///
  /// In ru, this message translates to:
  /// **'Запись вернётся на предыдущий этап. Например, если случайно отметили «Клиент пришёл».'**
  String get booking_undo_body;

  /// No description provided for @booking_host_closes_only.
  ///
  /// In ru, this message translates to:
  /// **'Только вы закрываете услугу как оказанную. Система сама этого не делает.'**
  String get booking_host_closes_only;

  /// No description provided for @booking_cancel_visit_q.
  ///
  /// In ru, this message translates to:
  /// **'Отменить визит?'**
  String get booking_cancel_visit_q;

  /// No description provided for @booking_cancel_visit_action.
  ///
  /// In ru, this message translates to:
  /// **'Отменить визит'**
  String get booking_cancel_visit_action;

  /// No description provided for @booking_reschedule_missing_service.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя перенести: нет услуги или исполнителя. Обновите список записей.'**
  String get booking_reschedule_missing_service;

  /// No description provided for @booking_reschedule_no_session.
  ///
  /// In ru, this message translates to:
  /// **'Нельзя перенести: сессия не найдена. Войдите снова.'**
  String get booking_reschedule_no_session;

  /// No description provided for @booking_status_updated.
  ///
  /// In ru, this message translates to:
  /// **'Статус обновлён'**
  String get booking_status_updated;

  /// No description provided for @booking_status_reverted.
  ///
  /// In ru, this message translates to:
  /// **'Статус возвращён'**
  String get booking_status_reverted;

  /// No description provided for @booking_status_update_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось обновить статус'**
  String get booking_status_update_failed;

  /// No description provided for @booking_visit_ended_unmarked.
  ///
  /// In ru, this message translates to:
  /// **'Визит закончился, статус ещё не отмечен'**
  String get booking_visit_ended_unmarked;

  /// No description provided for @booking_visit_ended_hint.
  ///
  /// In ru, this message translates to:
  /// **'Время записи прошло. Завершите визит сами или отметьте «не пришёл» — система не закроет услугу как сделанную.'**
  String get booking_visit_ended_hint;

  /// No description provided for @booking_client_already_arrived.
  ///
  /// In ru, this message translates to:
  /// **'Клиент уже пришёл (без подтверждения)'**
  String get booking_client_already_arrived;

  /// No description provided for @booking_visit_marks_title.
  ///
  /// In ru, this message translates to:
  /// **'Отметки визита'**
  String get booking_visit_marks_title;

  /// No description provided for @booking_marked_arrived.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено: был'**
  String get booking_marked_arrived;

  /// No description provided for @booking_marked_no_show.
  ///
  /// In ru, this message translates to:
  /// **'Отмечено: не пришёл'**
  String get booking_marked_no_show;

  /// No description provided for @booking_was_short.
  ///
  /// In ru, this message translates to:
  /// **'Был'**
  String get booking_was_short;

  /// No description provided for @booking_view_only_status.
  ///
  /// In ru, this message translates to:
  /// **'Только просмотр. Статус визита меняет аккаунт, который ведёт запись.'**
  String get booking_view_only_status;

  /// No description provided for @booking_client_profile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль клиента'**
  String get booking_client_profile;

  /// No description provided for @booking_client_profile_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Профиль клиента недоступен'**
  String get booking_client_profile_unavailable;

  /// No description provided for @booking_what_to_do.
  ///
  /// In ru, this message translates to:
  /// **'Что хотите сделать'**
  String get booking_what_to_do;

  /// No description provided for @booking_order_label.
  ///
  /// In ru, this message translates to:
  /// **'Заказ'**
  String get booking_order_label;

  /// No description provided for @booking_create_booking.
  ///
  /// In ru, this message translates to:
  /// **'Создать запись'**
  String get booking_create_booking;

  /// No description provided for @booking_book_with.
  ///
  /// In ru, this message translates to:
  /// **'Запись к'**
  String get booking_book_with;

  /// No description provided for @booking_all_bookings.
  ///
  /// In ru, this message translates to:
  /// **'Все записи'**
  String get booking_all_bookings;

  /// No description provided for @booking_search_bookings_hint.
  ///
  /// In ru, this message translates to:
  /// **'Клиент, услуга, телефон…'**
  String get booking_search_bookings_hint;

  /// No description provided for @booking_filter_by_date.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр по дате'**
  String get booking_filter_by_date;

  /// No description provided for @booking_quick_pick.
  ///
  /// In ru, this message translates to:
  /// **'Быстрый выбор'**
  String get booking_quick_pick;

  /// No description provided for @booking_or_custom_period.
  ///
  /// In ru, this message translates to:
  /// **'Или свой период'**
  String get booking_or_custom_period;

  /// No description provided for @booking_this_week.
  ///
  /// In ru, this message translates to:
  /// **'Эта неделя'**
  String get booking_this_week;

  /// No description provided for @booking_next_week.
  ///
  /// In ru, this message translates to:
  /// **'След. неделя'**
  String get booking_next_week;

  /// No description provided for @booking_this_month.
  ///
  /// In ru, this message translates to:
  /// **'Этот месяц'**
  String get booking_this_month;

  /// No description provided for @booking_next_month.
  ///
  /// In ru, this message translates to:
  /// **'След. месяц'**
  String get booking_next_month;

  /// No description provided for @booking_start_date.
  ///
  /// In ru, this message translates to:
  /// **'Дата начала'**
  String get booking_start_date;

  /// No description provided for @booking_end_date.
  ///
  /// In ru, this message translates to:
  /// **'Дата конца'**
  String get booking_end_date;

  /// No description provided for @booking_archive_empty.
  ///
  /// In ru, this message translates to:
  /// **'Архив пока пуст'**
  String get booking_archive_empty;

  /// No description provided for @booking_no_completed_yet.
  ///
  /// In ru, this message translates to:
  /// **'Завершённых визитов пока нет'**
  String get booking_no_completed_yet;

  /// No description provided for @booking_no_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отменённых записей нет'**
  String get booking_no_cancelled;

  /// No description provided for @booking_cancelled_section.
  ///
  /// In ru, this message translates to:
  /// **'Отменённые'**
  String get booking_cancelled_section;

  /// No description provided for @booking_need_closing.
  ///
  /// In ru, this message translates to:
  /// **'Требуют закрытия'**
  String get booking_need_closing;

  /// No description provided for @booking_history_title.
  ///
  /// In ru, this message translates to:
  /// **'История записей'**
  String get booking_history_title;

  /// No description provided for @booking_no_upcoming.
  ///
  /// In ru, this message translates to:
  /// **'Предстоящих записей нет'**
  String get booking_no_upcoming;

  /// No description provided for @booking_upcoming_empty_hint.
  ///
  /// In ru, this message translates to:
  /// **'Подтверждённые будущие визиты появятся здесь'**
  String get booking_upcoming_empty_hint;

  /// No description provided for @booking_create_first_hint.
  ///
  /// In ru, this message translates to:
  /// **'Создайте первую запись — она появится здесь'**
  String get booking_create_first_hint;

  /// No description provided for @booking_now_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Сейчас никого нет'**
  String get booking_now_empty_title;

  /// No description provided for @booking_now_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Здесь появится клиент, когда начнётся его визит'**
  String get booking_now_empty_subtitle;

  /// No description provided for @booking_pick_other_day_feed.
  ///
  /// In ru, this message translates to:
  /// **'Выберите другой день в ленте или откройте календарь'**
  String get booking_pick_other_day_feed;

  /// No description provided for @booking_day_orders_empty.
  ///
  /// In ru, this message translates to:
  /// **'На этот день заказов нет'**
  String get booking_day_orders_empty;

  /// No description provided for @booking_orders_title.
  ///
  /// In ru, this message translates to:
  /// **'Заказы'**
  String get booking_orders_title;

  /// No description provided for @booking_orders_for_you.
  ///
  /// In ru, this message translates to:
  /// **'Заказы для вас'**
  String get booking_orders_for_you;

  /// No description provided for @booking_orders_empty.
  ///
  /// In ru, this message translates to:
  /// **'Заказов пока нет'**
  String get booking_orders_empty;

  /// No description provided for @booking_orders_empty_hint.
  ///
  /// In ru, this message translates to:
  /// **'Когда вас добавят исполнителем в запись другого аккаунта, он появится здесь'**
  String get booking_orders_empty_hint;

  /// No description provided for @booking_orders_calendar.
  ///
  /// In ru, this message translates to:
  /// **'Календарь заказов'**
  String get booking_orders_calendar;

  /// No description provided for @booking_no_sources_yet.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет источников'**
  String get booking_no_sources_yet;

  /// No description provided for @booking_when_booked_to_you.
  ///
  /// In ru, this message translates to:
  /// **'Когда к вам запишут, визиты появятся здесь'**
  String get booking_when_booked_to_you;

  /// No description provided for @booking_analytics_empty_period.
  ///
  /// In ru, this message translates to:
  /// **'За период записей нет'**
  String get booking_analytics_empty_period;

  /// No description provided for @booking_revenue_label.
  ///
  /// In ru, this message translates to:
  /// **'Выручка'**
  String get booking_revenue_label;

  /// No description provided for @booking_avg_check_label.
  ///
  /// In ru, this message translates to:
  /// **'Средний чек'**
  String get booking_avg_check_label;

  /// No description provided for @booking_analytics_summary.
  ///
  /// In ru, this message translates to:
  /// **'{total} записей · {completed} оказано'**
  String booking_analytics_summary(int total, int completed);

  /// No description provided for @booking_analytics_cancelled_part.
  ///
  /// In ru, this message translates to:
  /// **' · {count} отменено'**
  String booking_analytics_cancelled_part(int count);

  /// No description provided for @booking_analytics_pending_part.
  ///
  /// In ru, this message translates to:
  /// **' · {count} ждут'**
  String booking_analytics_pending_part(int count);

  /// No description provided for @booking_staff_completed_line.
  ///
  /// In ru, this message translates to:
  /// **'{bookings} · {completed} оказано'**
  String booking_staff_completed_line(int bookings, int completed);

  /// No description provided for @booking_rate_visit.
  ///
  /// In ru, this message translates to:
  /// **'Оценить визит'**
  String get booking_rate_visit;

  /// No description provided for @booking_thanks_review.
  ///
  /// In ru, this message translates to:
  /// **'Спасибо за отзыв'**
  String get booking_thanks_review;

  /// No description provided for @booking_review_mock_hint.
  ///
  /// In ru, this message translates to:
  /// **'В mock он никуда не уходит — только UI. На проде появится на точке и в сводке профиля.'**
  String get booking_review_mock_hint;

  /// No description provided for @booking_review_demo_title.
  ///
  /// In ru, this message translates to:
  /// **'Стрижка · Салон на Абая · 21 мар'**
  String get booking_review_demo_title;

  /// No description provided for @booking_reviews_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} отзывов'**
  String booking_reviews_count(int count);

  /// No description provided for @booking_reviews_strip_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'По точкам записи · тег feedback'**
  String get booking_reviews_strip_subtitle;

  /// No description provided for @booking_reviews_title.
  ///
  /// In ru, this message translates to:
  /// **'Отзывы'**
  String get booking_reviews_title;

  /// No description provided for @booking_how_was_it.
  ///
  /// In ru, this message translates to:
  /// **'Как прошло?'**
  String get booking_how_was_it;

  /// No description provided for @booking_review_optional_hint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите, как прошло (необязательно)'**
  String get booking_review_optional_hint;

  /// No description provided for @booking_send_review.
  ///
  /// In ru, this message translates to:
  /// **'Отправить отзыв'**
  String get booking_send_review;

  /// No description provided for @booking_demo_leave_review.
  ///
  /// In ru, this message translates to:
  /// **'Демо: оставить отзыв'**
  String get booking_demo_leave_review;

  /// No description provided for @booking_point_reply_title.
  ///
  /// In ru, this message translates to:
  /// **'Ответ от имени точки'**
  String get booking_point_reply_title;

  /// No description provided for @booking_point_reply_label.
  ///
  /// In ru, this message translates to:
  /// **'Ответ точки'**
  String get booking_point_reply_label;

  /// No description provided for @booking_save_reply.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить ответ'**
  String get booking_save_reply;

  /// No description provided for @booking_edit_reply.
  ///
  /// In ru, this message translates to:
  /// **'Изменить ответ'**
  String get booking_edit_reply;

  /// No description provided for @booking_delete_reply.
  ///
  /// In ru, this message translates to:
  /// **'Удалить ответ'**
  String get booking_delete_reply;

  /// No description provided for @booking_mock_no_backend.
  ///
  /// In ru, this message translates to:
  /// **'Mock · без записи на бэк'**
  String get booking_mock_no_backend;

  /// No description provided for @booking_mock_host_reply.
  ///
  /// In ru, this message translates to:
  /// **'Mock · ответ хозяина'**
  String get booking_mock_host_reply;

  /// No description provided for @booking_reply_action.
  ///
  /// In ru, this message translates to:
  /// **'Ответить'**
  String get booking_reply_action;

  /// No description provided for @common_open.
  ///
  /// In ru, this message translates to:
  /// **'Открыть'**
  String get common_open;

  /// No description provided for @common_refresh.
  ///
  /// In ru, this message translates to:
  /// **'Обновить'**
  String get common_refresh;

  /// No description provided for @common_you.
  ///
  /// In ru, this message translates to:
  /// **'Вы'**
  String get common_you;

  /// No description provided for @common_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Не найден'**
  String get common_not_found;

  /// No description provided for @common_time.
  ///
  /// In ru, this message translates to:
  /// **'Время'**
  String get common_time;

  /// No description provided for @common_later.
  ///
  /// In ru, this message translates to:
  /// **'Позже'**
  String get common_later;

  /// No description provided for @common_details.
  ///
  /// In ru, this message translates to:
  /// **'Подробнее'**
  String get common_details;

  /// No description provided for @common_got_it.
  ///
  /// In ru, this message translates to:
  /// **'Понятно'**
  String get common_got_it;

  /// No description provided for @common_approve.
  ///
  /// In ru, this message translates to:
  /// **'Утвердить'**
  String get common_approve;

  /// No description provided for @common_approved.
  ///
  /// In ru, this message translates to:
  /// **'Утверждено'**
  String get common_approved;

  /// No description provided for @common_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get common_rejected;

  /// No description provided for @common_pending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get common_pending;

  /// No description provided for @common_type.
  ///
  /// In ru, this message translates to:
  /// **'Тип'**
  String get common_type;

  /// No description provided for @common_chat.
  ///
  /// In ru, this message translates to:
  /// **'Чат'**
  String get common_chat;

  /// No description provided for @common_rules.
  ///
  /// In ru, this message translates to:
  /// **'Правила'**
  String get common_rules;

  /// No description provided for @common_settings.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get common_settings;

  /// No description provided for @common_saved.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено'**
  String get common_saved;

  /// No description provided for @common_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить'**
  String get common_save_failed;

  /// No description provided for @common_day.
  ///
  /// In ru, this message translates to:
  /// **'День'**
  String get common_day;

  /// No description provided for @common_team.
  ///
  /// In ru, this message translates to:
  /// **'Команда'**
  String get common_team;

  /// No description provided for @common_hours.
  ///
  /// In ru, this message translates to:
  /// **'Часы'**
  String get common_hours;

  /// No description provided for @common_no_data.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных'**
  String get common_no_data;

  /// No description provided for @attendance_day_status_full.
  ///
  /// In ru, this message translates to:
  /// **'Полная смена'**
  String get attendance_day_status_full;

  /// No description provided for @attendance_day_status_late.
  ///
  /// In ru, this message translates to:
  /// **'Опоздание'**
  String get attendance_day_status_late;

  /// No description provided for @attendance_day_status_partial.
  ///
  /// In ru, this message translates to:
  /// **'Неполная'**
  String get attendance_day_status_partial;

  /// No description provided for @attendance_day_status_absent.
  ///
  /// In ru, this message translates to:
  /// **'Пропуск'**
  String get attendance_day_status_absent;

  /// No description provided for @attendance_day_status_excused.
  ///
  /// In ru, this message translates to:
  /// **'Оформлено'**
  String get attendance_day_status_excused;

  /// No description provided for @attendance_day_status_off.
  ///
  /// In ru, this message translates to:
  /// **'Выходной'**
  String get attendance_day_status_off;

  /// No description provided for @attendance_day_status_full_short.
  ///
  /// In ru, this message translates to:
  /// **'Полная'**
  String get attendance_day_status_full_short;

  /// No description provided for @attendance_day_status_late_short.
  ///
  /// In ru, this message translates to:
  /// **'Опозд.'**
  String get attendance_day_status_late_short;

  /// No description provided for @attendance_day_status_partial_short.
  ///
  /// In ru, this message translates to:
  /// **'Неполная'**
  String get attendance_day_status_partial_short;

  /// No description provided for @attendance_absence_kind_day_off.
  ///
  /// In ru, this message translates to:
  /// **'Выходной'**
  String get attendance_absence_kind_day_off;

  /// No description provided for @attendance_absence_kind_vacation.
  ///
  /// In ru, this message translates to:
  /// **'Отпуск'**
  String get attendance_absence_kind_vacation;

  /// No description provided for @attendance_absence_kind_sick.
  ///
  /// In ru, this message translates to:
  /// **'Больничный'**
  String get attendance_absence_kind_sick;

  /// No description provided for @attendance_worker_status_accepted.
  ///
  /// In ru, this message translates to:
  /// **'Принят'**
  String get attendance_worker_status_accepted;

  /// No description provided for @attendance_worker_status_pending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает приглашения'**
  String get attendance_worker_status_pending;

  /// No description provided for @attendance_worker_status_archived.
  ///
  /// In ru, this message translates to:
  /// **'В архиве'**
  String get attendance_worker_status_archived;

  /// No description provided for @attendance_worker_status_declined.
  ///
  /// In ru, this message translates to:
  /// **'Отклонён'**
  String get attendance_worker_status_declined;

  /// No description provided for @attendance_overtime_status_pending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get attendance_overtime_status_pending;

  /// No description provided for @attendance_overtime_status_approved.
  ///
  /// In ru, this message translates to:
  /// **'Утверждено'**
  String get attendance_overtime_status_approved;

  /// No description provided for @attendance_overtime_status_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get attendance_overtime_status_rejected;

  /// No description provided for @attendance_correction_status_pending.
  ///
  /// In ru, this message translates to:
  /// **'Ожидает'**
  String get attendance_correction_status_pending;

  /// No description provided for @attendance_correction_status_approved.
  ///
  /// In ru, this message translates to:
  /// **'Утверждено'**
  String get attendance_correction_status_approved;

  /// No description provided for @attendance_correction_status_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено'**
  String get attendance_correction_status_rejected;

  /// No description provided for @attendance_saved_locally.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено локально'**
  String get attendance_saved_locally;

  /// No description provided for @attendance_saved_locally_syncing.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено локально, синхронизируется'**
  String get attendance_saved_locally_syncing;

  /// No description provided for @attendance_company_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Компания не найдена'**
  String get attendance_company_not_found;

  /// No description provided for @attendance_company_default_name.
  ///
  /// In ru, this message translates to:
  /// **'Компания'**
  String get attendance_company_default_name;

  /// No description provided for @attendance_company_fallback.
  ///
  /// In ru, this message translates to:
  /// **'компанию'**
  String get attendance_company_fallback;

  /// No description provided for @attendance_hub_admin_tag_required.
  ///
  /// In ru, this message translates to:
  /// **'Включите тег «Веду посещаемость» в профиле'**
  String get attendance_hub_admin_tag_required;

  /// No description provided for @attendance_hub_new_company.
  ///
  /// In ru, this message translates to:
  /// **'Новая компания'**
  String get attendance_hub_new_company;

  /// No description provided for @attendance_hub_company_created.
  ///
  /// In ru, this message translates to:
  /// **'Компания создана'**
  String get attendance_hub_company_created;

  /// No description provided for @attendance_hub_company_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать компанию'**
  String get attendance_hub_company_create_failed;

  /// No description provided for @attendance_hub_companies.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get attendance_hub_companies;

  /// No description provided for @attendance_hub_empty_hint.
  ///
  /// In ru, this message translates to:
  /// **'Создайте компанию: геозона, работники и отметки. Кнопка «+» сверху.'**
  String get attendance_hub_empty_hint;

  /// No description provided for @attendance_hub_shifts.
  ///
  /// In ru, this message translates to:
  /// **'Смены'**
  String get attendance_hub_shifts;

  /// No description provided for @attendance_hub_my_attendance.
  ///
  /// In ru, this message translates to:
  /// **'Моя посещаемость'**
  String get attendance_hub_my_attendance;

  /// No description provided for @attendance_hub_my_attendance_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметки и смены'**
  String get attendance_hub_my_attendance_subtitle;

  /// No description provided for @attendance_hub_empty_admin.
  ///
  /// In ru, this message translates to:
  /// **'Создайте компанию: геозона, работники и отметки. Кнопка на профиле — тег «Веду посещаемость».'**
  String get attendance_hub_empty_admin;

  /// No description provided for @attendance_company_team_invites.
  ///
  /// In ru, this message translates to:
  /// **'Команда и приглашения'**
  String get attendance_company_team_invites;

  /// No description provided for @attendance_company_geofence_punches.
  ///
  /// In ru, this message translates to:
  /// **'Геозона и отметки'**
  String get attendance_company_geofence_punches;

  /// No description provided for @attendance_company_duty_queue.
  ///
  /// In ru, this message translates to:
  /// **'Очередь по дням'**
  String get attendance_company_duty_queue;

  /// No description provided for @attendance_company_leave_sick.
  ///
  /// In ru, this message translates to:
  /// **'Отпуск и больничный'**
  String get attendance_company_leave_sick;

  /// No description provided for @attendance_company_ot_approval.
  ///
  /// In ru, this message translates to:
  /// **'Утверждение доплат'**
  String get attendance_company_ot_approval;

  /// No description provided for @attendance_company_punch_edits.
  ///
  /// In ru, this message translates to:
  /// **'Правки отметок'**
  String get attendance_company_punch_edits;

  /// No description provided for @attendance_company_export_month.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт за месяц'**
  String get attendance_company_export_month;

  /// No description provided for @attendance_company_hours_team.
  ///
  /// In ru, this message translates to:
  /// **'Часы и команда'**
  String get attendance_company_hours_team;

  /// No description provided for @attendance_company_invite_rules.
  ///
  /// In ru, this message translates to:
  /// **'Invite и правила'**
  String get attendance_company_invite_rules;

  /// No description provided for @attendance_punch_title.
  ///
  /// In ru, this message translates to:
  /// **'Отметка'**
  String get attendance_punch_title;

  /// No description provided for @attendance_punch_admin_disabled_system.
  ///
  /// In ru, this message translates to:
  /// **'Админ не включил «Пришёл» и «Ушёл». Только свои отметки ниже.'**
  String get attendance_punch_admin_disabled_system;

  /// No description provided for @attendance_punch_custom_types.
  ///
  /// In ru, this message translates to:
  /// **'Свои отметки'**
  String get attendance_punch_custom_types;

  /// No description provided for @attendance_punch_cancel_last.
  ///
  /// In ru, this message translates to:
  /// **'Отменить последнюю отметку'**
  String get attendance_punch_cancel_last;

  /// No description provided for @attendance_punch_sim_out_of_zone.
  ///
  /// In ru, this message translates to:
  /// **'Симулировать «вне зоны»'**
  String get attendance_punch_sim_out_of_zone;

  /// No description provided for @attendance_punch_sim_in_zone.
  ///
  /// In ru, this message translates to:
  /// **'Симулировать «в зоне»'**
  String get attendance_punch_sim_in_zone;

  /// No description provided for @attendance_punch_sim_gps_off.
  ///
  /// In ru, this message translates to:
  /// **'Симулировать GPS выкл.'**
  String get attendance_punch_sim_gps_off;

  /// No description provided for @attendance_punch_sim_gps_on.
  ///
  /// In ru, this message translates to:
  /// **'Симулировать GPS вкл.'**
  String get attendance_punch_sim_gps_on;

  /// No description provided for @attendance_punch_history.
  ///
  /// In ru, this message translates to:
  /// **'История отметок'**
  String get attendance_punch_history;

  /// No description provided for @attendance_punch_history_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет отметок'**
  String get attendance_punch_history_empty;

  /// No description provided for @attendance_punch_saved.
  ///
  /// In ru, this message translates to:
  /// **'{type} — сохранено'**
  String attendance_punch_saved(String type);

  /// No description provided for @attendance_punch_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить отметку'**
  String get attendance_punch_save_failed;

  /// No description provided for @attendance_punch_cancel_title.
  ///
  /// In ru, this message translates to:
  /// **'Отменить отметку'**
  String get attendance_punch_cancel_title;

  /// No description provided for @attendance_punch_cancel_hint.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий необязателен — например, отметили по ошибке.'**
  String get attendance_punch_cancel_hint;

  /// No description provided for @attendance_punch_cancel_comment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий (необяз.)'**
  String get attendance_punch_cancel_comment;

  /// No description provided for @attendance_punch_cancelled.
  ///
  /// In ru, this message translates to:
  /// **'Отметка отменена'**
  String get attendance_punch_cancelled;

  /// No description provided for @attendance_punch_request_correction.
  ///
  /// In ru, this message translates to:
  /// **'Запросить исправление'**
  String get attendance_punch_request_correction;

  /// No description provided for @attendance_punch_no_correction_target.
  ///
  /// In ru, this message translates to:
  /// **'Нет отметки для исправления'**
  String get attendance_punch_no_correction_target;

  /// No description provided for @attendance_punch_correction_sent.
  ///
  /// In ru, this message translates to:
  /// **'Запрос на исправление отправлен'**
  String get attendance_punch_correction_sent;

  /// No description provided for @attendance_punch_request_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить запрос'**
  String get attendance_punch_request_failed;

  /// No description provided for @attendance_punch_accept_rules.
  ///
  /// In ru, this message translates to:
  /// **'Примите правила v{version} карточкой в чате компании.'**
  String attendance_punch_accept_rules(int version);

  /// No description provided for @attendance_punch_cancelled_suffix.
  ///
  /// In ru, this message translates to:
  /// **' · отменено'**
  String get attendance_punch_cancelled_suffix;

  /// No description provided for @attendance_punch_clock_in_at.
  ///
  /// In ru, this message translates to:
  /// **'Пришёл {time}'**
  String attendance_punch_clock_in_at(String time);

  /// No description provided for @attendance_punch_clock_out_at.
  ///
  /// In ru, this message translates to:
  /// **'Ушёл {time}'**
  String attendance_punch_clock_out_at(String time);

  /// No description provided for @attendance_punch_types_not_configured.
  ///
  /// In ru, this message translates to:
  /// **'Типы не настроены'**
  String get attendance_punch_types_not_configured;

  /// No description provided for @attendance_punch_types_enabled.
  ///
  /// In ru, this message translates to:
  /// **'Включено: {list}'**
  String attendance_punch_types_enabled(String list);

  /// No description provided for @attendance_punch_locating.
  ///
  /// In ru, this message translates to:
  /// **'Определяем местоположение…'**
  String get attendance_punch_locating;

  /// No description provided for @attendance_punch_gps_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'GPS недоступен'**
  String get attendance_punch_gps_unavailable;

  /// No description provided for @attendance_punch_in_zone.
  ///
  /// In ru, this message translates to:
  /// **'Вы в зоне ({radiusM} м)'**
  String attendance_punch_in_zone(int radiusM);

  /// No description provided for @attendance_punch_out_of_zone.
  ///
  /// In ru, this message translates to:
  /// **'Вы вне зоны'**
  String get attendance_punch_out_of_zone;

  /// No description provided for @attendance_punch_refresh_gps.
  ///
  /// In ru, this message translates to:
  /// **'Обновить GPS'**
  String get attendance_punch_refresh_gps;

  /// No description provided for @attendance_punch_shift_already_open.
  ///
  /// In ru, this message translates to:
  /// **'Смена уже открыта — сначала отметьте «Ушёл»'**
  String get attendance_punch_shift_already_open;

  /// No description provided for @attendance_punch_open_chat.
  ///
  /// In ru, this message translates to:
  /// **'Открыть чат'**
  String get attendance_punch_open_chat;

  /// No description provided for @attendance_pending_out_of_zone.
  ///
  /// In ru, this message translates to:
  /// **'Вы вне зоны — откройте экран отметки'**
  String get attendance_pending_out_of_zone;

  /// No description provided for @attendance_pending_locating.
  ///
  /// In ru, this message translates to:
  /// **'Определяем GPS…'**
  String get attendance_pending_locating;

  /// No description provided for @attendance_pending_in_zone.
  ///
  /// In ru, this message translates to:
  /// **'Вы в зоне · {radiusM} м'**
  String attendance_pending_in_zone(int radiusM);

  /// No description provided for @attendance_pending_out_zone_radius.
  ///
  /// In ru, this message translates to:
  /// **'Вы вне зоны · {radiusM} м'**
  String attendance_pending_out_zone_radius(int radiusM);

  /// No description provided for @attendance_pending_expected_in.
  ///
  /// In ru, this message translates to:
  /// **'Ожидается в'**
  String get attendance_pending_expected_in;

  /// No description provided for @attendance_pending_new_rules.
  ///
  /// In ru, this message translates to:
  /// **'Новые правила'**
  String get attendance_pending_new_rules;

  /// No description provided for @attendance_pending_accept_update.
  ///
  /// In ru, this message translates to:
  /// **'{workplace}: примите обновление v{version} карточкой в чате компании.'**
  String attendance_pending_accept_update(String workplace, int version);

  /// No description provided for @attendance_punch_types_title.
  ///
  /// In ru, this message translates to:
  /// **'Отметки'**
  String get attendance_punch_types_title;

  /// No description provided for @attendance_punch_types_shift.
  ///
  /// In ru, this message translates to:
  /// **'Смена'**
  String get attendance_punch_types_shift;

  /// No description provided for @attendance_punch_types_enable_system.
  ///
  /// In ru, this message translates to:
  /// **'Включите «Пришёл» или «Ушёл»'**
  String get attendance_punch_types_enable_system;

  /// No description provided for @attendance_punch_types_custom.
  ///
  /// In ru, this message translates to:
  /// **'Свои'**
  String get attendance_punch_types_custom;

  /// No description provided for @attendance_punch_types_custom_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет своих отметок. «+» сверху.'**
  String get attendance_punch_types_custom_empty;

  /// No description provided for @attendance_punch_types_add_title.
  ///
  /// In ru, this message translates to:
  /// **'Своя отметка'**
  String get attendance_punch_types_add_title;

  /// No description provided for @attendance_punch_types_hint_lunch.
  ///
  /// In ru, this message translates to:
  /// **'Обед'**
  String get attendance_punch_types_hint_lunch;

  /// No description provided for @attendance_punch_types_already_exists.
  ///
  /// In ru, this message translates to:
  /// **'Уже есть'**
  String get attendance_punch_types_already_exists;

  /// No description provided for @attendance_punch_types_at_time.
  ///
  /// In ru, this message translates to:
  /// **'в {time}'**
  String attendance_punch_types_at_time(String time);

  /// No description provided for @attendance_analytics_title.
  ///
  /// In ru, this message translates to:
  /// **'Аналитика'**
  String get attendance_analytics_title;

  /// No description provided for @attendance_analytics_no_period_data.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных за период'**
  String get attendance_analytics_no_period_data;

  /// No description provided for @attendance_analytics_calendar.
  ///
  /// In ru, this message translates to:
  /// **'Календарь'**
  String get attendance_analytics_calendar;

  /// No description provided for @attendance_analytics_calendar_legend.
  ///
  /// In ru, this message translates to:
  /// **'Цвет = статус · ✓ отметился · ✗ не пришёл'**
  String get attendance_analytics_calendar_legend;

  /// No description provided for @attendance_analytics_avg.
  ///
  /// In ru, this message translates to:
  /// **'В среднем'**
  String get attendance_analytics_avg;

  /// No description provided for @attendance_analytics_people_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} чел.'**
  String attendance_analytics_people_count(int count);

  /// No description provided for @attendance_analytics_late_abbr.
  ///
  /// In ru, this message translates to:
  /// **'{count} опозд.'**
  String attendance_analytics_late_abbr(int count);

  /// No description provided for @attendance_analytics_missed_abbr.
  ///
  /// In ru, this message translates to:
  /// **'{count} проп.'**
  String attendance_analytics_missed_abbr(int count);

  /// No description provided for @attendance_analytics_late_suffix.
  ///
  /// In ru, this message translates to:
  /// **' · {count} опозд.'**
  String attendance_analytics_late_suffix(int count);

  /// No description provided for @attendance_analytics_missed_suffix.
  ///
  /// In ru, this message translates to:
  /// **' · {count} проп.'**
  String attendance_analytics_missed_suffix(int count);

  /// No description provided for @attendance_analytics_swipe_weeks.
  ///
  /// In ru, this message translates to:
  /// **'Листайте по неделям'**
  String get attendance_analytics_swipe_weeks;

  /// No description provided for @attendance_analytics_worked_today.
  ///
  /// In ru, this message translates to:
  /// **'Отработано за день'**
  String get attendance_analytics_worked_today;

  /// No description provided for @attendance_analytics_excused_absence.
  ///
  /// In ru, this message translates to:
  /// **'Оформленное отсутствие'**
  String get attendance_analytics_excused_absence;

  /// No description provided for @attendance_analytics_punches.
  ///
  /// In ru, this message translates to:
  /// **'Отметки'**
  String get attendance_analytics_punches;

  /// No description provided for @attendance_analytics_no_punches.
  ///
  /// In ru, this message translates to:
  /// **'Отметок не было'**
  String get attendance_analytics_no_punches;

  /// No description provided for @attendance_analytics_excused_not_miss.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствие оформлено — не пропуск'**
  String get attendance_analytics_excused_not_miss;

  /// No description provided for @attendance_analytics_day_off.
  ///
  /// In ru, this message translates to:
  /// **'Выходной день'**
  String get attendance_analytics_day_off;

  /// No description provided for @attendance_analytics_today_marked.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня · {marked} / {total}'**
  String attendance_analytics_today_marked(int marked, int total);

  /// No description provided for @attendance_analytics_not_punched.
  ///
  /// In ru, this message translates to:
  /// **'Не отметился'**
  String get attendance_analytics_not_punched;

  /// No description provided for @attendance_analytics_total.
  ///
  /// In ru, this message translates to:
  /// **'Итого {total}'**
  String attendance_analytics_total(String total);

  /// No description provided for @attendance_analytics_journal.
  ///
  /// In ru, this message translates to:
  /// **'Журнал'**
  String get attendance_analytics_journal;

  /// No description provided for @attendance_analytics_journal_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Быстрый обзор по дням — нажмите на строку'**
  String get attendance_analytics_journal_subtitle;

  /// No description provided for @attendance_analytics_today_suffix.
  ///
  /// In ru, this message translates to:
  /// **'· сегодня'**
  String get attendance_analytics_today_suffix;

  /// No description provided for @attendance_analytics_employee.
  ///
  /// In ru, this message translates to:
  /// **'Сотрудник'**
  String get attendance_analytics_employee;

  /// No description provided for @attendance_analytics_absences.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствия'**
  String get attendance_analytics_absences;

  /// No description provided for @attendance_analytics_absences_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Оформленные периоды · не считаются пропуском'**
  String get attendance_analytics_absences_subtitle;

  /// No description provided for @attendance_analytics_history_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Последние события с устройства'**
  String get attendance_analytics_history_subtitle;

  /// No description provided for @attendance_analytics_worked_month.
  ///
  /// In ru, this message translates to:
  /// **'отработано за месяц'**
  String get attendance_analytics_worked_month;

  /// No description provided for @attendance_analytics_shifts.
  ///
  /// In ru, this message translates to:
  /// **'Смены'**
  String get attendance_analytics_shifts;

  /// No description provided for @attendance_analytics_lates.
  ///
  /// In ru, this message translates to:
  /// **'Опоздания'**
  String get attendance_analytics_lates;

  /// No description provided for @attendance_analytics_misses.
  ///
  /// In ru, this message translates to:
  /// **'Пропуски'**
  String get attendance_analytics_misses;

  /// No description provided for @attendance_analytics_payroll.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата'**
  String get attendance_analytics_payroll;

  /// No description provided for @attendance_analytics_payroll_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Расчёт за период'**
  String get attendance_analytics_payroll_subtitle;

  /// No description provided for @attendance_analytics_base_salary.
  ///
  /// In ru, this message translates to:
  /// **'Оклад'**
  String get attendance_analytics_base_salary;

  /// No description provided for @attendance_analytics_deductions.
  ///
  /// In ru, this message translates to:
  /// **'Списания'**
  String get attendance_analytics_deductions;

  /// No description provided for @attendance_analytics_bonuses.
  ///
  /// In ru, this message translates to:
  /// **'Доплаты'**
  String get attendance_analytics_bonuses;

  /// No description provided for @attendance_analytics_payout.
  ///
  /// In ru, this message translates to:
  /// **'К выплате'**
  String get attendance_analytics_payout;

  /// No description provided for @attendance_worker_no_companies.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных компаний. Примите приглашение в чате.'**
  String get attendance_worker_no_companies;

  /// No description provided for @attendance_worker_accept_rules.
  ///
  /// In ru, this message translates to:
  /// **'{workplace}: примите правила v{version}'**
  String attendance_worker_accept_rules(String workplace, int version);

  /// No description provided for @attendance_worker_on_shift.
  ///
  /// In ru, this message translates to:
  /// **'на смене'**
  String get attendance_worker_on_shift;

  /// No description provided for @attendance_worker_off_shift.
  ///
  /// In ru, this message translates to:
  /// **'не на смене'**
  String get attendance_worker_off_shift;

  /// No description provided for @attendance_worker_last_punch.
  ///
  /// In ru, this message translates to:
  /// **'Последнее: {label}'**
  String attendance_worker_last_punch(String label);

  /// No description provided for @attendance_worker_tag_required.
  ///
  /// In ru, this message translates to:
  /// **'Чтобы отметиться, включите тег «Мои отметки» в профиле.'**
  String get attendance_worker_tag_required;

  /// No description provided for @attendance_worker_punch_cta.
  ///
  /// In ru, this message translates to:
  /// **'Отметиться'**
  String get attendance_worker_punch_cta;

  /// No description provided for @attendance_worker_my_details.
  ///
  /// In ru, this message translates to:
  /// **'Мои детали'**
  String get attendance_worker_my_details;

  /// No description provided for @attendance_worker_lates_abbr.
  ///
  /// In ru, this message translates to:
  /// **'Опозд.'**
  String get attendance_worker_lates_abbr;

  /// No description provided for @attendance_workers_title.
  ///
  /// In ru, this message translates to:
  /// **'Работники'**
  String get attendance_workers_title;

  /// No description provided for @attendance_workers_archived_toast.
  ///
  /// In ru, this message translates to:
  /// **'В архиве'**
  String get attendance_workers_archived_toast;

  /// No description provided for @attendance_workers_archive_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось архивировать'**
  String get attendance_workers_archive_failed;

  /// No description provided for @attendance_workers_invite_sent.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отправлено'**
  String get attendance_workers_invite_sent;

  /// No description provided for @attendance_workers_invite_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить приглашение'**
  String get attendance_workers_invite_failed;

  /// No description provided for @attendance_workers_waiting.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают'**
  String get attendance_workers_waiting;

  /// No description provided for @attendance_workers_waiting_reply.
  ///
  /// In ru, this message translates to:
  /// **'{user} · ждёт ответа'**
  String attendance_workers_waiting_reply(String user);

  /// No description provided for @attendance_workers_in_team.
  ///
  /// In ru, this message translates to:
  /// **'В команде'**
  String get attendance_workers_in_team;

  /// No description provided for @attendance_workers_no_tag.
  ///
  /// In ru, this message translates to:
  /// **'{user} · нет тега'**
  String attendance_workers_no_tag(String user);

  /// No description provided for @attendance_workers_in_archive.
  ///
  /// In ru, this message translates to:
  /// **'{user} · в архиве'**
  String attendance_workers_in_archive(String user);

  /// No description provided for @attendance_workers_search_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось найти людей'**
  String get attendance_workers_search_failed;

  /// No description provided for @attendance_workers_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Ник или имя'**
  String get attendance_workers_search_hint;

  /// No description provided for @attendance_workers_search_empty.
  ///
  /// In ru, this message translates to:
  /// **'Никого не найдено'**
  String get attendance_workers_search_empty;

  /// No description provided for @attendance_workers_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Пока никого нет'**
  String get attendance_workers_empty_title;

  /// No description provided for @attendance_workers_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Пригласите аккаунт Clover — заявка уйдёт в чат'**
  String get attendance_workers_empty_subtitle;

  /// No description provided for @attendance_workers_clover_account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт Clover'**
  String get attendance_workers_clover_account;

  /// No description provided for @attendance_workers_no_work_tag.
  ///
  /// In ru, this message translates to:
  /// **'{user} · нет тега работника'**
  String attendance_workers_no_work_tag(String user);

  /// No description provided for @attendance_workers_to_archive.
  ///
  /// In ru, this message translates to:
  /// **'В архив'**
  String get attendance_workers_to_archive;

  /// No description provided for @attendance_workers_waiting_chat.
  ///
  /// In ru, this message translates to:
  /// **'{user} · ждёт ответа в чате'**
  String attendance_workers_waiting_chat(String user);

  /// No description provided for @attendance_workers_not_in_shifts.
  ///
  /// In ru, this message translates to:
  /// **'{user} · не в сменах'**
  String attendance_workers_not_in_shifts(String user);

  /// No description provided for @attendance_workers_reinvite.
  ///
  /// In ru, this message translates to:
  /// **'Пригласить снова'**
  String get attendance_workers_reinvite;

  /// No description provided for @attendance_timesheet_title.
  ///
  /// In ru, this message translates to:
  /// **'Табель'**
  String get attendance_timesheet_title;

  /// No description provided for @attendance_timesheet_export_subject.
  ///
  /// In ru, this message translates to:
  /// **'Табель посещаемости'**
  String get attendance_timesheet_export_subject;

  /// No description provided for @attendance_timesheet_no_export_data.
  ///
  /// In ru, this message translates to:
  /// **'Нет данных для экспорта'**
  String get attendance_timesheet_no_export_data;

  /// No description provided for @attendance_timesheet_export_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось экспортировать'**
  String get attendance_timesheet_export_failed;

  /// No description provided for @attendance_timesheet_export_csv.
  ///
  /// In ru, this message translates to:
  /// **'Экспорт CSV'**
  String get attendance_timesheet_export_csv;

  /// No description provided for @attendance_chat_title.
  ///
  /// In ru, this message translates to:
  /// **'Чат компании'**
  String get attendance_chat_title;

  /// No description provided for @attendance_chat_title_named.
  ///
  /// In ru, this message translates to:
  /// **'Посещаемость · {name}'**
  String attendance_chat_title_named(String name);

  /// No description provided for @attendance_chat_system_intro.
  ///
  /// In ru, this message translates to:
  /// **'Групповой чат компании. Invite и правила — только карточками.'**
  String get attendance_chat_system_intro;

  /// No description provided for @attendance_chat_no_cards.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных карточек. Добавьте работника или симулируйте обновление правил.'**
  String get attendance_chat_no_cards;

  /// No description provided for @attendance_chat_accepted.
  ///
  /// In ru, this message translates to:
  /// **'{name} принят · в активных и чате'**
  String attendance_chat_accepted(String name);

  /// No description provided for @attendance_chat_declined.
  ///
  /// In ru, this message translates to:
  /// **'Отклонено · вне команды'**
  String get attendance_chat_declined;

  /// No description provided for @attendance_chat_rules_accepted.
  ///
  /// In ru, this message translates to:
  /// **'Правила v{version} приняты'**
  String attendance_chat_rules_accepted(int version);

  /// No description provided for @attendance_chat_join_team.
  ///
  /// In ru, this message translates to:
  /// **'Стать частью команды'**
  String get attendance_chat_join_team;

  /// No description provided for @attendance_chat_invite_body.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение для {name} ({username}). После принятия — смена, часы и чат компании.'**
  String attendance_chat_invite_body(String name, String username);

  /// No description provided for @attendance_chat_rules_updated.
  ///
  /// In ru, this message translates to:
  /// **'Правила обновлены · v{version}'**
  String attendance_chat_rules_updated(int version);

  /// No description provided for @attendance_chat_rules_body.
  ///
  /// In ru, this message translates to:
  /// **'Геозона или типы отметок изменились. Пока не примете — отметка недоступна.'**
  String get attendance_chat_rules_body;

  /// No description provided for @attendance_chat_rules_accept_cta.
  ///
  /// In ru, this message translates to:
  /// **'Понятно, принимаю'**
  String get attendance_chat_rules_accept_cta;

  /// No description provided for @attendance_chat_open_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось открыть чат'**
  String get attendance_chat_open_failed;

  /// No description provided for @attendance_corrections_title.
  ///
  /// In ru, this message translates to:
  /// **'Исправления'**
  String get attendance_corrections_title;

  /// No description provided for @attendance_corrections_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить запросы'**
  String get attendance_corrections_load_failed;

  /// No description provided for @attendance_corrections_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет запросов на исправление'**
  String get attendance_corrections_empty;

  /// No description provided for @attendance_corrections_approved_section.
  ///
  /// In ru, this message translates to:
  /// **'Утверждены'**
  String get attendance_corrections_approved_section;

  /// No description provided for @attendance_corrections_rejected_section.
  ///
  /// In ru, this message translates to:
  /// **'Отклонены'**
  String get attendance_corrections_rejected_section;

  /// No description provided for @attendance_corrections_current_time.
  ///
  /// In ru, this message translates to:
  /// **'сейчас {time}'**
  String attendance_corrections_current_time(String time);

  /// No description provided for @attendance_geofence_title.
  ///
  /// In ru, this message translates to:
  /// **'Геозона'**
  String get attendance_geofence_title;

  /// No description provided for @attendance_geofence_permission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к геолокации в настройках'**
  String get attendance_geofence_permission;

  /// No description provided for @attendance_geofence_locate_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось определить местоположение'**
  String get attendance_geofence_locate_failed;

  /// No description provided for @attendance_geofence_saved.
  ///
  /// In ru, this message translates to:
  /// **'Геозона сохранена'**
  String get attendance_geofence_saved;

  /// No description provided for @attendance_geofence_hint.
  ///
  /// In ru, this message translates to:
  /// **'Тап по карте — переместить центр. Круг — зона отметки.'**
  String get attendance_geofence_hint;

  /// No description provided for @attendance_geofence_radius.
  ///
  /// In ru, this message translates to:
  /// **'Радиус'**
  String get attendance_geofence_radius;

  /// No description provided for @attendance_geofence_radius_m.
  ///
  /// In ru, this message translates to:
  /// **'{radius} м'**
  String attendance_geofence_radius_m(int radius);

  /// No description provided for @attendance_geofence_radius_m_named.
  ///
  /// In ru, this message translates to:
  /// **'Радиус {radius} м'**
  String attendance_geofence_radius_m_named(int radius);

  /// No description provided for @attendance_geofence_point_unset.
  ///
  /// In ru, this message translates to:
  /// **'Точка не задана'**
  String get attendance_geofence_point_unset;

  /// No description provided for @attendance_overtime_title.
  ///
  /// In ru, this message translates to:
  /// **'Переработка'**
  String get attendance_overtime_title;

  /// No description provided for @attendance_overtime_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет заявок на переработку'**
  String get attendance_overtime_empty;

  /// No description provided for @attendance_overtime_pending_section.
  ///
  /// In ru, this message translates to:
  /// **'Ожидают'**
  String get attendance_overtime_pending_section;

  /// No description provided for @attendance_overtime_in_payroll.
  ///
  /// In ru, this message translates to:
  /// **'В зарплате'**
  String get attendance_overtime_in_payroll;

  /// No description provided for @attendance_overtime_rejected_section.
  ///
  /// In ru, this message translates to:
  /// **'Отклонены'**
  String get attendance_overtime_rejected_section;

  /// No description provided for @attendance_overtime_hours_line.
  ///
  /// In ru, this message translates to:
  /// **'{date} · {hours} ч'**
  String attendance_overtime_hours_line(String date, String hours);

  /// No description provided for @attendance_overtime_suggestion.
  ///
  /// In ru, this message translates to:
  /// **'Уход позже графика · ~{hours} ч'**
  String attendance_overtime_suggestion(String hours);

  /// No description provided for @attendance_overtime_create_request.
  ///
  /// In ru, this message translates to:
  /// **'Создать заявку'**
  String get attendance_overtime_create_request;

  /// No description provided for @attendance_overtime_created.
  ///
  /// In ru, this message translates to:
  /// **'Заявка создана'**
  String get attendance_overtime_created;

  /// No description provided for @attendance_overtime_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать заявку'**
  String get attendance_overtime_create_failed;

  /// No description provided for @attendance_payroll_title.
  ///
  /// In ru, this message translates to:
  /// **'Зарплата'**
  String get attendance_payroll_title;

  /// No description provided for @attendance_payroll_no_workers.
  ///
  /// In ru, this message translates to:
  /// **'Нет работников для расчёта'**
  String get attendance_payroll_no_workers;

  /// No description provided for @attendance_payroll_lates.
  ///
  /// In ru, this message translates to:
  /// **'Опоздания'**
  String get attendance_payroll_lates;

  /// No description provided for @attendance_payroll_overtime.
  ///
  /// In ru, this message translates to:
  /// **'Переработка'**
  String get attendance_payroll_overtime;

  /// No description provided for @attendance_payroll_misses.
  ///
  /// In ru, this message translates to:
  /// **'Пропуски'**
  String get attendance_payroll_misses;

  /// No description provided for @attendance_payroll_partial_day.
  ///
  /// In ru, this message translates to:
  /// **'Неполный день'**
  String get attendance_payroll_partial_day;

  /// No description provided for @attendance_payroll_per_min.
  ///
  /// In ru, this message translates to:
  /// **'₸ / мин'**
  String get attendance_payroll_per_min;

  /// No description provided for @attendance_payroll_per_hour.
  ///
  /// In ru, this message translates to:
  /// **'₸ / час'**
  String get attendance_payroll_per_hour;

  /// No description provided for @attendance_payroll_per_day.
  ///
  /// In ru, this message translates to:
  /// **'₸ / день'**
  String get attendance_payroll_per_day;

  /// No description provided for @attendance_payroll_percent_day.
  ///
  /// In ru, this message translates to:
  /// **'% от дня'**
  String get attendance_payroll_percent_day;

  /// No description provided for @attendance_payroll_enter_salary.
  ///
  /// In ru, this message translates to:
  /// **'Укажите оклад в ₸'**
  String get attendance_payroll_enter_salary;

  /// No description provided for @attendance_payroll_salary_saved.
  ///
  /// In ru, this message translates to:
  /// **'Оклад сохранён'**
  String get attendance_payroll_salary_saved;

  /// No description provided for @attendance_payroll_salary_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить оклад'**
  String get attendance_payroll_salary_save_failed;

  /// No description provided for @attendance_payroll_salary_label.
  ///
  /// In ru, this message translates to:
  /// **'Оклад, ₸'**
  String get attendance_payroll_salary_label;

  /// No description provided for @attendance_payroll_save_salary.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить оклад'**
  String get attendance_payroll_save_salary;

  /// No description provided for @attendance_payroll_for_period.
  ///
  /// In ru, this message translates to:
  /// **'За {period}'**
  String attendance_payroll_for_period(String period);

  /// No description provided for @attendance_payroll_no_adjustments.
  ///
  /// In ru, this message translates to:
  /// **'Без корректировок'**
  String get attendance_payroll_no_adjustments;

  /// No description provided for @attendance_payroll_summary_line.
  ///
  /// In ru, this message translates to:
  /// **'{period} · {count} чел.'**
  String attendance_payroll_summary_line(String period, int count);

  /// No description provided for @attendance_payroll_rules_hint.
  ///
  /// In ru, this message translates to:
  /// **'Правила начисления'**
  String get attendance_payroll_rules_hint;

  /// No description provided for @attendance_absences_title.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствия'**
  String get attendance_absences_title;

  /// No description provided for @attendance_absences_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет отсутствий'**
  String get attendance_absences_empty;

  /// No description provided for @attendance_absences_add_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выходной, отпуск или больничный'**
  String get attendance_absences_add_hint;

  /// No description provided for @attendance_absences_no_workers.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных работников'**
  String get attendance_absences_no_workers;

  /// No description provided for @attendance_absences_worker.
  ///
  /// In ru, this message translates to:
  /// **'Работник'**
  String get attendance_absences_worker;

  /// No description provided for @attendance_absences_added.
  ///
  /// In ru, this message translates to:
  /// **'Добавлено'**
  String get attendance_absences_added;

  /// No description provided for @attendance_absence_title.
  ///
  /// In ru, this message translates to:
  /// **'Отсутствие'**
  String get attendance_absence_title;

  /// No description provided for @attendance_duty_title.
  ///
  /// In ru, this message translates to:
  /// **'Дежурные'**
  String get attendance_duty_title;

  /// No description provided for @attendance_duty_not_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня не день дежурства'**
  String get attendance_duty_not_today;

  /// No description provided for @attendance_duty_punch_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Отметка сегодня недоступна — нет дежурного по расписанию.'**
  String get attendance_duty_punch_unavailable;

  /// No description provided for @attendance_duty_queue_not_workday.
  ///
  /// In ru, this message translates to:
  /// **'Очередь есть, но сегодня не рабочий день по настройке.'**
  String get attendance_duty_queue_not_workday;

  /// No description provided for @attendance_duty_you_today.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня дежурите вы'**
  String get attendance_duty_you_today;

  /// No description provided for @attendance_duty_today_names.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня дежурит: {names}'**
  String attendance_duty_today_names(String names);

  /// No description provided for @attendance_duty_mode_only_you.
  ///
  /// In ru, this message translates to:
  /// **'Режим «только дежурный»: отметка доступна вам.'**
  String get attendance_duty_mode_only_you;

  /// No description provided for @attendance_duty_mode_only_others_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Режим «только дежурный»: отметка другим сегодня недоступна.'**
  String get attendance_duty_mode_only_others_blocked;

  /// No description provided for @attendance_duty_info_notify.
  ///
  /// In ru, this message translates to:
  /// **'Инфо + уведомление команде. Отметка доступна как обычно — дежурство не замок.'**
  String get attendance_duty_info_notify;

  /// No description provided for @attendance_duty_info_anyone.
  ///
  /// In ru, this message translates to:
  /// **'Инфо для команды. Отметиться может любой принятый работник.'**
  String get attendance_duty_info_anyone;

  /// No description provided for @attendance_duty_only_duty_punches.
  ///
  /// In ru, this message translates to:
  /// **'Только дежурный отмечает'**
  String get attendance_duty_only_duty_punches;

  /// No description provided for @attendance_duty_workdays.
  ///
  /// In ru, this message translates to:
  /// **'Рабочие дни'**
  String get attendance_duty_workdays;

  /// No description provided for @attendance_duty_queue.
  ///
  /// In ru, this message translates to:
  /// **'Очередь'**
  String get attendance_duty_queue;

  /// No description provided for @attendance_duty_add_workers_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала добавьте работников'**
  String get attendance_duty_add_workers_first;

  /// No description provided for @attendance_duty_none.
  ///
  /// In ru, this message translates to:
  /// **'Нет дежурного'**
  String get attendance_duty_none;

  /// No description provided for @attendance_duty_punch_only_duty.
  ///
  /// In ru, this message translates to:
  /// **'Отметка только у дежурного'**
  String get attendance_duty_punch_only_duty;

  /// No description provided for @attendance_duty_team_hint.
  ///
  /// In ru, this message translates to:
  /// **'Подсказка для команды'**
  String get attendance_duty_team_hint;

  /// No description provided for @attendance_settings_not_configured.
  ///
  /// In ru, this message translates to:
  /// **'Не настроено'**
  String get attendance_settings_not_configured;

  /// No description provided for @attendance_settings_custom_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} свои'**
  String attendance_settings_custom_count(int count);

  /// No description provided for @attendance_settings_pick_time.
  ///
  /// In ru, this message translates to:
  /// **'Выберите время'**
  String get attendance_settings_pick_time;

  /// No description provided for @bonus_history_title.
  ///
  /// In ru, this message translates to:
  /// **'История бонусов'**
  String get bonus_history_title;

  /// No description provided for @bonus_history_operations.
  ///
  /// In ru, this message translates to:
  /// **'Операции'**
  String get bonus_history_operations;

  /// No description provided for @bonus_history_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'История пока пуста'**
  String get bonus_history_empty_title;

  /// No description provided for @bonus_history_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Начисления и списания появятся после завершённых визитов'**
  String get bonus_history_empty_subtitle;

  /// No description provided for @bonus_balance.
  ///
  /// In ru, this message translates to:
  /// **'Баланс'**
  String get bonus_balance;

  /// No description provided for @bonus_redeem_hint.
  ///
  /// In ru, this message translates to:
  /// **'Можно списать при следующей записи к этому мастеру'**
  String get bonus_redeem_hint;

  /// No description provided for @bonus_my_title.
  ///
  /// In ru, this message translates to:
  /// **'Мои бонусы'**
  String get bonus_my_title;

  /// No description provided for @bonus_my_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Баланс у каждого мастера отдельно. Откройте карточку, чтобы увидеть историю.'**
  String get bonus_my_subtitle;

  /// No description provided for @bonus_my_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Бонусов пока нет'**
  String get bonus_my_empty_title;

  /// No description provided for @bonus_my_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'После визитов у мастеров с программой лояльности балансы появятся здесь'**
  String get bonus_my_empty_subtitle;

  /// No description provided for @profile_edit_action.
  ///
  /// In ru, this message translates to:
  /// **'Редактировать'**
  String get profile_edit_action;

  /// No description provided for @profile_add_post.
  ///
  /// In ru, this message translates to:
  /// **'Добавить пост'**
  String get profile_add_post;

  /// No description provided for @profile_add_cluster.
  ///
  /// In ru, this message translates to:
  /// **'Добавить кластер'**
  String get profile_add_cluster;

  /// No description provided for @profile_manage.
  ///
  /// In ru, this message translates to:
  /// **'Управление'**
  String get profile_manage;

  /// No description provided for @profile_cluster_created.
  ///
  /// In ru, this message translates to:
  /// **'Кластер создан'**
  String get profile_cluster_created;

  /// No description provided for @profile_cluster_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать кластер'**
  String get profile_cluster_create_failed;

  /// No description provided for @profile_post_published.
  ///
  /// In ru, this message translates to:
  /// **'Успешно опубликовано'**
  String get profile_post_published;

  /// No description provided for @profile_post_publish_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось опубликовать'**
  String get profile_post_publish_failed;

  /// No description provided for @profile_followers.
  ///
  /// In ru, this message translates to:
  /// **'Подписчики'**
  String get profile_followers;

  /// No description provided for @profile_following.
  ///
  /// In ru, this message translates to:
  /// **'Подписки'**
  String get profile_following;

  /// No description provided for @profile_posts_empty_own.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте первую публикацию'**
  String get profile_posts_empty_own;

  /// No description provided for @profile_posts_sign_in.
  ///
  /// In ru, this message translates to:
  /// **'Войдите, чтобы видеть публикации'**
  String get profile_posts_sign_in;

  /// No description provided for @profile_empty_bio.
  ///
  /// In ru, this message translates to:
  /// **'пусто'**
  String get profile_empty_bio;

  /// No description provided for @profile_more_suffix.
  ///
  /// In ru, this message translates to:
  /// **' еще'**
  String get profile_more_suffix;

  /// No description provided for @profile_username_saved.
  ///
  /// In ru, this message translates to:
  /// **'Никнейм сохранён'**
  String get profile_username_saved;

  /// No description provided for @profile_saved.
  ///
  /// In ru, this message translates to:
  /// **'Профиль сохранён'**
  String get profile_saved;

  /// No description provided for @profile_section_main.
  ///
  /// In ru, this message translates to:
  /// **'Основное'**
  String get profile_section_main;

  /// No description provided for @profile_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Как вас зовут'**
  String get profile_name_hint;

  /// No description provided for @profile_section_location.
  ///
  /// In ru, this message translates to:
  /// **'Локация'**
  String get profile_section_location;

  /// No description provided for @profile_banner_title.
  ///
  /// In ru, this message translates to:
  /// **'Обложка профиля'**
  String get profile_banner_title;

  /// No description provided for @profile_cover.
  ///
  /// In ru, this message translates to:
  /// **'Обложка'**
  String get profile_cover;

  /// No description provided for @profile_avatar.
  ///
  /// In ru, this message translates to:
  /// **'Аватар'**
  String get profile_avatar;

  /// No description provided for @profile_username_unset.
  ///
  /// In ru, this message translates to:
  /// **'Не задан'**
  String get profile_username_unset;

  /// No description provided for @profile_username_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Смена никнейма сейчас недоступна'**
  String get profile_username_unavailable;

  /// No description provided for @profile_username_charset.
  ///
  /// In ru, this message translates to:
  /// **'Никнейм может содержать только латиницу, цифры, «_» и «.»'**
  String get profile_username_charset;

  /// No description provided for @profile_account_tags.
  ///
  /// In ru, this message translates to:
  /// **'Теги аккаунта'**
  String get profile_account_tags;

  /// No description provided for @profile_pick_tags.
  ///
  /// In ru, this message translates to:
  /// **'Выберите теги'**
  String get profile_pick_tags;

  /// No description provided for @profile_about.
  ///
  /// In ru, this message translates to:
  /// **'О себе'**
  String get profile_about;

  /// No description provided for @profile_about_hint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о себе'**
  String get profile_about_hint;

  /// No description provided for @profile_change_cover.
  ///
  /// In ru, this message translates to:
  /// **'Изменить обложку'**
  String get profile_change_cover;

  /// No description provided for @profile_add_cover.
  ///
  /// In ru, this message translates to:
  /// **'Добавить обложку'**
  String get profile_add_cover;

  /// No description provided for @profile_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный профиль'**
  String get profile_invalid;

  /// No description provided for @profile_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Профиль не найден'**
  String get profile_not_found;

  /// No description provided for @profile_following_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет подписок'**
  String get profile_following_empty;

  /// No description provided for @profile_followers_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет подписчиков'**
  String get profile_followers_empty;

  /// No description provided for @profile_unfollow_padded.
  ///
  /// In ru, this message translates to:
  /// **'  Отписаться  '**
  String get profile_unfollow_padded;

  /// No description provided for @profile_follow_padded.
  ///
  /// In ru, this message translates to:
  /// **'  Подписаться  '**
  String get profile_follow_padded;

  /// No description provided for @chat_sign_in_to_see.
  ///
  /// In ru, this message translates to:
  /// **'Войдите в аккаунт, чтобы видеть сообщения'**
  String get chat_sign_in_to_see;

  /// No description provided for @chat_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить чаты'**
  String get chat_load_failed;

  /// No description provided for @chat_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по чатам и сообщениям'**
  String get chat_search_hint;

  /// No description provided for @chat_list_empty_title.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет чатов'**
  String get chat_list_empty_title;

  /// No description provided for @chat_list_empty_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Начните переписку с другого профиля'**
  String get chat_list_empty_subtitle;

  /// No description provided for @chat_search_in_messages.
  ///
  /// In ru, this message translates to:
  /// **'В сообщениях'**
  String get chat_search_in_messages;

  /// No description provided for @chat_search_no_message_hits.
  ///
  /// In ru, this message translates to:
  /// **'Совпадений в тексте сообщений нет'**
  String get chat_search_no_message_hits;

  /// No description provided for @chat_new_group.
  ///
  /// In ru, this message translates to:
  /// **'Новая группа'**
  String get chat_new_group;

  /// No description provided for @chat_group_name_required.
  ///
  /// In ru, this message translates to:
  /// **'Укажите название группы'**
  String get chat_group_name_required;

  /// No description provided for @chat_group_members_required.
  ///
  /// In ru, this message translates to:
  /// **'Выберите участников'**
  String get chat_group_members_required;

  /// No description provided for @chat_group_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Название группы'**
  String get chat_group_name_hint;

  /// No description provided for @chat_group_search_members.
  ///
  /// In ru, this message translates to:
  /// **'Поиск участников'**
  String get chat_group_search_members;

  /// No description provided for @chat_group_from_following.
  ///
  /// In ru, this message translates to:
  /// **'Участники из подписок'**
  String get chat_group_from_following;

  /// No description provided for @chat_group_create.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу'**
  String get chat_group_create;

  /// No description provided for @chat_forward_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск получателя'**
  String get chat_forward_search;

  /// No description provided for @chat_members_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить участников'**
  String get chat_members_load_failed;

  /// No description provided for @chat_not_ready.
  ///
  /// In ru, this message translates to:
  /// **'Чат ещё не готов'**
  String get chat_not_ready;

  /// No description provided for @chat_not_created.
  ///
  /// In ru, this message translates to:
  /// **'Чат ещё не создан'**
  String get chat_not_created;

  /// No description provided for @chat_wallpaper_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить фон'**
  String get chat_wallpaper_save_failed;

  /// No description provided for @chat_info_title.
  ///
  /// In ru, this message translates to:
  /// **'Информация'**
  String get chat_info_title;

  /// No description provided for @chat_wallpaper.
  ///
  /// In ru, this message translates to:
  /// **'Фон чата'**
  String get chat_wallpaper;

  /// No description provided for @chat_dm_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Личный чат'**
  String get chat_dm_subtitle;

  /// No description provided for @chat_members.
  ///
  /// In ru, this message translates to:
  /// **'Участники'**
  String get chat_members;

  /// No description provided for @chat_members_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет участников'**
  String get chat_members_empty;

  /// No description provided for @chat_group.
  ///
  /// In ru, this message translates to:
  /// **'Группа'**
  String get chat_group;

  /// No description provided for @chat_invalid_user.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный пользователь'**
  String get chat_invalid_user;

  /// No description provided for @chat_invalid.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный чат'**
  String get chat_invalid;

  /// No description provided for @chat_no_access.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступа к этому чату'**
  String get chat_no_access;

  /// No description provided for @chat_blocked.
  ///
  /// In ru, this message translates to:
  /// **'Переписка недоступна — пользователь в блоке'**
  String get chat_blocked;

  /// No description provided for @chat_action_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить действие'**
  String get chat_action_failed;

  /// No description provided for @chat_star_soon.
  ///
  /// In ru, this message translates to:
  /// **'Избранные для сообщений — скоро'**
  String get chat_star_soon;

  /// No description provided for @chat_photo_read_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать фото'**
  String get chat_photo_read_failed;

  /// No description provided for @chat_file_read_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось прочитать документ'**
  String get chat_file_read_failed;

  /// No description provided for @chat_typing.
  ///
  /// In ru, this message translates to:
  /// **'печатает…'**
  String get chat_typing;

  /// No description provided for @chat_thread_search_hint.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по сообщениям'**
  String get chat_thread_search_hint;

  /// No description provided for @chat_opening.
  ///
  /// In ru, this message translates to:
  /// **'Открываем чат…'**
  String get chat_opening;

  /// No description provided for @chat_first_message.
  ///
  /// In ru, this message translates to:
  /// **'Напишите первое сообщение'**
  String get chat_first_message;

  /// No description provided for @chat_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось выполнить'**
  String get chat_failed;

  /// No description provided for @chat_wallpaper_with_emojis.
  ///
  /// In ru, this message translates to:
  /// **'Фон чата · {emojis}'**
  String chat_wallpaper_with_emojis(String emojis);

  /// No description provided for @chat_member_you.
  ///
  /// In ru, this message translates to:
  /// **'{handle} (вы)'**
  String chat_member_you(String handle);

  /// No description provided for @chat_members_one.
  ///
  /// In ru, this message translates to:
  /// **'{count} участник'**
  String chat_members_one(int count);

  /// No description provided for @chat_members_few.
  ///
  /// In ru, this message translates to:
  /// **'{count} участника'**
  String chat_members_few(int count);

  /// No description provided for @chat_members_many.
  ///
  /// In ru, this message translates to:
  /// **'{count} участников'**
  String chat_members_many(int count);

  /// No description provided for @catalog_locations_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить местоположения'**
  String get catalog_locations_load_failed;

  /// No description provided for @catalog_locations_title.
  ///
  /// In ru, this message translates to:
  /// **'Местоположения'**
  String get catalog_locations_title;

  /// No description provided for @catalog_location_new.
  ///
  /// In ru, this message translates to:
  /// **'Новое местоположение'**
  String get catalog_location_new;

  /// No description provided for @catalog_locations_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто — добавьте первое местоположение'**
  String get catalog_locations_empty;

  /// No description provided for @catalog_location_save_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сохранить изменения'**
  String get catalog_location_save_failed;

  /// No description provided for @catalog_location_delete_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить местоположение?'**
  String get catalog_location_delete_title;

  /// No description provided for @catalog_location.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение'**
  String get catalog_location;

  /// No description provided for @catalog_location_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Место не найдено'**
  String get catalog_location_not_found;

  /// No description provided for @catalog_address_cyrillic.
  ///
  /// In ru, this message translates to:
  /// **'Адрес (кириллица)'**
  String get catalog_address_cyrillic;

  /// No description provided for @catalog_address_hint.
  ///
  /// In ru, this message translates to:
  /// **'ул. Абая, 150, Алматы (необязательно)'**
  String get catalog_address_hint;

  /// No description provided for @catalog_binding.
  ///
  /// In ru, this message translates to:
  /// **'Привязка'**
  String get catalog_binding;

  /// No description provided for @catalog_bound_yes.
  ///
  /// In ru, this message translates to:
  /// **'Страна и город привязаны к этому адресу'**
  String get catalog_bound_yes;

  /// No description provided for @catalog_bound_no.
  ///
  /// In ru, this message translates to:
  /// **'Выберите страну и город для этого адреса'**
  String get catalog_bound_no;

  /// No description provided for @catalog_location_active_on.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение видно и доступно'**
  String get catalog_location_active_on;

  /// No description provided for @catalog_location_active_off.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение скрыто и недоступно'**
  String get catalog_location_active_off;

  /// No description provided for @catalog_accept_changes.
  ///
  /// In ru, this message translates to:
  /// **'Принять изменения'**
  String get catalog_accept_changes;

  /// No description provided for @catalog_location_added.
  ///
  /// In ru, this message translates to:
  /// **'Местоположение добавлено'**
  String get catalog_location_added;

  /// No description provided for @catalog_address_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск адреса'**
  String get catalog_address_search;

  /// No description provided for @catalog_locations_none_active.
  ///
  /// In ru, this message translates to:
  /// **'Нет активных местоположений'**
  String get catalog_locations_none_active;

  /// No description provided for @catalog_address_tap.
  ///
  /// In ru, this message translates to:
  /// **'Адрес · нажмите, чтобы ввести'**
  String get catalog_address_tap;

  /// No description provided for @catalog_tags_none.
  ///
  /// In ru, this message translates to:
  /// **'Нет доступных тегов'**
  String get catalog_tags_none;

  /// No description provided for @booking_minutes_plain.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин'**
  String booking_minutes_plain(int count);

  /// No description provided for @booking_stats_line.
  ///
  /// In ru, this message translates to:
  /// **'{total} записей · {completed} оказано'**
  String booking_stats_line(int total, int completed);

  /// No description provided for @booking_stats_cancelled.
  ///
  /// In ru, this message translates to:
  /// **' · {count} отменено'**
  String booking_stats_cancelled(int count);

  /// No description provided for @booking_stats_pending.
  ///
  /// In ru, this message translates to:
  /// **' · {count} ждут'**
  String booking_stats_pending(int count);

  /// No description provided for @booking_staff_completed.
  ///
  /// In ru, this message translates to:
  /// **'{bookings} · {completed} оказано'**
  String booking_staff_completed(int bookings, int completed);

  /// No description provided for @booking_slot_taken.
  ///
  /// In ru, this message translates to:
  /// **'Это время уже занято у {name}'**
  String booking_slot_taken(String name);

  /// No description provided for @booking_executor_absent.
  ///
  /// In ru, this message translates to:
  /// **'{name} недоступен в этот день'**
  String booking_executor_absent(String name);

  /// No description provided for @booking_bonus_will_spend.
  ///
  /// In ru, this message translates to:
  /// **'На балансе {balance}. После визита спишем до {spend} ({percent}% цены). Остаток — на месте.'**
  String booking_bonus_will_spend(String balance, String spend, int percent);

  /// No description provided for @booking_bonus_no_spend.
  ///
  /// In ru, this message translates to:
  /// **'На балансе {balance}. Бонусы за этот визит не списываем.'**
  String booking_bonus_no_spend(String balance);

  /// No description provided for @booking_bonus_spend.
  ///
  /// In ru, this message translates to:
  /// **'Списать −{amount} {word}'**
  String booking_bonus_spend(String amount, String word);

  /// No description provided for @booking_bonus_earn.
  ///
  /// In ru, this message translates to:
  /// **'Начислить +{amount} {word}'**
  String booking_bonus_earn(String amount, String word);

  /// No description provided for @booking_comment_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий: {text}'**
  String booking_comment_prefix(String text);

  /// No description provided for @booking_service_cancel_body.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» перестанет отображаться клиентам. Новые записи будут недоступны.'**
  String booking_service_cancel_body(String title);

  /// No description provided for @booking_masters_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} мастер(ов)'**
  String booking_masters_count(int count);

  /// No description provided for @booking_max_people.
  ///
  /// In ru, this message translates to:
  /// **'до {count} чел.'**
  String booking_max_people(int count);

  /// No description provided for @booking_master_prefix.
  ///
  /// In ru, this message translates to:
  /// **'Мастер: {name}'**
  String booking_master_prefix(String name);

  /// No description provided for @booking_ops_slot_line.
  ///
  /// In ru, this message translates to:
  /// **'{name} · {start}–{end}'**
  String booking_ops_slot_line(String name, String start, String end);

  /// No description provided for @booking_invite_waiting.
  ///
  /// In ru, this message translates to:
  /// **'@{username} · ждёт ответа в чате'**
  String booking_invite_waiting(String username);

  /// No description provided for @booking_cancel_visit_body.
  ///
  /// In ru, this message translates to:
  /// **'«{title}» у {host} будет отменена. Слот освободится для других клиентов.'**
  String booking_cancel_visit_body(String title, String host);

  /// No description provided for @booking_chat_title_named.
  ///
  /// In ru, this message translates to:
  /// **'Запись · {name}'**
  String booking_chat_title_named(String name);

  /// No description provided for @booking_time_duration.
  ///
  /// In ru, this message translates to:
  /// **'{range} · {minutes} мин'**
  String booking_time_duration(String range, int minutes);

  /// No description provided for @post_booking_service.
  ///
  /// In ru, this message translates to:
  /// **'Услуга для записи'**
  String get post_booking_service;

  /// No description provided for @post_unavailable.
  ///
  /// In ru, this message translates to:
  /// **'Пост недоступен'**
  String get post_unavailable;

  /// No description provided for @post_invalid_id.
  ///
  /// In ru, this message translates to:
  /// **'Некорректный id поста'**
  String get post_invalid_id;

  /// No description provided for @post_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Пост не найден'**
  String get post_not_found;

  /// No description provided for @post_create_cluster_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала создайте кластер'**
  String get post_create_cluster_first;

  /// No description provided for @post_untitled.
  ///
  /// In ru, this message translates to:
  /// **'Без названия'**
  String get post_untitled;

  /// No description provided for @post_linked_to_cluster.
  ///
  /// In ru, this message translates to:
  /// **'Пост привязан к кластеру'**
  String get post_linked_to_cluster;

  /// No description provided for @post_link_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось привязать пост'**
  String get post_link_failed;

  /// No description provided for @post_unlinked_from_cluster.
  ///
  /// In ru, this message translates to:
  /// **'Пост отвязан от кластера'**
  String get post_unlinked_from_cluster;

  /// No description provided for @post_unlink_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отвязать пост'**
  String get post_unlink_failed;

  /// No description provided for @post_archive_event_title.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать ивент?'**
  String get post_archive_event_title;

  /// No description provided for @post_archive_publication_title.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать публикацию?'**
  String get post_archive_publication_title;

  /// No description provided for @post_archive_event_body.
  ///
  /// In ru, this message translates to:
  /// **'Событие пропадёт из ленты и карты.'**
  String get post_archive_event_body;

  /// No description provided for @post_archive_publication_body.
  ///
  /// In ru, this message translates to:
  /// **'Публикация пропадёт из профиля.'**
  String get post_archive_publication_body;

  /// No description provided for @post_event_archived.
  ///
  /// In ru, this message translates to:
  /// **'Ивент архивирован'**
  String get post_event_archived;

  /// No description provided for @post_publication_archived.
  ///
  /// In ru, this message translates to:
  /// **'Публикация архивирована'**
  String get post_publication_archived;

  /// No description provided for @post_unarchive_event_title.
  ///
  /// In ru, this message translates to:
  /// **'Разархивировать ивент?'**
  String get post_unarchive_event_title;

  /// No description provided for @post_unarchive_publication_title.
  ///
  /// In ru, this message translates to:
  /// **'Разархивировать публикацию?'**
  String get post_unarchive_publication_title;

  /// No description provided for @post_unarchive_event_body.
  ///
  /// In ru, this message translates to:
  /// **'Событие снова появится в ленте и на карте.'**
  String get post_unarchive_event_body;

  /// No description provided for @post_unarchive_publication_body.
  ///
  /// In ru, this message translates to:
  /// **'Публикация снова появится в профиле.'**
  String get post_unarchive_publication_body;

  /// No description provided for @post_event_unarchived.
  ///
  /// In ru, this message translates to:
  /// **'Ивент разархивирован'**
  String get post_event_unarchived;

  /// No description provided for @post_publication_unarchived.
  ///
  /// In ru, this message translates to:
  /// **'Публикация разархивирована'**
  String get post_publication_unarchived;

  /// No description provided for @post_unarchive_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось разархивировать'**
  String get post_unarchive_failed;

  /// No description provided for @post_delete_event_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить ивент?'**
  String get post_delete_event_title;

  /// No description provided for @post_delete_publication_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить публикацию?'**
  String get post_delete_publication_title;

  /// No description provided for @post_delete_event_body.
  ///
  /// In ru, this message translates to:
  /// **'Событие, пост и медиа будут удалены безвозвратно.'**
  String get post_delete_event_body;

  /// No description provided for @post_delete_publication_body.
  ///
  /// In ru, this message translates to:
  /// **'Публикация и медиа будут удалены безвозвратно.'**
  String get post_delete_publication_body;

  /// No description provided for @post_event_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Ивент удалён'**
  String get post_event_deleted;

  /// No description provided for @post_publication_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Публикация удалена'**
  String get post_publication_deleted;

  /// No description provided for @post_unlink_cluster.
  ///
  /// In ru, this message translates to:
  /// **'Отвязать от кластера'**
  String get post_unlink_cluster;

  /// No description provided for @post_link_cluster.
  ///
  /// In ru, this message translates to:
  /// **'Привязать к кластеру'**
  String get post_link_cluster;

  /// No description provided for @post_author.
  ///
  /// In ru, this message translates to:
  /// **'Автор'**
  String get post_author;

  /// No description provided for @post_service_loading.
  ///
  /// In ru, this message translates to:
  /// **'Загрузка услуги…'**
  String get post_service_loading;

  /// No description provided for @post_book_service.
  ///
  /// In ru, this message translates to:
  /// **'Запись на услугу'**
  String get post_book_service;

  /// No description provided for @post_book_this_service.
  ///
  /// In ru, this message translates to:
  /// **'Записаться на эту услугу'**
  String get post_book_this_service;

  /// No description provided for @post_host.
  ///
  /// In ru, this message translates to:
  /// **'Хост'**
  String get post_host;

  /// No description provided for @post_likes_count.
  ///
  /// In ru, this message translates to:
  /// **'нравится {count}'**
  String post_likes_count(int count);

  /// No description provided for @post_dislikes_count.
  ///
  /// In ru, this message translates to:
  /// **'не нравится {count}'**
  String post_dislikes_count(int count);

  /// No description provided for @post_datetime_section.
  ///
  /// In ru, this message translates to:
  /// **'ДАТА И ВРЕМЯ'**
  String get post_datetime_section;

  /// No description provided for @post_completed.
  ///
  /// In ru, this message translates to:
  /// **'Завершено'**
  String get post_completed;

  /// No description provided for @post_now.
  ///
  /// In ru, this message translates to:
  /// **'сейчас'**
  String get post_now;

  /// No description provided for @post_hide_replies.
  ///
  /// In ru, this message translates to:
  /// **'Скрыть ответы'**
  String get post_hide_replies;

  /// No description provided for @post_view_replies.
  ///
  /// In ru, this message translates to:
  /// **'Посмотреть ответы ({count})'**
  String post_view_replies(int count);

  /// No description provided for @post_comments_title.
  ///
  /// In ru, this message translates to:
  /// **'Комментарии'**
  String get post_comments_title;

  /// No description provided for @post_comment_send_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось отправить комментарий'**
  String get post_comment_send_failed;

  /// No description provided for @post_comments_empty.
  ///
  /// In ru, this message translates to:
  /// **'Комментариев пока нет.\nБудьте первым!'**
  String get post_comments_empty;

  /// No description provided for @post_reply_for.
  ///
  /// In ru, this message translates to:
  /// **'Ответ для {username}'**
  String post_reply_for(String username);

  /// No description provided for @post_comment_hint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте комментарий…'**
  String get post_comment_hint;

  /// No description provided for @post_reply_hint.
  ///
  /// In ru, this message translates to:
  /// **'Ответить {username}…'**
  String post_reply_hint(String username);

  /// No description provided for @post_create_title.
  ///
  /// In ru, this message translates to:
  /// **'Новая публикация'**
  String get post_create_title;

  /// No description provided for @post_publication.
  ///
  /// In ru, this message translates to:
  /// **'Публикация'**
  String get post_publication;

  /// No description provided for @post_publish.
  ///
  /// In ru, this message translates to:
  /// **'Опубликовать'**
  String get post_publish;

  /// No description provided for @post_title_label.
  ///
  /// In ru, this message translates to:
  /// **'Заголовок'**
  String get post_title_label;

  /// No description provided for @post_title_hint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте заголовок'**
  String get post_title_hint;

  /// No description provided for @post_emoji_hint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте эмодзи'**
  String get post_emoji_hint;

  /// No description provided for @post_tags.
  ///
  /// In ru, this message translates to:
  /// **'Теги'**
  String get post_tags;

  /// No description provided for @post_pick_location.
  ///
  /// In ru, this message translates to:
  /// **'Выберите местоположение'**
  String get post_pick_location;

  /// No description provided for @post_event_period_required.
  ///
  /// In ru, this message translates to:
  /// **'Ивент на карте — укажите начало и конец'**
  String get post_event_period_required;

  /// No description provided for @post_period_optional.
  ///
  /// In ru, this message translates to:
  /// **'Необязательно — без периода обычная публикация'**
  String get post_period_optional;

  /// No description provided for @post_body_hint.
  ///
  /// In ru, this message translates to:
  /// **'Расскажите о публикации'**
  String get post_body_hint;

  /// No description provided for @post_create_service_first.
  ///
  /// In ru, this message translates to:
  /// **'Сначала создайте услугу в записях'**
  String get post_create_service_first;

  /// No description provided for @post_no_service.
  ///
  /// In ru, this message translates to:
  /// **'Без услуги'**
  String get post_no_service;

  /// No description provided for @post_service_unlinked.
  ///
  /// In ru, this message translates to:
  /// **'Не привязана'**
  String get post_service_unlinked;

  /// No description provided for @post_shared.
  ///
  /// In ru, this message translates to:
  /// **'Пост отправлен'**
  String get post_shared;

  /// No description provided for @post_share_no_following.
  ///
  /// In ru, this message translates to:
  /// **'Нет подписок для отправки'**
  String get post_share_no_following;

  /// No description provided for @post_share_message_hint.
  ///
  /// In ru, this message translates to:
  /// **'Напишите сообщение…'**
  String get post_share_message_hint;

  /// No description provided for @post_address_section.
  ///
  /// In ru, this message translates to:
  /// **'АДРЕС И ОРИЕНТИР'**
  String get post_address_section;

  /// No description provided for @cluster_delete_title.
  ///
  /// In ru, this message translates to:
  /// **'Удалить кластер?'**
  String get cluster_delete_title;

  /// No description provided for @cluster_delete_body.
  ///
  /// In ru, this message translates to:
  /// **'Обложка тоже будет удалена.'**
  String get cluster_delete_body;

  /// No description provided for @cluster_deleted.
  ///
  /// In ru, this message translates to:
  /// **'Кластер удалён'**
  String get cluster_deleted;

  /// No description provided for @cluster_title.
  ///
  /// In ru, this message translates to:
  /// **'Кластер'**
  String get cluster_title;

  /// No description provided for @cluster_archive_title.
  ///
  /// In ru, this message translates to:
  /// **'Архивировать кластер?'**
  String get cluster_archive_title;

  /// No description provided for @cluster_archive_body.
  ///
  /// In ru, this message translates to:
  /// **'Он пропадёт из списка в профиле.'**
  String get cluster_archive_body;

  /// No description provided for @cluster_archived.
  ///
  /// In ru, this message translates to:
  /// **'Кластер архивирован'**
  String get cluster_archived;

  /// No description provided for @cluster_archive_hub_title.
  ///
  /// In ru, this message translates to:
  /// **'Архив кластеров'**
  String get cluster_archive_hub_title;

  /// No description provided for @cluster_archive_empty.
  ///
  /// In ru, this message translates to:
  /// **'Архив кластеров пуст'**
  String get cluster_archive_empty;

  /// No description provided for @cluster_unarchive_title.
  ///
  /// In ru, this message translates to:
  /// **'Разархивировать кластер?'**
  String get cluster_unarchive_title;

  /// No description provided for @cluster_unarchive_body.
  ///
  /// In ru, this message translates to:
  /// **'Он снова появится в профиле.'**
  String get cluster_unarchive_body;

  /// No description provided for @cluster_unarchived.
  ///
  /// In ru, this message translates to:
  /// **'Кластер разархивирован'**
  String get cluster_unarchived;

  /// No description provided for @cluster_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Название кластера'**
  String get cluster_name_label;

  /// No description provided for @cluster_desc_hint.
  ///
  /// In ru, this message translates to:
  /// **'Краткое описание (необязательно)'**
  String get cluster_desc_hint;

  /// No description provided for @cluster_create_action.
  ///
  /// In ru, this message translates to:
  /// **'Создать кластер'**
  String get cluster_create_action;

  /// No description provided for @cluster_cover.
  ///
  /// In ru, this message translates to:
  /// **'Обложка кластера'**
  String get cluster_cover;

  /// No description provided for @cluster_new.
  ///
  /// In ru, this message translates to:
  /// **'Новый кластер'**
  String get cluster_new;

  /// No description provided for @cluster_tab.
  ///
  /// In ru, this message translates to:
  /// **'Кластеры'**
  String get cluster_tab;

  /// No description provided for @archive_events_title.
  ///
  /// In ru, this message translates to:
  /// **'Архив ивентов'**
  String get archive_events_title;

  /// No description provided for @archive_events_empty.
  ///
  /// In ru, this message translates to:
  /// **'Архив ивентов пуст'**
  String get archive_events_empty;

  /// No description provided for @archive_posts_title.
  ///
  /// In ru, this message translates to:
  /// **'Архив публикаций'**
  String get archive_posts_title;

  /// No description provided for @archive_posts_empty.
  ///
  /// In ru, this message translates to:
  /// **'Архив публикаций пуст'**
  String get archive_posts_empty;

  /// No description provided for @archive_content.
  ///
  /// In ru, this message translates to:
  /// **'Содержимое'**
  String get archive_content;

  /// No description provided for @archive_posts_events_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Архивированные посты и ивенты'**
  String get archive_posts_events_subtitle;

  /// No description provided for @archive_clusters_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Архивированные коллекции'**
  String get archive_clusters_subtitle;

  /// No description provided for @chat_invite_team.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в команду'**
  String get chat_invite_team;

  /// No description provided for @chat_company_rules.
  ///
  /// In ru, this message translates to:
  /// **'Правила компании'**
  String get chat_company_rules;

  /// No description provided for @chat_invite_declined.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение отклонено'**
  String get chat_invite_declined;

  /// No description provided for @chat_invite_booking.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение в запись'**
  String get chat_invite_booking;

  /// No description provided for @chat_on_team.
  ///
  /// In ru, this message translates to:
  /// **'Вы в команде'**
  String get chat_on_team;

  /// No description provided for @chat_accept_rules.
  ///
  /// In ru, this message translates to:
  /// **'Принять правила'**
  String get chat_accept_rules;

  /// No description provided for @chat_rules_accepted.
  ///
  /// In ru, this message translates to:
  /// **'Правила приняты'**
  String get chat_rules_accepted;

  /// No description provided for @chat_you_are_staff.
  ///
  /// In ru, this message translates to:
  /// **'Вы исполнитель'**
  String get chat_you_are_staff;

  /// No description provided for @chat_attachment.
  ///
  /// In ru, this message translates to:
  /// **'Вложение'**
  String get chat_attachment;

  /// No description provided for @chat_document.
  ///
  /// In ru, this message translates to:
  /// **'Документ'**
  String get chat_document;

  /// No description provided for @chat_wallpaper_hint.
  ///
  /// In ru, this message translates to:
  /// **'Вставь смайлики — фон увидят все в этом чате'**
  String get chat_wallpaper_hint;

  /// No description provided for @chat_wallpaper_preview.
  ///
  /// In ru, this message translates to:
  /// **'Превью фона'**
  String get chat_wallpaper_preview;

  /// No description provided for @chat_wallpaper_example.
  ///
  /// In ru, this message translates to:
  /// **'Например 🍀✨💬'**
  String get chat_wallpaper_example;

  /// No description provided for @chat_edited_short.
  ///
  /// In ru, this message translates to:
  /// **'изм.'**
  String get chat_edited_short;

  /// No description provided for @chat_photo_permission.
  ///
  /// In ru, this message translates to:
  /// **'Разрешите доступ к фото, чтобы сохранить'**
  String get chat_photo_permission;

  /// No description provided for @chat_saved_to_gallery.
  ///
  /// In ru, this message translates to:
  /// **'Сохранено в Галерею'**
  String get chat_saved_to_gallery;

  /// No description provided for @chat_photo_download_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось скачать фото'**
  String get chat_photo_download_failed;

  /// No description provided for @chat_members_count.
  ///
  /// In ru, this message translates to:
  /// **'{count, plural, one{{count} участник} few{{count} участника} other{{count} участников}}'**
  String chat_members_count(int count);

  /// No description provided for @chat_member_you_label.
  ///
  /// In ru, this message translates to:
  /// **'{handle} (вы)'**
  String chat_member_you_label(String handle);

  /// No description provided for @chat_wallpaper_emojis.
  ///
  /// In ru, this message translates to:
  /// **'Фон чата · {emojis}'**
  String chat_wallpaper_emojis(String emojis);

  /// No description provided for @settings_filters_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить фильтры'**
  String get settings_filters_load_failed;

  /// No description provided for @settings_filters_search.
  ///
  /// In ru, this message translates to:
  /// **'Поиск по фильтрам'**
  String get settings_filters_search;

  /// No description provided for @settings_filters_values_word.
  ///
  /// In ru, this message translates to:
  /// **'значений'**
  String get settings_filters_values_word;

  /// No description provided for @settings_wait_loading.
  ///
  /// In ru, this message translates to:
  /// **'Подождите загрузку'**
  String get settings_wait_loading;

  /// No description provided for @settings_guide_topic_missing.
  ///
  /// In ru, this message translates to:
  /// **'Тема гайда не найдена'**
  String get settings_guide_topic_missing;

  /// No description provided for @settings_companies_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить компании'**
  String get settings_companies_load_failed;

  /// No description provided for @settings_companies_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет компаний. Нажмите «Добавить».'**
  String get settings_companies_empty;

  /// No description provided for @settings_post_filters_title.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры публикации'**
  String get settings_post_filters_title;

  /// No description provided for @settings_pick_filters.
  ///
  /// In ru, this message translates to:
  /// **'Выберите фильтры'**
  String get settings_pick_filters;

  /// No description provided for @settings_filters_selected.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры выбраны'**
  String get settings_filters_selected;

  /// No description provided for @settings_filters_categories_hint.
  ///
  /// In ru, this message translates to:
  /// **'Размер, цвет, бренд и другие категории'**
  String get settings_filters_categories_hint;

  /// No description provided for @settings_filter_value_one.
  ///
  /// In ru, this message translates to:
  /// **'значение'**
  String get settings_filter_value_one;

  /// No description provided for @settings_filter_value_few.
  ///
  /// In ru, this message translates to:
  /// **'значения'**
  String get settings_filter_value_few;

  /// No description provided for @settings_location_filter_own_only.
  ///
  /// In ru, this message translates to:
  /// **'Фильтр по местам доступен на своём профиле'**
  String get settings_location_filter_own_only;

  /// No description provided for @settings_places_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить места'**
  String get settings_places_load_failed;

  /// No description provided for @settings_all_places.
  ///
  /// In ru, this message translates to:
  /// **'Все места'**
  String get settings_all_places;

  /// No description provided for @settings_no_address_filter.
  ///
  /// In ru, this message translates to:
  /// **'Без фильтра по адресу'**
  String get settings_no_address_filter;

  /// No description provided for @settings_add_place_hint.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте место в Ресурсы → Местоположения — тогда можно фильтровать посты.'**
  String get settings_add_place_hint;

  /// No description provided for @settings_no_session.
  ///
  /// In ru, this message translates to:
  /// **'Нет сессии'**
  String get settings_no_session;

  /// No description provided for @settings_new_category.
  ///
  /// In ru, this message translates to:
  /// **'Новая категория'**
  String get settings_new_category;

  /// No description provided for @settings_category.
  ///
  /// In ru, this message translates to:
  /// **'Категория'**
  String get settings_category;

  /// No description provided for @settings_category_name.
  ///
  /// In ru, this message translates to:
  /// **'Название категории'**
  String get settings_category_name;

  /// No description provided for @settings_category_name_hint.
  ///
  /// In ru, this message translates to:
  /// **'Например: Размер, Цвет, Бренд'**
  String get settings_category_name_hint;

  /// No description provided for @settings_values.
  ///
  /// In ru, this message translates to:
  /// **'Значения'**
  String get settings_values;

  /// No description provided for @settings_values_hint.
  ///
  /// In ru, this message translates to:
  /// **'XS, Черный, Nike…'**
  String get settings_values_hint;

  /// No description provided for @settings_add_one_value.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы одно значение'**
  String get settings_add_one_value;

  /// No description provided for @settings_save_category.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить категорию'**
  String get settings_save_category;

  /// No description provided for @settings_save_changes.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить изменения'**
  String get settings_save_changes;

  /// No description provided for @settings_deletion.
  ///
  /// In ru, this message translates to:
  /// **'Удаление'**
  String get settings_deletion;

  /// No description provided for @settings_filter_categories_title.
  ///
  /// In ru, this message translates to:
  /// **'Категории фильтров'**
  String get settings_filter_categories_title;

  /// No description provided for @settings_filter_categories_intro.
  ///
  /// In ru, this message translates to:
  /// **'Создайте категорию, укажите название и добавьте варианты значений. После первой категории фильтр появится в профиле.'**
  String get settings_filter_categories_intro;

  /// No description provided for @settings_create_category.
  ///
  /// In ru, this message translates to:
  /// **'Создать категорию'**
  String get settings_create_category;

  /// No description provided for @settings_no_categories.
  ///
  /// In ru, this message translates to:
  /// **'Пока нет категорий'**
  String get settings_no_categories;

  /// No description provided for @settings_categories_example.
  ///
  /// In ru, this message translates to:
  /// **'Например: Размер → XS, S, M\nЦвет → Черный, Белый'**
  String get settings_categories_example;

  /// No description provided for @settings_create_first_category.
  ///
  /// In ru, this message translates to:
  /// **'Создать первую категорию'**
  String get settings_create_first_category;

  /// No description provided for @settings_guide_services_intro.
  ///
  /// In ru, this message translates to:
  /// **'Коротко про сервисы Clover. Можно сразу активировать тег хозяина.'**
  String get settings_guide_services_intro;

  /// No description provided for @settings_activate.
  ///
  /// In ru, this message translates to:
  /// **'Активировать'**
  String get settings_activate;

  /// No description provided for @settings_service_enabled.
  ///
  /// In ru, this message translates to:
  /// **'Сервис включён на профиле'**
  String get settings_service_enabled;

  /// No description provided for @settings_activate_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось активировать'**
  String get settings_activate_failed;

  /// No description provided for @settings_resources_addresses.
  ///
  /// In ru, this message translates to:
  /// **'Адреса и точки на карте'**
  String get settings_resources_addresses;

  /// No description provided for @settings_resources_showcase.
  ///
  /// In ru, this message translates to:
  /// **'Категории витрины профиля'**
  String get settings_resources_showcase;

  /// No description provided for @settings_resources_what.
  ///
  /// In ru, this message translates to:
  /// **'Что такое ресурсы'**
  String get settings_resources_what;

  /// No description provided for @settings_saved_posts_empty.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённых постов пока нет'**
  String get settings_saved_posts_empty;

  /// No description provided for @settings_saved_posts_tile.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённые посты'**
  String get settings_saved_posts_tile;

  /// No description provided for @venue_my_bookings.
  ///
  /// In ru, this message translates to:
  /// **'Мои брони'**
  String get venue_my_bookings;

  /// No description provided for @venue_guests.
  ///
  /// In ru, this message translates to:
  /// **'Гостей'**
  String get venue_guests;

  /// No description provided for @venue_establishment.
  ///
  /// In ru, this message translates to:
  /// **'Заведение'**
  String get venue_establishment;

  /// No description provided for @venue_tickets_fares.
  ///
  /// In ru, this message translates to:
  /// **'Билеты / тарифы'**
  String get venue_tickets_fares;

  /// No description provided for @venue_places_list.
  ///
  /// In ru, this message translates to:
  /// **'Места списком'**
  String get venue_places_list;

  /// No description provided for @venue_plan_schema.
  ///
  /// In ru, this message translates to:
  /// **'План / схема'**
  String get venue_plan_schema;

  /// No description provided for @venue_sessions_slots.
  ///
  /// In ru, this message translates to:
  /// **'Сеансы / слоты'**
  String get venue_sessions_slots;

  /// No description provided for @venue_hub_mock_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Моки · билеты, места и схема. Редактор плана — на сайте.'**
  String get venue_hub_mock_subtitle;

  /// No description provided for @venue_establishments.
  ///
  /// In ru, this message translates to:
  /// **'Заведения'**
  String get venue_establishments;

  /// No description provided for @venue_requests_confirmed.
  ///
  /// In ru, this message translates to:
  /// **'Запросы и подтверждённые (мок)'**
  String get venue_requests_confirmed;

  /// No description provided for @venue_process_doc.
  ///
  /// In ru, this message translates to:
  /// **'Процесс: docs/business/venue-seating.md'**
  String get venue_process_doc;

  /// No description provided for @venue_mocks_no_backend.
  ///
  /// In ru, this message translates to:
  /// **'Моки · без бэка'**
  String get venue_mocks_no_backend;

  /// No description provided for @venue_client_requests_mock.
  ///
  /// In ru, this message translates to:
  /// **'Клиентский список запросов (мок).'**
  String get venue_client_requests_mock;

  /// No description provided for @venue_client_schema_hint.
  ///
  /// In ru, this message translates to:
  /// **'Клиент видит схему с сайта (JSON) · только выбор и запрос.'**
  String get venue_client_schema_hint;

  /// No description provided for @venue_client_flow.
  ///
  /// In ru, this message translates to:
  /// **'Клиент: схема и/или список → запрос, не оплата.'**
  String get venue_client_flow;

  /// No description provided for @venue_session.
  ///
  /// In ru, this message translates to:
  /// **'Сеанс'**
  String get venue_session;

  /// No description provided for @venue_pick_place.
  ///
  /// In ru, this message translates to:
  /// **'Выберите место'**
  String get venue_pick_place;

  /// No description provided for @venue_send_request.
  ///
  /// In ru, this message translates to:
  /// **'Отправить запрос'**
  String get venue_send_request;

  /// No description provided for @venue_mock_request_sent.
  ///
  /// In ru, this message translates to:
  /// **'Мок: запрос отправлен · soft-hold'**
  String get venue_mock_request_sent;

  /// No description provided for @venue_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Заведение не найдено'**
  String get venue_not_found;

  /// No description provided for @venue_catalog.
  ///
  /// In ru, this message translates to:
  /// **'Каталог'**
  String get venue_catalog;

  /// No description provided for @venue_level_a.
  ///
  /// In ru, this message translates to:
  /// **'Уровень A'**
  String get venue_level_a;

  /// No description provided for @venue_level_b.
  ///
  /// In ru, this message translates to:
  /// **'Уровень B'**
  String get venue_level_b;

  /// No description provided for @venue_level_c_preview.
  ///
  /// In ru, this message translates to:
  /// **'Уровень C · превью'**
  String get venue_level_c_preview;

  /// No description provided for @venue_no_schema_hint.
  ///
  /// In ru, this message translates to:
  /// **'Нет схемы · подсказка'**
  String get venue_no_schema_hint;

  /// No description provided for @venue_when_bookable.
  ///
  /// In ru, this message translates to:
  /// **'Когда можно бронировать'**
  String get venue_when_bookable;

  /// No description provided for @venue_requests_to_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Запросы → подтверждение'**
  String get venue_requests_to_confirm;

  /// No description provided for @venue_client_view.
  ///
  /// In ru, this message translates to:
  /// **'Как видит клиент'**
  String get venue_client_view;

  /// No description provided for @venue_request_preview.
  ///
  /// In ru, this message translates to:
  /// **'Превью запроса брони'**
  String get venue_request_preview;

  /// No description provided for @venue_request.
  ///
  /// In ru, this message translates to:
  /// **'Запрос'**
  String get venue_request;

  /// No description provided for @venue_request_not_found.
  ///
  /// In ru, this message translates to:
  /// **'Запрос не найден'**
  String get venue_request_not_found;

  /// No description provided for @venue_actions_mock.
  ///
  /// In ru, this message translates to:
  /// **'Действия моковые — бэка нет.'**
  String get venue_actions_mock;

  /// No description provided for @venue_mock_confirmed.
  ///
  /// In ru, this message translates to:
  /// **'Мок: подтверждено'**
  String get venue_mock_confirmed;

  /// No description provided for @venue_mock_rejected.
  ///
  /// In ru, this message translates to:
  /// **'Мок: отклонено'**
  String get venue_mock_rejected;

  /// No description provided for @venue_extra_pay.
  ///
  /// In ru, this message translates to:
  /// **'Нужна доплата (вне Clover)'**
  String get venue_extra_pay;

  /// No description provided for @venue_mock_extra_pay.
  ///
  /// In ru, this message translates to:
  /// **'Мок: условие доплаты'**
  String get venue_mock_extra_pay;

  /// No description provided for @venue_soft_hold_flow.
  ///
  /// In ru, this message translates to:
  /// **'Запрос → soft-hold → admin решает. Не auto-confirm.'**
  String get venue_soft_hold_flow;

  /// No description provided for @venue_tab_empty.
  ///
  /// In ru, this message translates to:
  /// **'Пусто в этой вкладке'**
  String get venue_tab_empty;

  /// No description provided for @venue_plan_load_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось загрузить план'**
  String get venue_plan_load_failed;

  /// No description provided for @venue_plan_load_error.
  ///
  /// In ru, this message translates to:
  /// **'Ошибка загрузки плана'**
  String get venue_plan_load_error;

  /// No description provided for @venue_plan_site_only.
  ///
  /// In ru, this message translates to:
  /// **'Сайт нарисовал → мобилка только смотрит (JSON с сайта, мок).'**
  String get venue_plan_site_only;

  /// No description provided for @venue_plan_preview.
  ///
  /// In ru, this message translates to:
  /// **'Превью схемы. Рисовать и править — только на сайте.'**
  String get venue_plan_preview;

  /// No description provided for @venue_no_schema_tickets.
  ///
  /// In ru, this message translates to:
  /// **'Схемы нет. Хозяин может остаться на билетах / списке.'**
  String get venue_no_schema_tickets;

  /// No description provided for @venue_empty_canvas.
  ///
  /// In ru, this message translates to:
  /// **'Пустой холст. На сайте появится редактор «как Figma».'**
  String get venue_empty_canvas;

  /// No description provided for @venue_level_b_bookable.
  ///
  /// In ru, this message translates to:
  /// **'Уровень B · те же bookable, что на схеме.'**
  String get venue_level_b_bookable;

  /// No description provided for @venue_no_seats_tickets_only.
  ///
  /// In ru, this message translates to:
  /// **'У этого заведения пока нет мест — только билеты.'**
  String get venue_no_seats_tickets_only;

  /// No description provided for @venue_occasion_hint.
  ///
  /// In ru, this message translates to:
  /// **'Occasion: сеанс кино или слот ресторана.'**
  String get venue_occasion_hint;

  /// No description provided for @venue_no_sessions.
  ///
  /// In ru, this message translates to:
  /// **'Сеансов нет'**
  String get venue_no_sessions;

  /// No description provided for @venue_level_a_no_schema.
  ///
  /// In ru, this message translates to:
  /// **'Уровень A · без схемы. Клиент выбирает тариф и qty.'**
  String get venue_level_a_no_schema;

  /// No description provided for @venue_mock_badge.
  ///
  /// In ru, this message translates to:
  /// **'мок'**
  String get venue_mock_badge;

  /// No description provided for @settings_attendance_enable_tag.
  ///
  /// In ru, this message translates to:
  /// **'Включите тег «Веду посещаемость» в профиле'**
  String get settings_attendance_enable_tag;

  /// No description provided for @settings_attendance_company.
  ///
  /// In ru, this message translates to:
  /// **'Компания'**
  String get settings_attendance_company;

  /// No description provided for @settings_attendance_new_company.
  ///
  /// In ru, this message translates to:
  /// **'Новая компания'**
  String get settings_attendance_new_company;

  /// No description provided for @settings_attendance_company_created.
  ///
  /// In ru, this message translates to:
  /// **'Компания создана'**
  String get settings_attendance_company_created;

  /// No description provided for @settings_attendance_company_create_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось создать компанию'**
  String get settings_attendance_company_create_failed;

  /// No description provided for @settings_attendance_companies.
  ///
  /// In ru, this message translates to:
  /// **'Компании'**
  String get settings_attendance_companies;

  /// No description provided for @settings_attendance_shifts.
  ///
  /// In ru, this message translates to:
  /// **'Смены'**
  String get settings_attendance_shifts;

  /// No description provided for @settings_attendance_my_title.
  ///
  /// In ru, this message translates to:
  /// **'Моя посещаемость'**
  String get settings_attendance_my_title;

  /// No description provided for @settings_attendance_my_subtitle.
  ///
  /// In ru, this message translates to:
  /// **'Отметки и смены'**
  String get settings_attendance_my_subtitle;

  /// No description provided for @settings_filter_delete_confirm.
  ///
  /// In ru, this message translates to:
  /// **'Нажмите, чтобы удалить «{name}»'**
  String settings_filter_delete_confirm(String name);

  /// No description provided for @settings_filter_deleted.
  ///
  /// In ru, this message translates to:
  /// **'«{name}» удалена'**
  String settings_filter_deleted(String name);

  /// No description provided for @settings_saved_categories_count.
  ///
  /// In ru, this message translates to:
  /// **'Сохранённые категории ({count})'**
  String settings_saved_categories_count(int count);

  /// No description provided for @settings_venue_client.
  ///
  /// In ru, this message translates to:
  /// **'Клиент'**
  String get settings_venue_client;

  /// No description provided for @venue_when.
  ///
  /// In ru, this message translates to:
  /// **'Когда'**
  String get venue_when;

  /// No description provided for @venue_status.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get venue_status;

  /// No description provided for @venue_empty_for_now.
  ///
  /// In ru, this message translates to:
  /// **'Пока пусто'**
  String get venue_empty_for_now;

  /// No description provided for @venue_seat_capacity.
  ///
  /// In ru, this message translates to:
  /// **'до {count} гост.'**
  String venue_seat_capacity(int count);

  /// No description provided for @venue_session_free.
  ///
  /// In ru, this message translates to:
  /// **'{when} · свободно {free}/{total}'**
  String venue_session_free(String when, int free, int total);

  /// No description provided for @venue_ticket_remaining.
  ///
  /// In ru, this message translates to:
  /// **'{price} · осталось {remaining}'**
  String venue_ticket_remaining(String price, int remaining);

  /// No description provided for @post_share_sent_to.
  ///
  /// In ru, this message translates to:
  /// **'Пост отправлен {count} получателям'**
  String post_share_sent_to(int count);

  /// No description provided for @post_in_days.
  ///
  /// In ru, this message translates to:
  /// **'через {label}'**
  String post_in_days(String label);

  /// No description provided for @catalog_total_count.
  ///
  /// In ru, this message translates to:
  /// **'Всего: {count}'**
  String catalog_total_count(int count);

  /// No description provided for @catalog_inactive_dot.
  ///
  /// In ru, this message translates to:
  /// **'{subtitle} · неактивно'**
  String catalog_inactive_dot(String subtitle);

  /// No description provided for @common_from_short.
  ///
  /// In ru, this message translates to:
  /// **'С'**
  String get common_from_short;

  /// No description provided for @attendance_rules_accepted.
  ///
  /// In ru, this message translates to:
  /// **'Правила v{version} приняты'**
  String attendance_rules_accepted(String version);

  /// No description provided for @attendance_invite_body.
  ///
  /// In ru, this message translates to:
  /// **'Приглашение для {name} ({username}). После принятия — смена, часы и чат компании.'**
  String attendance_invite_body(String name, String username);

  /// No description provided for @attendance_rules_updated.
  ///
  /// In ru, this message translates to:
  /// **'Правила обновлены · v{version}'**
  String attendance_rules_updated(String version);

  /// No description provided for @attendance_rules_changed_body.
  ///
  /// In ru, this message translates to:
  /// **'Геозона или типы отметок изменились. Пока не примете — отметка недоступна.'**
  String get attendance_rules_changed_body;

  /// No description provided for @attendance_correction_now.
  ///
  /// In ru, this message translates to:
  /// **'сейчас {time}'**
  String attendance_correction_now(String time);

  /// No description provided for @attendance_meters.
  ///
  /// In ru, this message translates to:
  /// **'{meters} м'**
  String attendance_meters(int meters);

  /// No description provided for @attendance_in_zone.
  ///
  /// In ru, this message translates to:
  /// **'Вы в зоне · {meters} м'**
  String attendance_in_zone(int meters);

  /// No description provided for @attendance_out_zone.
  ///
  /// In ru, this message translates to:
  /// **'Вы вне зоны · {meters} м'**
  String attendance_out_zone(int meters);

  /// No description provided for @attendance_in_zone_paren.
  ///
  /// In ru, this message translates to:
  /// **'Вы в зоне ({meters} м)'**
  String attendance_in_zone_paren(int meters);

  /// No description provided for @attendance_enabled_types.
  ///
  /// In ru, this message translates to:
  /// **'Включено: {list}'**
  String attendance_enabled_types(String list);

  /// No description provided for @attendance_at_time.
  ///
  /// In ru, this message translates to:
  /// **'в {time}'**
  String attendance_at_time(String time);

  /// No description provided for @attendance_radius_label.
  ///
  /// In ru, this message translates to:
  /// **'Радиус {meters} м'**
  String attendance_radius_label(int meters);

  /// No description provided for @attendance_clock_in_at.
  ///
  /// In ru, this message translates to:
  /// **'Пришёл {time}'**
  String attendance_clock_in_at(String time);

  /// No description provided for @attendance_clock_out_at.
  ///
  /// In ru, this message translates to:
  /// **'Ушёл {time}'**
  String attendance_clock_out_at(String time);

  /// No description provided for @attendance_custom_count.
  ///
  /// In ru, this message translates to:
  /// **'{count} свои'**
  String attendance_custom_count(int count);

  /// No description provided for @attendance_duty_today_named.
  ///
  /// In ru, this message translates to:
  /// **'Сегодня дежурит: {names}'**
  String attendance_duty_today_named(String names);

  /// No description provided for @attendance_pending_accept.
  ///
  /// In ru, this message translates to:
  /// **'{workplace}: примите обновление v{version} карточкой в чате компании.'**
  String attendance_pending_accept(String workplace, String version);

  /// No description provided for @common_days_one.
  ///
  /// In ru, this message translates to:
  /// **'{count} день'**
  String common_days_one(int count);

  /// No description provided for @common_days_few.
  ///
  /// In ru, this message translates to:
  /// **'{count} дня'**
  String common_days_few(int count);

  /// No description provided for @common_days_many.
  ///
  /// In ru, this message translates to:
  /// **'{count} дней'**
  String common_days_many(int count);

  /// No description provided for @post_archive_failed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось архивировать'**
  String get post_archive_failed;

  /// No description provided for @post_empty.
  ///
  /// In ru, this message translates to:
  /// **'Нет публикаций'**
  String get post_empty;

  /// No description provided for @post_relative_minutes.
  ///
  /// In ru, this message translates to:
  /// **'{count} мин.'**
  String post_relative_minutes(int count);

  /// No description provided for @post_relative_hours.
  ///
  /// In ru, this message translates to:
  /// **'{count} ч.'**
  String post_relative_hours(int count);

  /// No description provided for @post_relative_days.
  ///
  /// In ru, this message translates to:
  /// **'{count} д.'**
  String post_relative_days(int count);

  /// No description provided for @post_emoji_label.
  ///
  /// In ru, this message translates to:
  /// **'Эмодзи'**
  String get post_emoji_label;

  /// No description provided for @post_shared_to.
  ///
  /// In ru, this message translates to:
  /// **'Пост отправлен {count} получателям'**
  String post_shared_to(int count);

  /// No description provided for @chat_create_group.
  ///
  /// In ru, this message translates to:
  /// **'Создать группу'**
  String get chat_create_group;

  /// No description provided for @chat_wallpaper_label.
  ///
  /// In ru, this message translates to:
  /// **'Фон чата · {preview}'**
  String chat_wallpaper_label(String preview);

  /// No description provided for @chat_you_suffix.
  ///
  /// In ru, this message translates to:
  /// **'{handle} (вы)'**
  String chat_you_suffix(String handle);

  /// No description provided for @chat_join_workplace.
  ///
  /// In ru, this message translates to:
  /// **'Стать частью «{name}»'**
  String chat_join_workplace(String name);

  /// No description provided for @chat_join_booking_staff.
  ///
  /// In ru, this message translates to:
  /// **'Стать исполнителем · «{name}»'**
  String chat_join_booking_staff(String name);

  /// No description provided for @profile_name_label.
  ///
  /// In ru, this message translates to:
  /// **'Имя'**
  String get profile_name_label;

  /// No description provided for @profile_section_account.
  ///
  /// In ru, this message translates to:
  /// **'Аккаунт'**
  String get profile_section_account;

  /// No description provided for @profile_username.
  ///
  /// In ru, this message translates to:
  /// **'Никнейм'**
  String get profile_username;

  /// No description provided for @profile_book.
  ///
  /// In ru, this message translates to:
  /// **'Записаться'**
  String get profile_book;

  /// No description provided for @profile_calendar.
  ///
  /// In ru, this message translates to:
  /// **'Календарь'**
  String get profile_calendar;

  /// No description provided for @venue_operations.
  ///
  /// In ru, this message translates to:
  /// **'Операции'**
  String get venue_operations;

  /// No description provided for @venue_comment.
  ///
  /// In ru, this message translates to:
  /// **'Комментарий'**
  String get venue_comment;

  /// No description provided for @settings_filters_count.
  ///
  /// In ru, this message translates to:
  /// **'Фильтры ({count})'**
  String settings_filters_count(int count);

  /// No description provided for @common_nothing_here.
  ///
  /// In ru, this message translates to:
  /// **'Ничего нет'**
  String get common_nothing_here;

  /// No description provided for @common_something_wrong.
  ///
  /// In ru, this message translates to:
  /// **'Что-то пошло не так'**
  String get common_something_wrong;

  /// No description provided for @common_options.
  ///
  /// In ru, this message translates to:
  /// **'Опции'**
  String get common_options;

  /// No description provided for @common_emoji_hint.
  ///
  /// In ru, this message translates to:
  /// **'Выберите или введите эмодзи'**
  String get common_emoji_hint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'kk', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'kk':
      return AppLocalizationsKk();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
