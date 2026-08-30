import 'package:auto_route/auto_route.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/resources/style.dart';
import 'package:clover/core/shared/app_nav_bar/app_nav_bar.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/_feed_/events_page/data/models/events_filter.dart';
import 'package:clover/feature/_feed_/events_page/presentation/cubit/events_feed_cubit.dart';
import 'package:clover/feature/_feed_/events_page/presentation/scope/events_feed_filter_scope.dart';
import 'package:clover/feature/_feed_/events_page/presentation/widget/event_feed_post_item.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late final EventsFeedCubit _cubit;
  late final ScrollController _scrollController;
  EventsFilter? _lastFilter;

  static const _loadMoreThreshold = 320.0;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EventsFeedCubit>();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final filter = EventsFeedFilterScope.of(context);
    if (_lastFilter != filter) {
      _lastFilter = filter;
      _cubit.load(filter);
    }
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

  @override
  Widget build(BuildContext context) {
    final bottomGap = AppNavBar.scrollBottomClearance(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<EventsFeedCubit, EventsFeedState>(
        listenWhen: (previous, current) {
          final prev = previous.mapOrNull(loaded: (s) => s);
          final next = current.mapOrNull(loaded: (s) => s);
          if (next == null) return false;
          return prev?.items.length != next.items.length ||
              prev?.isLoadingMore != next.isLoadingMore ||
              prev?.hasMore != next.hasMore;
        },
        listener: (context, state) {
          state.mapOrNull(
            loaded: (s) {
              if (s.hasMore && !s.isLoadingMore) _schedulePrefetchCheck();
            },
          );
        },
        child: Scaffold(
          backgroundColor: context.colors.pageBackground,
          body: BlocBuilder<EventsFeedCubit, EventsFeedState>(
            builder: (context, state) {
              final isLoading = state.maybeMap(
                loading: (_) => true,
                initial: (_) => true,
                orElse: () => false,
              );
              final isRefreshing = state.maybeMap(loaded: (s) => s.isRefreshing, orElse: () => false);
              final isLoadingMore = state.maybeMap(loaded: (s) => s.isLoadingMore, orElse: () => false);
              final hasMore = state.maybeMap(loaded: (s) => s.hasMore, orElse: () => false);
              final items = state.maybeMap(loaded: (s) => s.items, orElse: () => const <PostFeedItem>[]);
              final errorMessage = state.maybeMap(error: (s) => s.message, orElse: () => null);

              return AppRefresh(
                onRefresh: _cubit.refresh,
                child: CustomScrollView(
                  controller: _scrollController,
                  physics: AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      title: Text(
                        'События',
                        style: AppTextStyle.base(20, color: context.colors.textColor, fontWeight: FontWeight.w500),
                      ),
                      centerTitle: true,
                      floating: true,
                      snap: true,
                      pinned: false,
                      backgroundColor: context.colors.pageBackground,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                    ),
                    if (isLoading)
                      SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator(color: context.colors.primary)),
                      )
                    else if (errorMessage != null)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EventsFeedError(
                          message: errorMessage,
                          onRetry: () => _cubit.load(_lastFilter ?? EventsFilter.defaults),
                        ),
                      )
                    else if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Ничего не найдено\nПопробуйте изменить фильтр',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: context.colors.subTextColor, height: 1.4),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      if (isRefreshing)
                        SliverToBoxAdapter(
                          child: LinearProgressIndicator(minHeight: 2, color: context.colors.primary),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: bottomGap),
                        sliver: SliverList.separated(
                          itemCount: items.length + (isLoadingMore ? 1 : 0),
                          separatorBuilder: (context, index) =>
                              ColoredBox(color: context.colors.pageBackground, child: SizedBox(height: 10)),
                          itemBuilder: (context, index) {
                            if (index >= items.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            return EventFeedPostItem(item: items[index]);
                          },
                        ),
                      ),
                      if (!hasMore && !isLoadingMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(24, 8, 24, 24),
                            child: Text(
                              'Больше публикаций нет',
                              textAlign: TextAlign.center,
                              style: AppTextStyle.base(13, color: context.colors.subTextColor),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EventsFeedError extends StatelessWidget {
  const _EventsFeedError({required this.message, required this.onRetry});

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
