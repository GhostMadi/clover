import {
  isWorkerMembershipStatus,
  mapAbsence,
  mapCustomPunch,
  mapFolder,
  mapMembershipLite,
  mapOvertime,
  mapPunchRecord,
  mapWorkplace,
  dutyRosterToJson,
  payrollRulesToJson,
  timeToRpc,
  type AttendanceAbsence,
  type AttendanceAdminHub,
  type AttendanceCustomPunch,
  type AttendanceDutyRoster,
  type AttendanceMembershipLite,
  type AttendanceOvertime,
  type AttendancePayrollRules,
  type AttendancePunchRecord,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import {
  mapOverviewPunch,
  type AnalyticsPunch,
} from "@/features/attendance/lib/attendance-analytics";
import { createClient } from "@/lib/supabase/client";

function asRecordArray(value: unknown): Record<string, unknown>[] {
  if (!Array.isArray(value)) return [];
  return value.filter(
    (row): row is Record<string, unknown> =>
      row != null && typeof row === "object" && !Array.isArray(row),
  );
}

export type BootstrapParsed = {
  folders: AttendanceAdminHub["folders"];
  workplaces: AttendanceWorkplace[];
  memberships: AttendanceMembershipLite[];
  /** Memberships текущего пользователя (active/pending). */
  myMemberships: AttendanceMembershipLite[];
  absences: AttendanceAbsence[];
  overtimeEntries: AttendanceOvertime[];
  punches: AttendancePunchRecord[];
  userId: string | null;
};

export async function fetchBootstrap(): Promise<BootstrapParsed> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return {
      folders: [],
      workplaces: [],
      memberships: [],
      myMemberships: [],
      absences: [],
      overtimeEntries: [],
      punches: [],
      userId: null,
    };
  }

  const { data, error } = await supabase.rpc("attendance_bootstrap_me", {
    p_since: null,
  });
  if (error) throw error;

  const root =
    data != null && typeof data === "object" && !Array.isArray(data)
      ? (data as Record<string, unknown>)
      : {};

  const folders = asRecordArray(root.folders)
    .map(mapFolder)
    .filter((f): f is NonNullable<typeof f> => f != null);

  const typeLabels = new Map<string, string>();
  const punchesByWorkplace = new Map<string, AttendanceCustomPunch[]>();
  for (const [i, raw] of asRecordArray(root.punch_types).entries()) {
    const wid = String(raw.workplace_id ?? "").trim();
    const punch = mapCustomPunch(raw, i);
    if (punch) {
      typeLabels.set(punch.id, punch.label);
      if (wid) {
        const list = punchesByWorkplace.get(wid) ?? [];
        list.push(punch);
        punchesByWorkplace.set(wid, list);
      }
    }
  }

  const workplaces = asRecordArray(root.workplaces)
    .map((raw) => {
      const id = String(raw.id ?? "").trim();
      const custom = (punchesByWorkplace.get(id) ?? [])
        .slice()
        .sort((a, b) => a.sortOrder - b.sortOrder);
      return mapWorkplace(raw, custom);
    })
    .filter((w): w is AttendanceWorkplace => w != null);

  const memberships = asRecordArray(root.memberships)
    .map(mapMembershipLite)
    .filter((m): m is AttendanceMembershipLite => m != null);

  const myMemberships = memberships.filter(
    (m) =>
      m.profileId === user.id &&
      (m.status === "active" ||
        m.status === "pending" ||
        m.status === "accepted"),
  );

  const absences = asRecordArray(root.absences)
    .map(mapAbsence)
    .filter((a): a is AttendanceAbsence => a != null);

  const overtimeEntries = asRecordArray(root.overtime_entries)
    .map(mapOvertime)
    .filter((o): o is AttendanceOvertime => o != null);

  const punches = asRecordArray(root.punches)
    .map((raw) => mapPunchRecord(raw, typeLabels))
    .filter((p): p is AttendancePunchRecord => p != null);

  return {
    folders,
    workplaces,
    memberships,
    myMemberships,
    absences,
    overtimeEntries,
    punches,
    userId: user.id,
  };
}

/** Admin-хаб: bootstrap + filter `is_admin`. */
export async function loadAttendanceAdminHub(): Promise<
  AttendanceAdminHub & { hasWorkerMembership: boolean }
