import 'package:auto_route/auto_route.dart';
import 'package:clover/core/dependencies/get_it.dart';
import 'package:clover/core/resources/colors.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/core/shared/app_button.dart';
import 'package:clover/core/shared/app_refresh.dart';
import 'package:clover/feature/_archive_/shared/presentation/widget/archive_post_grid_shimmer.dart';
import 'package:clover/feature/_archive_/event_archive/presentation/cubit/event_archive_cubit.dart';
import 'package:clover/feature/_post_/post/data/models/post_archive_context.dart';
import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_grid.dart';
import 'package:clover/feature/_settings_/settings/presentation/widget/settings_screen_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@RoutePage()
class EventArchivePage extends StatefulWidget {
  const EventArchivePage({super.key});

  @override
  State<EventArchivePage> createState() => _EventArchivePageState();
}

class _EventArchivePageState extends State<EventArchivePage> {
  late final EventArchiveCubit _cubit;
  final String? _uid = Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _cubit = sl<EventArchiveCubit>();
    final uid = _uid?.trim();
    if (uid != null && uid.isNotEmpty) {
      _cubit.load(uid);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    final uid = _uid?.trim();
    if (uid == null || uid.isEmpty) return;
    await _cubit.load(uid);
  }

  Future<void> _openPost(PostFeedItem item) async {
    final refreshed = await context.router.push<bool>(
      PostRoute(
        postId: item.post.id,
        initialPost: item.post,
        initialMarker: item.marker,
        archiveContext: PostArchiveContext.event,
      ),
    );
    if (refreshed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: SettingsScreenShell(
        title: 'Архив ивентов',
        body: AppRefresh(
          onRefresh: _refresh,
          child: BlocBuilder<EventArchiveCubit, EventArchiveState>(
            builder: (context, state) {
              return switch (state) {
                EventArchiveInitial() || EventArchiveLoading() => const ArchivePostGridShimmer(),
                EventArchiveError(:final message) => _ArchiveError(message: message, onRetry: _refresh),
                EventArchiveLoaded(:final items) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(3, 8, 3, SettingsScreenShell.scrollBottomGap(context)),
                  child: PostGrid(
                    posts: items.map((e) => e.post).toList(growable: false),
                    emptyMessage: 'Архив ивентов пуст',
                    onPostTap: (post) {
                      for (final item in items) {
                        if (item.post.id == post.id) {
                          _openPost(item);
                          return;
                        }
                      }
                    },
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

class _ArchiveError extends StatelessWidget {
  const _ArchiveError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.colors.subTextColor)),
          const SizedBox(height: 12),
          AppButton(text: 'Повторить', onTap: onRetry),
        ],
      ),
    );
  }
}
