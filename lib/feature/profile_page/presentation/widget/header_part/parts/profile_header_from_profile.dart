import 'package:clover/feature/profile_page/data/model/profile_new_model.dart';
import 'package:clover/feature/profile_page/presentation/form/profile_page_formatting.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/profile_header_section.dart';
import 'package:flutter/material.dart';

/// [ProfileHeaderSection] из [ProfileNewModel] — одна точка маппинга полей.
class ProfileHeaderFromProfile extends StatelessWidget {
  const ProfileHeaderFromProfile({super.key, required this.profile});

  final ProfileNewModel profile;

  @override
  Widget build(BuildContext context) {
    final rawUsername = profile.username?.trim();
    final username = rawUsername != null && rawUsername.isNotEmpty ? rawUsername : null;

    final rawName = profile.fullName?.trim();
    final fullName = rawName != null && rawName.isNotEmpty ? rawName : null;

    final location = profile.locationLine.trim();
    final locationDisplay = location.isEmpty ? null : location;

    final rawBio = profile.bio?.trim();
    final bio = rawBio != null && rawBio.isNotEmpty ? rawBio : null;

    return ProfileHeaderSection(
      coverImageUrl: profile.backgroundUrl,
      avatarImageUrl: profile.avatarUrl,
      statFollowers: ProfilePageFormatting.statString(profile.followersCount),
      statFollowing: ProfilePageFormatting.statString(profile.followingCount),
      statPosts: ProfilePageFormatting.statString(profile.postCount),
      statCollections: ProfilePageFormatting.statString(profile.clusterCount),
      fullName: fullName,
      username: username,
      category: profile.categoryLabelRu,
      bio: bio,
      location: locationDisplay,
      onFollowersTap: () {
        //   => context.router.root.push(
        //   FollowListsRoute(profileId: profile.id, username: username, initialTabIndex: 0),
        // )
      },
      onFollowingTap: () {
        //    context.router.root.push(
        //   FollowListsRoute(profileId: profile.id, username: username, initialTabIndex: 1),
        // )
      },
    );
  }
}
