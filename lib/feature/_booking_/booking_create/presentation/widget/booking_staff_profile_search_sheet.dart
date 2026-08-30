import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/feature/_booking_/booking_create/data/models/booking_staff_profile.dart';
import 'package:clover/feature/_booking_/booking_create/data/repository/booking_staff_repository.dart';
import 'package:flutter/material.dart';

/// Поиск аккаунта приложения для назначения исполнителем услуги.
abstract final class BookingStaffProfileSearchSheet {
  static Future<BookingStaffProfile?> show(
    BuildContext context, {
    required BookingStaffRepository repository,
    Set<String> excludeProfileIds = const {},
  }) {
    return AppBottomSheet.show<BookingStaffProfile>(
      context: context,
      title: 'Добавить исполнителя',
      expandBody: true,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _Body(
        repository: repository,
        excludeProfileIds: excludeProfileIds,
      ),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({
    required this.repository,
    required this.excludeProfileIds,
  });

  final BookingStaffRepository repository;
  final Set<String> excludeProfileIds;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _queryController;
  List<BookingStaffProfile> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
    _search('');
  }

  @override
  void dispose() {
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.repository.searchProfiles(
        query,
        excludeProfileIds: widget.excludeProfileIds,
      );
      if (!mounted) return;
      setState(() {
        _results = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
        _results = const [];
      });
    }
  }

  void _onQueryChanged() {
    _search(_queryController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppField(
          controller: _queryController,
          hintText: 'Поиск по никнейму или имени',
          prefixIcon: AppIcons.searchRounded.icon,
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: context.colors.subTextColor),
            ),
          ),
        Expanded(
          child: _loading && _results.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _results.isEmpty
              ? Center(
                  child: Text(
                    'Никого не найдено',
                    style: AppTextStyle.base(14, color: context.colors.subTextColor),
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final profile = _results[index];
                    return _ProfileTile(
                      profile: profile,
                      onTap: () => Navigator.of(context).pop(profile),
                    );
                  },
                ),
        ),
      ],
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
            AppButton(
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
