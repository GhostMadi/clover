import 'dart:async';

import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_time_picker.dart';
import 'package:clover/feature/_catalog_/city/data/models/city_code.dart';
import 'package:clover/feature/_catalog_/countries/data/models/country_code.dart';
import 'package:clover/feature/_catalog_/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/_post_/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/_post_/post/data/models/post_profile_filter_value.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_marker_details_shimmer.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_profile_filter_chips.dart';
import 'package:flutter/material.dart';

/// Компонент-обертка, добавляющий фирменную вертикальную линию слева от контента.
class AppLeftBorderBlock extends StatelessWidget {
  const AppLeftBorderBlock({
    super.key,
    required this.child,
    this.lineWidth = 3.0,
    this.padding = const EdgeInsets.only(left: 12, top: 2, bottom: 2),
  });

  final Widget child;
  final double lineWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: context.colors.primary, width: lineWidth),
        ),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Маркер как часть детального поста.
/// Стиль: Премиальный Нео-Минимализм с инстаграм-форматом текста.
class PostMarkerInfoSection extends StatelessWidget {
  const PostMarkerInfoSection({
    super.key,
    this.marker,
    this.title,
    this.description,
    this.username,
    this.likesCount = 0,
    this.dislikesCount = 0,
    this.isMarkerLoading = false,
    this.profileFilters = const [],
    this.postTextEmoji,
    this.postTags = const [],
    this.postAddressPrimary,
    this.postAddressCyrillic,
    this.postCountryCode,
    this.postCityCode,
  });

  final PostMarkerSummary? marker;
  final String? title;
  final String? description;
  final String? username;
  final int likesCount;
  final int dislikesCount;
  final bool isMarkerLoading;
  final List<PostProfileFilterValue> profileFilters;
  final String? postTextEmoji;
  final List<MarkerTagModel> postTags;
  final String? postAddressPrimary;
  final String? postAddressCyrillic;
  final String? postCountryCode;
  final String? postCityCode;

  @override
  Widget build(BuildContext context) {
    final titleText = title?.trim() ?? '';
    final descriptionText = description?.trim() ?? '';
    final authorName = _displayUsername(username);
    final likesLabel = _likesLabel(likesCount);
    final dislikesLabel = _dislikesLabel(dislikesCount);
    final markerData = marker;
    final hasPostDetails = markerData == null && _hasPostPublicationDetails;
    final hasCaption =
        authorName.isNotEmpty ||
        likesLabel != null ||
        dislikesLabel != null ||
        titleText.isNotEmpty ||
        descriptionText.isNotEmpty ||
        profileFilters.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasCaption)
            _PostCaptionBlock(
              authorName: authorName,
              likesLabel: likesLabel,
              dislikesLabel: dislikesLabel,
              title: titleText,
              description: descriptionText,
              profileFilters: profileFilters,
            ),
          if (isMarkerLoading) ...[
            if (hasCaption) const SizedBox(height: 24),
            const PostMarkerDetailsShimmer(),
          ] else if (markerData != null) ...[
            if (hasCaption) const SizedBox(height: 24),
            _MarkerDetailsBlock(marker: markerData),
          ] else if (hasPostDetails) ...[
            if (hasCaption) const SizedBox(height: 24),
            _PostPublicationDetailsBlock(
              textEmoji: postTextEmoji,
              tags: postTags,
              addressPrimary: postAddressPrimary,
              addressCyrillic: postAddressCyrillic,
              countryCode: postCountryCode,
              cityCode: postCityCode,
            ),
          ],
        ],
      ),
    );
  }

  static String _displayUsername(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return 'noName';
    return value;
  }

  static String? _likesLabel(int count) {
    if (count <= 0) return null;
    return 'нравится $count';
  }

  static String? _dislikesLabel(int count) {
    if (count <= 0) return null;
    return 'не нравится $count';
  }

  bool get _hasPostPublicationDetails {
    final emoji = postTextEmoji?.trim() ?? '';
    if (emoji.isNotEmpty) return true;
    if (postTags.isNotEmpty) return true;
    final address = postAddressPrimary?.trim();
    if (address != null && address.isNotEmpty) return true;
    return false;
  }
}

class _PostCaptionBlock extends StatelessWidget {
  const _PostCaptionBlock({
    required this.authorName,
    required this.likesLabel,
    required this.dislikesLabel,
    required this.title,
    required this.description,
    required this.profileFilters,
  });