> {
  const { folders, workplaces, memberships, myMemberships } =
    await fetchBootstrap();
  const adminWorkplaces = workplaces.filter((w) => w.isAdmin);
  const hasWorkerMembership = myMemberships.some((m) =>
    isWorkerMembershipStatus(m.status),
  );
  const isWorkerOnly = adminWorkplaces.length === 0 && hasWorkerMembership;
  return {
    folders,
    adminWorkplaces,
    isWorkerOnly,
    hasWorkerMembership,
  };
}

export type WorkerHubData = {
  memberships: AttendanceMembershipLite[];
  workplaces: AttendanceWorkplace[];
  punches: AttendancePunchRecord[];
  absences: AttendanceAbsence[];
  userId: string;
};

export async function loadWorkerHub(): Promise<WorkerHubData | null> {
  const boot = await fetchBootstrap();
  if (!boot.userId) return null;
  const memberships = boot.myMemberships.filter(
    (m) => m.status !== "declined",
  );
  return {
    memberships,
    workplaces: boot.workplaces,
    punches: boot.punches.filter((p) => p.profileId === boot.userId),
    absences: boot.absences.filter((a) => a.profileId === boot.userId),
    userId: boot.userId,
  };
}

export async function createWorkplace(params: {
  name: string;
  folderId?: string | null;
}): Promise<string> {
  const name = params.name.trim();
  if (!name) throw new Error("Укажите название");
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_create_workplace", {
    p_name: name,
    p_folder_id: params.folderId ?? null,
    p_lat: null,
    p_lng: null,
    p_geofence_radius_m: 150,
  });
  if (error) throw error;
  return String(data);
}

export async function createFolder(name: string): Promise<string> {
  const trimmed = name.trim();
  if (!trimmed) throw new Error("Укажите название папки");
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_create_folder", {
    p_name: trimmed,
  });
  if (error) throw error;
  return String(data);
}

export async function setWorkplaceFolder(params: {
  workplaceId: string;
  folderId: string | null;
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_set_workplace_folder", {
    p_workplace_id: params.workplaceId,
    p_folder_id: params.folderId,
  });
  if (error) throw error;
}

export async function getAdminWorkplace(
  workplaceId: string,
): Promise<AttendanceWorkplace | null> {
  const hub = await loadAttendanceAdminHub();
  return hub.adminWorkplaces.find((w) => w.id === workplaceId) ?? null;
}

export async function renameWorkplace(params: {
  workplaceId: string;
  name: string;
}): Promise<void> {
  const name = params.name.trim();
  if (!name) throw new Error("Укажите название");
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_update_workplace_settings", {
    p_workplace_id: params.workplaceId,
    p_name: name,
    p_bump_config: false,
  });
  if (error) throw error;
}

export async function updateGeofence(params: {
  workplaceId: string;
  lat: number;
  lng: number;
  geofenceRadiusM: number;
}): Promise<void> {
  const radius = Math.round(params.geofenceRadiusM);
  if (radius < 50 || radius > 300) {
    throw new Error("Радиус должен быть от 50 до 300 м");
  }
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_update_workplace_settings", {
    p_workplace_id: params.workplaceId,
    p_lat: params.lat,
    p_lng: params.lng,
    p_geofence_radius_m: radius,
    p_bump_config: true,
  });
  if (error) throw error;
}

export async function setDutyOnlyPunch(params: {
  workplaceId: string;
  dutyOnlyPunch: boolean;
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_set_duty_only_punch", {
    p_workplace_id: params.workplaceId,
    p_duty_only_punch: params.dutyOnlyPunch,
  });
  if (error) throw error;
}

export async function savePunchConfig(params: {
  workplaceId: string;
  clockInEnabled: boolean;
  clockOutEnabled: boolean;
  clockInScheduled: string | null;
  clockOutScheduled: string | null;
  customPunches: Array<{
    id?: string;
    label: string;
    scheduledTime: string | null;
  }>;
}): Promise<void> {
  if (!params.clockInEnabled && !params.clockOutEnabled) {
    throw new Error("Включите хотя бы «Пришёл» или «Ушёл»");
  }
  const supabase = createClient();
  const { error: settingsError } = await supabase.rpc(
    "attendance_update_workplace_settings",
    {
      p_workplace_id: params.workplaceId,
      p_clock_in_enabled: params.clockInEnabled,
      p_clock_out_enabled: params.clockOutEnabled,
      p_clock_in_scheduled: params.clockInEnabled
        ? timeToRpc(params.clockInScheduled)
        : null,
      p_clock_out_scheduled: params.clockOutEnabled
        ? timeToRpc(params.clockOutScheduled)
        : null,
      p_bump_config: true,
    },
  );
  if (settingsError) throw settingsError;

  const types = params.customPunches
    .map((p, i) => {
      const label = p.label.trim();
      if (!label) return null;
      const scheduled = timeToRpc(p.scheduledTime);
      return {
        ...(p.id ? { id: p.id } : {}),
        label,
        ...(scheduled ? { scheduled_time: scheduled } : {}),
        sort_order: i,
      };
    })
    .filter((p): p is NonNullable<typeof p> => p != null);

  const { error: typesError } = await supabase.rpc(
    "attendance_replace_punch_types",
    {
      p_workplace_id: params.workplaceId,
      p_types: types,
    },
  );
  if (typesError) throw typesError;
}

