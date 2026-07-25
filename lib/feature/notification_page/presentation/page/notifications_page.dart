import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/notification_page/data/models/notification_item.dart';
import 'package:clover/feature/notification_page/presentation/cubit/notifications_cubit.dart';
import 'package:clover/feature/notification_page/presentation/utils/notification_date_grouping.dart';
import 'package:clover/feature/notification_page/presentation/widget/notification_section_header.dart';
import 'package:clover/feature/notification_page/presentation/widget/notification_tile.dart';
import 'package:clover/feature/settings/presentation/widget/settings_screen_shell.dart';
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

  Future<void> _openPost(NotificationItem item) async {
    final postId = item.postId?.trim();
    if (postId == null || postId.isEmpty) return;
    await context.router.push(PostRoute(postId: postId));
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
                NotificationsInitial() || NotificationsLoading() => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
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
                  onOpen: _openPost,
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
  });

  final List<NotificationItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final Future<void> Function(NotificationItem item) onOpen;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppRefresh(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Уведомлений пока нет',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, color: AppColors.subTextColor),
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
            return _buildListItem(sections, index, onOpen);
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
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Text(
              'Больше уведомлений нет',
              textAlign: TextAlign.center,
              style: AppTextStyle.base(13, color: AppColors.subTextColor),
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
    List<(NotificationDateSection, List<NotificationItem>)> sections,
    int index,
    Future<void> Function(NotificationItem item) onOpen,
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
              NotificationTile(item: item, onTap: item.postId != null ? () => onOpen(item) : null),
              if (showDivider) const Divider(height: 1, thickness: 1, color: AppColors.divider),
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.iconMuted),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.base(16, color: AppColors.textColor, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
