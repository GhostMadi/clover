import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_post_/post_share/data/models/post_share_recipient.dart';
import 'package:clover/feature/_post_/post_share/presentation/cubit/post_share_recipients_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class ChatGroupCreateSheet {
  static Future<({String conversationId, String title})?> show(BuildContext context) async {
    final cubit = sl<PostShareRecipientsCubit>()..load();
    final repository = sl<ChatRepository>();

    try {
      return await AppBottomSheet.show<({String conversationId, String title})>(
        context: context,
        title: 'Новая группа',
        upperCaseTitle: false,
        expandBody: true,
        contentHeight: MediaQuery.sizeOf(context).height * 0.72,
        content: _ChatGroupCreateBody(cubit: cubit, repository: repository),
      );
    } finally {
      if (!cubit.isClosed) await cubit.close();
    }
  }
}

class _ChatGroupCreateBody extends StatefulWidget {
  const _ChatGroupCreateBody({required this.cubit, required this.repository});

  final PostShareRecipientsCubit cubit;
  final ChatRepository repository;

  @override
  State<_ChatGroupCreateBody> createState() => _ChatGroupCreateBodyState();
}

class _ChatGroupCreateBodyState extends State<_ChatGroupCreateBody> {
  late final TextEditingController _titleController;
  late final TextEditingController _searchController;
  final Set<String> _selectedIds = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _searchController = TextEditingController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<PostShareRecipient> _filter(List<PostShareRecipient> items) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items
        .where((item) => item.displayUsername.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _create() async {
    if (_submitting) return;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.show(context, message: 'Укажите название группы', kind: AppSnackBarKind.error);
      return;
    }
    if (_selectedIds.isEmpty) {
      AppSnackBar.show(context, message: 'Выберите участников', kind: AppSnackBarKind.error);
      return;
    }

    setState(() => _submitting = true);
    try {
      final conversationId = await widget.repository.createGroup(
        title: title,
        userIds: _selectedIds.toList(growable: false),
      );
      if (!mounted) return;
      Navigator.of(context).pop((conversationId: conversationId, title: title));
    } on ChatRepositoryException catch (error) {
      if (!mounted) return;
      AppSnackBar.show(context, message: error.message, kind: AppSnackBarKind.error);
    } catch (error) {
      if (!mounted) return;
      AppSnackBar.show(context, message: '$error', kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.cubit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppField(
            controller: _titleController,
            hintText: 'Название группы',
            prefixIcon: AppIcons.groupOutlined.icon,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          AppField(
            controller: _searchController,
            hintText: 'Поиск участников',
            prefixIcon: AppIcons.searchRounded.icon,
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 12),
          Text(
            'Участники из подписок',
            style: AppTextStyle.base(14, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<PostShareRecipientsCubit, PostShareRecipientsState>(
              builder: (context, state) {
                return switch (state) {
                  PostShareRecipientsInitial() || PostShareRecipientsLoading() => Center(
                    child: CircularProgressIndicator(color: context.colors.primary),
                  ),
                  PostShareRecipientsError(:final message) => Center(
                    child: Text(message, style: AppTextStyle.base(14, color: context.colors.subTextColor)),
                  ),
                  PostShareRecipientsLoaded(:final following) => _RecipientsList(
                    recipients: _filter(following),
                    selectedIds: _selectedIds,
                    onToggle: (id) => setState(() {
                      if (_selectedIds.contains(id)) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    }),
                  ),
                };
              },
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _create,
            style: FilledButton.styleFrom(backgroundColor: context.colors.primary),
            child: _submitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.white),
                  )
                : const Text('Создать группу'),
          ),
        ],
      ),
    );
  }
}

class _RecipientsList extends StatelessWidget {
  const _RecipientsList({
    required this.recipients,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<PostShareRecipient> recipients;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    if (recipients.isEmpty) {
      return Center(
        child: Text(
          'Никого не найдено',
          style: AppTextStyle.base(14, color: context.colors.subTextColor),
        ),
      );
    }

    return ListView.separated(
      itemCount: recipients.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.border.withValues(alpha: 0.6)),
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        final selected = selectedIds.contains(recipient.profileId);
        final username = recipient.displayUsername;

        return InkWell(
          onTap: () => onToggle(recipient.profileId),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: context.colors.surfaceSoft,
                  backgroundImage: recipient.avatarUrl?.trim().isNotEmpty == true
                      ? NetworkImage(recipient.avatarUrl!.trim())
                      : null,
                  child: recipient.avatarUrl?.trim().isNotEmpty == true
                      ? null
                      : Text(
                          username.isNotEmpty ? username.characters.first.toUpperCase() : '?',
                          style: AppTextStyle.base(16, color: context.colors.primary, fontWeight: FontWeight.w700),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    username.startsWith('@') ? username : '@$username',
                    style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  selected ? AppIcons.checkCircle.icon : AppIcons.checkBoxBlank.icon,
                  color: selected ? context.colors.primary : context.colors.iconMuted,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
