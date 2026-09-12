"use client";

import { MessageCircle, Pencil, Smartphone } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceNameModal } from "@/features/attendance/components/attendance-name-modal";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import {
  fetchBootstrap,
  getAdminWorkplace,
  loadProfileLabels,
  renameWorkplace,
} from "@/features/attendance/lib/attendance-api";
import {
  dayKey,
  formatDateKey,
  onDutyFor,
  type AttendanceAbsence,
  type AttendanceOvertime,
  type AttendancePunchRecord,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceTodayCache,
  revivePunches,
  serializePunches,
  writeAttendanceTodayCache,
} from "@/features/attendance/lib/attendance-prefs";
import { getSessionUserId } from "@/lib/run-service-swr";

type MemberRow = { id: string; name: string; username: string };

function sameLocalDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function isClockIn(kind: string): boolean {
  return kind === "clock_in" || kind === "in" || kind.endsWith("_in");
}

export function AttendanceTodayView({ workplaceId }: { workplaceId: string }) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [members, setMembers] = useState<MemberRow[]>([]);
  const [punches, setPunches] = useState<AttendancePunchRecord[]>([]);
  const [absences, setAbsences] = useState<AttendanceAbsence[]>([]);
  const [overtime, setOvertime] = useState<AttendanceOvertime[]>([]);
  const [renameOpen, setRenameOpen] = useState(false);

  const today = useMemo(() => dayKey(new Date()), []);
  const todayKey = useMemo(() => formatDateKey(today), [today]);

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const uid = await getSessionUserId();
      const w = await getAdminWorkplace(workplaceId);
      if (!w) {
        setError("Компания не найдена или нет прав admin");
        setWorkplace(null);
        return;
      }
      const boot = await fetchBootstrap();
      const active = boot.memberships.filter(
        (m) => m.workplaceId === workplaceId && m.status === "active",
      );
      const ids = active.map((m) => m.profileId);
      const lab = await loadProfileLabels(ids);
      const nextMembers = active.map((m) => ({
        id: m.profileId,
        name: lab.get(m.profileId)?.name ?? m.profileId.slice(0, 8),
        username: lab.get(m.profileId)?.username ?? "",
      }));
      const nextPunches = boot.punches.filter((p) => p.workplaceId === workplaceId);
      const nextAbsences = boot.absences.filter((a) => a.workplaceId === workplaceId);
      const nextOt = boot.overtimeEntries.filter((o) => o.workplaceId === workplaceId);
      setMembers(nextMembers);
      setWorkplace(w);
      setPunches(nextPunches);
      setAbsences(nextAbsences);
      setOvertime(nextOt);
      writeAttendanceTodayCache(uid, workplaceId, {
        dayKey: todayKey,
        workplace: w,
        members: nextMembers,
        punches: serializePunches(nextPunches),
        absences: nextAbsences,
        overtime: nextOt,
      });
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, [workplaceId, todayKey]);

  useEffect(() => {
    void (async () => {
      const uid = await getSessionUserId();
      const cached = readAttendanceTodayCache(uid, workplaceId, todayKey);
      if (cached) {
        setWorkplace(cached.workplace);
        setMembers(cached.members);
        setPunches(revivePunches(cached.punches));
        setAbsences(cached.absences);
        setOvertime(cached.overtime);
        setLoading(false);
        await reload({ soft: true });
      } else {
        await reload();
      }
    })();
  }, [reload, workplaceId, todayKey]);
  const todayPunches = useMemo(
    () => punches.filter((p) => sameLocalDay(p.punchedAt, today) && !p.cancelled),
    [punches, today],
  );

  const onDutyIds = useMemo(() => {
    if (!workplace) return [] as string[];
    return onDutyFor(workplace.dutyRoster, today);
  }, [workplace, today]);

  const punchedInIds = useMemo(() => {
    const set = new Set<string>();
    for (const p of todayPunches) {
      if (isClockIn(p.punchKind)) set.add(p.profileId);
    }
    return set;
  }, [todayPunches]);

  const absentToday = useMemo(() => {
    return absences.filter((a) => a.startDate <= todayKey && todayKey <= a.endDate);
  }, [absences, todayKey]);

  const pendingOt = useMemo(
    () => overtime.filter((o) => o.status === "pending"),
    [overtime],
  );

  const onShift = members.filter(
    (m) => onDutyIds.includes(m.id) || punchedInIds.has(m.id),
  );
  const missingPunch = members.filter(
    (m) => onDutyIds.includes(m.id) && !punchedInIds.has(m.id),
  );
  const punchedNotOnRoster = members.filter(
    (m) => punchedInIds.has(m.id) && !onDutyIds.includes(m.id),
  );

  if (loading) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Сегодня">
        <AttendanceListShimmer rows={6} />
      </AttendanceWorkspaceShell>
    );
  }

  if (error || !workplace) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Сегодня">
        <div className="space-y-3">
          <p className="text-[14px] text-error">
            {error ?? "Компания не найдена или нет прав admin"}
          </p>
          <AppButtonLink href="/app/settings/attendance/companies" service="attendance">
            К хабу
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell
      workplaceId={workplaceId}
      title="Сегодня"
      brandSubtitle="Сегодня по компании"
      companyName={workplace.name}
      trailing={
        <button
          type="button"
          title="Переименовать"
          onClick={() => setRenameOpen(true)}
          className="flex h-10 w-10 items-center justify-center rounded-full text-svc-attendance-ink hover:bg-svc-attendance"
          aria-label="Переименовать"
        >
          <Pencil className="h-4 w-4" strokeWidth={2} />
        </button>
      }
    >
      <div className="space-y-5">
        <div className="flex flex-wrap items-start justify-between gap-3 rounded-[16px] border border-line bg-svc-attendance/30 px-4 py-3">
          <div className="flex gap-3">
            <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] bg-svc-attendance text-svc-attendance-ink">
              <Smartphone className="h-5 w-5" strokeWidth={2} />
            </span>
            <div>
              <p className="text-[14px] font-bold text-ink">Отметки — в приложении</p>
              <p className="mt-0.5 text-[12px] text-muted">
                На сайте — день компании: кто на смене, кто не отметился, заявки.
              </p>
            </div>
          </div>
          {workplace.groupConversationId ? (
            <Link
              href={`/app/chat/${workplace.groupConversationId}`}
              className="inline-flex items-center gap-1.5 rounded-[12px] border border-line bg-surface px-3 py-2 text-[12px] font-bold text-svc-attendance-ink hover:bg-svc-attendance/40"
            >
              <MessageCircle className="h-4 w-4" strokeWidth={2} />
              Чат
            </Link>
          ) : null}
        </div>

        <div className="grid gap-4 sm:grid-cols-3">
          <StatCard label="На смене / отметились" value={String(onShift.length)} />
          <StatCard label="Не отметились" value={String(missingPunch.length)} warn />
          <StatCard label="OT на проверке" value={String(pendingOt.length)} />
        </div>

        <div className="grid gap-4 lg:grid-cols-2 xl:grid-cols-3">
          <PeopleCard
            title="Не отметились"
            empty="Все дежурные уже отметились"
            rows={missingPunch}
            tone="warn"
          />
          <PeopleCard
            title="Отметились сегодня"
            empty="Пока нет отметок за сегодня"
            rows={members.filter((m) => punchedInIds.has(m.id))}
          />
          <PeopleCard
            title="На дежурстве (ростер)"
            empty="На сегодня никто не в ростере"
            rows={members.filter((m) => onDutyIds.includes(m.id))}
          />
        </div>

        {punchedNotOnRoster.length > 0 ? (
          <PeopleCard
            title="Отметились вне ростера"
            empty=""
            rows={punchedNotOnRoster}
          />
        ) : null}

        {absentToday.length > 0 ? (
          <section className="rounded-[16px] border border-line bg-surface p-4">
            <h2 className="text-[13px] font-bold uppercase tracking-wide text-muted">
              Отсутствия сегодня
            </h2>
            <ul className="mt-3 space-y-2">
              {absentToday.map((a) => {
                const m = members.find((x) => x.id === a.profileId);
                return (
                  <li
                    key={a.id}
                    className="flex justify-between gap-2 rounded-[12px] border border-line px-3 py-2 text-[13px]"
                  >
                    <span className="font-semibold text-ink">
                      {m?.name ?? a.profileId.slice(0, 8)}
                    </span>
                    <span className="text-muted">{a.kind}</span>
                  </li>
                );
              })}
            </ul>
          </section>
        ) : null}

        <section className="rounded-[16px] border border-line bg-surface p-4">
          <div className="flex items-center justify-between gap-2">
            <h2 className="text-[13px] font-bold uppercase tracking-wide text-muted">
              Заявки на исправление / OT
            </h2>
            <Link
              href={`/app/settings/attendance/w/${workplaceId}/duty`}
              className="text-[12px] font-bold text-svc-attendance-ink hover:underline"
            >
              К дежурствам
            </Link>
          </div>
          {pendingOt.length === 0 ? (
            <p className="mt-3 text-[13px] text-muted">
              Нет ожидающих OT. Inbox исправлений отметок — в догоне (см. gaps).
            </p>
          ) : (
            <ul className="mt-3 space-y-2">
              {pendingOt.slice(0, 8).map((o) => {
                const m = members.find((x) => x.id === o.profileId);
                return (
                  <li
                    key={o.id}
                    className="rounded-[12px] border border-line px-3 py-2 text-[13px]"
                  >
                    <span className="font-semibold text-ink">
                      {m?.name ?? o.profileId.slice(0, 8)}
                    </span>
                    <span className="text-muted"> · ожидает проверки</span>
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      </div>

      <AttendanceNameModal
        open={renameOpen}
        title="Переименовать"
        label="Название"
        initialValue={workplace.name}
        submitLabel="Сохранить"
        onClose={() => setRenameOpen(false)}
        onSubmit={async (name) => {
          await renameWorkplace({ workplaceId: workplace.id, name });
          await reload();
        }}
      />
    </AttendanceWorkspaceShell>
  );
}

function StatCard({
  label,
  value,
  warn,
}: {
  label: string;
  value: string;
  warn?: boolean;
}) {
  return (
    <div
      className={`rounded-[16px] border px-4 py-3 ${
        warn
          ? "border-svc-attendance-ink/25 bg-svc-attendance"
          : "border-line bg-surface"
      }`}
    >
      <p className="text-[11px] font-bold uppercase tracking-wide text-muted">{label}</p>
      <p className="mt-1 font-display text-[28px] font-semibold text-ink">{value}</p>
    </div>
  );
}

function PeopleCard({
  title,
  empty,
  rows,
  tone,
}: {
  title: string;
  empty: string;
  rows: MemberRow[];
  tone?: "warn";
}) {
  return (
    <section
      className={`rounded-[16px] border p-4 ${
        tone === "warn"
          ? "border-svc-attendance-ink/30 bg-svc-attendance/40"
          : "border-line bg-surface"
      }`}
    >
      <h2 className="text-[13px] font-bold uppercase tracking-wide text-muted">{title}</h2>
      {rows.length === 0 ? (
        <p className="mt-3 text-[13px] text-muted">{empty}</p>
      ) : (
        <ul className="mt-3 max-h-64 space-y-1.5 overflow-y-auto">
          {rows.map((m) => (
            <li
              key={m.id}
              className="rounded-[10px] border border-line bg-bg px-3 py-2 text-[13px]"
            >
              <span className="font-semibold text-ink">{m.name}</span>
              {m.username ? (
                <span className="text-muted"> · {m.username}</span>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
