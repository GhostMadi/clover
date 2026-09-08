import 'package:auto_route/auto_route.dart';
import 'package:clover/core/router/app_router.gr.dart';
import 'package:clover/feature/_profile_/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/form/profile_page_formatting.dart';
import 'package:clover/feature/_profile_/profile_page/presentation/widget/header_part/profile_header_section.dart';
import 'package:flutter/material.dart';

/// [ProfileHeaderSection] из [ProfileNewModel] — одна точка маппинга полей.
class ProfileHeaderFromProfile extends StatelessWidget {
  const ProfileHeaderFromProfile({
    super.key,
    required this.profile,
    this.showServicePowerTags = true,
  });

  final ProfileNewModel profile;

  /// Силовые теги (`admin` / `worker`, цвет сервиса) — только на **своём** профиле.
  final bool showServicePowerTags;

  @override
  Widget build(BuildContext context) {
    final rawUsername = profile.username?.trim();
    final username = rawUsername != null && rawUsername.isNotEmpty ? rawUsername : null;

    final rawName = profile.fullName?.trim();
    final fullName = rawName != null && rawName.isNotEmpty ? rawName : null;

    final location = ProfilePageFormatting.locationLine(profile).trim();
    final locationDisplay = location.isEmpty ? null : location;

    final rawBio = profile.bio?.trim();
    final bio = rawBio != null && rawBio.isNotEmpty ? rawBio : null;

    final tags = showServicePowerTags
        ? profile.tags
        : profile.tags.where((tag) => tag.serviceKind == null).toList(growable: false);

    return ProfileHeaderSection(
      coverImageUrl: profile.backgroundUrl,
      avatarImageUrl: profile.avatarUrl,
      statFollowers: ProfilePageFormatting.statString(profile.followersCount),
      statFollowing: ProfilePageFormatting.statString(profile.followingCount),
      statPosts: ProfilePageFormatting.statString(profile.postCount),
      statCollections: ProfilePageFormatting.statString(profile.clusterCount),
      fullName: fullName,
      username: username,
      bio: bio,
      location: locationDisplay,
      tags: tags,
      onFollowersTap: () {
        context.router.root.push(
          FollowersAndFollowingsRoute(
            profileId: profile.id,
            username: username,
            initialTabIndex: 1,
          ),
        );
      },
      onFollowingTap: () {
        context.router.root.push(
          FollowersAndFollowingsRoute(
            profileId: profile.id,
            username: username,
            initialTabIndex: 0,
          ),
        );
      },
    );
  }
}
