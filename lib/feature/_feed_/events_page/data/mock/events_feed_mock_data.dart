import 'package:clover/feature/marker_tags/data/models/marker_tag_model.dart';
import 'package:clover/feature/post/data/models/post_feed_item.dart';
import 'package:clover/feature/post/data/models/post_marker_summary.dart';
import 'package:clover/feature/post/data/models/post_media_model.dart';
import 'package:clover/feature/post/data/models/post_model.dart';

/// Муляжи ивентов для ленты на вкладке «Карта».
abstract final class EventsFeedMockData {
  static List<PostFeedItem> items() {
    final now = DateTime.now();

    return [
      _item(
        id: 'evt-1',
        author: 'aliya.events',
        avatarSeed: 'aliya',
        title: 'Sunset Rooftop Session',
        description:
            'Живая музыка, авторские коктейли и вид на город. Вход по списку до 22:00.',
        likes: 128,
        dislikes: 3,
        comments: 24,
        emoji: '🌇',
        countryCode: 'kz',
        cityCode: 'almaty',
        addressPrimary: 'Esentai Terrace, пр. Аль-Фараби 77/8',
        addressCyrillic: 'Эсентай Терраса',
        eventTime: now.add(const Duration(hours: 5)),
        endTime: now.add(const Duration(hours: 9)),
        coverUrl: 'https://picsum.photos/seed/rooftop__ar-4x3.jpg',
        tags: const ['party', 'networking'],
        following: false,
      ),
      _item(
        id: 'evt-2',
        author: 'studio.nomad',
        avatarSeed: 'nomad',
        title: 'Open Gallery Night',
        description: 'Открытие выставки молодых художников. Бесплатный вход, вино и guided tour.',
        likes: 86,
        dislikes: 1,
        comments: 11,
        emoji: '🎨',
        countryCode: 'kz',
        cityCode: 'almaty',
        addressPrimary: 'ARTиШОК, ул. Курмангазы 97',
        eventTime: now.add(const Duration(days: 1, hours: 2)),
        endTime: now.add(const Duration(days: 1, hours: 6)),
        coverUrl: 'https://picsum.photos/seed/gallery__ar-9x16.jpg',
        extraMediaUrl: 'https://picsum.photos/seed/gallery2__ar-4x3.jpg',
        tags: const ['exhibition', 'festival'],
        following: true,
      ),
      _item(
        id: 'evt-3',
        author: 'runclub.almaty',
        avatarSeed: 'run',
        title: 'Morning City Run 5K',
        description: 'Старт у Mega Alma-Ata. Темп средний, после пробежки — кофе для всех участников.',
        likes: 54,
        dislikes: 0,
        comments: 7,
        emoji: '🏃',
        countryCode: 'kz',
        cityCode: 'almaty',
        addressPrimary: 'MEGA Alma-Ata, парковка P2',
        eventTime: now.add(const Duration(days: 2, hours: 7)),
        endTime: now.add(const Duration(days: 2, hours: 9)),
        coverUrl: 'https://picsum.photos/seed/run__ar-16x9.jpg',
        tags: const ['fitness', 'community'],
        following: false,
      ),
      _item(
        id: 'evt-4',
        author: 'jazz.bar.lite',
        avatarSeed: 'jazz',
        title: 'Live Jazz & Vinyl Market',
        description: 'Квартет + маркет виниловых пластинок. Столики бронируются в директ.',
        likes: 203,
        dislikes: 6,
        comments: 31,
        emoji: '🎷',
        countryCode: 'kz',
        cityCode: 'almaty',
        addressPrimary: 'The Bus, ул. Жибек Жолы 135',
        addressCyrillic: 'The Bus Jazz Bar',
        eventTime: now.add(const Duration(days: 3, hours: 4)),
        endTime: now.add(const Duration(days: 3, hours: 8)),
        coverUrl: 'https://picsum.photos/seed/jazz__ar-4x3.jpg',
        tags: const ['concert', 'bar'],
        following: false,
      ),
      _regularPost(
        id: 'post-1',
        author: 'daily.coffee',
        avatarSeed: 'coffee',
        title: 'Утренний латте',
        description: 'Новый сорт зёрен в меню — попробуйте до конца недели.',
        likes: 42,
        coverUrl: 'https://picsum.photos/seed/coffee__ar-4x3.jpg',
      ),
      _regularPost(
        id: 'post-2',
        author: 'city.views',
        avatarSeed: 'views',
        title: 'Вид с крыши',
        description: 'Закат вчера был нереальный — делюсь кадром.',
        likes: 91,
        coverUrl: 'https://picsum.photos/seed/roofview__ar-1x1.jpg',
      ),
    ];
  }

  static PostFeedItem _regularPost({
    required String id,
    required String author,
    required String avatarSeed,
    required String title,
    required String description,
    required int likes,
    required String coverUrl,
  }) {
    return PostFeedItem(
      post: PostModel(
        id: id,
        userId: 'user-$id',
        title: title,
        description: description,
        likesCount: likes,
        dislikesCount: 0,
        commentsCount: likes ~/ 5,
        savesCount: likes ~/ 6,
        sendsCount: 2,
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        media: [_media(id, coverUrl, 0)],
      ),
      authorUsername: author,
      authorAvatarUrl: 'https://i.pravatar.cc/150?u=$avatarSeed',
    );
  }

  static PostFeedItem _item({
    required String id,
    required String author,
    required String avatarSeed,
    required String title,
    required String description,
    required int likes,
    required int dislikes,
    required int comments,
    required String emoji,
    required String countryCode,
    required String cityCode,
    required String addressPrimary,
    String? addressCyrillic,
    required DateTime eventTime,
    required DateTime endTime,
    required String coverUrl,
    String? extraMediaUrl,
    required List<String> tags,
    required bool following,
  }) {
    final media = <PostMediaModel>[
      _media(id, coverUrl, 0),
      if (extraMediaUrl != null) _media(id, extraMediaUrl, 1),
    ];

    return PostFeedItem(
      post: PostModel(
        id: id,
        userId: 'user-$id',
        markerId: 'marker-$id',
        title: title,
        description: description,
        likesCount: likes,
        dislikesCount: dislikes,
        commentsCount: comments,
        savesCount: likes ~/ 4,
        sendsCount: comments ~/ 2,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        media: media,
      ),
      authorUsername: author,
      authorAvatarUrl: 'https://i.pravatar.cc/150?u=$avatarSeed',
      myReaction: likes.isEven ? 'like' : null,
      myFollowingAuthor: following,
      marker: PostMarkerSummary(
        id: 'marker-$id',
        textEmoji: emoji,
        addressPrimary: addressPrimary,
        addressCyrillic: addressCyrillic,
        countryCode: countryCode,
        cityCode: cityCode,
        eventTime: eventTime,
        endTime: endTime,
        status: 'active',
        tags: [for (final key in tags) MarkerTagModel(id: '$id-$key', key: key)],
      ),
    );
  }

  static PostMediaModel _media(String postId, String url, int sortOrder) {
    return PostMediaModel(
      id: '${postId}_m$sortOrder',
      postId: postId,
      url: url,
      sortOrder: sortOrder,
    );
  }
}
