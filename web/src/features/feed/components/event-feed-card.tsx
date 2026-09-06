"use client";

import {
  Bookmark,
  Heart,
  MessageCircle,
  Send,
  ThumbsDown,
  User,
} from "lucide-react";
import Link from "next/link";
import { useState, useTransition } from "react";
import { followUser, unfollowUser } from "@/features/catalog/lib/social-api";
import { CommentsSheet } from "@/features/post/components/comments-sheet";
import { PostFeedDetails } from "@/features/post/components/post-feed-details";
import { PostMediaCarousel } from "@/features/post/components/post-media-carousel";
import type { FeedPost } from "@/features/post/lib/parse-feed";
import { setPostReaction, setPostSaved } from "@/features/post/lib/reactions-api";

function countLabel(n: number): string | null {
  return n > 0 ? String(n) : null;
}

function ReactionBtn({
  active,
  danger,
  label,
  onClick,
  children,
}: {
  active?: boolean;
  danger?: boolean;
  label?: string | null;
  onClick?: () => void;
  children: React.ReactNode;
}) {
  const color = active ? (danger ? "text-destructive" : "text-ink") : "text-ink";
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex items-center gap-1 rounded-xl px-2 py-1.5 text-[13px] font-semibold ${color}`}
    >
      {children}
      {label ? <span>{label}</span> : null}
    </button>
  );
}

type EventFeedCardProps = {
  post: FeedPost;
  currentUserId: string | null;
  followingAuthor: boolean;
  /** Как в мобилке: «Отписаться» только после действия в этой сессии. */
  followToggledInSession: boolean;
  onFollowChange: (authorId: string, following: boolean) => void;
};

/**
 * Карточка ленты 1:1 по структуре EventFeedPostItem:
 * author (+ follow) → media → reactions → details.
 */
export function EventFeedCard({
  post: initial,
  currentUserId,
  followingAuthor,
  followToggledInSession,
  onFollowChange,
}: EventFeedCardProps) {
  const [post, setPost] = useState(initial);
  const [followBusy, setFollowBusy] = useState(false);
  const [commentsOpen, setCommentsOpen] = useState(false);
  const [, startTransition] = useTransition();
  const authorName = post.authorUsername?.trim() || "noName";
  const liked = post.myReaction === "like";
  const disliked = post.myReaction === "dislike";
  const title = post.title?.trim() ?? "";
  const emoji = post.textEmoji?.trim() ?? "";
  const profileHref = `/app/u/${post.userId}`;
  const isOwn = Boolean(currentUserId && currentUserId === post.userId);
  const showFollow =
    Boolean(currentUserId) && !isOwn && (!followingAuthor || followToggledInSession);

  const toggleLike = () => {
    const next = liked ? null : "like";
    const prev = post;
    setPost({
      ...post,
      myReaction: next,
      likesCount: Math.max(0, post.likesCount + (next === "like" ? 1 : liked ? -1 : 0)),
      dislikesCount: Math.max(0, post.dislikesCount + (disliked && next === "like" ? -1 : 0)),
    });
    startTransition(async () => {
      try {
        await setPostReaction(post.id, next);
      } catch {
        setPost(prev);
      }
    });
  };

  const toggleDislike = () => {
    const next = disliked ? null : "dislike";
    const prev = post;
    setPost({
      ...post,
      myReaction: next,
      dislikesCount: Math.max(0, post.dislikesCount + (next === "dislike" ? 1 : disliked ? -1 : 0)),
      likesCount: Math.max(0, post.likesCount + (liked && next === "dislike" ? -1 : 0)),
    });
    startTransition(async () => {
      try {
        await setPostReaction(post.id, next);
      } catch {
        setPost(prev);
      }
    });
  };

  const toggleSave = () => {
    const next = !post.mySaved;
    const prev = post;
    setPost({ ...post, mySaved: next });
    startTransition(async () => {
      try {
        await setPostSaved(post.id, next);
      } catch {
        setPost(prev);
      }
    });
  };

  const toggleFollow = () => {
    if (followBusy || !showFollow) return;
    const next = !followingAuthor;
    setFollowBusy(true);
    onFollowChange(post.userId, next);
    startTransition(async () => {
      try {
        if (next) await followUser(post.userId);
        else await unfollowUser(post.userId);
      } catch {
        onFollowChange(post.userId, !next);
      } finally {
        setFollowBusy(false);
      }
    });
  };

  return (
    <article className="w-full bg-surface">
      <header className="flex items-center gap-3 px-5 py-3">
        <Link
          href={profileHref}
          className="h-11 w-11 shrink-0 overflow-hidden rounded-full border border-line bg-surface-soft"
        >
          {post.authorAvatarUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={post.authorAvatarUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            <div className="flex h-full w-full items-center justify-center">
              <User className="h-5 w-5 text-muted" strokeWidth={1.5} />
            </div>
          )}
        </Link>
        <Link href={profileHref} className="min-w-0 flex-1 truncate text-[15px] font-bold leading-snug text-ink">
          {authorName}
        </Link>
        {showFollow ? (
          followingAuthor ? (
            <button
              type="button"
              disabled={followBusy}
              onClick={toggleFollow}
              className="h-10 shrink-0 rounded-[14px] border border-line px-3.5 text-[13px] font-bold text-ink transition hover:bg-bg disabled:opacity-60"
            >
              Отписаться
            </button>
          ) : (
            <button
              type="button"
              disabled={followBusy}
              onClick={toggleFollow}
              className="h-10 shrink-0 rounded-[14px] bg-brand px-3.5 text-[13px] font-bold text-on-brand transition hover:opacity-90 disabled:opacity-60"
            >
              Подписаться
            </button>
          )
        ) : null}
      </header>

      <PostMediaCarousel media={post.media} title={title} fallbackEmoji={emoji || "☘️"} />

      <div className="flex items-center px-3 pt-2.5">
        <ReactionBtn danger active={liked} label={countLabel(post.likesCount)} onClick={toggleLike}>
          <Heart className={`h-[22px] w-[22px] ${liked ? "fill-current" : ""}`} strokeWidth={1.75} />
        </ReactionBtn>
        <ReactionBtn active={disliked} label={countLabel(post.dislikesCount)} onClick={toggleDislike}>
          <ThumbsDown className={`h-[22px] w-[22px] ${disliked ? "fill-current" : ""}`} strokeWidth={1.75} />
        </ReactionBtn>
        <div className="flex-1" />
        <ReactionBtn
          label={countLabel(post.commentsCount)}
          onClick={() => setCommentsOpen(true)}
        >
          <MessageCircle className="h-[22px] w-[22px]" strokeWidth={1.75} />
        </ReactionBtn>
        <ReactionBtn label={countLabel(post.sendsCount)}>
          <Send className="h-[22px] w-[22px]" strokeWidth={1.75} />
        </ReactionBtn>
        <ReactionBtn active={post.mySaved} onClick={toggleSave}>
          <Bookmark className={`h-[22px] w-[22px] ${post.mySaved ? "fill-current" : ""}`} strokeWidth={1.75} />
        </ReactionBtn>
      </div>

      <PostFeedDetails post={post} currentUserId={currentUserId} />

      <CommentsSheet
        postId={post.id}
        open={commentsOpen}
        onClose={() => setCommentsOpen(false)}
        onCountDelta={(delta) =>
          setPost((p) => ({
            ...p,
            commentsCount: Math.max(0, p.commentsCount + delta),
          }))
        }
      />
    </article>
  );
}
