import 'package:clover/feature/_post_/post/data/models/post_feed_item.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_booking_service_section.dart';
import 'package:clover/feature/_post_/post/presentation/widget/post_marker_info_section.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Текстовый блок карточки поста под медиа — как на [PostPage].
class PostFeedCardDetails extends StatelessWidget {
  const PostFeedCardDetails({
    super.key,
    required this.item,
    this.showBookingSection = true,
    this.isMarkerLoading = false,
    this.isBookingServiceLoading = false,
  });

  final PostFeedItem item;
  final bool showBookingSection;
  final bool isMarkerLoading;
  final bool isBookingServiceLoading;

  @override
  Widget build(BuildContext context) {
    final post = item.post;
    final title = post.title?.trim();
    final description = post.description?.trim();
    final username = item.authorUsername?.trim();
    final hostLabel = (username != null && username.isNotEmpty) ? username : 'Хост';

    final uid = Supabase.instance.client.auth.currentUser?.id.trim();
    final isOwnPost = uid != null && uid.isNotEmpty && post.userId.trim() == uid;
    final showBooking = showBookingSection && (item.hasBookingService || item.bookingService != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PostMarkerInfoSection(
          marker: item.marker,
          title: title,
          description: description,
          username: username,
          likesCount: post.likesCount,
          dislikesCount: post.dislikesCount,
          isMarkerLoading: isMarkerLoading,
          profileFilters: item.profileFilters,
          postTextEmoji: post.textEmoji,
          postTags: post.tags,
          postAddressPrimary: post.addressPrimary,
          postAddressCyrillic: post.addressCyrillic,
          postCountryCode: post.countryCode,
          postCityCode: post.cityCode,
        ),
        if (showBooking)
          PostBookingServiceSection(
            hostId: post.userId,
            hostDisplayName: hostLabel,
            service: item.bookingService,
            isLoading: isBookingServiceLoading || item.isBookingServicePayloadPending,
            showBookAction: !isOwnPost,
          ),
      ],
    );
  }
}
