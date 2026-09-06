"use client";

import { ArrowLeft, User } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState } from "react";
import {
  listProfileFollowers,
  listProfileFollowing,
  type SocialProfileRow,
} from "@/features/catalog/lib/social-api";

type Mode = "followers" | "following";

type FollowListViewProps = {
  profileId: string;
  mode: Mode;
  backHref: string;
  title: string;
};

export function FollowListView({
  profileId,
  mode,
  backHref,
  title,
}: FollowListViewProps) {
  const [rows, setRows] = useState<SocialProfileRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const list =
        mode === "followers"
          ? await listProfileFollowers(profileId, 100, 0)
          : await listProfileFollowing(profileId, 100, 0);
      setRows(list);
      setError(null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Ошибка загрузки");
    } finally {
      setLoading(false);
    }
  }, [mode, profileId]);

  useEffect(() => {
    void load();
  }, [load]);

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto w-full max-w-[560px]">
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-surface/95 px-2 backdrop-blur-md">
          <Link
            href={backHref}
            className="flex h-10 w-10 items-center justify-center rounded-full hover:bg-bg"
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </Link>
          <h1 className="text-[16px] font-bold text-ink">{title}</h1>
        </header>

        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : error ? (
          <p className="px-4 py-8 text-center text-[13px] font-semibold text-destructive">
            {error}
          </p>
        ) : rows.length === 0 ? (
          <p className="py-16 text-center text-sm text-muted">Пока пусто</p>
        ) : (
          <ul className="divide-y divide-line">
            {rows.map((r) => (
              <li key={r.profileId}>
                <Link
                  href={`/app/u/${r.profileId}`}
                  className="flex items-center gap-3 px-4 py-3 transition hover:bg-bg"
                >
                  <span className="flex h-11 w-11 shrink-0 items-center justify-center overflow-hidden rounded-full bg-mint">
                    {r.avatarUrl ? (
                      // eslint-disable-next-line @next/next/no-img-element
                      <img src={r.avatarUrl} alt="" className="h-full w-full object-cover" />
                    ) : (
                      <User className="h-5 w-5 text-muted" strokeWidth={1.5} />
                    )}
                  </span>
                  <span className="min-w-0 flex-1 truncate text-[15px] font-bold text-ink">
                    {r.username?.trim() || "noName"}
                  </span>
                </Link>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
