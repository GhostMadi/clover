"use client";

import { Plus, Search, X } from "lucide-react";
import { useCallback, useEffect, useId, useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceNameModal } from "@/features/attendance/components/attendance-name-modal";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  archiveMember,
  getAdminWorkplace,
  inviteMember,
  listWorkplaceMembers,
  loadProfileLabels,
  reinviteMember,
  searchAttendanceProfiles,
  setMemberBaseSalary,
  type AttendanceProfileHit,
} from "@/features/attendance/lib/attendance-api";
import type { AttendanceMembershipLite } from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceMembersCache,
  writeAttendanceMembersCache,
} from "@/features/attendance/lib/attendance-prefs";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import { ServiceEmpty } from "@/features/shared/components/service-page";
import { getSessionUserId } from "@/lib/run-service-swr";

type Tab = "active" | "pending" | "archived";

type MemberRow = AttendanceMembershipLite & {
  displayName: string;
  username: string;
};

function tabOf(status: string): Tab {
  if (status === "pending") return "pending";
  if (status === "archived" || status === "declined") return "archived";
  return "active";
}

export function AttendanceMembersView({ workplaceId }: { workplaceId: string }) {
  const back = `/app/settings/attendance/w/${workplaceId}`;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [members, setMembers] = useState<MemberRow[]>([]);
  const [tab, setTab] = useState<Tab>("active");
  const [inviteOpen, setInviteOpen] = useState(false);
  const [salaryMember, setSalaryMember] = useState<MemberRow | null>(null);
  const [memberToArchive, setMemberToArchive] = useState<MemberRow | null>(null);
  const [archiveError, setArchiveError] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const archiveTitleId = useId();

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const uid = await getSessionUserId();
      const workplace = await getAdminWorkplace(workplaceId);
      if (!workplace) {
        setError("Компания не найдена или нет прав admin");
        setMembers([]);
        return;
      }
      const list = await listWorkplaceMembers(workplaceId);
      const labels = await loadProfileLabels(list.map((m) => m.profileId));
      const next = list.map((m) => {
        const label = labels.get(m.profileId);
        return {
          ...m,
          displayName: label?.name ?? m.profileId.slice(0, 8),
          username: label?.username ?? m.profileId.slice(0, 8),
        };
      });
      setMembers(next);
      writeAttendanceMembersCache(uid, workplaceId, next);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId]);

  useEffect(() => {
    void (async () => {
      const uid = await getSessionUserId();
      const cached = readAttendanceMembersCache(uid, workplaceId);
      if (cached?.members?.length) {
        setMembers(cached.members);
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
  }, [reload, workplaceId]);

  const counts = useMemo(() => {
    let active = 0;
    let pending = 0;
    let archived = 0;
    for (const m of members) {
      const t = tabOf(m.status);
      if (t === "active") active += 1;
      else if (t === "pending") pending += 1;
      else archived += 1;
    }
    return { active, pending, archived };
  }, [members]);

  const filtered = members.filter((m) => tabOf(m.status) === tab);

  if (loading) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Люди">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (error) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Люди">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{error}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell
      workplaceId={workplaceId}
      title="Люди"
      lead="Кто работает в компании: активные, приглашения и архив."
      trailing={
        <button
          type="button"
          title="Пригласить"
          onClick={() => setInviteOpen(true)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-svc-attendance-ink hover:bg-svc-attendance"
          aria-label="Пригласить"
        >
          <Plus className="h-5 w-5" strokeWidth={2.25} />
        </button>
      }
    >
      <div className="space-y-4 px-4 py-4 pb-10">
        <div className="flex gap-1 rounded-[14px] border border-line bg-surface p-1">
          {(
            [
              ["active", `Активные · ${counts.active}`],
              ["pending", `Ожидают · ${counts.pending}`],
              ["archived", `Архив · ${counts.archived}`],
            ] as const
          ).map(([key, label]) => (
            <button
              key={key}
              type="button"
              onClick={() => setTab(key)}
              className={`min-w-0 flex-1 rounded-[10px] px-2 py-2 text-[12px] font-bold transition ${
                tab === key
                  ? "bg-svc-attendance text-svc-attendance-ink"
                  : "text-muted hover:bg-bg"
              }`}
            >
              {label}
            </button>
          ))}
        </div>

        <p className="text-[12px] leading-snug text-muted">
          {tab === "pending"
            ? "Приглашение уходит в чат. Пока его не приняли, отметок нет."
            : tab === "archived"
              ? "Не в сменах и зарплате. Вернуть можно повторным приглашением."
              : "Приглашение создаёт карточку в чате. Зарплату можно задать у человека."}
        </p>

        {filtered.length === 0 ? (
          <ServiceEmpty>
            {tab === "pending"
              ? "Нет ожидающих приглашений."
              : tab === "archived"
                ? "Архив пуст."
                : "Пока нет активных людей. Пригласите через плюс."}
          </ServiceEmpty>
        ) : (
          <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
            {filtered.map((m, i) => (
              <li key={m.id} className={i > 0 ? "border-t border-line" : ""}>
                <div className="space-y-2 px-3.5 py-3.5">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="truncate text-[15px] font-bold text-ink">
                        {m.displayName}
                      </p>
                      <p className="truncate text-[12px] text-muted">
                        {m.username}
                        {tab === "active"
                          ? !m.hasAttendanceWorkTag
                            ? " · Неактивен"
                            : ` · ${m.baseSalaryTenge.toLocaleString("ru-RU")} ₸`
                          : ""}
                      </p>
                    </div>
                  </div>
                  <div className="flex flex-wrap gap-2">
                    {tab === "active" ? (
                      <>
                        <ActionChip
                          label="Зарплата"
                          disabled={busyId === m.id}
                          onClick={() => setSalaryMember(m)}
                        />
                        <ActionChip
                          label="Убрать"
                          disabled={busyId === m.id}
                          danger
                          onClick={() => {
                            setArchiveError(null);
                            setMemberToArchive(m);
                          }}
                        />
                      </>
                    ) : null}
                    {tab === "pending" || tab === "archived" ? (
                      <ActionChip
                        label="Повторно пригласить"
                        disabled={busyId === m.id}
                        onClick={() => {
                          setBusyId(m.id);
                          void reinviteMember(m.id)
                            .then(() => reload())
                            .finally(() => setBusyId(null));
                        }}
                      />
                    ) : null}
                    {tab === "pending" ? (
                      <ActionChip
                        label="Убрать"
                        disabled={busyId === m.id}
                        danger
                        onClick={() => {
                          setArchiveError(null);
                          setMemberToArchive(m);
                        }}
                      />
                    ) : null}
                  </div>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>

      {memberToArchive ? (
        <div
          className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 p-0 sm:items-center sm:p-4"
          role="dialog"
          aria-modal="true"
          aria-labelledby={archiveTitleId}
          onClick={() => {
            if (busyId !== memberToArchive.id) setMemberToArchive(null);
          }}
        >
          <div
            className="w-full max-w-md rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-2 border-b border-line px-3 py-2.5">
              <h2 id={archiveTitleId} className="min-w-0 flex-1 text-[16px] font-bold text-ink">
                Убрать из компании?
              </h2>
              <button
                type="button"
                onClick={() => setMemberToArchive(null)}
                disabled={busyId === memberToArchive.id}
                className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg disabled:opacity-50"
                aria-label="Закрыть"
              >
                <X className="h-5 w-5" strokeWidth={2} />
              </button>
            </div>
            <div className="space-y-4 px-4 py-4">
              <p className="text-[14px] leading-snug text-ink">
                {memberToArchive.displayName} не будет в сменах и зарплате. Прошлые отметки
                останутся.
              </p>
              {archiveError ? (
                <p className="text-[13px] text-destructive">{archiveError}</p>
              ) : null}
              <div className="flex gap-2">
                <AppButton
                  variant="outline"
                  className="flex-1"
                  disabled={busyId === memberToArchive.id}
                  onClick={() => setMemberToArchive(null)}
                >
                  Оставить
                </AppButton>
                <AppButton
                  service="attendance"
                  className="flex-1"
                  loading={busyId === memberToArchive.id}
                  onClick={() => {
                    const person = memberToArchive;
                    setBusyId(person.id);
                    setArchiveError(null);
                    void archiveMember(person.id)
                      .then(() => {
                        setMemberToArchive(null);
                        return reload();
                      })
                      .catch((e: unknown) => {
                        setArchiveError(
                          e instanceof Error ? e.message : "Не удалось убрать",
                        );
                      })
                      .finally(() => setBusyId(null));
                  }}
                >
                  Убрать
                </AppButton>
              </div>
            </div>
          </div>
        </div>
      ) : null}

      <InviteMemberModal
        open={inviteOpen}
        workplaceId={workplaceId}
        excludeIds={members.map((m) => m.profileId)}
        onClose={() => setInviteOpen(false)}
        onInvited={() => void reload()}
      />

      <AttendanceNameModal
        open={salaryMember != null}
        title="Базовая зарплата"
        label="Сумма, ₸"
        placeholder="350000"
        initialValue={
          salaryMember ? String(salaryMember.baseSalaryTenge || "") : ""
        }
        submitLabel="Сохранить"
        onClose={() => setSalaryMember(null)}
        onSubmit={async (raw) => {
          if (!salaryMember) return;
          const n = Number(raw.replace(/\s/g, "").replace(",", "."));
          if (!Number.isFinite(n) || n < 0) {
            throw new Error("Укажите число ≥ 0");
          }
          await setMemberBaseSalary({
            workplaceId,
            profileId: salaryMember.profileId,
            baseSalaryTenge: n,
          });
          await reload();
        }}
      />
    </AttendanceWorkspaceShell>
  );
}

function ActionChip({
  label,
  onClick,
  disabled,
  danger,
}: {
  label: string;
  onClick: () => void;
  disabled?: boolean;
  danger?: boolean;
}) {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={`rounded-full px-3 py-1.5 text-[12px] font-bold disabled:opacity-40 ${
        danger
          ? "bg-bg text-error hover:bg-destructive/10"
          : "bg-svc-attendance text-svc-attendance-ink hover:opacity-90"
      }`}
    >
      {label}
    </button>
  );
}

function InviteMemberModal({
  open,
  workplaceId,
  excludeIds,
  onClose,
  onInvited,
}: {
  open: boolean;
  workplaceId: string;
  excludeIds: string[];
  onClose: () => void;
  onInvited: () => void;
}) {
  const [query, setQuery] = useState("");
  const [hits, setHits] = useState<AttendanceProfileHit[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const excludeKey = excludeIds.slice().sort().join(",");

  useEffect(() => {
    if (!open) return;
    setQuery("");
    setHits([]);
    setError(null);
  }, [open]);

  useEffect(() => {
    if (!open) return;
    let cancelled = false;
    const exclude = new Set(excludeIds);
    const handle = setTimeout(() => {
      void searchAttendanceProfiles(query, exclude)
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
    // excludeKey stable-ish fingerprint
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, query, excludeKey]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-ink/50 p-0 sm:items-center sm:p-4"
      role="dialog"
      aria-modal="true"
      onClick={onClose}
    >
      <div
        className="max-h-[min(88dvh,640px)] w-full max-w-md overflow-y-auto rounded-t-2xl border border-line bg-surface shadow-elevate-lg sm:rounded-2xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="sticky top-0 border-b border-line bg-surface px-4 py-3">
          <h2 className="text-[16px] font-bold text-ink">Пригласить</h2>
          <p className="mt-0.5 text-[12px] text-muted">
            Карточка invite уйдёт в чат с человеком
          </p>
        </div>
        <div className="space-y-3 px-4 py-4">
          <label className="relative block">
            <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted" />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Ник или имя"
              className="h-12 w-full rounded-[14px] border border-line bg-bg pl-10 pr-3.5 text-[15px] text-ink outline-none focus:border-svc-attendance-ink/50"
            />
          </label>
          {error ? <p className="text-[13px] text-error">{error}</p> : null}
          <ul className="space-y-1">
            {hits.map((h) => (
              <li key={h.id}>
                <button
                  type="button"
                  disabled={busy}
                  onClick={() => {
                    setBusy(true);
                    setError(null);
                    void inviteMember({ workplaceId, profileId: h.id })
                      .then(() => {
                        onInvited();
                        onClose();
                      })
                      .catch((e: unknown) => {
                        setError(
                          e instanceof Error ? e.message : "Не удалось пригласить",
                        );
                      })
                      .finally(() => setBusy(false));
                  }}
                  className="flex w-full items-center gap-3 rounded-[14px] px-2 py-2.5 text-left hover:bg-svc-attendance/40 disabled:opacity-40"
                >
                  <span className="flex h-10 w-10 items-center justify-center rounded-full bg-svc-attendance text-[13px] font-bold text-svc-attendance-ink">
                    {(h.fullName || h.username).slice(0, 1).toUpperCase()}
                  </span>
                  <span className="min-w-0">
                    <span className="block truncate text-[14px] font-bold text-ink">
                      {h.fullName || `@${h.username}`}
                    </span>
                    <span className="block truncate text-[12px] text-muted">
                      @{h.username.replace(/^@/, "")}
                    </span>
                  </span>
                </button>
              </li>
            ))}
          </ul>
          {hits.length === 0 ? (
            <p className="py-6 text-center text-[13px] text-muted">Никого не нашли</p>
          ) : null}
          <AppButton type="button" variant="outline" onClick={onClose}>
            Закрыть
          </AppButton>
        </div>
      </div>
    </div>
  );
}
