"use client";

import { useCallback, useEffect, useId, useMemo, useRef, useState } from "react";
import { X } from "lucide-react";
import { AppButton } from "@/components/shared/app-button";
import {
  cancelStaffInvite,
  createStaffByName,
  inviteStaff,
  listMyStaff,
  listPendingStaffInvites,
  searchStaffProfiles,
  staffInviteErrorMessage,
  type BookingStaffInvite,
  type StaffProfileHit,
} from "@/features/booking/lib/staff-api";
import type { BookingStaff } from "@/features/booking/lib/booking-model";

const fieldCls =
  "h-12 w-full rounded-[14px] border border-line bg-bg px-3.5 text-[15px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50";

type Props = {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
};

/** Модалка: исполнитель по имени или приглашение из Clover. */
export function AddStaffModal({ open, onClose, onCreated }: Props) {
  const titleId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [name, setName] = useState("");
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<StaffProfileHit[]>([]);
  const [pending, setPending] = useState<BookingStaffInvite[]>([]);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [tab, setTab] = useState<"name" | "invite">("name");

  const pendingIds = useMemo(
    () => new Set(pending.map((p) => p.inviteeId).filter(Boolean)),
    [pending],
  );
  const staffProfileIds = useMemo(
    () =>
      new Set(
        staff
          .map((s) => s.profileId?.trim())
          .filter((id): id is string => Boolean(id)),
      ),
    [staff],
  );

  const reloadMeta = useCallback(() => {
    void Promise.all([listPendingStaffInvites(), listMyStaff()])
      .then(([invites, team]) => {
        setPending(invites);
        setStaff(team);
      })
      .catch(() => {
        setPending([]);
        setStaff([]);
      });
  }, []);

  useEffect(() => {
    if (!open) return;
    setName("");
    setQuery("");
    setHits([]);
    setError(null);
    setSuccess(null);
    setTab("name");
    reloadMeta();
    const t = setTimeout(() => inputRef.current?.focus(), 50);
    return () => clearTimeout(t);
  }, [open, reloadMeta]);

  useEffect(() => {
    if (!open || tab !== "invite") return;
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

  const inviteStatus = (profileId: string): "team" | "pending" | null => {
    if (staffProfileIds.has(profileId)) return "team";
    if (pendingIds.has(profileId)) return "pending";
    return null;
  };

  const submitName = async () => {
    if (!name.trim() || busy) return;
    setBusy(true);
    setError(null);
    setSuccess(null);
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

  const sendInvite = async (id: string) => {
    if (busy || inviteStatus(id)) return;
    setBusy(true);
    setError(null);
    setSuccess(null);
    try {
      await inviteStaff(id);
      setSuccess("Приглашение отправлено в чат");
      reloadMeta();
    } catch (e: unknown) {
      setError(staffInviteErrorMessage(e));
    } finally {
      setBusy(false);
    }
  };

  const onCancelInvite = async (id: string) => {
    if (busy) return;
    setBusy(true);
    setError(null);
    try {
      await cancelStaffInvite(id);
      reloadMeta();
    } catch (e: unknown) {
      setError(staffInviteErrorMessage(e, "Не удалось отменить"));
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
            Исполнители
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
              onClick={() => setTab("invite")}
              className={`flex-1 rounded-[10px] py-2 text-[13px] font-bold transition ${
                tab === "invite"
                  ? "bg-svc-booking text-svc-booking-ink"
                  : "text-muted hover:text-ink"
              }`}
            >
              Пригласить
            </button>
          </div>

          {pending.length > 0 ? (
            <div className="space-y-2">
              <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
                Ожидают ответа
              </p>
              <ul className="space-y-1.5">
                {pending.map((inv) => {
                  const title =
                    inv.inviteeDisplayName.trim() ||
                    inv.inviteeUsername?.trim() ||
                    "Пользователь";
                  return (
                    <li
                      key={inv.id}
                      className="flex items-center gap-2 rounded-[12px] border border-line bg-bg px-3 py-2"
                    >
                      <span className="min-w-0 flex-1 truncate text-[13px] font-semibold text-ink">
                        {title}
                        {inv.inviteeUsername ? (
                          <span className="ml-1 font-medium text-muted">
                            @{inv.inviteeUsername}
                          </span>
                        ) : null}
                      </span>
                      <button
                        type="button"
                        disabled={busy}
                        onClick={() => void onCancelInvite(inv.id)}
                        className="shrink-0 rounded-[10px] px-2.5 py-1.5 text-[12px] font-bold text-destructive hover:bg-destructive/10 disabled:opacity-50"
                      >
                        Отменить
                      </button>
                    </li>
                  );
                })}
              </ul>
            </div>
          ) : null}

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
              <p className="text-[13px] text-muted">
                Отправим приглашение в чат. Исполнитель появится в списке после принятия.
              </p>
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
              {success ? <p className="text-sm font-semibold text-svc-booking-ink">{success}</p> : null}
              {error ? <p className="text-sm text-destructive">{error}</p> : null}
              <ul className="max-h-64 space-y-1 overflow-y-auto">
                {hits.length === 0 ? (
                  <li className="px-1 py-3 text-sm text-muted">
                    {query.trim() ? "Никого не нашли" : "Начните вводить ник"}
                  </li>
                ) : (
                  hits.map((h) => {
                    const status = inviteStatus(h.id);
                    const locked = Boolean(status) || busy;
                    const actionLabel =
                      status === "team"
                        ? "В команде"
                        : status === "pending"
                          ? "Приглашён"
                          : "Пригласить";
                    return (
                      <li key={h.id}>
                        <button
                          type="button"
                          disabled={locked}
                          onClick={() => void sendInvite(h.id)}
                          className={`flex w-full items-center gap-3 rounded-[14px] border px-3 py-2.5 text-left transition disabled:opacity-70 ${
                            status
                              ? "border-line bg-surface-muted"
                              : "border-line bg-bg hover:border-svc-booking-ink/40"
                          }`}
                        >
                          <span className="flex h-9 w-9 shrink-0 items-center justify-center overflow-hidden rounded-full bg-surface-muted text-[12px] font-bold text-muted">
                            {h.avatarUrl ? (
                              // eslint-disable-next-line @next/next/no-img-element
                              <img src={h.avatarUrl} alt="" className="h-full w-full object-cover" />
                            ) : (
                              (h.displayName || h.username).slice(0, 1).toUpperCase()
                            )}
                          </span>
                          <span className="min-w-0 flex-1">
                            <span className="block truncate text-[14px] font-bold text-ink">
                              {h.displayName || h.username}
                            </span>
                            <span className="block truncate text-[12px] text-muted">
                              @{h.username}
                            </span>
                          </span>
                          <span
                            className={`shrink-0 text-[12px] font-bold ${
                              status ? "text-muted" : "text-svc-booking-ink"
                            }`}
                          >
                            {actionLabel}
                          </span>
                        </button>
                      </li>
                    );
                  })
                )}
              </ul>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
