import { PostsGrid } from "@/features/post/components/posts-grid";
import { toGridPosts } from "@/features/post/lib/grid-post";
import type { FeedPost } from "@/features/post/lib/parse-feed";

/** Сетка публикаций профиля. */
export function ProfilePostsGrid({ posts }: { posts: FeedPost[] }) {
  if (posts.length === 0) {
    return (
      <div className="py-12 text-center sm:py-16">
        <p className="text-sm font-semibold text-ink">Пока нет публикаций</p>
        <p className="mt-1 text-sm text-muted">Добавь первую в приложении Clover</p>
      </div>
    );
  }

  return <PostsGrid posts={toGridPosts(posts)} />;
}
