import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/feature/work/data/models/work_member.dart';
import 'package:clover/feature/work/data/models/work_relation_type.dart';
import 'package:clover/feature/work/data/repository/work_repository.dart';
import 'package:clover/feature/work/presentation/widget/work_member_tile.dart';
import 'package:flutter/material.dart';

enum WorkInviteSheetMode {
  employerInviteEmployee,
  workerFindEmployer,
}

extension on WorkInviteSheetMode {
  WorkRelationType get relationType => switch (this) {
    WorkInviteSheetMode.employerInviteEmployee => WorkRelationType.hire,
    WorkInviteSheetMode.workerFindEmployer => WorkRelationType.join,
  };

  String get title => switch (this) {
    WorkInviteSheetMode.employerInviteEmployee => 'Пригласить работника',
    WorkInviteSheetMode.workerFindEmployer => 'Найти работодателя',
  };

  String get searchHint => switch (this) {
    WorkInviteSheetMode.employerInviteEmployee => 'Поиск по никнейму',
    WorkInviteSheetMode.workerFindEmployer => 'Поиск работодателя',
  };
}

/// Шторка поиска аккаунта и отправки заявки.
abstract final class WorkInviteBottomSheet {
  static Future<WorkMember?> show(
    BuildContext context, {
    required WorkInviteSheetMode mode,
    required WorkRepository repository,
    Set<String> excludePeerIds = const {},
  }) {
    return AppBottomSheet.show<WorkMember>(
      context: context,
      title: mode.title,
      expandBody: true,
      contentPadding: const EdgeInsets.all(16),
      sheetOuterPadding: const EdgeInsets.fromLTRB(16, 48, 16, 12),
      contentBottomSpacing: 16,
      content: _WorkInviteSheetBody(
        mode: mode,
        repository: repository,
        excludePeerIds: excludePeerIds,
      ),
    );
  }
}

class _WorkInviteSheetBody extends StatefulWidget {
  const _WorkInviteSheetBody({
    required this.mode,
    required this.repository,
    required this.excludePeerIds,
  });

  final WorkInviteSheetMode mode;
  final WorkRepository repository;
  final Set<String> excludePeerIds;

  @override
  State<_WorkInviteSheetBody> createState() => _WorkInviteSheetBodyState();
}

class _WorkInviteSheetBodyState extends State<_WorkInviteSheetBody> {
  late final TextEditingController _queryController;
  List<WorkMember> _results = const [];
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
      final rows = await widget.repository.searchProfiles(query, action: widget.mode.relationType);
      if (!mounted) return;
      final filtered = rows.where((m) => !widget.excludePeerIds.contains(m.id.trim())).toList();
      setState(() {
        _results = filtered;
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
          hintText: widget.mode.searchHint,
          prefixIcon: Icons.search_rounded,
          textInputAction: TextInputAction.search,
        ),
        const SizedBox(height: 16),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: AppColors.subTextColor),
            ),
          ),
        Expanded(
          child: _loading && _results.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _results.isEmpty
              ? Center(
                  child: Text(
                    'Никого не найдено',
                    style: AppTextStyle.base(14, color: AppColors.subTextColor),
                  ),
                )
              : ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final member = _results[index];
                    return WorkSearchAccountTile(
                      member: member,
                      onSend: () => Navigator.of(context).pop(member),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class WorkSearchAccountTile extends StatelessWidget {
  const WorkSearchAccountTile({super.key, required this.member, required this.onSend});

  final WorkMember member;
  final VoidCallback onSend;

  static const double _buttonHeight = 40;
  static const double _buttonRadius = 12;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkMemberTile(member: member),
            const SizedBox(height: 12),
            AppButton(
              text: 'Отправить заявку',
              height: _buttonHeight,
              borderRadius: _buttonRadius,
              onTap: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
