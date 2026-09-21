"use client";

import { User } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import {
  listMyBlockedUsers,
  unblockUser,
  type SocialProfileRow,
} from "@/features/catalog/lib/social-api";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export function SettingsBlockedView() {
  const [rows, setRows] = useState<SocialProfileRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const list = await listMyBlockedUsers(100, 0);
      setRows(list);
      setError(null);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Ошибка загрузки");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const onUnblock = (id: string) => {
    if (busyId) return;
    setBusyId(id);
    startTransition(async () => {
      try {
        await unblockUser(id);
        setRows((prev) => prev.filter((r) => r.profileId !== id));
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось разблокировать");
      } finally {
        setBusyId(null);
      }
    });
  };

  return (
    <SettingsShell title="Заблокированные">
      <div className="px-4 py-5 pb-10">
        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : error ? (
          <p className="px-2 py-8 text-center text-[13px] font-semibold text-destructive">
            {error}
          </p>
        ) : rows.length === 0 ? (
          <p className="py-16 text-center text-sm text-muted">Список пуст</p>
        ) : (
          <ul className="divide-y divide-line rounded-[16px] border border-line">
            {rows.map((r) => {
              const label = r.username?.trim()
                ? `@${r.username.trim()}`
                : "Пользователь";
              const busy = busyId === r.profileId;
              return (
                <li
                  key={r.profileId}
                  className="flex items-center gap-3 px-3.5 py-3"
                >
                  <Link
                    href={`/app/u/${r.profileId}`}
                    className="flex min-w-0 flex-1 items-center gap-3"
                  >
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center overflow-hidden rounded-full bg-mint">
                      {r.avatarUrl ? (
                        // eslint-disable-next-line @next/next/no-img-element
                        <img
                          src={r.avatarUrl}
                          alt=""
                          className="h-full w-full object-cover"
                        />
                      ) : (
                        <User className="h-4 w-4 text-muted" strokeWidth={1.5} />
                      )}
                    </span>
                    <span className="truncate text-[14px] font-bold text-ink">
                      {label}
                    </span>
                  </Link>
                  <AppButton
                    type="button"
                    size="row"
                    variant="outline"
                    disabled={busy}
                    loading={busy}
                    className="!h-9 shrink-0 !border-destructive/40 !px-3 !text-[12px] !text-destructive hover:!bg-destructive/10"
                    onClick={() => onUnblock(r.profileId)}
                  >
                    Разблокировать
                  </AppButton>
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </SettingsShell>
  );
}
