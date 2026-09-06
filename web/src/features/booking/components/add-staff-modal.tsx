"use client";

import { useEffect, useId, useRef, useState } from "react";
import { X } from "lucide-react";
import { AppButton } from "@/components/shared/app-button";
import {
  createStaffByName,
  ensureStaffFromProfile,
  searchStaffProfiles,
  type StaffProfileHit,
} from "@/features/booking/lib/staff-api";

const fieldCls =
  "h-12 w-full rounded-[14px] border border-line bg-bg px-3.5 text-[15px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50";

type Props = {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
};

/** Модалка: мастер по имени или из профиля Clover. */
export function AddStaffModal({ open, onClose, onCreated }: Props) {
  const titleId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [name, setName] = useState("");
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<StaffProfileHit[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [tab, setTab] = useState<"name" | "profile">("name");

  useEffect(() => {
    if (!open) return;
    setName("");
    setQuery("");
    setHits([]);
    setError(null);
    setTab("name");
    const t = setTimeout(() => inputRef.current?.focus(), 50);
    return () => clearTimeout(t);
  }, [open]);

  useEffect(() => {
    if (!open || tab !== "profile") return;
    let cancelled = false;
    const handle = setTimeout(() => {
      void searchStaffProfiles(query)
        .then((list) => {
          if (!cancelled) setHits(list);
        })
        .catch(() => {
          if (!cancelled) setHits([]);
        });
    }, 250);
    return () => {
      cancelled = true;
      clearTimeout(handle);
    };
  }, [open, tab, query]);

  if (!open) return null;

  const submitName = async () => {
    if (!name.trim() || busy) return;
    setBusy(true);
    setError(null);
    try {
      await createStaffByName(name);
      onCreated();
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось добавить");
    } finally {
      setBusy(false);
    }
  };

  const pickProfile = async (id: string) => {
    if (busy) return;
    setBusy(true);
    setError(null);
    try {
      await ensureStaffFromProfile(id);
      onCreated();
      onClose();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось добавить");
    } finally {
      setBusy(false);
    }
  };

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal="true"
      aria-labelledby={titleId}
      onClick={onClose}
    >
      <div
        className="max-h-[min(88dvh,640px)] w-full max-w-md overflow-y-auto rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 flex items-center gap-2 border-b border-line bg-surface px-3 py-2.5">
          <h2 id={titleId} className="min-w-0 flex-1 text-[16px] font-bold text-ink">
            Добавить мастера
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
            aria-label="Закрыть"
          >
            <X className="h-5 w-5" strokeWidth={2} />
          </button>
        </div>

        <div className="space-y-4 px-4 py-4">
          <div className="flex gap-1 rounded-[14px] border border-line bg-bg p-1">
            <button
              type="button"
              onClick={() => setTab("name")}
              className={`flex-1 rounded-[10px] py-2 text-[13px] font-bold transition ${
                tab === "name"
                  ? "bg-svc-booking text-svc-booking-ink"
                  : "text-muted hover:text-ink"
              }`}
            >
              По имени
            </button>
            <button
              type="button"
              onClick={() => setTab("profile")}
              className={`flex-1 rounded-[10px] py-2 text-[13px] font-bold transition ${
                tab === "profile"
                  ? "bg-svc-booking text-svc-booking-ink"
                  : "text-muted hover:text-ink"
              }`}
            >
              Из Clover
            </button>
          </div>

          {tab === "name" ? (
            <>
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold uppercase tracking-wide text-muted">
                  Имя
                </span>
                <input
                  ref={inputRef}
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") void submitName();
                  }}
                  placeholder="Например, Айгерим"
                  className={fieldCls}
                />
              </label>
              {error ? <p className="text-sm text-destructive">{error}</p> : null}
              <AppButton
                service="booking"
                loading={busy}
                disabled={!name.trim()}
                onClick={() => void submitName()}
              >
                Добавить
              </AppButton>
            </>
          ) : (
            <>
              <label className="block">
                <span className="mb-1.5 block text-[12px] font-bold uppercase tracking-wide text-muted">
                  Поиск
                </span>
                <input
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Ник или имя"
                  className={fieldCls}
                />
              </label>
              {error ? <p className="text-sm text-destructive">{error}</p> : null}
              <ul className="max-h-64 space-y-1 overflow-y-auto">
                {hits.length === 0 ? (
                  <li className="px-1 py-3 text-sm text-muted">
                    {query.trim() ? "Никого не нашли" : "Начните вводить ник"}
                  </li>
                ) : (
                  hits.map((h) => (
                    <li key={h.id}>
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => void pickProfile(h.id)}
                        className="flex w-full items-center gap-3 rounded-[14px] border border-line bg-bg px-3 py-2.5 text-left transition hover:border-svc-booking-ink/40 disabled:opacity-50"
                      >
                        <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-full bg-surface-muted text-[12px] font-bold text-muted">
                          {h.avatarUrl ? (
                            // eslint-disable-next-line @next/next/no-img-element
                            <img src={h.avatarUrl} alt="" className="h-full w-full object-cover" />
                          ) : (
                            (h.displayName || h.username).slice(0, 1).toUpperCase()
                          )}
                        </span>
                        <span className="min-w-0">
                          <span className="block truncate text-[14px] font-bold text-ink">
                            {h.displayName || h.username}
                          </span>
                          <span className="block truncate text-[12px] text-muted">
                            @{h.username}
                          </span>
                        </span>
                      </button>
                    </li>
                  ))
                )}
              </ul>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
