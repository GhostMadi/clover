import {
  dayKey,
  formatDateKey,
  formatMinutes,
  isoWeekday,
  parseDateKey,
  type AttendanceAbsence,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";

export type AnalyticsPunch = {
  id: string;
  profileId: string;
  punchKind: string;
  punchedAt: Date;
  cancelled: boolean;
};

export type DayStatus =
  | "full"
  | "late"
  | "partial"
  | "absent"
  | "excused"
  | "off";

export type WorkerDay = {
  dateKey: string;
  status: DayStatus;
  totalMinutes: number;
  lateMinutes: number;
};

export type AnalyticsWorker = {
  id: string;
  displayName: string;
  username: string;
  totalMinutes: number;
  daysWorked: number;
  lateDays: number;
  missedDays: number;
  days: WorkerDay[];
};

export type AnalyticsOverview = {
  workers: AnalyticsWorker[];
  totalMinutes: number;
  avgMinutesPerWorker: number;
  lateDaysTotal: number;
  missedDaysTotal: number;
};

export function mapOverviewPunch(
  raw: Record<string, unknown>,
): AnalyticsPunch | null {
  const id = String(raw.id ?? "").trim();
  const profileId = String(raw.profile_id ?? "").trim();
  const punchedAt = new Date(String(raw.punched_at ?? ""));
  if (!id || !profileId || Number.isNaN(punchedAt.getTime())) return null;
  return {
    id,
    profileId,
    punchKind: String(raw.punch_kind ?? "clock_in"),
    punchedAt,
    cancelled: raw.cancelled_at != null,
  };
}

function coversAbsence(a: AttendanceAbsence, key: Date): boolean {
  const start = dayKey(parseDateKey(a.startDate));
  const end = dayKey(parseDateKey(a.endDate));
  return key >= start && key <= end;
}

function dayRecord(params: {
  key: Date;
  punches: AnalyticsPunch[];
  absences: AttendanceAbsence[];
  workplace: AttendanceWorkplace;
  today: Date;
}): WorkerDay {
  const { key, punches, absences, workplace, today } = params;
  const dateKey = formatDateKey(key);
  if (key > today) {
    return { dateKey, status: "off", totalMinutes: 0, lateMinutes: 0 };
  }
  if (absences.some((a) => coversAbsence(a, key))) {
    return { dateKey, status: "excused", totalMinutes: 0, lateMinutes: 0 };
  }
  const dayPunches = punches
    .filter((p) => !p.cancelled && formatDateKey(dayKey(p.punchedAt)) === dateKey)
    .sort((a, b) => a.punchedAt.getTime() - b.punchedAt.getTime());

  if (dayPunches.length === 0) {
    const wd = isoWeekday(key);
    if (wd === 6 || wd === 7) {
      return { dateKey, status: "off", totalMinutes: 0, lateMinutes: 0 };
    }
    return { dateKey, status: "absent", totalMinutes: 0, lateMinutes: 0 };
  }

  let firstIn: Date | null = null;
  let lastOut: Date | null = null;
  for (const p of dayPunches) {
    if (p.punchKind === "clock_in" && !firstIn) firstIn = p.punchedAt;
    if (p.punchKind === "clock_out") lastOut = p.punchedAt;
  }

  let minutes = 0;
  if (firstIn && lastOut && lastOut >= firstIn) {
    minutes = Math.round((lastOut.getTime() - firstIn.getTime()) / 60000);
  }

  let status: DayStatus = "full";
  let lateMinutes = 0;
  if (firstIn && !lastOut) {
    status = "partial";
  } else if (firstIn && workplace.clockInScheduled) {
    const [hh, mm] = workplace.clockInScheduled.split(":").map(Number);
    const scheduledAt = new Date(
      key.getFullYear(),
      key.getMonth(),
      key.getDate(),
      hh ?? 0,
      mm ?? 0,
    );
    if (firstIn.getTime() > scheduledAt.getTime() + 5 * 60000) {
      status = "late";
      lateMinutes = Math.round(
        (firstIn.getTime() - scheduledAt.getTime()) / 60000,
      );
    }
  }

  return { dateKey, status, totalMinutes: minutes, lateMinutes };
}

export function buildAnalyticsOverview(params: {
  workplace: AttendanceWorkplace;
  workerIds: string[];
  labels: Map<string, { name: string; username: string }>;
  punches: AnalyticsPunch[];
  absences: AttendanceAbsence[];
  start: string;
  end: string;
}): AnalyticsOverview {
  const start = dayKey(parseDateKey(params.start));
  const end = dayKey(parseDateKey(params.end));
  const today = dayKey(new Date());
  const workers: AnalyticsWorker[] = [];

  for (const id of params.workerIds) {
    const label = params.labels.get(id);
    const punches = params.punches.filter((p) => p.profileId === id);
    const absences = params.absences.filter((a) => a.profileId === id);
    const days: WorkerDay[] = [];
    let total = 0;
    let worked = 0;
    let late = 0;
    let missed = 0;
    for (let d = new Date(start); d <= end; d.setDate(d.getDate() + 1)) {
      const key = dayKey(d);
      const record = dayRecord({
        key,
        punches,
        absences,
        workplace: params.workplace,
        today,
      });
      days.push(record);
      total += record.totalMinutes;
      if (
        record.status === "full" ||
        record.status === "late" ||
        record.status === "partial"
      ) {
        worked += 1;
      }
      if (record.status === "late") late += 1;
      if (record.status === "absent" || record.status === "partial") missed += 1;
    }
    workers.push({
      id,
      displayName: label?.name ?? id.slice(0, 8),
      username: label?.username ?? "",
      totalMinutes: total,
      daysWorked: worked,
      lateDays: late,
      missedDays: missed,
      days,
    });
  }

  workers.sort((a, b) => b.totalMinutes - a.totalMinutes);
  const totalMinutes = workers.reduce((s, w) => s + w.totalMinutes, 0);
  return {
    workers,
    totalMinutes,
    avgMinutesPerWorker:
      workers.length === 0 ? 0 : Math.floor(totalMinutes / workers.length),
    lateDaysTotal: workers.reduce((s, w) => s + w.lateDays, 0),
    missedDaysTotal: workers.reduce((s, w) => s + w.missedDays, 0),
  };
}

export { formatMinutes };
