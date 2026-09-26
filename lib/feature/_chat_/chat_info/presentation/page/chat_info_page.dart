import 'package:auto_route/auto_route.dart';
import 'package:clover/core/extension/context.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_snack_bar.dart';
import 'package:clover/feature/_chat_/chat/data/repository/chat_repository.dart';
import 'package:clover/feature/_chat_/chat_info/data/models/chat_participant.dart';
import 'package:clover/feature/_chat_/chat_info/presentation/cubit/chat_info_cubit.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_emoji_wallpaper_sheet.dart';
import 'package:clover/feature/_chat_/chat_page/presentation/widget/chat_peer_accent.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class ChatInfoPage extends StatefulWidget {
  const ChatInfoPage({
    super.key,
    this.chatId,
    this.otherUserId,
    required this.username,
    this.isGroup = false,
  });

  final String? chatId;
  final String? otherUserId;
  final String username;
  final bool isGroup;

  @override
  State<ChatInfoPage> createState() => _ChatInfoPageState();
}

class _ChatInfoPageState extends State<ChatInfoPage> {
  late final ChatInfoCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<ChatInfoCubit>()
      ..load(
        chatId: widget.chatId,
        otherUserId: widget.otherUserId,
        isGroup: widget.isGroup,
      );
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String get _title {
    final raw = widget.username.trim();
    if (raw.isEmpty) return widget.isGroup ? context.l10n.chat_group : 'user';
    if (widget.isGroup) return raw;
    return raw.startsWith('@') ? raw.substring(1) : raw;
  }

  String get _accentSeed {
    final chatId = widget.chatId?.trim();
    if (chatId != null && chatId.isNotEmpty) return chatId;
    final other = widget.otherUserId?.trim();
    if (other != null && other.isNotEmpty) return other;
    return _title;
  }

  void _openProfile(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return;
    final me = _cubit.currentUserId;
    if (me != null && me == id) return;
    context.router.push(GuestProfileRoute(userId: id));
  }

