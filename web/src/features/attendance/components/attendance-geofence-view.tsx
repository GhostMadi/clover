"use client";

import { useRouter } from "next/navigation";
import { useEffect, useId, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppButtonLink } from "@/components/shared/app-button";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  getAdminWorkplace,
  updateGeofence,
} from "@/features/attendance/lib/attendance-api";
import { hasGeofenceCenter } from "@/features/attendance/lib/attendance-model";
import {
  readAttendanceWorkplaceCache,
  writeAttendanceWorkplaceCache,
} from "@/features/attendance/lib/attendance-prefs";
import { AttendanceWorkspaceShell } from "@/features/attendance/components/attendance-workspace-shell";
import { MapboxPinMap } from "@/features/maps/mapbox-pin-map";
import { getSessionUserId } from "@/lib/run-service-swr";

const ALMATY = { lat: 43.238949, lon: 76.889709 };

function zoomForRadius(radiusM: number): number {
  if (radiusM <= 75) return 16.5;
  if (radiusM <= 150) return 15.5;
  return 14.5;
}

export function AttendanceGeofenceView({ workplaceId }: { workplaceId: string }) {
  const router = useRouter();
  const hostId = useId().replace(/:/g, "");
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [mapError, setMapError] = useState<string | null>(null);
  const [pin, setPin] = useState(ALMATY);
  const [radius, setRadius] = useState(150);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const back = `/app/settings/attendance/w/${workplaceId}/settings`;

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const uid = await getSessionUserId();
      if (cancelled) return;
      const apply = (w: NonNullable<Awaited<ReturnType<typeof getAdminWorkplace>>>) => {
        if (hasGeofenceCenter(w)) {
          setPin({ lat: w.latitude!, lon: w.longitude! });
        }
        setRadius(w.geofenceRadiusM || 150);
      };
      const cached = readAttendanceWorkplaceCache(uid, workplaceId);
      if (cached) {
        apply(cached);
        setLoading(false);
      }
      try {
        const w = await getAdminWorkplace(workplaceId);
        if (cancelled) return;
        if (!w) {
          if (!cached) setLoadError("Компания не найдена или нет прав admin");
          setLoading(false);
          return;
        }
        apply(w);
        writeAttendanceWorkplaceCache(uid, workplaceId, w);
        setLoading(false);
      } catch (e: unknown) {
        if (cancelled) return;
        if (!cached) {
          setLoadError(e instanceof Error ? e.message : "Не удалось загрузить");
        }
        setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [workplaceId]);

  const save = async () => {
    setSaving(true);
    setError(null);
    try {
      await updateGeofence({
        workplaceId,
        lat: pin.lat,
        lng: pin.lon,
        geofenceRadiusM: radius,
      });
      router.push(back);
      router.refresh();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Геозона">
        <div className="px-4 py-5">
          <AttendanceListShimmer rows={3} />
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  if (loadError) {
    return (
      <AttendanceWorkspaceShell workplaceId={workplaceId} title="Геозона">
        <div className="space-y-3 px-4 py-5">
          <p className="text-[14px] text-error">{loadError}</p>
          <AppButtonLink href={back} service="attendance">
            Назад
          </AppButtonLink>
        </div>
      </AttendanceWorkspaceShell>
    );
  }

  return (
    <AttendanceWorkspaceShell workplaceId={workplaceId} title="Геозона">
      <div className="flex flex-col gap-4 px-4 py-4 pb-10">
        <p className="text-[13px] text-muted">
          Тапните карту, чтобы поставить центр. Радиус — зона, где можно
          отметиться.
        </p>

        {mapError ? (
          <p className="rounded-[12px] border border-line bg-surface-muted px-3 py-8 text-center text-[13px] text-muted">
            {mapError}
          </p>
        ) : (
          <MapboxPinMap
            hostId={hostId}
            className="h-[280px] w-full overflow-hidden rounded-[16px] border border-line bg-mint"
            initialCenter={pin}
            zoom={zoomForRadius(radius)}
            pin={pin}
            geofenceRadiusM={radius}
            onPinChange={setPin}
            onReadyError={setMapError}
          />
        )}

        <p className="text-[11px] text-muted">
          {pin.lat.toFixed(5)}, {pin.lon.toFixed(5)}
        </p>

        <label className="block">
          <div className="mb-2 flex items-center justify-between gap-2">
            <span className="text-[13px] font-semibold text-ink">Радиус</span>
            <span className="text-[13px] font-bold text-svc-attendance-ink">
              {radius} м
            </span>
          </div>
          <input
            type="range"
            min={50}
            max={300}
            step={10}
            value={radius}
            onChange={(e) => setRadius(Number(e.target.value))}
            className="w-full accent-[var(--svc-attendance-ink)]"
          />
          <div className="mt-1 flex justify-between text-[11px] text-muted">
            <span>50 м</span>
            <span>300 м</span>
          </div>
        </label>

        {error ? <p className="text-[13px] text-error">{error}</p> : null}

        <AppButton
          type="button"
          service="attendance"
          loading={saving}
          onClick={() => void save()}
        >
          Сохранить
        </AppButton>
      </div>
    </AttendanceWorkspaceShell>
  );
}
