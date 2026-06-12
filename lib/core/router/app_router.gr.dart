// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i11;
import 'package:clover/feature/auth/login/presentation/page/login_page.dart'
    as _i2;
import 'package:clover/feature/auth/presentation/page/root_page.dart' as _i10;
import 'package:clover/feature/dashboard_page/presentation/page/app_dashboard.dart'
    as _i1;
import 'package:clover/feature/map_page/presentation/page/map_page.dart' as _i3;
import 'package:clover/feature/message_page/presentation/page/message_page.dart'
    as _i4;
import 'package:clover/feature/post/data/models/post_model.dart' as _i13;
import 'package:clover/feature/post/presentation/page/post_page.dart' as _i8;
import 'package:clover/feature/post_create/presentation/page/create_post.dart'
    as _i7;
import 'package:clover/feature/post_create/presentation/page/post_create_compose_page.dart'
    as _i5;
import 'package:clover/feature/post_create/presentation/page/post_create_editor_page.dart'
    as _i6;
import 'package:clover/feature/profile_page/presentation/page/profile_page.dart'
    as _i9;
import 'package:flutter/material.dart' as _i12;

/// generated route for
/// [_i1.AppDashboardPage]
class AppDashboardRoute extends _i11.PageRouteInfo<void> {
  const AppDashboardRoute({List<_i11.PageRouteInfo>? children})
    : super(AppDashboardRoute.name, initialChildren: children);

  static const String name = 'AppDashboardRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i1.AppDashboardPage();
    },
  );
}

/// generated route for
/// [_i2.LoginPage]
class LoginRoute extends _i11.PageRouteInfo<void> {
  const LoginRoute({List<_i11.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i2.LoginPage();
    },
  );
}

/// generated route for
/// [_i3.MapPage]
class MapRoute extends _i11.PageRouteInfo<void> {
  const MapRoute({List<_i11.PageRouteInfo>? children})
    : super(MapRoute.name, initialChildren: children);

  static const String name = 'MapRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i3.MapPage();
    },
  );
}

/// generated route for
/// [_i4.MessagePage]
class MessageRoute extends _i11.PageRouteInfo<void> {
  const MessageRoute({List<_i11.PageRouteInfo>? children})
    : super(MessageRoute.name, initialChildren: children);

  static const String name = 'MessageRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i4.MessagePage();
    },
  );
}

/// generated route for
/// [_i5.PostCreateComposePage]
class PostCreateComposeRoute extends _i11.PageRouteInfo<void> {
  const PostCreateComposeRoute({List<_i11.PageRouteInfo>? children})
    : super(PostCreateComposeRoute.name, initialChildren: children);

  static const String name = 'PostCreateComposeRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i5.PostCreateComposePage();
    },
  );
}

/// generated route for
/// [_i6.PostCreateEditorPage]
class PostCreateEditorRoute extends _i11.PageRouteInfo<void> {
  const PostCreateEditorRoute({List<_i11.PageRouteInfo>? children})
    : super(PostCreateEditorRoute.name, initialChildren: children);

  static const String name = 'PostCreateEditorRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i6.PostCreateEditorPage();
    },
  );
}

/// generated route for
/// [_i7.PostCreatePage]
class PostCreateRoute extends _i11.PageRouteInfo<void> {
  const PostCreateRoute({List<_i11.PageRouteInfo>? children})
    : super(PostCreateRoute.name, initialChildren: children);

  static const String name = 'PostCreateRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i7.PostCreatePage();
    },
  );
}

/// generated route for
/// [_i8.PostPage]
class PostRoute extends _i11.PageRouteInfo<PostRouteArgs> {
  PostRoute({
    _i12.Key? key,
    required String postId,
    _i13.PostModel? initialPost,
    List<_i11.PageRouteInfo>? children,
  }) : super(
         PostRoute.name,
         args: PostRouteArgs(
           key: key,
           postId: postId,
           initialPost: initialPost,
         ),
         initialChildren: children,
       );

  static const String name = 'PostRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<PostRouteArgs>();
      return _i8.PostPage(
        key: args.key,
        postId: args.postId,
        initialPost: args.initialPost,
      );
    },
  );
}

class PostRouteArgs {
  const PostRouteArgs({this.key, required this.postId, this.initialPost});

  final _i12.Key? key;

  final String postId;

  final _i13.PostModel? initialPost;

  @override
  String toString() {
    return 'PostRouteArgs{key: $key, postId: $postId, initialPost: $initialPost}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PostRouteArgs) return false;
    return key == other.key &&
        postId == other.postId &&
        initialPost == other.initialPost;
  }

  @override
  int get hashCode => key.hashCode ^ postId.hashCode ^ initialPost.hashCode;
}

/// generated route for
/// [_i9.ProfilePage]
class ProfileRoute extends _i11.PageRouteInfo<void> {
  const ProfileRoute({List<_i11.PageRouteInfo>? children})
    : super(ProfileRoute.name, initialChildren: children);

  static const String name = 'ProfileRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i9.ProfilePage();
    },
  );
}

/// generated route for
/// [_i10.RootPage]
class RootRoute extends _i11.PageRouteInfo<void> {
  const RootRoute({List<_i11.PageRouteInfo>? children})
    : super(RootRoute.name, initialChildren: children);

  static const String name = 'RootRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i10.RootPage();
    },
  );
}
