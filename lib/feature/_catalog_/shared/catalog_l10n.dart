import 'package:clover/feature/_catalog_/city/data/models/city_code.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_group_key.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_key.dart';
import 'package:clover/feature/_safety_/content_report/data/models/content_report_reason.dart';
import 'package:clover/l10n/app_localizations.dart';

extension CountryCodeL10n on CountryCode {
  String label(AppLocalizations l10n) => switch (this) {
    CountryCode.kz => l10n.catalog_country_kz,
    CountryCode.ru => l10n.catalog_country_ru,
  };
}

extension CityCodeL10n on CityCode {
  String label(AppLocalizations l10n) => switch (this) {
    CityCode.almaty => l10n.catalog_city_almaty,
    CityCode.astana => l10n.catalog_city_astana,
    CityCode.shymkent => l10n.catalog_city_shymkent,
    CityCode.kazan => l10n.catalog_city_kazan,
    CityCode.moscow => l10n.catalog_city_moscow,
    CityCode.saintPetersburg => l10n.catalog_city_saint_petersburg,
  };
}

extension MarkerTagGroupKeyL10n on MarkerTagGroupKey {
  String label(AppLocalizations l10n) => switch (this) {
    MarkerTagGroupKey.who => l10n.catalog_group_who,
    MarkerTagGroupKey.type => l10n.catalog_group_type,
    MarkerTagGroupKey.forAudience => l10n.catalog_group_for,
    MarkerTagGroupKey.place => l10n.catalog_group_place,
    MarkerTagGroupKey.event => l10n.catalog_group_event,
    MarkerTagGroupKey.format => l10n.catalog_group_format,
    MarkerTagGroupKey.conditions => l10n.catalog_group_conditions,
    MarkerTagGroupKey.admin => l10n.catalog_group_admin,
    MarkerTagGroupKey.worker => l10n.catalog_group_worker,
  };
}

