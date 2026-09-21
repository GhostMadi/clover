import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
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
                        final name = (row.username?.trim().isNotEmpty == true)
                            ? '@${row.username!.trim()}'
                            : 'Пользователь';
                        final busy = _busyIds.contains(row.profileId);
                        return AppTile(
                          title: name,
                          subtitle: 'Разблокировать',
                          icon: AppIcons.block.icon,
                          iconColor: context.colors.destructive,
                          trailing: busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : null,
                          enabled: !busy,
                          onTap: () => _unblock(row),
                        );
                      },
                    ),
    );
  }
}