/** Члены одной компании (admin видит roster в bootstrap). */
export async function listWorkplaceMembers(
  workplaceId: string,
): Promise<AttendanceMembershipLite[]> {
  const { memberships, workplaces } = await fetchBootstrap();
  const admin = workplaces.find((w) => w.id === workplaceId && w.isAdmin);
  if (!admin) return [];
  return memberships.filter((m) => m.workplaceId === workplaceId);
}

export async function acceptAttendanceInvite(membershipId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_accept_invite", {
    p_membership_id: membershipId,
  });
  if (error) throw error;
}

export async function rejectAttendanceInvite(membershipId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_reject_invite", {
    p_membership_id: membershipId,
  });
  if (error) throw error;
}

export async function ackAttendanceConfig(workplaceId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_ack_config", {
    p_workplace_id: workplaceId,
  });
  if (error) throw error;
}

export async function inviteMember(params: {
  workplaceId: string;
  profileId: string;
}): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_invite_member", {
    p_workplace_id: params.workplaceId,
    p_profile_id: params.profileId,
  });
  if (error) throw error;
  return String(data);
}

export async function archiveMember(membershipId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_archive_member", {
    p_membership_id: membershipId,
  });
  if (error) throw error;
}

export async function reinviteMember(membershipId: string): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_reinvite_member", {
    p_membership_id: membershipId,
  });
  if (error) throw error;
}

export async function setMemberBaseSalary(params: {
  workplaceId: string;
  profileId: string;
  baseSalaryTenge: number;
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_set_member_base_salary", {
    p_workplace_id: params.workplaceId,
    p_profile_id: params.profileId,
    p_base_salary_tenge: Math.max(0, Math.round(params.baseSalaryTenge)),
  });
  if (error) throw error;
}

export type AttendanceProfileHit = {
  id: string;
  username: string;
  fullName: string | null;
  avatarUrl: string | null;
};

export async function searchAttendanceProfiles(
  query: string,
  excludeProfileIds: Set<string> = new Set(),
): Promise<AttendanceProfileHit[]> {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return [];

  const q = query.trim().replace(/^@+/, "");
  let builder = supabase
    .from("profiles")
    .select("id, username, full_name, avatar_url")
    .neq("id", user.id);

  if (q) {
    const pattern = `%${q}%`;
    builder = builder.or(`username.ilike.${pattern},full_name.ilike.${pattern}`);
  }

  const { data, error } = await builder.order("username").limit(20);
  if (error) throw error;

  return (data ?? [])
    .map((row) => {
      const id = String(row.id ?? "").trim();
      if (!id || excludeProfileIds.has(id)) return null;
      return {
        id,
        username: String(row.username ?? "noName"),
        fullName: row.full_name ? String(row.full_name) : null,
        avatarUrl: row.avatar_url ? String(row.avatar_url) : null,
      };
    })
    .filter((h): h is AttendanceProfileHit => h != null);
}

export async function updateDutyRoster(params: {
  workplaceId: string;
  roster: AttendanceDutyRoster;
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_update_duty_roster", {
    p_workplace_id: params.workplaceId,
    p_duty_roster: dutyRosterToJson(params.roster),
  });
  if (error) throw error;
}

export async function setOvertimeStatus(params: {
  entryId: string;
  status: "approved" | "rejected";
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_set_overtime_status", {
    p_entry_id: params.entryId,
    p_status: params.status,
  });
  if (error) throw error;
}

export async function upsertAbsence(params: {
  workplaceId: string;
  profileId: string;
  kind: string;
  startDate: string;
  endDate: string;
  note?: string | null;
}): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_upsert_absence", {
    p_workplace_id: params.workplaceId,
    p_profile_id: params.profileId,
    p_kind: params.kind,
    p_start_date: params.startDate,
    p_end_date: params.endDate,
    p_note: params.note ?? null,
    p_absence_id: null,
  });
  if (error) throw error;
  return String(data);
}

