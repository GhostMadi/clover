"use client";

import { Building2, ChevronRight, FolderPlus, Plus } from "lucide-react";
import Link from "next/link";
import { useCallback, useEffect, useMemo, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AttendanceNameModal } from "@/features/attendance/components/attendance-name-modal";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  createFolder,
  createWorkplace,
  loadAttendanceAdminHub,
  setWorkplaceFolder,
} from "@/features/attendance/lib/attendance-api";
import type {
  AttendanceFolder,
  AttendanceWorkplace,
} from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceShortcut,
  writeAttendanceShortcut,
} from "@/features/attendance/lib/shortcut-prefs";
import { SettingsShell } from "@/features/settings/components/settings-shell";
import { createClient } from "@/lib/supabase/client";
import { serviceTileIcon } from "@/lib/service-accent";

type HubState =
  | { status: "loading" }
  | { status: "error"; message: string }
      | {
          status: "ready";
          folders: AttendanceFolder[];
          adminWorkplaces: AttendanceWorkplace[];
          isWorkerOnly: boolean;
          hasWorkerMembership: boolean;
        };

export function AttendanceHubView() {
  const [uid, setUid] = useState<string | null>(null);
  const [shortcut, setShortcut] = useState(false);
  const [hub, setHub] = useState<HubState>({ status: "loading" });
  const [createOpen, setCreateOpen] = useState(false);
  const [folderOpen, setFolderOpen] = useState(false);
  const [createFolderId, setCreateFolderId] = useState<string | null>(null);

  const reload = useCallback(async () => {
    setHub({ status: "loading" });
    try {
      const data = await loadAttendanceAdminHub();
      setHub({
        status: "ready",
        folders: data.folders,
        adminWorkplaces: data.adminWorkplaces,
        isWorkerOnly: data.isWorkerOnly,
        hasWorkerMembership: data.hasWorkerMembership,
      });
    } catch (e: unknown) {
      setHub({
        status: "error",
        message: e instanceof Error ? e.message : "Не удалось загрузить",
      });
    }
  }, []);

  useEffect(() => {
    setShortcut(readAttendanceShortcut());
    void createClient()
      .auth.getSession()
      .then(({ data }) => {
        const id = data.session?.user.id ?? null;
        setUid(id);
        setShortcut(readAttendanceShortcut(id));
      });
    void reload();
  }, [reload]);

  const grouped = useMemo(() => {
    if (hub.status !== "ready") return null;
    const byFolder = new Map<string | null, AttendanceWorkplace[]>();
    for (const folder of hub.folders) {
      byFolder.set(folder.id, []);
    }
    byFolder.set(null, []);
    for (const w of hub.adminWorkplaces) {
      const key =
        w.folderId && byFolder.has(w.folderId) ? w.folderId : null;
      const list = byFolder.get(key) ?? [];
      list.push(w);
      byFolder.set(key, list);
    }
    return { folders: hub.folders, byFolder };
  }, [hub]);

  const empty =
    hub.status === "ready" &&
    hub.adminWorkplaces.length === 0 &&
    hub.folders.length === 0;

  return (
    <SettingsShell
      title="Посещаемость"
      service="attendance"
      trailing={
        <button
          type="button"
          title="Новая компания"
          onClick={() => {
            setCreateFolderId(null);
            setCreateOpen(true);
          }}
          className="flex h-10 w-10 items-center justify-center rounded-full text-svc-attendance-ink hover:bg-svc-attendance"
          aria-label="Новая компания"
        >
          <Plus className="h-5 w-5" strokeWidth={2.25} />
        </button>
      }
    >
      <div className="space-y-6 px-4 py-5">
        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Навигация
          </p>
          <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
            <div className="flex items-start justify-between gap-3">
              <div className="min-w-0 flex-1">
                <p className="text-[15px] font-bold text-ink">
                  Кнопка «Посещаемость» сбоку
                </p>
                <p className="mt-0.5 text-[12px] text-muted">
                  Открывает «Моя посещаемость»; admin-компании — в Настройках
                </p>
              </div>
              <button
                type="button"
                role="switch"
                aria-checked={shortcut}
                onClick={() => {
                  const next = !shortcut;
                  setShortcut(next);
                  writeAttendanceShortcut(uid, next);
                }}
                className={`relative h-7 w-12 shrink-0 rounded-full transition ${
                  shortcut ? "bg-svc-attendance-ink" : "bg-line"
                }`}
              >
                <span
                  className={`absolute top-0.5 h-6 w-6 rounded-full bg-surface shadow-elevate-sm transition ${
                    shortcut ? "left-[1.35rem]" : "left-0.5"
                  }`}
                />
              </button>
            </div>
          </div>
        </section>

        {hub.status === "loading" ? (
          <AttendanceListShimmer />
        ) : hub.status === "error" ? (
          <div className="space-y-3 rounded-[16px] border border-line bg-surface px-4 py-5">
            <p className="text-[14px] text-error">{hub.message}</p>
            <AppButton type="button" service="attendance" onClick={() => void reload()}>
              Повторить
            </AppButton>
          </div>
        ) : (
          <>
            {hub.hasWorkerMembership ? (
              <Link
                href="/app/attendance"
                className="flex items-center gap-3 rounded-[16px] border border-svc-attendance-ink/30 bg-svc-attendance/50 px-3.5 py-3.5 transition hover:bg-svc-attendance"
              >
                <span className={serviceTileIcon("attendance")}>
                  <Building2 className="h-5 w-5" strokeWidth={2} />
                </span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[15px] font-bold text-ink">
                    Моя посещаемость
                  </span>
                  <span className="block text-[12px] text-muted">
                    Часы, история и детали · без кнопки «Отметиться»
                  </span>
                </span>
                <ChevronRight className="h-5 w-5 text-svc-attendance-ink" />
              </Link>
            ) : null}

            {hub.isWorkerOnly ? (
              <div className="rounded-[16px] border border-line bg-surface px-3.5 py-3.5">
                <p className="text-[14px] font-semibold text-ink">
                  Отметки — в приложении
                </p>
                <p className="mt-1 text-[12px] text-muted">
                  На сайте смотрите детали. Punch и GPS только на телефоне. Ниже
                  можно создать свою компанию как admin.
                </p>
              </div>
            ) : null}

            {empty ? (
              <div className="space-y-4 rounded-[16px] border border-line bg-surface px-4 py-6 text-center">
                <span className={`${serviceTileIcon("attendance")} mx-auto`}>
                  <Building2 className="h-5 w-5" strokeWidth={2} />
                </span>
                <div>
                  <p className="text-[16px] font-bold text-ink">Создать компанию</p>
                  <p className="mt-1 text-[13px] text-muted">
                    Геозона, команда и табель — после создания. Punch остаётся на
                    телефоне у сотрудников.
                  </p>
                </div>
                <AppButton
                  type="button"
                  service="attendance"
                  onClick={() => {
                    setCreateFolderId(null);
                    setCreateOpen(true);
                  }}
                >
                  Создать компанию
                </AppButton>
              </div>
            ) : (
              <section className="space-y-4">
                <div className="flex items-center justify-between gap-2 px-1">
                  <p className="text-[12px] font-bold uppercase tracking-wide text-muted">
                    Компании
                  </p>
                  <button
                    type="button"
                    onClick={() => setFolderOpen(true)}
                    className="inline-flex items-center gap-1.5 text-[12px] font-bold text-svc-attendance-ink"
                  >
                    <FolderPlus className="h-4 w-4" strokeWidth={2} />
                    Папка
                  </button>
                </div>

                {grouped?.folders.map((folder) => {
                  const items = grouped.byFolder.get(folder.id) ?? [];
                  return (
                    <div key={folder.id} className="space-y-2">
                      <div className="flex items-center justify-between gap-2 px-1">
                        <p className="text-[13px] font-bold text-ink">{folder.name}</p>
                        <button
                          type="button"
                          onClick={() => {
                            setCreateFolderId(folder.id);
                            setCreateOpen(true);
                          }}
                          className="text-[12px] font-semibold text-svc-attendance-ink"
                        >
                          + в папку
                        </button>
                      </div>
                      {items.length === 0 ? (
                        <p className="px-1 text-[12px] text-muted">Пусто</p>
                      ) : (
                        <WorkplaceList
                          items={items}
                          folders={grouped.folders}
                          onMoved={() => void reload()}
                        />
                      )}
                    </div>
                  );
                })}

                <div className="space-y-2">
                  {(grouped?.folders.length ?? 0) > 0 ? (
                    <p className="px-1 text-[13px] font-bold text-ink">Без папки</p>
                  ) : null}
                  <WorkplaceList
                    items={grouped?.byFolder.get(null) ?? []}
                    folders={grouped?.folders ?? []}
                    onMoved={() => void reload()}
                  />
                </div>
              </section>
            )}
          </>
        )}
      </div>

      <AttendanceNameModal
        open={createOpen}
        title="Новая компания"
        label="Название"
        placeholder="Например, Clover Café"
        initialValue="Компания"
        onClose={() => setCreateOpen(false)}
        onSubmit={async (name) => {
          await createWorkplace({ name, folderId: createFolderId });
          await reload();
        }}
      />
      <AttendanceNameModal
        open={folderOpen}
        title="Новая папка"
        label="Название папки"
        placeholder="Например, Филиалы"
        onClose={() => setFolderOpen(false)}
        onSubmit={async (name) => {
          await createFolder(name);
          await reload();
        }}
      />
    </SettingsShell>
  );
}

