import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_post_/post_share/data/models/post_share_recipient.dart';
import 'package:clover/feature/_post_/post_share/data/repository/post_share_repository.dart';
import 'package:clover/feature/_post_/post_share/presentation/cubit/post_share_recipients_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Шторка «Поделиться» — сетка подписок и поле сообщения (Instagram-style).
abstract final class PostShareSheet {
  static Future<int?> show(BuildContext context, {required String postId}) async {
    final cubit = sl<PostShareRecipientsCubit>()..load();
    final repository = sl<PostShareRepository>();

    final height = MediaQuery.sizeOf(context).height * 0.75;

    try {
      return await AppBottomSheet.show<int>(
        context: context,
        title: 'Поделиться',
        upperCaseTitle: false,
        contentHeight: height,
        expandBody: true,
        contentPadding: EdgeInsets.zero,
        contentBottomSpacing: 0,
        sheetOuterPadding: const EdgeInsets.fromLTRB(12, 100, 12, 12),
        content: _PostShareSheetBody(cubit: cubit, postId: postId, repository: repository),
      );
    } finally {
      if (!cubit.isClosed) await cubit.close();
    }
  }
}

class _PostShareSheetBody extends StatefulWidget {
  const _PostShareSheetBody({required this.cubit, required this.postId, required this.repository});

  final PostShareRecipientsCubit cubit;
  final String postId;
  final PostShareRepository repository;

  @override
  State<_PostShareSheetBody> createState() => _PostShareSheetBodyState();
}

class _PostShareSheetBodyState extends State<_PostShareSheetBody> {
  late final TextEditingController _searchController;
  late final TextEditingController _messageController;
  final Set<String> _selectedIds = {};
  bool _submitting = false;

  PostShareRecipientsCubit get _cubit => widget.cubit;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  void _toggleRecipient(PostShareRecipient recipient) {
    setState(() {
      if (_selectedIds.contains(recipient.profileId)) {
        _selectedIds.remove(recipient.profileId);
      } else {
        _selectedIds.add(recipient.profileId);
      }
    });
  }

  Future<void> _onSend() async {
    if (_selectedIds.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    try {
      final result = await widget.repository.sharePostToRecipients(
        postId: widget.postId,
        recipientIds: _selectedIds.toList(growable: false),
        message: _messageController.text,
      );
      if (!mounted) return;

      AppSnackBar.show(
        context,
        message: result.sharedCount == 1
            ? 'Пост отправлен'
            : 'Пост отправлен ${result.sharedCount} получателям',
        kind: AppSnackBarKind.success,
      );
      Navigator.of(context).pop(result.sendsCount);
    } on PostShareException catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: e.message, kind: AppSnackBarKind.error);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(context, message: '$e', kind: AppSnackBarKind.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  List<PostShareRecipient> _filterFollowing(List<PostShareRecipient> following) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return following;

    return following
        .where((item) {
          final username = item.displayUsername.toLowerCase();
          return username.contains(query);
        })
        .toList(growable: false);
  }

  List<PostShareRecipient> _orderedRecipients({
    required List<PostShareRecipient> following,
    required List<PostShareRecipient> frequent,
  }) {
    final filtered = _filterFollowing(following);
    final query = _searchController.text.trim();
    if (query.isNotEmpty) return filtered;

    final frequentOrder = {for (var i = 0; i < frequent.length; i++) frequent[i].profileId: i};

    final sorted = [...filtered];
    sorted.sort((a, b) {
      final ai = frequentOrder[a.profileId];
      final bi = frequentOrder[b.profileId];
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.displayUsername.compareTo(b.displayUsername);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostShareRecipientsCubit, PostShareRecipientsState>(
      bloc: _cubit,
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AppField(
                controller: _searchController,
                hintText: 'Поиск',
                prefixIcon: AppIcons.searchRounded.icon,
                textInputAction: TextInputAction.search,
              ),
            ),
            Expanded(child: _buildBody(state)),
            Divider(height: 1, color: context.colors.border),
            _ShareMessageInputBar(
              controller: _messageController,
              canSend: _selectedIds.isNotEmpty && !_submitting,
              submitting: _submitting,
              onSend: _onSend,
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(PostShareRecipientsState state) {
    return switch (state) {
      PostShareRecipientsInitial() ||
      PostShareRecipientsLoading() => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      PostShareRecipientsError(:final message) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyle.base(14, color: context.colors.subTextColor),
          ),
        ),
      ),
      PostShareRecipientsLoaded(:final following, :final frequent) => _buildGrid(
        following: following,
        frequent: frequent,
      ),
    };
  }

  Widget _buildGrid({
    required List<PostShareRecipient> following,
    required List<PostShareRecipient> frequent,
  }) {
    final recipients = _orderedRecipients(following: following, frequent: frequent);
    final query = _searchController.text.trim();

    if (recipients.isEmpty) {
      return Center(
        child: Text(
          query.isEmpty ? 'Нет подписок для отправки' : 'Никого не найдено',
          style: AppTextStyle.base(14, color: context.colors.subTextColor),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: recipients.length,
      itemBuilder: (context, index) {
        final recipient = recipients[index];
        return _ShareRecipientGridCell(
          recipient: recipient,
          selected: _selectedIds.contains(recipient.profileId),
          onTap: () => _toggleRecipient(recipient),
        );
      },
    );
  }
}

class _ShareRecipientGridCell extends StatelessWidget {
  const _ShareRecipientGridCell({required this.recipient, required this.selected, required this.onTap});

  final PostShareRecipient recipient;
  final bool selected;
  final VoidCallback onTap;

  static const double _avatarSize = 56;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = recipient.avatarUrl?.trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _avatarSize + 8,
            height: _avatarSize + 8,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: _avatarSize + (selected ? 6 : 0),
                  height: _avatarSize + (selected ? 6 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: context.colors.primary, width: 2) : null,
                  ),
                  child: CircleAvatar(
                    radius: _avatarSize / 2,
                    backgroundColor: context.colors.surfaceSoft,
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Icon(AppIcons.user.icon, color: context.colors.iconMuted, size: 28)
                        : null,
                  ),
                ),
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                      child: Icon(AppIcons.checkRounded.icon, size: 14, color: context.colors.textInverse),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            recipient.displayUsername,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTextStyle.base(11, color: context.colors.textColor),
          ),
        ],
      ),
    );
  }
}

class _ShareMessageInputBar extends StatelessWidget {
  const _ShareMessageInputBar({
    required this.controller,
    required this.canSend,
    required this.submitting,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final bool submitting;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: AppField(
          controller: controller,
          hintText: 'Напишите сообщение…',
          textInputAction: TextInputAction.send,
          isEnabled: !submitting,
          suffixIcon: IconButton(
            onPressed: canSend ? onSend : null,
            icon: submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(AppIcons.send.icon, color: canSend ? context.colors.primary : context.colors.iconMuted),
          ),
        ),
      ),
    );
  }
}
