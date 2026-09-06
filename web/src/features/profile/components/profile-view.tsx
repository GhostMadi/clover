"use client";

import { FolderPlus, MapPin, MessageCircle, Plus, User } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";
import { AppButton, AppButtonLink } from "@/components/shared/app-button";
import { SignOutButton } from "@/features/auth/components/sign-out-button";
import { followUser, unfollowUser } from "@/features/catalog/lib/social-api";
import { createDm } from "@/features/chat/lib/chat-api";
import { ProfileFilterChips } from "@/features/resources/components/profile-filter-chips";
import { ProfileBanner } from "@/features/profile/components/profile-banner";
import { ProfileBio } from "@/features/profile/components/profile-bio";
import { ProfileClusters } from "@/features/profile/components/profile-clusters";
import { ProfilePostsGrid } from "@/features/profile/components/profile-posts-grid";
import type { ClusterItem } from "@/features/profile/lib/clusters-api";
import { listProfilePostsClient } from "@/features/profile/lib/posts-client";
import { formatStat, type Profile } from "@/features/profile/lib/profile-model";
import type { FeedPost } from "@/features/post/lib/parse-feed";

function Stat({
  value,
  label,
  href,
}: {
  value: string;
  label: string;
  href?: string;
}) {
  const inner = (
    <>
      <p className="text-lg font-extrabold leading-tight text-ink sm:text-xl">{value}</p>
      <p className="truncate text-xs font-medium text-muted sm:text-sm">{label}</p>
    </>
  );
  if (href) {
    return (
      <Link href={href} className="min-w-0 flex-1 text-center transition hover:opacity-80">
        {inner}
      </Link>
    );
  }
  return <div className="min-w-0 flex-1 text-center">{inner}</div>;
}

type ProfileViewProps = {
  profile: Profile;
  posts: FeedPost[];
  clusters?: ClusterItem[];
  mode?: "own" | "guest";
  initialFollowing?: boolean;
};

