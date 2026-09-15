"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import {
  getAdminWorkplace,
  listPunchCorrections,
  resolvePunchCorrection,
} from "@/features/attendance/lib/attendance-api";
import {
  CORRECTION_STATUS_LABEL,
  punchKindLabelRu,
  type AttendanceCorrectionRequest,
  type AttendanceCorrectionStatus,
  type AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";

type Tab = "pending" | "approved" | "rejected";

function formatCorrectionTime(iso: string | null | undefined): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  const dd = String(d.getDate()).padStart(2, "0");
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const hh = String(d.getHours()).padStart(2, "0");
  const min = String(d.getMinutes()).padStart(2, "0");
  return `${dd}.${mm} ${hh}:${min}`;
}

function statusBadgeClass(status: AttendanceCorrectionStatus): string {
  if (status === "approved") {
    return "bg-svc-attendance text-svc-attendance-ink";
  }
  if (status === "rejected") {
    return "bg-destructive/10 text-error";
  }
  return "bg-bg text-muted";
}

export function AttendanceCorrectionsView({
  workplaceId,
}: {
  workplaceId: string;
}) {
  const back = `/app/settings/attendance/w/${workplaceId}`;
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [workplace, setWorkplace] = useState<AttendanceWorkplace | null>(null);
  const [items, setItems] = useState<AttendanceCorrectionRequest[]>([]);
  const [tab, setTab] = useState<Tab>("pending");
  const [busyId, setBusyId] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  const reload = useCallback(async (opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const w = await getAdminWorkplace(workplaceId);
      if (!w) {
        setError("Компания не найдена или нет прав admin");
        setWorkplace(null);
        setItems([]);
        return;
      }
      const list = await listPunchCorrections({ workplaceId });
      setWorkplace(w);
      setItems(list);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить запросы");
    } finally {
      setLoading(false);
    }
  }, [workplaceId]);

  useEffect(() => {
    void reload();
  }, [reload]);

  const counts = useMemo(() => {
    let pending = 0;
    let approved = 0;
    let rejected = 0;
    for (const item of items) {
      if (item.status === "approved") approved += 1;
      else if (item.status === "rejected") rejected += 1;
      else pending += 1;
    }
    return { pending, approved, rejected };
  }, [items]);

  const filtered = useMemo(
    () => items.filter((item) => item.status === tab),
    [items, tab],
  );

  const resolve = async (
    correctionId: string,
    status: "approved" | "rejected",
  ) => {
    setBusyId(correctionId);
    setActionError(null);
    const prev = items;
    setItems((list) =>
      list.map((item) =>
        item.id === correctionId
          ? {
              ...item,
              status,
              resolvedAt: new Date().toISOString(),
            }
          : item,
      ),
    );
    try {
      await resolvePunchCorrection({ correctionId, status });
      await reload({ soft: true });
    } catch (e: unknown) {
      setItems(prev);
      setActionError(
        e instanceof Error ? e.message : "Не удалось сохранить решение",
      );
    } finally {
      setBusyId(null);
    }
  };

  if (loading) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Исправления">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={6} />
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (error || !workplace) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Исправления">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">
            {error ?? "Нет данных"}
          </p>
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
      title="Исправления"
      companyName={workplace.name}
    >
      <div className="space-y-4 px-4 py-4 pb-10">
        <p className="text-[13px] text-muted">
          Работник просит поправить отметку. Утвердите — время обновится;
          отклоните — без изменений.
        </p>

        <div className="flex gap-1 rounded-[14px] border border-line bg-surface p-1">
          {(
            [
              ["pending", `Ожидают · ${counts.pending}`],
              ["approved", `Утверждены · ${counts.approved}`],
              ["rejected", `Отклонены · ${counts.rejected}`],
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

        {actionError ? (
          <p className="text-[13px] text-error">{actionError}</p>
        ) : null}

        {filtered.length === 0 ? (
          <p className="py-10 text-center text-[14px] text-muted">
            {tab === "approved"
              ? "Нет утверждённых запросов"
              : tab === "rejected"
                ? "Нет отклонённых запросов"
                : "Нет ожидающих запросов"}
          </p>
        ) : (
          <ul className="space-y-2.5">
            {filtered.map((item) => {
              const punched = formatCorrectionTime(item.punchedAt);
              const proposed = formatCorrectionTime(item.proposedPunchedAt);
              const created = formatCorrectionTime(item.createdAt);
              const note = item.note?.trim();
              return (
                <li
                  key={item.id}
                  className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5"
                >
                  <div className="flex items-start gap-2">
                    <p className="min-w-0 flex-1 text-[15px] font-bold text-ink">
                      {item.workerName}
                    </p>
                    <span
                      className={`shrink-0 rounded-full px-2.5 py-1 text-[11px] font-bold ${statusBadgeClass(item.status)}`}
                    >
                      {CORRECTION_STATUS_LABEL[item.status]}
                    </span>
                  </div>
                  <p className="mt-1 text-[14px] font-semibold text-ink">
                    {punchKindLabelRu(item.punchKind)}
                  </p>
                  {punched ? (
                    <p className="mt-0.5 text-[13px] text-muted">
                      Сейчас: {punched}
                    </p>
                  ) : null}
                  {proposed ? (
                    <p className="text-[13px] text-muted">
                      Предлагает: {proposed}
                    </p>
                  ) : null}
                  {note ? (
                    <p className="mt-1.5 text-[13px] leading-snug text-muted">
                      {note}
                    </p>
                  ) : null}
                  {created ? (
                    <p className="mt-1 text-[12px] text-muted">
                      Запрос · {created}
                    </p>
                  ) : null}
                  {item.status === "pending" ? (
                    <div className="mt-3 flex gap-2">
                      <AppButton
                        type="button"
                        service="attendance"
                        size="row"
                        className="flex-1"
                        loading={busyId === item.id}
                        disabled={busyId != null}
                        onClick={() => void resolve(item.id, "approved")}
                      >
                        Утвердить
                      </AppButton>
                      <AppButton
                        type="button"
                        service="attendance"
                        variant="outline"
                        size="row"
                        className="flex-1"
                        disabled={busyId != null}
                        onClick={() => void resolve(item.id, "rejected")}
                      >
                        Отклонить
                      </AppButton>
                    </div>
                  ) : null}
                </li>
              );
            })}
          </ul>
        )}
      </div>
    </AttendanceWorkspaceShell>
  );
}
