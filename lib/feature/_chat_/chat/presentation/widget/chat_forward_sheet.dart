import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_field.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_chat_/chat_page/data/models/chat_message.dart';
import 'package:clover/feature/_post_/post_share/data/models/post_share_recipient.dart';
import 'package:clover/feature/_post_/post_share/presentation/cubit/post_share_recipients_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract final class ChatForwardSheet {
  static Future<bool> show(
    BuildContext context, {
    required ChatMessage message,
  }) async {
    final cubit = sl<PostShareRecipientsCubit>()..load();
    final repository = sl<ChatRepository>();

    try {
      final result = await AppBottomSheet.show<bool>(
        context: context,
        title: 'Переслать',
        upperCaseTitle: false,
        expandBody: true,
        contentHeight: MediaQuery.sizeOf(context).height * 0.72,
        content: _ChatForwardBody(cubit: cubit, repository: repository, message: message),
      );
      return result == true;
    } finally {
      if (!cubit.isClosed) await cubit.close();
    }
  }
}

class _ChatForwardBody extends StatefulWidget {
  const _ChatForwardBody({
    required this.cubit,
    required this.repository,
    required this.message,
  });

  final PostShareRecipientsCubit cubit;
  final ChatRepository repository;
  final ChatMessage message;

  @override
  State<_ChatForwardBody> createState() => _ChatForwardBodyState();
}

class _ChatForwardBodyState extends State<_ChatForwardBody> {
  late final TextEditingController _searchController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PostShareRecipient> _filter(List<PostShareRecipient> items) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) => item.displayUsername.toLowerCase().contains(query)).toList(growable: false);
  }

  Future<void> _forwardTo(PostShareRecipient recipient) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final conversationId = await widget.repository.createDm(recipient.profileId);
      await widget.repository.forwardMessage(
        targetConversationId: conversationId,
        message: widget.message,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
            controller: _searchController,
            hintText: 'Поиск получателя',
            prefixIcon: AppIcons.searchRounded.icon,
            textInputAction: TextInputAction.search,
          ),
          const SizedBox(height: 12),
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
                  PostShareRecipientsLoaded(:final following) => ListView.separated(
                    itemCount: _filter(following).length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: context.colors.border.withValues(alpha: 0.6)),
                    itemBuilder: (context, index) {
                      final recipient = _filter(following)[index];
                      final username = recipient.displayUsername;
                      return ListTile(
                        enabled: !_submitting,
                        leading: CircleAvatar(
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
                        title: Text(
                          username.startsWith('@') ? username : '@$username',
                          style: AppTextStyle.base(15, color: context.colors.textColor, fontWeight: FontWeight.w600),
                        ),
                        onTap: () => _forwardTo(recipient),
                      );
                    },
                  ),
                };
              },
            ),
          ),
        ],
      ),
    );
  }
}
