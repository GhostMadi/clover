import 'package:clover/core/extension/context.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_outlined_button.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_actor.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_kind.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/widget/notification_avatar_stack.dart';
import 'package:clover/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatefulWidget {
  const NotificationTile({
    super.key,
    required this.item,
    this.onFollowToggle,
    this.onTap,
    this.onLoginConfirm,
    this.onLoginRevoke,
    this.onLoginChangePassword,
  });

  final NotificationItem item;
  final ValueChanged<NotificationItem>? onFollowToggle;
  final VoidCallback? onTap;
  final VoidCallback? onLoginConfirm;
  final VoidCallback? onLoginRevoke;
  final VoidCallback? onLoginChangePassword;

  @override
  State<NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<NotificationTile> {
  late bool _isFollowing = widget.item.isFollowingActor;

  @override
  void didUpdateWidget(covariant NotificationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.isFollowingActor != widget.item.isFollowingActor) {
      _isFollowing = widget.item.isFollowingActor;
    }
  }

  void _toggleFollow() {
    setState(() => _isFollowing = !_isFollowing);
    widget.onFollowToggle?.call(widget.item.copyWith(isFollowingActor: _isFollowing));
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final l10n = context.l10n;
    final text = _buildMessage(item, l10n);
    final timeLabel = _formatRelativeTime(item.createdAt, l10n);
    final showPostPreview = item.postPreviewUrl != null &&
        (item.kind == NotificationKind.like ||
            item.kind == NotificationKind.dislike ||
            item.kind == NotificationKind.comment ||
            item.kind == NotificationKind.commentLike ||
            item.kind == NotificationKind.commentDislike);

    return Material(
      color: item.isUnread ? context.colors.bgSoftMint.withValues(alpha: 0.55) : context.colors.pageBackground,
      child: InkWell(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NotificationAvatarStack(actors: item.actors, kind: item.kind),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyle.base(14, color: context.colors.textColor, height: 1.35),
                        children: text,
                      ),
                    ),
                    if (item.commentPreview case final preview? when preview.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.base(13, color: context.colors.subTextColor, height: 1.3),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: AppTextStyle.base(12, color: context.colors.subTextColor.withValues(alpha: 0.85)),
                    ),
                    if (item.showLoginActions) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (item.loginActions.contains('confirm') || item.loginActions.isEmpty)
                            AppButton(
                              text: l10n.feed_notif_login_its_me,
                              height: 32,
                              borderRadius: 10,
                              onTap: widget.onLoginConfirm,
                            ),
                          if (item.loginActions.contains('revoke') || item.loginActions.isEmpty)
                            AppOutlinedButton(
                              text: l10n.feed_notif_login_revoke,
                              height: 32,
                              borderRadius: 10,
                              onTap: widget.onLoginRevoke,
                            ),
                          if (item.loginActions.contains('change_password') ||
                              item.loginActions.isEmpty)
                            AppOutlinedButton(
                              text: l10n.feed_notif_login_change_password,
                              height: 32,
                              borderRadius: 10,
                              onTap: widget.onLoginChangePassword,
                            ),
                        ],
                      ),
                    ] else if (item.kind == NotificationKind.accountLogin &&
                        item.loginResolved != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        switch (item.loginResolved) {
                          'confirmed' => l10n.feed_notif_login_confirmed,
                          'revoked' || 'revoked_others' => l10n.feed_notif_login_revoked,
                          _ => l10n.feed_notif_login_resolved,
                        },
                        style: AppTextStyle.base(12, color: context.colors.subTextColor),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (item.showFollowButton)
                _FollowButton(isFollowing: _isFollowing, onTap: _toggleFollow)
              else if (showPostPreview)
                _PostPreview(url: item.postPreviewUrl!),
            ],
          ),
        ),
      ),
    );
  }

  List<InlineSpan> _buildMessage(NotificationItem item, AppLocalizations l10n) {
    final actorsLabel = _actorsLabel(item.actors, l10n);
    final bold = (String text) => TextSpan(
      text: text,
      style: AppTextStyle.base(14, color: context.colors.textColor, fontWeight: FontWeight.w700, height: 1.35),
    );
    final regular = (String text) => TextSpan(
      text: text,
      style: AppTextStyle.base(14, color: context.colors.textColor, height: 1.35),
    );

    return switch (item.kind) {
      NotificationKind.followedYou => [bold(actorsLabel), regular(l10n.feed_notif_followed_you)],
      NotificationKind.youFollowed => [regular(l10n.feed_notif_you_followed), bold(actorsLabel)],
      NotificationKind.mutualFollow => [
        bold(actorsLabel),
        regular(l10n.feed_notif_mutual_follow),
      ],
      NotificationKind.like => _reactionMessage(
        actorsLabel,
        l10n.feed_notif_verb_liked,
        l10n.feed_notif_target_your_post,
        bold,
        regular,
      ),
      NotificationKind.dislike => _reactionMessage(
        actorsLabel,
        l10n.feed_notif_verb_disliked,
        l10n.feed_notif_target_your_post,
        bold,
        regular,
      ),
      NotificationKind.comment => item.isReply
          ? _reactionMessage(
              actorsLabel,
              l10n.feed_notif_verb_replied,
              l10n.feed_notif_target_on_your_comment,
              bold,
              regular,
            )
          : _reactionMessage(
              actorsLabel,
              l10n.feed_notif_verb_commented,
              l10n.feed_notif_target_your_post,
              bold,
              regular,
            ),
      NotificationKind.commentLike => _reactionMessage(
        actorsLabel,
        l10n.feed_notif_verb_liked,
        l10n.feed_notif_target_your_comment,
        bold,
        regular,
      ),
      NotificationKind.commentDislike => _reactionMessage(
        actorsLabel,
        l10n.feed_notif_verb_disliked,
        l10n.feed_notif_target_your_comment,
        bold,
        regular,
      ),
      NotificationKind.bookingCreatedHost => [
        bold(actorsLabel),
        regular(l10n.feed_notif_booking_created_host(_serviceLabel(item, l10n), _whenSuffix(item))),
      ],
      NotificationKind.bookingBookedClient => [
        regular(l10n.feed_notif_booking_booked_client_prefix),
        bold(_serviceLabel(item, l10n)),
        regular(_whenSuffix(item)),
      ],
      NotificationKind.bookingReminderClient => [
        regular(_reminderLead(item, l10n)),
        bold(_serviceLabel(item, l10n)),
        regular(l10n.feed_notif_booking_reminder_at_host(_hostLabel(item, l10n), _whenSuffix(item))),
      ],
      NotificationKind.bookingVisitStarted => [
        regular(l10n.feed_notif_visit_started_prefix),
        bold(_serviceLabel(item, l10n)),
        regular(l10n.feed_notif_visit_started_suffix(_whenSuffix(item))),
      ],
      NotificationKind.bookingVisitNeedsClose => [
        regular(l10n.feed_notif_visit_close_prefix),
        bold(_serviceLabel(item, l10n)),
        regular(_whenSuffix(item)),
      ],
      NotificationKind.bookingCancelledHost => [
        bold(actorsLabel),
        regular(l10n.feed_notif_cancelled_host(_serviceLabel(item, l10n), _whenSuffix(item))),
      ],
      NotificationKind.bookingCancelledClient => [
        bold(actorsLabel),
        regular(l10n.feed_notif_cancelled_client(_serviceLabel(item, l10n), _whenSuffix(item))),
      ],
      NotificationKind.bookingCompletedClient => [
        regular(l10n.feed_notif_completed_prefix),
        bold(_serviceLabel(item, l10n)),
        if (item.bonusEarnAmount case final bonus?) regular(l10n.feed_notif_bonus_earn(bonus)) else regular(''),
      ],
      NotificationKind.bookingNoShowClient => [
        regular(l10n.feed_notif_no_show_prefix),
        bold(_serviceLabel(item, l10n)),
        regular(_whenSuffix(item)),
      ],
      NotificationKind.bookingRescheduled => [
        bold(actorsLabel),
        regular(l10n.feed_notif_rescheduled),
        bold(_serviceLabel(item, l10n)),
        regular(_whenSuffix(item)),
      ],
      NotificationKind.bookingAssignedStaff => [
        regular(l10n.feed_notif_assigned_staff_prefix),
        bold(_serviceLabel(item, l10n)),
        regular(_whenSuffix(item)),
      ],
      NotificationKind.attendanceInvite => [
        bold(actorsLabel),
        regular(l10n.feed_notif_attendance_invite),
      ],
      NotificationKind.attendanceRulesAck => [
        regular(l10n.feed_notif_attendance_rules),
      ],
      NotificationKind.attendanceDuty => [
        regular(l10n.feed_notif_attendance_duty),
      ],
      NotificationKind.attendanceCorrection => [
        regular(l10n.feed_notif_attendance_correction),
      ],
      NotificationKind.attendancePunchDue => [
        regular(_attendancePunchDueLead(item, l10n)),
      ],
      NotificationKind.accountLogin => [
        regular(l10n.feed_notif_login_prefix),
        bold(
          item.loginWhere?.trim().isNotEmpty == true
              ? item.loginWhere!
              : l10n.feed_notif_login_new_device,
        ),
      ],
    };
  }

  String _serviceLabel(NotificationItem item, AppLocalizations l10n) {
    final title = item.bookingServiceTitle?.trim();
    if (title != null && title.isNotEmpty) return title;
    return l10n.feed_notif_service_fallback;
  }

  String _whenSuffix(NotificationItem item) {
    final when = item.bookingStartsAt;
    if (when == null) return '';
    final time =
        '${when.day.toString().padLeft(2, '0')}.${when.month.toString().padLeft(2, '0')} ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    return ', $time';
  }

  String _hostLabel(NotificationItem item, AppLocalizations l10n) {
    if (item.actors.isNotEmpty) return item.actors.first.displayName;
    return l10n.feed_notif_host_fallback;
  }

  String _reminderLead(NotificationItem item, AppLocalizations l10n) {
    final minutes = item.bookingReminderMinutesBefore;
    return switch (minutes) {
      1440 => l10n.feed_notif_reminder_tomorrow,
      180 => l10n.feed_notif_reminder_3h,
      120 => l10n.feed_notif_reminder_2h,
      60 => l10n.feed_notif_reminder_1h,
      30 => l10n.feed_notif_reminder_30m,
      15 => l10n.feed_notif_reminder_15m,
      final m? when m > 0 => l10n.feed_notif_reminder_minutes(m),
      _ => l10n.feed_notif_reminder_default,
    };
  }

  String _attendancePunchDueLead(NotificationItem item, AppLocalizations l10n) {
    final place = item.attendanceWorkplaceName?.trim();
    final suffix = (place != null && place.isNotEmpty) ? ' · $place' : '';
    return switch (item.attendanceDueKind) {
      'clock_out' => l10n.feed_notif_punch_clock_out(suffix),
      'auto_closed' => l10n.feed_notif_punch_auto_closed(suffix),
      _ => l10n.feed_notif_punch_clock_in(suffix),
    };
  }

  List<InlineSpan> _reactionMessage(
    String actorsLabel,
    String verb,
    String target,
    TextSpan Function(String) bold,
    TextSpan Function(String) regular,
  ) {
    return [bold(actorsLabel), regular(' $verb $target')];
  }

  String _actorsLabel(List<NotificationActor> actors, AppLocalizations l10n) {
    if (actors.isEmpty) return l10n.common_someone;
    if (actors.length == 1) return actors.first.displayName;
    if (actors.length == 2) {
      return '${actors[0].displayName} ${l10n.common_and} ${actors[1].displayName}';
    }
    return '${actors[0].displayName}, ${actors[1].displayName} ${l10n.common_and_more(actors.length - 2)}';
  }

  String _formatRelativeTime(DateTime date, AppLocalizations l10n) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return l10n.common_just_now;
    if (diff.inMinutes < 60) return l10n.common_minutes_short(diff.inMinutes);
    if (diff.inHours < 24) return l10n.common_hours_short(diff.inHours);
    if (diff.inDays < 7) return l10n.common_days_short(diff.inDays);
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}';
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.isFollowing, required this.onTap});

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (isFollowing) {
      return AppOutlinedButton(
        text: l10n.common_following,
        height: 34,
        borderRadius: 10,
        onTap: onTap,
      );
    }

    return AppButton(
      text: l10n.common_follow,
      height: 34,
      borderRadius: 10,
      onTap: onTap,
    );
  }
}

class _PostPreview extends StatelessWidget {
  const _PostPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final trimmed = url.trim();
    final isAsset = trimmed.startsWith('assets/') || trimmed.startsWith('asset:');
    final assetPath = trimmed.startsWith('asset:') ? trimmed.substring('asset:'.length) : trimmed;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: isAsset
          ? Image.asset(
              assetPath,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _previewFallback(context),
            )
          : Image.network(
              trimmed,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _previewFallback(context),
            ),
    );
  }

  Widget _previewFallback(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      color: context.colors.surfaceSoft,
      child: Icon(
        AppIcons.imageOutlined.icon,
        size: 20,
        color: context.colors.subTextColor.withValues(alpha: 0.6),
      ),
    );
  }
}
