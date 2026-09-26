import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/app_icons.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/shared/app_bottom_sheet.dart';
import 'package:clover/core/shared/app_functional_button/app_functional_screen.dart';
import 'package:clover/core/shared/app_functional_button/functional_button_item.dart';
import 'package:clover/core/shared/app_state.dart';
import 'package:clover/feature/_catalog_/social_graph/data/repository/social_graph_repository.dart';
import 'package:clover/feature/_feed_/map_page/data/models/map_marker_item.dart';
import 'package:clover/feature/_feed_/map_page/presentation/cubit/map_marker_stack_feed_cubit.dart';
import 'package:clover/feature/_feed_/map_page/presentation/widget/map_marker_stack_feed_item.dart';
import 'package:clover/feature/_post_/post/data/repository/post_repository.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_feed_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:clover/core/extension/context.dart';

/// Шторка стопки: вертикальная лента постов (как events feed).
abstract final class MapMarkerGroupSheet {
  static Future<void> show(BuildContext context, {required List<MapMarkerItem> markers}) {
    final height = MediaQuery.sizeOf(context).height * 0.86;

    return AppBottomSheet.show<void>(
      context: context,
      upperCaseTitle: false,
      showCloseButton: false,
      postFeedSurface: true,
      contentHeight: height,
      expandBody: true,
      contentPadding: EdgeInsets.zero,
      contentBottomSpacing: 0,
      sheetOuterPadding: const EdgeInsets.fromLTRB(12, 80, 12, 12),
      content: _MapMarkerStackFeedBody(markers: markers),
    );
  }
}

class _MapMarkerStackFeedBody extends StatefulWidget {
  const _MapMarkerStackFeedBody({required this.markers});

  final List<MapMarkerItem> markers;

  @override
  State<_MapMarkerStackFeedBody> createState() => _MapMarkerStackFeedBodyState();
}

class _MapMarkerStackFeedBodyState extends State<_MapMarkerStackFeedBody> {
  late final MapMarkerStackFeedCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = MapMarkerStackFeedCubit(
      sl<PostRepository>(),
      sl<SocialGraphRepository>(),
      Supabase.instance.client,
    )..load(widget.markers);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  List<FunctionalButtonItem> get _backButton => [
        FunctionalButtonItem(
          icon: AppIcons.back.icon,
          keepWhenCollapsed: true,
          customColor: context.colors.primary,
          iconColor: context.colors.textInverse,
          onTap: _close,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<MapMarkerStackFeedCubit, MapMarkerStackFeedState>(
        builder: (context, state) {
          final bottomGap = AppFunctionalScreen.scrollBottomClearance(context);

          return AppFunctionalScreen(
            collapsed: true,
            collapsedBarWidthPerButton: 150,
            backgroundColor: context.colors.pageBackground,
            buttons: _backButton,
            body: switch (state) {
              MapMarkerStackFeedInitial() || MapMarkerStackFeedLoading() => const PostFeedShimmer(),
              MapMarkerStackFeedError(:final message) => AppState(
                state: AppScreenState.error,
                variant: AppStateVariant.inline,
                errorMessage: message,
                onRetry: () => _cubit.load(widget.markers),
                child: const SizedBox.shrink(),
              ),
              MapMarkerStackFeedLoaded(:final items) when items.isEmpty => AppState(
                state: AppScreenState.empty,
                variant: AppStateVariant.inline,
                emptyTitle: context.l10n.feed_map_empty_posts,
                child: const SizedBox.shrink(),
              ),
              MapMarkerStackFeedLoaded(:final items) => ListView.separated(
                padding: EdgeInsets.only(bottom: bottomGap),
                itemCount: items.length,
                separatorBuilder: (_, __) => ColoredBox(
                  color: context.colors.pageBackground,
                  child: const SizedBox(height: 10),
                ),
                itemBuilder: (context, index) => MapMarkerStackFeedItem(item: items[index]),
              ),
            },
          );
        },
      ),
    );
  }
}