/** Витрина профиля: свой или чужой (guest). */
export function ProfileView({
  profile,
  posts,
  clusters = [],
  mode = "own",
  initialFollowing = false,
}: ProfileViewProps) {
  const isGuest = mode === "guest";
  const router = useRouter();
  const [following, setFollowing] = useState(initialFollowing);
  const [followersCount, setFollowersCount] = useState(profile.followersCount);
  const [busy, setBusy] = useState(false);
  const [chatBusy, setChatBusy] = useState(false);
  const [addOpen, setAddOpen] = useState(false);
  const [selectedClusterId, setSelectedClusterId] = useState<string | null>(null);
  const [filterKeys, setFilterKeys] = useState<Set<string>>(new Set());
  const [gridPosts, setGridPosts] = useState(posts);
  const [gridLoading, setGridLoading] = useState(false);
  const [, startTransition] = useTransition();

  useEffect(() => {
    setGridPosts(posts);
  }, [posts]);

  useEffect(() => {
    let cancelled = false;
    setGridLoading(true);
    void listProfilePostsClient(profile.id, {
      clusterId: selectedClusterId,
      filterSelectionKeys: [...filterKeys],
    })
      .then((list) => {
        if (!cancelled) setGridPosts(list);
      })
      .catch(() => {
        if (!cancelled && !selectedClusterId && filterKeys.size === 0) setGridPosts(posts);
      })
      .finally(() => {
        if (!cancelled) setGridLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [profile.id, selectedClusterId, filterKeys, posts]);

  const name = profile.fullName?.trim() || null;
  const nick = profile.username?.trim() || null;
  const bio = profile.bio?.trim() || null;
  const location = profile.location.trim() || null;
  const avatar = profile.avatarUrl?.trim() || null;
  const cover = profile.backgroundUrl?.trim() || null;

  const openChat = () => {
    if (chatBusy) return;
    setChatBusy(true);
    void createDm(profile.id)
      .then((id) => {
        router.push(
          `/app/chat/${id}?u=${encodeURIComponent(nick || name || "чат")}${
            avatar ? `&a=${encodeURIComponent(avatar)}` : ""
          }${profile.id ? `&peer=${encodeURIComponent(profile.id)}` : ""}`,
        );
      })
      .catch(() => {
        setChatBusy(false);
      });
  };

  const toggleFollow = () => {
    if (busy) return;
    const next = !following;
    setBusy(true);
    setFollowing(next);
    setFollowersCount((n) => Math.max(0, n + (next ? 1 : -1)));
    startTransition(async () => {
      try {
        if (next) await followUser(profile.id);
        else await unfollowUser(profile.id);
      } catch {
        setFollowing(!next);
        setFollowersCount((n) => Math.max(0, n + (next ? -1 : 1)));
      } finally {
        setBusy(false);
      }
    });
  };

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-bg md:min-h-dvh">
      <div className="mx-auto max-w-2xl lg:max-w-3xl xl:max-w-4xl">
        <ProfileBanner imageUrl={cover ?? ""} empty={!cover} />

        <div className="px-4 pt-3 sm:px-5 sm:pt-4 lg:px-6">
          <div className="flex items-center gap-3 sm:gap-5">
            <div className="shrink-0 rounded-full bg-brand p-[3px]">
              <div className="rounded-full bg-surface p-[2px]">
                <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full bg-mint sm:h-24 sm:w-24 lg:h-28 lg:w-28">
                  {avatar ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={avatar} alt="" className="h-full w-full object-cover" />
                  ) : (
                    <User className="h-11 w-11 text-muted sm:h-12 sm:w-12" strokeWidth={1.5} />
                  )}
                </div>
              </div>
            </div>

            <div className="flex min-w-0 flex-1 items-center">
              <Stat
                value={formatStat(followersCount)}
                label="Подписчики"
                href={`/app/u/${profile.id}/social?tab=followers`}
              />
              <Stat
                value={formatStat(profile.followingCount)}
                label="Подписки"
                href={`/app/u/${profile.id}/social?tab=following`}
              />
              <Stat value={formatStat(profile.postCount)} label="Публикации" />
            </div>
          </div>

          <div className="mt-4 space-y-1 sm:mt-5">
            {name ? (
              <h1 className="font-display text-lg font-extrabold tracking-tight text-ink sm:text-2xl">
                {name}
              </h1>
            ) : null}
            {nick ? (
              <p className="text-sm font-bold text-brand sm:text-base">@{nick}</p>
            ) : (
              <p className="text-sm font-semibold text-muted">пусто</p>
            )}
          </div>

          {bio ? (
            <div className="mt-3 max-w-2xl sm:mt-4">
              <ProfileBio text={bio} />
            </div>
          ) : null}

          {location ? (
            <div className="mt-3 flex items-center gap-1.5 text-brand">
              <MapPin className="h-3.5 w-3.5 shrink-0 sm:h-4 sm:w-4" strokeWidth={2.5} />
              <p className="text-xs font-semibold sm:text-sm">{location}</p>
            </div>
          ) : null}

          {isGuest ? (
            <div className="mt-4 flex max-w-xl flex-col gap-2 sm:mt-5">
              <div className="flex gap-2">
                {following ? (
                  <button
                    type="button"
                    disabled={busy}
                    onClick={toggleFollow}
                    className="h-11 flex-1 rounded-[14px] border border-line bg-surface text-sm font-semibold text-ink transition hover:bg-bg disabled:opacity-60 sm:h-12"
                  >
                    Отписаться
                  </button>
                ) : (
                  <button
                    type="button"
                    disabled={busy}
                    onClick={toggleFollow}
                    className="h-11 flex-1 rounded-[14px] bg-brand text-sm font-semibold text-on-brand transition hover:opacity-90 disabled:opacity-60 sm:h-12"
                  >
                    Подписаться
                  </button>
                )}
                <button
                  type="button"
                  disabled={chatBusy}
                  onClick={openChat}
                  title="Сообщения"
                  className="flex h-11 w-11 shrink-0 items-center justify-center rounded-[14px] border border-line bg-surface text-ink transition hover:bg-mint disabled:opacity-60 sm:h-12 sm:w-12"
                >
                  <MessageCircle className="h-5 w-5" strokeWidth={2} />
                </button>
              </div>
              {profile.tagKeys.includes("booking") ? (
                <AppButtonLink
                  href={`/app/u/${profile.id}/book`}
                  size="row"
                  service="booking"
                  className="w-full"
                >
                  Записаться
                </AppButtonLink>
              ) : null}
            </div>
          ) : (
            <div className="mt-4 flex max-w-xl items-center gap-2 sm:mt-5 sm:gap-2.5">
              <AppButtonLink
                href="/app/profile/edit"
                variant="outline"
                size="row"
                className="flex-1"
              >
                Редактировать
              </AppButtonLink>
              <AppButton
                size="icon"
                title="Добавить"
                aria-label="Добавить"
                onClick={() => setAddOpen(true)}
              >
                <Plus strokeWidth={2.5} className="text-on-brand" />
              </AppButton>
            </div>
          )}
        </div>

        <ProfileClusters
          initial={clusters}
          canManage={!isGuest}
          selectedId={selectedClusterId}
          onSelect={setSelectedClusterId}
        />

        <div className="mt-6 border-t border-line px-4 pt-4 sm:mt-8 sm:px-5 sm:pt-5 lg:px-6">
          <ProfileFilterChips
            profileId={profile.id}
            enabled={Boolean(profile.hasFilters) || !isGuest}
            selectedKeys={filterKeys}
            onChange={setFilterKeys}
            title={selectedClusterId ? "Посты коллекции" : "Публикации"}
          />
          {gridLoading ? (
            <p className="py-10 text-center text-sm text-muted">Загрузка…</p>
          ) : (
            <ProfilePostsGrid posts={gridPosts} />
          )}
        </div>

        {!isGuest ? (
          <div className="flex justify-center px-4 py-10 sm:px-5 lg:px-6">
            <SignOutButton />
          </div>
        ) : (
          <div className="h-10" />
        )}
      </div>

      {addOpen ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center sm:items-center">
          <button
            type="button"
            className="absolute inset-0 bg-ink/40"
            aria-label="Закрыть"
            onClick={() => setAddOpen(false)}
          />
          <div className="relative z-10 w-full max-w-md rounded-t-[20px] bg-surface shadow-xl sm:rounded-[20px]">
            <div className="border-b border-line px-4 py-3">
              <h2 className="text-[16px] font-bold text-ink">Добавить</h2>
            </div>
            <ul className="p-2">
              <li>
                <Link
                  href="/app/posts/new"
                  onClick={() => setAddOpen(false)}
                  className="flex items-center gap-3 rounded-[14px] px-3 py-3.5 hover:bg-bg"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-[12px] bg-mint text-brand">
                    <Plus className="h-5 w-5" strokeWidth={2.5} />
                  </span>
                  <span>
                    <span className="block text-[15px] font-bold text-ink">Добавить пост</span>
                    <span className="block text-[12px] text-muted">Фото и публикация</span>
                  </span>
                </Link>
              </li>
              <li>
                <Link
                  href="/app/clusters/new"
                  onClick={() => setAddOpen(false)}
                  className="flex items-center gap-3 rounded-[14px] px-3 py-3.5 hover:bg-bg"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-[12px] bg-mint text-brand">
                    <FolderPlus className="h-5 w-5" strokeWidth={2} />
                  </span>
                  <span>
                    <span className="block text-[15px] font-bold text-ink">Добавить кластер</span>
                    <span className="block text-[12px] text-muted">Коллекция на профиле</span>
                  </span>
                </Link>
              </li>
            </ul>
          </div>
        </div>
      ) : null}
    </div>
  );
}
