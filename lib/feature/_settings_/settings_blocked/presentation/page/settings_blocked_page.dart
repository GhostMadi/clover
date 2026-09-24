import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/core/shared/app_tile.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SettingsBlockedPage extends StatefulWidget {
  const SettingsBlockedPage({super.key});

  @override
  State<SettingsBlockedPage> createState() => _SettingsBlockedPageState();
}

class _SettingsBlockedPageState extends State<SettingsBlockedPage> {
  final _repo = sl<SocialGraphRepository>();
  List<BlockedProfileRow> _rows = const [];
  bool _loading = true;
  String? _error;
  final Set<String> _busyIds = {};

  static const double _buttonHeight = 36;
  static const double _buttonRadius = 12;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _displayName(BlockedProfileRow row) {
    final username = row.username?.trim();
    if (username != null && username.isNotEmpty) return '@$username';
    return 'Пользователь';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.listMyBlockedUsers();
      if (!mounted) return;
      setState(() {
        _rows = rows;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  void _openProfile(BlockedProfileRow row) {
    context.router.push(GuestProfileRoute(userId: row.profileId));
  }

  Future<void> _confirmUnblock(BlockedProfileRow row) async {
    final id = row.profileId;
    if (_busyIds.contains(id)) return;

    final name = _displayName(row);
    final ok = await AppBottomSheet.show<bool>(
      context: context,
      title: 'Разблокировать?',
      content: Text(
        'Разблокировать $name?',
        style: AppTextStyle.base(15, color: context.colors.subTextColor, height: 1.35),
      ),
      actionsAxis: Axis.horizontal,
      actions: [
        AppOutlinedButton(
          text: 'Нет',
          onTap: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          text: 'Да',
          onTap: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (ok != true || !mounted) return;
    await _unblock(row);
  }

  Future<void> _unblock(BlockedProfileRow row) async {
    final id = row.profileId;
    if (_busyIds.contains(id)) return;
    setState(() => _busyIds.add(id));
    try {
      await _repo.unblockUser(id);
      if (!mounted) return;
      setState(() {
        _rows = [for (final r in _rows) if (r.profileId != id) r];
        _busyIds.remove(id);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsScreenShell(
      title: 'Заблокированные',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.base(14, color: context.colors.destructive),
                    ),
                  ),
                )
              : _rows.isEmpty
                  ? Center(
                      child: Text(
                        'Список пуст',
                        style: AppTextStyle.base(14, color: context.colors.subTextColor),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        SettingsScreenShell.scrollBottomGap(context),
                      ),
                      itemCount: _rows.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final row = _rows[index];
                        final name = _displayName(row);
                        final busy = _busyIds.contains(row.profileId);
                        final avatarUrl = row.avatarUrl?.trim();

                        return AppTile(
                          filled: true,
                          title: name,
                          onTap: () => _openProfile(row),
                          leading: CircleAvatar(
                            radius: 20,
                            backgroundColor: context.colors.surfaceSoft,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Icon(AppIcons.user.icon, color: context.colors.iconMuted, size: 20)
                                : null,
                          ),
                          trailing: AppOutlinedButton(
                            text: '  Разблокировать  ',
                            height: _buttonHeight,
                            borderRadius: _buttonRadius,
                            isLoading: busy,
                            onTap: busy ? null : () => _confirmUnblock(row),
                          ),
                        );
                      },
                    ),
    );
  }
}
