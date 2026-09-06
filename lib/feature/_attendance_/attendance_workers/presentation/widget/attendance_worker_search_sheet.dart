import 'dart:async';

import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/feature/_attendance_/shared/data/models/attendance_profile_hit.dart';
import 'package:clover/feature/_attendance_/shared/presentation/widget/attendance_service_ui.dart';
import 'package:flutter/material.dart';

/// Поиск человека по нику / имени для invite в компанию.
abstract final class AttendanceWorkerSearchSheet {
  static Future<AttendanceProfileHit?> show(
    BuildContext context, {
    required Future<List<AttendanceProfileHit>> Function(String query) search,
  }) {
    return AttendanceBottomSheet.show<AttendanceProfileHit>(
      context: context,
      title: 'Добавить работника',
      expandBody: true,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _Body(search: search),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body({required this.search});

  final Future<List<AttendanceProfileHit>> Function(String query) search;

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  late final TextEditingController _queryController;
  Timer? _debounce;
  List<AttendanceProfileHit> _results = const [];
  bool _loading = false;
  String? _error;
  int _searchToken = 0;

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController();
    _queryController.addListener(_onQueryChanged);
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.removeListener(_onQueryChanged);
    _queryController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      _search(_queryController.text);
    });
  }

  Future<void> _search(String query) async {
    final token = ++_searchToken;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await widget.search(query);
      if (!mounted || token != _searchToken) return;
      setState(() {
        _results = rows;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _loading = false;
        _error = 'Не удалось найти людей';
        _results = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AttendanceField(
          controller: _queryController,
          hintText: 'Поиск по нику или имени',
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
              style: AppTextStyle.base(13, color: colors.subTextColor),
            ),
          ),
        Expanded(
          child: _loading && _results.isEmpty
              ? Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: attendanceServiceAccent(colors).icon,
                  ),
                )
              : _results.isEmpty
                  ? Center(
                      child: Text(
                        'Никого не найдено',
                        style: AppTextStyle.base(14, color: colors.subTextColor),
                      ),
                    )
                  : ListView.separated(
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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

  final AttendanceProfileHit profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accent = attendanceServiceAccent(colors);
    final avatarUrl = profile.avatarUrl?.trim();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border.withValues(alpha: 0.55)),
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
                  backgroundColor: accent.soft,
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(AppIcons.user.icon, color: accent.icon, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.title,
                        style: AppTextStyle.base(15, color: colors.textColor, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.displayUsername,
                        style: AppTextStyle.base(13, color: colors.subTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AttendancePrimaryButton(
              text: 'Пригласить',
              height: 40,
              borderRadius: 12,
              isExpanded: true,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}
