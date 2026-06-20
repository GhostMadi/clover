import 'package:clover/core/extension/context.dart';
import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_avatar.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_banner.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_info.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_account_tags.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/parts/profile_header_shimmer.dart';
import 'package:clover/feature/profile_page/presentation/widget/header_part/profile_header_stat.dart';
import 'package:flutter/material.dart';

/// Верхняя секция профиля: баннер, аватар, статистика, текстовый блок.
///
/// Части лежат в `profile_header/` — по одному виджету на зону экрана.
class ProfileHeaderSection extends StatelessWidget {
  const ProfileHeaderSection({
    super.key,
    this.isLoading = false,
    this.coverImageUrl,
    this.avatarImageUrl,
    this.statFollowers = '0',
    this.statFollowing = '0',
    this.statPosts = '0',
    this.statCollections = '0',
    this.fullName,
    this.username,
    this.category,
    this.bio,
    this.location,
    this.tags = const [],
    this.onFollowersTap,
    this.onFollowingTap,
  });

  final bool isLoading;
  final String? coverImageUrl;
  final String? avatarImageUrl;
  final String statFollowers;
  final String statFollowing;
  final String statPosts;
  final String statCollections;
  final String? fullName;
  final String? username;
  final String? category;
  final String? bio;
  final String? location;
  final List<MarkerTagModel> tags;
  final VoidCallback? onFollowersTap;
  final VoidCallback? onFollowingTap;

  static const double _figmaPaddingH = 16;
  static const double _figmaPaddingTop = 12;
  static const double _figmaPaddingBottom = 16;
  static const double _figmaGapAfterStats = 16;
  static const double _figmaGapBlock = 12;

  const ProfileHeaderSection.loading({super.key})
    : isLoading = true,
      coverImageUrl = null,
      avatarImageUrl = null,
      statFollowers = '0',
      statFollowing = '0',
      statPosts = '0',
      statCollections = '0',
      fullName = null,
      username = null,
      category = null,
      bio = null,
      location = null,
      tags = const [],
      onFollowersTap = null,
      onFollowingTap = null;

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ProfileHeaderShimmer();

    final cover = coverImageUrl?.trim();
    final hasCover = cover != null && cover.isNotEmpty;
    final bioText = bio?.trim();
    final hasBio = bioText != null && bioText.isNotEmpty;
    final locationText = location?.trim();
    final hasLocation = locationText != null && locationText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCover) ProfileHeaderBanner(imageUrl: cover),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.widthByContext(_figmaPaddingH),
            context.heightByContext(_figmaPaddingTop),
            context.widthByContext(_figmaPaddingH),
            context.heightByContext(_figmaPaddingBottom),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProfileHeaderAvatar(imageUrl: avatarImageUrl),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _tappableStat(
                            onTap: onFollowersTap,
                            child: ProfileHeaderStat(value: statFollowers, label: 'Подписчики'),
                          ),
                        ),
                        Expanded(
                          child: _tappableStat(
                            onTap: onFollowingTap,
                            child: ProfileHeaderStat(value: statFollowing, label: 'Подписки'),
                          ),
                        ),
                        Expanded(
                          child: ProfileHeaderStat(value: statPosts, label: 'Публикации'),
                        ),
                        // Expanded(
                        //   child: ProfileHeaderStat(value: statCollections, label: 'Коллекции'),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: context.heightByContext(_figmaGapAfterStats)),
              ProfileHeaderIdentity(fullName: fullName, username: username, category: category),
              if (tags.isNotEmpty) ...[
                SizedBox(height: context.heightByContext(_figmaGapBlock)),
                ProfileHeaderAccountTags(tags: tags),
              ],
              if (hasBio) ...[
                SizedBox(height: context.heightByContext(_figmaGapBlock)),
                ProfileHeaderBio(text: bioText),
              ],
              if (hasLocation) ...[
                SizedBox(height: context.heightByContext(_figmaGapBlock)),
                ProfileHeaderLocation(location: locationText),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget _tappableStat({required VoidCallback? onTap, required Widget child}) {
    if (onTap == null) return child;
    return GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: child);
  }
}