  Future<void> _openWallpaper(ChatInfoLoaded state) async {
    if (!state.canEditWallpaper) {
      AppSnackBar.show(context, message: context.l10n.chat_not_ready);
      return;
    }

    final next = await ChatEmojiWallpaperSheet.show(
      context,
      initialEmojis: state.wallpaperEmojis,
      seed: _accentSeed,
    );
    if (!mounted || next == null) return;

    try {
      await _cubit.setWallpaperEmojis(next);
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.show(
        context,
        message: e is ChatRepositoryException ? e.message : context.l10n.chat_wallpaper_save_failed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = ChatPeerAccent.forSeed(context.colors, _accentSeed);

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: context.colors.pageBackground,
        appBar: AppBar(
          backgroundColor: context.colors.pageBackground,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(AppIcons.arrowBackRounded.icon, size: 22),
            color: context.colors.textColor,
            onPressed: () => context.router.maybePop(),
          ),
          title: Text(
            context.l10n.chat_info_title,
            style: AppTextStyle.base(17, color: context.colors.textColor, fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<ChatInfoCubit, ChatInfoState>(
          builder: (context, state) {
            if (state is ChatInfoLoading || state is ChatInfoInitial) {
              return Center(child: CircularProgressIndicator(color: context.colors.primary));
            }
            if (state is ChatInfoError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.base(15, color: context.colors.subTextColor),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => _cubit.load(
                          chatId: widget.chatId,
                          otherUserId: widget.otherUserId,
                          isGroup: widget.isGroup,
                        ),
                        child: Text(
                          context.l10n.common_retry,
                          style: AppTextStyle.base(15, color: context.colors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final loaded = state as ChatInfoLoaded;
            final participants = loaded.participants;
            final peer = !widget.isGroup && participants.isNotEmpty
                ? participants.firstWhere(
                    (p) => p.userId != _cubit.currentUserId,
                    orElse: () => participants.first,
                  )
                : null;

            final wallpaperLabel = loaded.wallpaperEmojis.isEmpty
                ? context.l10n.chat_wallpaper
                : context.l10n.chat_wallpaper_label(loaded.wallpaperEmojis.take(4).join(''));

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                const SizedBox(height: 12),
                Center(
                  child: _ChatInfoHeroAvatar(
                    title: _title,
                    isGroup: widget.isGroup,
                    accent: accent,
                    avatarUrl: peer?.avatarUrl,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _title,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(22, color: context.colors.textColor, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isGroup ? _groupSubtitle(participants.length) : context.l10n.chat_dm_subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.base(14, color: context.colors.subTextColor),
                ),
                const SizedBox(height: 28),
                if (!widget.isGroup && peer != null) ...[
                  _ChatInfoActionTile(
                    icon: AppIcons.user.icon,
                    label: context.l10n.profile_title,
                    onTap: () => _openProfile(peer.userId),
                  ),
                  const SizedBox(height: 8),
                ],
                if (loaded.canEditWallpaper)
                  _ChatInfoActionTile(
                    icon: AppIcons.editPalette.icon,
                    label: wallpaperLabel,
                    onTap: () => _openWallpaper(loaded),
                  ),
                if (widget.isGroup) ...[
                  const SizedBox(height: 28),
                  Text(
                    context.l10n.chat_members,
                    style: AppTextStyle.base(13, color: context.colors.subTextColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (participants.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        context.l10n.chat_members_empty,
                        style: AppTextStyle.base(14, color: context.colors.subTextColor),
                      ),
                    )
                  else
                    ...participants.map(
                      (p) => _ChatInfoMemberTile(
                        participant: p,
                        accent: ChatPeerAccent.forSeed(context.colors, p.userId),
                        isMe: p.userId == _cubit.currentUserId,
                        onTap: () => _openProfile(p.userId),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  String _groupSubtitle(int count) {
    if (count <= 0) return context.l10n.chat_group;
    return context.l10n.chat_members_count(count);
  }
}

class _ChatInfoHeroAvatar extends StatelessWidget {
  const _ChatInfoHeroAvatar({
    required this.title,
    required this.isGroup,
    required this.accent,
    this.avatarUrl,
  });

  final String title;
  final bool isGroup;
  final ChatPeerAccent accent;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final url = avatarUrl?.trim();
    final letter = title.replaceAll('@', '').trim();
    final initial = letter.isEmpty ? '?' : letter.characters.first.toUpperCase();

    return Container(
      width: 96,
      height: 96,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.fill,
        shape: BoxShape.circle,
        border: Border.all(color: (accent.border ?? context.colors.border).withValues(alpha: 0.7)),
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      child: url != null && url.isNotEmpty
          ? null
          : isGroup
              ? Icon(AppIcons.groupOutlined.icon, size: 40, color: accent.ink)
              : Text(
                  initial,
                  style: AppTextStyle.base(36, color: accent.ink, fontWeight: FontWeight.w700),
                ),
    );
  }
}

class _ChatInfoActionTile extends StatelessWidget {
  const _ChatInfoActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: context.colors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w600),
                ),
              ),
              Icon(AppIcons.chevronRight.icon, size: 20, color: context.colors.iconMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInfoMemberTile extends StatelessWidget {
  const _ChatInfoMemberTile({
    required this.participant,
    required this.accent,
    required this.isMe,
    required this.onTap,
  });

  final ChatParticipant participant;
  final ChatPeerAccent accent;
  final bool isMe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = participant.avatarUrl?.trim();
    final handle = participant.displayUsername;
    final letter = handle.replaceAll('@', '');
    final initial = letter.isEmpty ? '?' : letter.characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: context.colors.pageBackground,
        child: InkWell(
          onTap: isMe ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: accent.fill,
                  backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
                  child: url == null || url.isEmpty
                      ? Text(
                          initial,
                          style: AppTextStyle.base(16, color: accent.ink, fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isMe ? context.l10n.chat_you_suffix(handle) : handle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w600),
                      ),
                      if (participant.isAdmin) ...[
                        const SizedBox(height: 2),
                        Text(
                          context.l10n.catalog_group_admin,
                          style: AppTextStyle.base(12, color: context.colors.subTextColor),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMe) Icon(AppIcons.chevronRight.icon, size: 18, color: context.colors.iconMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
