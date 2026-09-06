import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/booking_create/presentation/cubit/booking_staff_search_cubit.dart';
import 'package:clover/feature/_booking_/shared/presentation/widget/booking_service_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Поиск аккаунта приложения для назначения исполнителем услуги.
abstract final class BookingStaffProfileSearchSheet {
  static Future<BookingStaffProfile?> show(
    BuildContext context, {
    Set<String> excludeProfileIds = const {},
  }) {
    return AppBottomSheet.show<BookingStaffProfile>(
      service: kBookingService,
      context: context,
      title: 'Добавить исполнителя',
      expandBody: true,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _Body(excludeProfileIds: excludeProfileIds),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.excludeProfileIds});

  final Set<String> excludeProfileIds;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final BookingStaffSearchCubit _cubit;
  late final TextEditingController _queryController;

  @override
  void initState() {
    super.initState();
    _cubit = sl<BookingStaffSearchCubit>()..configure(excludeProfileIds: widget.excludeProfileIds);
    _queryController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
    _cubit.search('');
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onQueryChanged() {
    _cubit.search(_queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<BookingStaffSearchCubit, BookingStaffSearchState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BookingField(
                controller: _queryController,
                hintText: 'Поиск по никнейму или имени',
                prefixIcon: AppIcons.searchRounded.icon,
                textInputAction: TextInputAction.search,
              ),
              const SizedBox(height: 16),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyle.base(13, color: context.colors.subTextColor),
                  ),
                ),
              Expanded(
                child: state.loading && state.results.isEmpty
                    ? const BookingLoader(strokeWidth: 2)
                    : state.results.isEmpty
                    ? Center(
                        child: Text(
                          'Никого не найдено',
                          style: AppTextStyle.base(14, color: context.colors.subTextColor),
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final profile = state.results[index];
                          return _ProfileTile(
                            profile: profile,
                            onTap: () => Navigator.of(context).pop(profile),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.profile, required this.onTap});

  final BookingStaffProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile.avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: context.colors.surfaceSoft,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(AppIcons.user.icon, color: context.colors.iconMuted, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.title,
                        style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      if (profile.displayName?.trim().isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(
                          profile.displayUsername,
                          style: AppTextStyle.base(13, color: context.colors.subTextColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BookingPrimaryButton(
              text: 'Добавить',
              height: 40,
              borderRadius: 12,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
