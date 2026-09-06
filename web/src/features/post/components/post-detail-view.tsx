"use client";

import { ArrowLeft } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { EventFeedCard } from "@/features/feed/components/event-feed-card";
import { PostClusterMenu } from "@/features/post/components/post-cluster-menu";
import type { FeedPost } from "@/features/post/lib/parse-feed";

type PostDetailViewProps = {
  post: FeedPost;
  currentUserId: string | null;
};

/** Экран поста как в мобилке: шапка «назад» + карточка ленты. */
export function PostDetailView({ post, currentUserId }: PostDetailViewProps) {
  const router = useRouter();
  const [following, setFollowing] = useState(post.myFollowingAuthor);
  const [toggled, setToggled] = useState(false);
  const isOwn = Boolean(currentUserId && currentUserId === post.userId);

  const handleBack = () => {
    if (typeof window !== "undefined" && window.history.length > 1) {
      router.back();
      return;
    }
    router.push(
      currentUserId && currentUserId === post.userId
        ? "/app/profile"
        : post.userId
          ? `/app/u/${post.userId}`
          : "/app",
    );
  };

  const profileHref =
    currentUserId && currentUserId === post.userId
      ? "/app/profile"
      : `/app/u/${post.userId}`;

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-bg md:min-h-dvh">
      <div className="sticky top-0 z-10 border-b border-line bg-surface/95 backdrop-blur-md">
        <div className="mx-auto flex h-12 max-w-[480px] items-center gap-2 px-3 sm:max-w-[520px]">
          <button
            type="button"
            onClick={handleBack}
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink transition hover:bg-bg"
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </button>
          <p className="min-w-0 flex-1 truncate text-[15px] font-bold text-ink">Публикация</p>
          {isOwn ? <PostClusterMenu postId={post.id} ownerId={post.userId} /> : null}
          {post.userId && !isOwn ? (
            <Link href={profileHref} className="truncate text-[13px] font-semibold text-brand">
              Профиль
            </Link>
          ) : null}
        </div>
      </div>

      <div className="mx-auto w-full max-w-[430px] pb-8 sm:max-w-[480px]">
        <EventFeedCard
          post={post}
          currentUserId={currentUserId}
          followingAuthor={following}
          followToggledInSession={toggled}
          onFollowChange={(_authorId, next) => {
            setFollowing(next);
            setToggled(true);
          }}
        />
      </div>
    </div>
  );
}
