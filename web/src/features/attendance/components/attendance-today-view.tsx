"use client";

import { Pencil } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceNameModal } from "@/features/attendance/components/attendance-name-modal";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import {
  fetchBootstrap,
  loadProfileLabels,
  renameWorkplace,
} from "@/features/attendance/lib/attendance-api";
import {
  ABSENCE_KIND_LABEL,
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
import {
  ServiceEmpty,
  ServiceInformer,
  ServiceSection,
} from "@/features/shared/components/service-page";
import { runServiceSwr } from "@/lib/run-service-swr";

type MemberRow = { id: string; name: string; username: string };

type TodaySnapshot = {
  workplace: AttendanceWorkplace;
  members: MemberRow[];
  punches: AttendancePunchRecord[];
  absences: AttendanceAbsence[];
  overtime: AttendanceOvertime[];
};

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

  const applySnapshot = useCallback((data: TodaySnapshot) => {
    setWorkplace(data.workplace);
    setMembers(data.members);
    setPunches(data.punches);
    setAbsences(data.absences);
    setOvertime(data.overtime);
  }, []);

  const reload = useCallback(async () => {
    await runServiceSwr<TodaySnapshot>({
      read: (uid) => {
        const cached = readAttendanceTodayCache(uid, workplaceId, todayKey);
        if (!cached) return null;
        return {
          workplace: cached.workplace,
          members: cached.members,
          punches: revivePunches(cached.punches),
          absences: cached.absences,
          overtime: cached.overtime,
        };
      },
      fetch: async () => {
        const boot = await fetchBootstrap();
        const w =
          boot.workplaces.find((x) => x.id === workplaceId && x.isAdmin) ?? null;
        if (!w) throw new Error("Компания не найдена или нет прав admin");
        const active = boot.memberships.filter(
          (m) => m.workplaceId === workplaceId && m.status === "active",
        );
        const lab = await loadProfileLabels(active.map((m) => m.profileId));
        return {
          workplace: w,
          members: active.map((m) => ({
            id: m.profileId,
            name: lab.get(m.profileId)?.name ?? m.profileId.slice(0, 8),
            username: lab.get(m.profileId)?.username ?? "",
          })),
          punches: boot.punches.filter((p) => p.workplaceId === workplaceId),
          absences: boot.absences.filter((a) => a.workplaceId === workplaceId),
          overtime: boot.overtimeEntries.filter((o) => o.workplaceId === workplaceId),
        };
      },
      write: (uid, data) => {
        writeAttendanceTodayCache(uid, workplaceId, {
          dayKey: todayKey,
          workplace: data.workplace,
          members: data.members,
          punches: serializePunches(data.punches),
          absences: data.absences,
          overtime: data.overtime,
        });
      },
      apply: applySnapshot,
      setLoading,
      setError,
    });
  }, [applySnapshot, todayKey, workplaceId]);

  useEffect(() => {
    void reload();
  }, [reload]);

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
  const punchedToday = members.filter((m) => punchedInIds.has(m.id));

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
            К компаниям
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell
      workplaceId={workplaceId}
      title="Сегодня"
      lead="Кто сейчас на смене и кто ещё не отметился."
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
        <ServiceInformer service="attendance" tone="next">
          На смене {onShift.length} · не отметились {missingPunch.length} · отсутствия{" "}
          {absentToday.length}
        </ServiceInformer>
        <ServiceInformer service="attendance" tone="warning">
          Отметки ставят в приложении. Здесь видно день компании.
        </ServiceInformer>

        <div className="grid gap-4 lg:grid-cols-2">
          <PeopleCard
            title="На смене"
            hint="В графике на сегодня или уже отметились."
            empty="На сегодня никого нет в графике и нет отметок."
            rows={onShift}
          />
          <PeopleCard
            title="Не отметились"
            hint="Дежурные, у которых ещё нет отметки прихода."
            empty="Все дежурные уже отметились."
            rows={missingPunch}
            warn
          />
          <PeopleCard
            title="Отметились вне графика"
            hint="Приход есть, но человека нет в очереди на сегодня."
            empty="Все отметки совпали с графиком."
            rows={punchedNotOnRoster}
          />
          <PeopleCard
            title="Отметились сегодня"
            hint="Кто уже поставил приход."
            empty="Пока нет отметок за сегодня."
            rows={punchedToday}
          />
        </div>

        <ServiceSection
          title="Отсутствия"
          action={
            <Link
              href={`/app/settings/attendance/w/${workplaceId}/duty`}
              className="text-[12px] font-bold text-svc-attendance-ink hover:underline"
            >
              К дежурствам
            </Link>
          }
        >
          <p className="mb-3 text-[12px] leading-snug text-muted">
            Выходной, отпуск или больничный на сегодня.
          </p>
          {absentToday.length === 0 ? (
            <ServiceEmpty>Сегодня оформленных отсутствий нет.</ServiceEmpty>
          ) : (
            <ul className="space-y-1.5">
              {absentToday.map((a) => {
                const m = members.find((x) => x.id === a.profileId);
                return (
                  <li
                    key={a.id}
                    className="flex justify-between gap-2 rounded-[12px] border border-line bg-surface px-3 py-2 text-[13px]"
                  >
                    <span className="font-semibold text-ink">
                      {m?.name ?? a.profileId.slice(0, 8)}
                    </span>
                    <span className="text-muted">
                      {ABSENCE_KIND_LABEL[a.kind] ?? a.kind}
                    </span>
                  </li>
                );
              })}
            </ul>
          )}
        </ServiceSection>

        <ServiceSection title="Заявки на переработку">
          <p className="mb-3 text-[12px] leading-snug text-muted">
            Ждут решения. Принять или отклонить можно в дежурствах.
          </p>
          {pendingOt.length === 0 ? (
            <ServiceEmpty>Нет заявок, которые ждут решения.</ServiceEmpty>
          ) : (
            <ul className="space-y-1.5">
              {pendingOt.slice(0, 8).map((o) => {
                const m = members.find((x) => x.id === o.profileId);
                return (
                  <li
                    key={o.id}
                    className="rounded-[12px] border border-line bg-surface px-3 py-2 text-[13px]"
                  >
                    <span className="font-semibold text-ink">
                      {m?.name ?? o.profileId.slice(0, 8)}
                    </span>
                    <span className="text-muted"> · ждёт решения</span>
                  </li>
                );
              })}
            </ul>
          )}
        </ServiceSection>
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

function PeopleCard({
  title,
  hint,
  empty,
  rows,
  warn,
}: {
  title: string;
  hint: string;
  empty: string;
  rows: MemberRow[];
  warn?: boolean;
}) {
  return (
    <section
      className={`rounded-[16px] border p-4 ${
        warn && rows.length > 0
          ? "border-svc-attendance-ink/30 bg-svc-attendance/40"
          : "border-line bg-surface"
      }`}
    >
      <h2 className="text-[14px] font-bold text-ink">{title}</h2>
      <p className="mt-1 text-[12px] leading-snug text-muted">{hint}</p>
      {rows.length === 0 ? (
        <div className="mt-3">
          <ServiceEmpty>{empty}</ServiceEmpty>
        </div>
      ) : (
        <ul className="mt-3 max-h-64 space-y-1.5 overflow-y-auto">
          {rows.map((m) => (
            <li
              key={m.id}
              className="rounded-[10px] border border-line bg-bg px-3 py-2 text-[13px]"
            >
              <span className="font-semibold text-ink">{m.name}</span>
              {m.username ? <span className="text-muted"> · {m.username}</span> : null}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}