function WorkplaceList({
  items,
  folders,
  onMoved,
}: {
  items: AttendanceWorkplace[];
  folders: AttendanceFolder[];
  onMoved: () => void;
}) {
  if (items.length === 0) return null;
  return (
    <ul className="overflow-hidden rounded-[16px] border border-line bg-surface">
      {items.map((w, i) => (
        <li key={w.id} className={i > 0 ? "border-t border-line" : ""}>
          <div className="flex items-stretch">
            <Link
              href={`/app/settings/attendance/w/${w.id}`}
              className="flex min-w-0 flex-1 items-center gap-3 px-3.5 py-3.5 transition hover:bg-svc-attendance/40"
            >
              <span className={serviceTileIcon("attendance")}>
                <Building2 className="h-5 w-5" strokeWidth={2} />
              </span>
              <span className="min-w-0 flex-1">
                <span className="block truncate text-[15px] font-bold text-ink">
                  {w.name}
                </span>
                <span className="block text-[12px] text-muted">Компания · admin</span>
              </span>
              <ChevronRight className="h-5 w-5 shrink-0 text-muted" strokeWidth={2} />
            </Link>
            {folders.length > 0 ? (
              <label className="flex items-center border-l border-line px-2">
                <span className="sr-only">Папка</span>
                <select
                  className="max-w-[7.5rem] truncate rounded-[10px] border-0 bg-transparent py-1 text-[11px] font-semibold text-muted outline-none"
                  value={w.folderId ?? ""}
                  onChange={(e) => {
                    const next = e.target.value || null;
                    void setWorkplaceFolder({
                      workplaceId: w.id,
                      folderId: next,
                    }).then(onMoved);
                  }}
                >
                  <option value="">Без папки</option>
                  {folders.map((f) => (
                    <option key={f.id} value={f.id}>
                      {f.name}
                    </option>
                  ))}
                </select>
              </label>
            ) : null}
          </div>
        </li>
      ))}
    </ul>
  );
}
