import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/deep_link/app_deep_link_navigator.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/_booking_/booking_points/data/booking_point_nav.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/_feed_/notification_page/data/models/notification_kind.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/cubit/notifications_cubit.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/utils/notification_date_grouping.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/widget/notification_section_header.dart';
import 'package:clover/feature/_feed_/notification_page/presentation/widget/notification_tile.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsCubit _cubit;
  late final ScrollController _scrollController;

  static const _loadMoreThreshold = 320.0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<NotificationsCubit>()..load();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _cubit.loadMore();
    }
  }

  void _schedulePrefetchCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  Future<void> _openNotification(NotificationItem item) async {
    final postId = item.postId?.trim();
    if (postId != null && postId.isNotEmpty) {
      await context.router.push(PostRoute(postId: postId));
      return;
    }

    final bookingId = item.bookingId?.trim();
    if (bookingId != null && bookingId.isNotEmpty) {
      await sl<AppDeepLinkNavigator>().openBookingById(context.router, bookingId);
      return;
    }

    if (item.kind.isBookingHostInbox) {
      final pointId = await resolveBookingPointIdForNav();
      if (!mounted) return;
      await context.router.push(BookingListRoute(pointId: pointId));
      return;
    }

    if (item.kind.isBookingClientInbox) {
      await context.router.push(const MyBookingsRoute());
      return;
    }

    if (item.showFollowButton) {
      final userId = item.actors.isNotEmpty ? item.actors.first.id.trim() : '';
      if (userId.isNotEmpty) {
        await context.router.push(GuestProfileRoute(userId: userId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<NotificationsCubit, NotificationsState>(
        listenWhen: (previous, current) {
          final prev = previous is NotificationsLoaded ? previous : null;
          final next = current is NotificationsLoaded ? current : null;
          if (next == null) return false;
          return prev?.items.length != next.items.length ||
              prev?.isLoadingMore != next.isLoadingMore ||
              prev?.hasMore != next.hasMore;
        },
        listener: (context, state) {
          if (state is NotificationsLoaded && state.hasMore && !state.isLoadingMore) {
            _schedulePrefetchCheck();
          }
        },
        child: SettingsScreenShell(
          title: 'Уведомления',
          body: BlocBuilder<NotificationsCubit, NotificationsState>(
            builder: (context, state) {
              return switch (state) {
                NotificationsInitial() || NotificationsLoading() => Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
                ),
                NotificationsError(:final message) => _NotificationsError(
                  message: message,
                  onRetry: _cubit.load,
                ),
                NotificationsLoaded(:final items, :final hasMore, :final isLoadingMore) => _LoadedBody(
                  items: items,
                  hasMore: hasMore,
                  isLoadingMore: isLoadingMore,
                  scrollController: _scrollController,
                  onRefresh: _cubit.refresh,
                  onOpen: _openNotification,
                  onFollowToggle: _cubit.toggleFollow,
                  onLoginConfirm: _cubit.confirmLogin,
                  onLoginRevoke: _cubit.revokeLogin,
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
    required this.scrollController,
    required this.onRefresh,
    required this.onOpen,
    required this.onFollowToggle,
    required this.onLoginConfirm,
    required this.onLoginRevoke,
  });

  final List<NotificationItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final Future<void> Function(NotificationItem item) onOpen;
  final Future<void> Function(NotificationItem item) onFollowToggle;
  final Future<void> Function(NotificationItem item) onLoginConfirm;
  final Future<void> Function(NotificationItem item) onLoginRevoke;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppRefresh(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Уведомлений нет',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: context.colors.subTextColor),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final sections = NotificationDateGrouping.group(items);
    final bottomGap = SettingsScreenShell.scrollBottomGap(context);
    final extraItems = (isLoadingMore ? 1 : 0) + (!hasMore && !isLoadingMore ? 1 : 0);

    return AppRefresh(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: bottomGap),
        itemCount: _listItemCount(sections) + extraItems,
        itemBuilder: (context, index) {
          final contentCount = _listItemCount(sections);
          if (index < contentCount) {
            return _buildListItem(
              context,
              sections,
              index,
              onOpen,
              onFollowToggle,
              onLoginConfirm,
              onLoginRevoke,
            );
          }

          if (isLoadingMore && index == contentCount) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Text(
              'Показаны уведомления за последние 30 дней',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: context.colors.subTextColor),
            ),
          );
        },
      ),
    );
  }

  int _listItemCount(List<(NotificationDateSection, List<NotificationItem>)> sections) {
    var count = 0;
    for (final (_, sectionItems) in sections) {
      count += 1 + sectionItems.length;
    }
    return count;
  }

  Widget _buildListItem(
    BuildContext context,
    List<(NotificationDateSection, List<NotificationItem>)> sections,
    int index,
    Future<void> Function(NotificationItem item) onOpen,
    Future<void> Function(NotificationItem item) onFollowToggle,
    Future<void> Function(NotificationItem item) onLoginConfirm,
    Future<void> Function(NotificationItem item) onLoginRevoke,
  ) {
    var cursor = 0;
    for (final (section, sectionItems) in sections) {
      if (index == cursor) {
        return NotificationSectionHeader(title: NotificationDateGrouping.title(section));
      }
      cursor++;

      for (var i = 0; i < sectionItems.length; i++) {
        if (index == cursor) {
          final item = sectionItems[i];
          final showDivider = i < sectionItems.length - 1;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NotificationTile(
                item: item,
                onTap: item.postId != null || item.showFollowButton || item.bookingId != null
                    ? () => onOpen(item)
                    : null,
                onFollowToggle: item.showFollowButton ? (_) => onFollowToggle(item) : null,
                onLoginConfirm: item.showLoginActions ? () => onLoginConfirm(item) : null,
                onLoginRevoke: item.showLoginActions ? () => onLoginRevoke(item) : null,
                onLoginChangePassword: item.showLoginActions
                    ? () => context.router.push(const SettingsPasswordRoute())
                    : null,
              ),
              if (showDivider) Divider(height: 1, thickness: 1, color: context.colors.divider),
            ],
          );
        }
        cursor++;
      }
    }

    return const SizedBox.shrink();
  }
}

class _NotificationsError extends StatelessWidget {
  const _NotificationsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.errorOutline.icon, size: 48, color: context.colors.iconMuted),
            SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(16, color: context.colors.textColor, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: context.colors.primary),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