export async function loadAnalyticsOverviewRaw(params: {
  workplaceId: string;
  start: string;
  end: string;
}): Promise<{ punches: AnalyticsPunch[]; absences: AttendanceAbsence[] }> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_analytics_overview", {
    p_workplace_id: params.workplaceId,
    p_start: params.start,
    p_end: params.end,
  });
  if (error) throw error;
  const root =
    data != null && typeof data === "object" && !Array.isArray(data)
      ? (data as Record<string, unknown>)
      : {};
  const punches = asRecordArray(root.punches)
    .map(mapOverviewPunch)
    .filter((p): p is AnalyticsPunch => p != null);
  const absences = asRecordArray(root.absences)
    .map(mapAbsence)
    .filter((a): a is AttendanceAbsence => a != null);
  return { punches, absences };
}

export async function downloadTimesheetCsv(params: {
  workplaceId: string;
  start: string;
  end: string;
}): Promise<string> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_timesheet_csv", {
    p_workplace_id: params.workplaceId,
    p_start: params.start,
    p_end: params.end,
  });
  if (error) throw error;
  return String(data ?? "");
}

export async function updatePayrollSettings(params: {
  workplaceId: string;
  rules: AttendancePayrollRules;
}): Promise<void> {
  const supabase = createClient();
  const { error } = await supabase.rpc("attendance_update_payroll_settings", {
    p_workplace_id: params.workplaceId,
    p_payroll_rules: payrollRulesToJson(params.rules),
  });
  if (error) throw error;
}

export type PayrollPreview = {
  periodLabel: string;
  workers: Array<{
    workerId: string;
    displayName: string;
    username: string;
    baseSalary: number;
    netPay: number;
    lines: Array<{
      label: string;
      detail: string;
      amount: number;
      kind: string;
    }>;
  }>;
  team: {
    baseTotal: number;
    deductionsTotal: number;
    bonusesTotal: number;
    netTotal: number;
  };
};

export async function payrollPreview(params: {
  workplaceId: string;
  start: string;
  end: string;
  rules?: AttendancePayrollRules | null;
}): Promise<PayrollPreview> {
  const supabase = createClient();
  const { data, error } = await supabase.rpc("attendance_payroll_preview", {
    p_workplace_id: params.workplaceId,
    p_start: params.start,
    p_end: params.end,
    p_rules: params.rules ? payrollRulesToJson(params.rules) : null,
  });
  if (error) throw error;
  const root =
    data != null && typeof data === "object" && !Array.isArray(data)
      ? (data as Record<string, unknown>)
      : {};
  const teamRaw =
    root.team != null && typeof root.team === "object"
      ? (root.team as Record<string, unknown>)
      : {};
  const workers = asRecordArray(root.workers).map((w) => ({
    workerId: String(w.worker_id ?? ""),
    displayName: String(w.display_name ?? ""),
    username: String(w.username ?? ""),
    baseSalary: Number(w.base_salary) || 0,
    netPay: Number(w.net_pay) || 0,
    lines: asRecordArray(w.lines).map((l) => ({
      label: String(l.label ?? ""),
      detail: String(l.detail ?? ""),
      amount: Number(l.amount) || 0,
      kind: String(l.kind ?? ""),
    })),
  }));
  return {
    periodLabel: String(root.period_label ?? ""),
    workers,
    team: {
      baseTotal: Number(teamRaw.base_total) || 0,
      deductionsTotal: Number(teamRaw.deductions_total) || 0,
      bonusesTotal: Number(teamRaw.bonuses_total) || 0,
      netTotal: Number(teamRaw.net_total) || 0,
    },
  };
}

export async function loadProfileLabels(
  ids: string[],
): Promise<Map<string, { name: string; username: string }>> {
  const labels = new Map<string, { name: string; username: string }>();
  if (ids.length === 0) return labels;
  const supabase = createClient();
  const { data } = await supabase
    .from("profiles")
    .select("id, username, full_name")
    .in("id", ids);
  for (const row of data ?? []) {
    const id = String(row.id);
    const username = String(row.username ?? "").trim();
    const fullName = String(row.full_name ?? "").trim();
    const handle = username
      ? username.startsWith("@")
        ? username
        : `@${username}`
      : "";
    labels.set(id, {
      name: fullName || handle || id.slice(0, 8),
      username: handle || username || id.slice(0, 8),
    });
  }
  return labels;
}