extension MarkerTagKeyL10n on MarkerTagKey {
  String label(AppLocalizations l10n) => switch (this) {
    MarkerTagKey.business => l10n.catalog_tag_business,
    MarkerTagKey.individual => l10n.catalog_tag_individual,
    MarkerTagKey.community => l10n.catalog_tag_community,
    MarkerTagKey.brand => l10n.catalog_tag_brand,
    MarkerTagKey.salon => l10n.catalog_tag_salon,
    MarkerTagKey.barbershop => l10n.catalog_tag_barbershop,
    MarkerTagKey.music => l10n.catalog_tag_music,
    MarkerTagKey.sports => l10n.catalog_tag_sports,
    MarkerTagKey.food => l10n.catalog_tag_food,
    MarkerTagKey.tech => l10n.catalog_tag_tech,
    MarkerTagKey.store => l10n.catalog_tag_store,
    MarkerTagKey.kids => l10n.catalog_tag_kids,
    MarkerTagKey.teens => l10n.catalog_tag_teens,
    MarkerTagKey.adults => l10n.catalog_tag_adults,
    MarkerTagKey.seniors => l10n.catalog_tag_seniors,
    MarkerTagKey.families => l10n.catalog_tag_families,
    MarkerTagKey.couples => l10n.catalog_tag_couples,
    MarkerTagKey.students => l10n.catalog_tag_students,
    MarkerTagKey.professionals => l10n.catalog_tag_professionals,
    MarkerTagKey.menOnly => l10n.catalog_tag_men_only,
    MarkerTagKey.womenOnly => l10n.catalog_tag_women_only,
    MarkerTagKey.restaurant => l10n.catalog_tag_restaurant,
    MarkerTagKey.cafe => l10n.catalog_tag_cafe,
    MarkerTagKey.bar => l10n.catalog_tag_bar,
    MarkerTagKey.cinema => l10n.catalog_tag_cinema,
    MarkerTagKey.club => l10n.catalog_tag_club,
    MarkerTagKey.shop => l10n.catalog_tag_shop,
    MarkerTagKey.beauty => l10n.catalog_tag_beauty,
    MarkerTagKey.fitness => l10n.catalog_tag_fitness,
    MarkerTagKey.medical => l10n.catalog_tag_medical,
    MarkerTagKey.education => l10n.catalog_tag_education,
    MarkerTagKey.coworking => l10n.catalog_tag_coworking,
    MarkerTagKey.hotel => l10n.catalog_tag_hotel,
    MarkerTagKey.mall => l10n.catalog_tag_mall,
    MarkerTagKey.party => l10n.catalog_tag_party,
    MarkerTagKey.networking => l10n.catalog_tag_networking,
    MarkerTagKey.workshop => l10n.catalog_tag_workshop,
    MarkerTagKey.lecture => l10n.catalog_tag_lecture,
    MarkerTagKey.festival => l10n.catalog_tag_festival,
    MarkerTagKey.concert => l10n.catalog_tag_concert,
    MarkerTagKey.exhibition => l10n.catalog_tag_exhibition,
    MarkerTagKey.movieNight => l10n.catalog_tag_movie_night,
    MarkerTagKey.gameNight => l10n.catalog_tag_game_night,
    MarkerTagKey.dating => l10n.catalog_tag_dating,
    MarkerTagKey.kidsEvent => l10n.catalog_tag_kids_event,
    MarkerTagKey.sportEvent => l10n.catalog_tag_sport_event,
    MarkerTagKey.sale => l10n.catalog_tag_sale,
    MarkerTagKey.grandOpening => l10n.catalog_tag_grand_opening,
    MarkerTagKey.indoor => l10n.catalog_tag_indoor,
    MarkerTagKey.outdoor => l10n.catalog_tag_outdoor,
    MarkerTagKey.online => l10n.catalog_tag_online,
    MarkerTagKey.active => l10n.catalog_tag_active,
    MarkerTagKey.chill => l10n.catalog_tag_chill,
    MarkerTagKey.extreme => l10n.catalog_tag_extreme,
    MarkerTagKey.creative => l10n.catalog_tag_creative,
    MarkerTagKey.educational => l10n.catalog_tag_educational,
    MarkerTagKey.entertainment => l10n.catalog_tag_entertainment,
    MarkerTagKey.free => l10n.catalog_tag_free,
    MarkerTagKey.paid => l10n.catalog_tag_paid,
    MarkerTagKey.reservation => l10n.catalog_tag_reservation,
    MarkerTagKey.limitedSpots => l10n.catalog_tag_limited_spots,
    MarkerTagKey.petFriendly => l10n.catalog_tag_pet_friendly,
    MarkerTagKey.eco => l10n.catalog_tag_eco,
    MarkerTagKey.plus18 => l10n.catalog_tag_plus18,
    MarkerTagKey.night => l10n.catalog_tag_night,
    MarkerTagKey.newEvent => l10n.catalog_tag_new_event,
    MarkerTagKey.popular => l10n.catalog_tag_popular,
    MarkerTagKey.booking => l10n.catalog_tag_booking,
    MarkerTagKey.attendance => l10n.catalog_tag_attendance,
    MarkerTagKey.resources => l10n.catalog_tag_resources,
    MarkerTagKey.feedback => l10n.catalog_tag_feedback,
    MarkerTagKey.bookingCalendar => l10n.catalog_tag_booking_calendar,
    MarkerTagKey.attendanceWork => l10n.catalog_tag_attendance_work,
  };
}

extension ContentReportReasonL10n on ContentReportReason {
  String label(AppLocalizations l10n) => switch (this) {
    ContentReportReason.objectionableContent => l10n.ugc_report_objectionable,
    ContentReportReason.abusiveUser => l10n.ugc_report_abusive,
    ContentReportReason.spam => l10n.ugc_report_spam,
    ContentReportReason.harassment => l10n.ugc_report_harassment_threats,
    ContentReportReason.other => l10n.ugc_report_other,
  };
}