  final String authorName;
  final String? likesLabel;
  final String? dislikesLabel;
  final String title;
  final String description;
  final List<PostProfileFilterValue> profileFilters;

  @override
  Widget build(BuildContext context) {
    final hasReactions = likesLabel != null || dislikesLabel != null;
    final reactionsStyle = AppTextStyle.base(
      14,
      color: context.colors.textColor,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (authorName.isNotEmpty || hasReactions)
          Text.rich(
            TextSpan(
              children: [
                if (authorName.isNotEmpty)
                  TextSpan(
                    text: '$authorName ',
                    style: AppTextStyle.base(
                      14,
                      color: context.colors.textColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                if (likesLabel != null) TextSpan(text: likesLabel, style: reactionsStyle),
                if (likesLabel != null && dislikesLabel != null)
                  TextSpan(
                    text: ' · ',
                    style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w400),
                  ),
                if (dislikesLabel != null) TextSpan(text: dislikesLabel, style: reactionsStyle),
              ],
            ),
          ),
        if (profileFilters.isNotEmpty) ...[
          if (authorName.isNotEmpty || hasReactions) const SizedBox(height: 8),
          PostProfileFilterChips(filters: profileFilters),
        ],
        if (title.isNotEmpty) ...[
          if (authorName.isNotEmpty || hasReactions || profileFilters.isNotEmpty) const SizedBox(height: 6),
          Text(
            title,
            style: AppTextStyle.base(
              20,
              color: context.colors.textColor,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
              height: 1.25,
            ),
          ),
        ],
        if (description.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            description,
            style: AppTextStyle.base(
              15,
              color: context.colors.subTextColor,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ],
    );
  }
}

class _PostPublicationDetailsBlock extends StatelessWidget {
  const _PostPublicationDetailsBlock({
    required this.textEmoji,
    required this.tags,
    this.addressPrimary,
    this.addressCyrillic,
    this.countryCode,
    this.cityCode,
  });

  final String? textEmoji;
  final List<MarkerTagModel> tags;
  final String? addressPrimary;
  final String? addressCyrillic;
  final String? countryCode;
  final String? cityCode;

  String? get _countryLabel => CountryCode.tryParse(countryCode)?.labelRu;

  String? get _cityLabel {
    final country = countryCode?.trim();
    final city = cityCode?.trim();
    if (country == null || country.isEmpty || city == null || city.isEmpty) return null;
    return CityCode.tryParse(countryCode: country, cityCode: city)?.labelRu ?? city;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emoji = textEmoji?.trim() ?? '';
    final country = _countryLabel;
    final city = _cityLabel;
    final primary = addressPrimary?.trim();
    final secondaryRaw = addressCyrillic?.trim();
    final secondary = (secondaryRaw != null && secondaryRaw.isNotEmpty && secondaryRaw != primary)
        ? secondaryRaw
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emoji.isNotEmpty || city != null || country != null) ...[
          Row(
            children: [
              if (emoji.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowDark.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
                ),
                const SizedBox(width: 10),
              ],
              if (city != null || country != null)
                Expanded(
                  child: Text(
                    [city, country].where((e) => e != null).join(' · '),
                    style: AppTextStyle.base(12, fontWeight: FontWeight.w600, color: colors.subTextColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (primary != null && primary.isNotEmpty) ...[
          AppLeftBorderBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'АДРЕС И ОРИЕНТИР',
                  style: AppTextStyle.base(
                    10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.subTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  primary,
                  style: AppTextStyle.base(
                    16,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textColor,
                    height: 1.3,
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    style: AppTextStyle.base(13, fontWeight: FontWeight.w400, color: context.colors.subTextColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (tags.isNotEmpty) _MarkerTagChips(tags: tags),
      ],
    );
  }
}

class _MarkerDetailsBlock extends StatelessWidget {
  const _MarkerDetailsBlock({required this.marker});

  final PostMarkerSummary marker;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final emoji = marker.textEmoji.trim();
    final country = marker.countryLabel;
    final city = marker.cityLabel;
    final primaryAddress = marker.primaryAddressLine;
    final secondaryAddress = marker.secondaryAddressLine;
    final start = marker.eventTime?.toLocal();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (emoji.isNotEmpty || city != null || country != null) ...[
          Row(
            children: [
              if (emoji.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.shadowDark.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 16, height: 1)),
                ),
                const SizedBox(width: 10),
              ],
              if (city != null || country != null)
                Expanded(
                  child: Text(
                    [city, country].where((e) => e != null).join(' · '),
                    style: AppTextStyle.base(12, fontWeight: FontWeight.w600, color: colors.subTextColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (primaryAddress != null) ...[
          AppLeftBorderBlock(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'АДРЕС И ОРИЕНТИР',
                  style: AppTextStyle.base(
                    10,
                    fontWeight: FontWeight.w700,
                    color: context.colors.subTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  primaryAddress,
                  style: AppTextStyle.base(
                    16,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textColor,
                    height: 1.3,
                  ),
                ),
                if (secondaryAddress != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondaryAddress,
                    style: AppTextStyle.base(13, fontWeight: FontWeight.w400, color: context.colors.subTextColor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (start != null) ...[
          AppLeftBorderBlock(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ДАТА И ВРЕМЯ',
                        style: AppTextStyle.base(
                          10,
                          fontWeight: FontWeight.w700,
                          color: context.colors.subTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppTimePicker.formatEventStart(start),
                        style: AppTextStyle.base(14, fontWeight: FontWeight.w700, color: context.colors.textColor),
                      ),
                    ],
                  ),
                ),
                _PostMarkerCountdown(eventTime: marker.eventTime!, endTime: marker.endTime),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (marker.tags.isNotEmpty) _MarkerTagChips(tags: marker.tags),
      ],
    );
  }
}

// --- Интерактивный компактный таймер ---
class _PostMarkerCountdown extends StatefulWidget {
  const _PostMarkerCountdown({required this.eventTime, this.endTime});
  final DateTime eventTime;
  final DateTime? endTime;

  @override
  State<_PostMarkerCountdown> createState() => _PostMarkerCountdownState();
}

class _PostMarkerCountdownState extends State<_PostMarkerCountdown> {
  Timer? _timer;
  _MarkerCountdownPhase? _timerPhase;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _ensureTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _ensureTimer() {
    final phase = _phase(_now);
    if (phase == _MarkerCountdownPhase.finished) {
      _timer?.cancel();
      _timer = null;
      _timerPhase = null;
      return;
    }
    if (_timerPhase == phase && _timer != null) return;

    _timer?.cancel();
    _timerPhase = phase;
    final interval = phase == _MarkerCountdownPhase.beforeStartDays
        ? const Duration(minutes: 1)
        : const Duration(seconds: 1);

    _timer = Timer.periodic(interval, (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
      _ensureTimer();
    });
  }

  _MarkerCountdownPhase _phase(DateTime now) {
    final start = widget.eventTime.toLocal();
    final end = widget.endTime?.toLocal();

    if (now.isBefore(start)) {
      final remaining = start.difference(now);
      if (remaining >= const Duration(hours: 24)) return _MarkerCountdownPhase.beforeStartDays;
      return _MarkerCountdownPhase.beforeStartHours;
    }
    if (end != null && now.isBefore(end)) return _MarkerCountdownPhase.live;
    return _MarkerCountdownPhase.finished;
  }

  @override
  Widget build(BuildContext context) {
    final start = widget.eventTime.toLocal();
    final end = widget.endTime?.toLocal();
    final phase = _phase(_now);

    final value = switch (phase) {
      _MarkerCountdownPhase.beforeStartDays =>
        'через ${AppTimePicker.formatDaysRemaining(start.difference(_now).inDays)}',
      _MarkerCountdownPhase.beforeStartHours => AppTimePicker.formatCountdown(start.difference(_now)),
      _MarkerCountdownPhase.live =>
        end == null ? 'LIVE' : AppTimePicker.formatCountdown(end.difference(_now)),
      _MarkerCountdownPhase.finished => 'Завершено',
    };

    final isLive = phase == _MarkerCountdownPhase.live;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLive ? context.colors.primary : context.colors.textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value.toUpperCase(),
        style: AppTextStyle.base(
          10,
          fontWeight: FontWeight.w800,
          color: isLive ? context.colors.white : context.colors.subTextColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

enum _MarkerCountdownPhase { beforeStartDays, beforeStartHours, live, finished }

// --- Чистые "воздушные" теги с хэштегом в нижнем регистре ---
class _MarkerTagChips extends StatelessWidget {
  const _MarkerTagChips({required this.tags});
  final List<MarkerTagModel> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '#${tag.labelRu.toLowerCase()}',
              style: AppTextStyle.base(11, fontWeight: FontWeight.w700, color: context.colors.primary),
            ),
          ),
      ],
    );
  }
}
