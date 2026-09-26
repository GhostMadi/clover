"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppCheckboxRow } from "@/components/shared/app-checkbox";
import {
  citiesForCountry,
  COUNTRY_OPTIONS,
} from "@/features/catalog/lib/locations";
import {
  deleteManagedLocation,
  getMyLocation,
  updateManagedLocation,
  type ManagedLocation,
} from "@/features/resources/lib/locations-api";
import {
  readResourcesLocationCache,
  writeResourcesLocationCache,
  writeResourcesLocationsCache,
  readResourcesLocationsCache,
} from "@/features/resources/lib/resources-prefs";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";
import {
  ServiceConfirmDialog,
  ServiceEmpty,
  ServiceInformer,
  ServiceListShimmer,
} from "@/features/shared/components/service-page";
import { getSessionUserId } from "@/lib/run-service-swr";

const LIST_HREF = "/app/settings/resources/locations";
const CARD = "rounded-[16px] border border-line bg-surface p-4";
const FIELD =
  "h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none focus:border-svc-resources-ink";

type LocationDetailViewProps = { locationId: string };

export function LocationDetailView({ locationId }: LocationDetailViewProps) {
  const router = useRouter();
  const [loc, setLoc] = useState<ManagedLocation | null>(null);
  const [addressCyrillic, setAddressCyrillic] = useState("");
  const [addressLatin, setAddressLatin] = useState("");
  const [countryCode, setCountryCode] = useState("");
  const [cityCode, setCityCode] = useState("");
  const [isActive, setIsActive] = useState(true);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [deleteError, setDeleteError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  const applyLoc = (row: ManagedLocation) => {
    setLoc(row);
    const cyr = row.addressCyrillic?.trim() || "";
    const primary = row.addressPrimary.trim();
    setAddressCyrillic(cyr || primary);
    setAddressLatin(cyr && primary !== cyr ? primary : "");
    setCountryCode(row.countryCode ?? "");
    setCityCode(row.cityCode ?? "");
    setIsActive(row.isActive);
  };

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const uid = await getSessionUserId();
      if (cancelled) return;
      const cached =
        readResourcesLocationCache(uid, locationId) ??
        readResourcesLocationsCache(uid)?.find((l) => l.id === locationId) ??
        null;
      if (cached) {
        applyLoc(cached);
        setLoading(false);
      }
      try {
        const row = await getMyLocation(locationId);
        if (cancelled) return;
        if (!row) {
          if (!cached) setError("Место не найдено");
          setLoading(false);
          return;
        }
        applyLoc(row);
        writeResourcesLocationCache(uid, row);
        const list = readResourcesLocationsCache(uid);
        if (list) {
          writeResourcesLocationsCache(
            uid,
            list.map((l) => (l.id === row.id ? row : l)),
          );
        }
        setLoading(false);
      } catch (e: unknown) {
        if (cancelled) return;
        if (!cached) {
          setError(e instanceof Error ? e.message : "Ошибка загрузки");
        }
        setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [locationId]);

  const cities = countryCode ? citiesForCountry(countryCode) : [];

  const save = () => {
    setSaving(true);
    setError(null);
    startTransition(async () => {
      try {
        const clearGeo = !countryCode || !cityCode;
        await updateManagedLocation({
          id: locationId,
          addressCyrillic,
          addressLatin,
          clearAddressLatin: !addressLatin.trim(),
          clearGeoBinding: clearGeo,
          countryCode: clearGeo ? null : countryCode,
          cityCode: clearGeo ? null : cityCode,
          isActive,
        });
        router.push(LIST_HREF);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось сохранить");
        setSaving(false);
      }
    });
  };

  const remove = () => {
    setDeleting(true);
    setDeleteError(null);
    startTransition(async () => {
      try {
        await deleteManagedLocation(locationId);
        router.push(LIST_HREF);
      } catch (e: unknown) {
        setDeleteError(e instanceof Error ? e.message : "Не удалось удалить");
        setDeleting(false);
      }
    });
  };

  const title = loc?.addressCyrillic || loc?.addressPrimary || "Место";

  return (
    <ResourcesWorkspaceShell
      title={title}
      lead="Адрес, город и статус места. Точку на карте здесь не переставить."
      backHref={LIST_HREF}
    >
      <div className="mx-auto max-w-3xl space-y-4 pb-10">
        {error ? (
          <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}
        {loading ? <ServiceListShimmer rows={3} /> : null}
        {!loading && !loc && !error ? <ServiceEmpty>Место не найдено.</ServiceEmpty> : null}
        {loc ? (
          <>
            <section className={`${CARD} space-y-4`}>
              <div>
                <h2 className="text-[15px] font-bold text-ink">Адрес</h2>
                <p className="mt-1 text-[12px] leading-snug text-muted">
                  Кириллица обязательна. Латиница — по желанию, для гостей без русской
                  раскладки.
                </p>
              </div>
              <label className="block">
                <span className="mb-1.5 block text-sm font-semibold text-ink">
                  Адрес (кириллица)
                </span>
                <input
                  value={addressCyrillic}
                  onChange={(e) => setAddressCyrillic(e.target.value)}
                  placeholder="ул. Абая, 150, Алматы"
                  className={FIELD}
                />
              </label>
              <label className="block">
                <span className="mb-1.5 block text-sm font-semibold text-ink">
                  Адрес (латиница)
                </span>
                <input
                  value={addressLatin}
                  onChange={(e) => setAddressLatin(e.target.value)}
                  placeholder="Abay ave, 150, Almaty — по желанию"
                  className={FIELD}
                />
              </label>
              {loc.latitude != null && loc.longitude != null ? (
                <p className="text-[12px] text-muted">
                  Точка на карте: {loc.latitude.toFixed(5)}, {loc.longitude.toFixed(5)}
                </p>
              ) : null}
            </section>

            <section className={`${CARD} space-y-3`}>
              <div>
                <h2 className="text-[15px] font-bold text-ink">Страна и город</h2>
                <p className="mt-1 text-[12px] leading-snug text-muted">
                  По ним место попадает в нужный город на карте. Можно оставить пустыми.
                </p>
              </div>
              <div className="grid grid-cols-2 gap-3">
                <label className="block">
                  <span className="mb-1.5 block text-sm font-semibold text-ink">Страна</span>
                  <select
                    value={countryCode}
                    onChange={(e) => {
                      const cc = e.target.value;
                      setCountryCode(cc);
                      setCityCode(citiesForCountry(cc)[0]?.code ?? "");
                    }}
                    className={FIELD}
                  >
                    <option value="">—</option>
                    {COUNTRY_OPTIONS.map((c) => (
                      <option key={c.code} value={c.code}>
                        {c.label}
                      </option>
                    ))}
                  </select>
                </label>
                <label className="block">
                  <span className="mb-1.5 block text-sm font-semibold text-ink">Город</span>
                  <select
                    value={cityCode}
                    onChange={(e) => setCityCode(e.target.value)}
                    disabled={!countryCode}
                    className={`${FIELD} disabled:opacity-40`}
                  >
                    <option value="">—</option>
                    {cities.map((c) => (
                      <option key={c.code} value={c.code}>
                        {c.label}
                      </option>
                    ))}
                  </select>
                </label>
              </div>
            </section>

            <section className={`${CARD} space-y-3`}>
              <h2 className="text-[15px] font-bold text-ink">Статус</h2>
              <AppCheckboxRow
                title="Активно"
                subtitle="Неактивное место нельзя выбрать в новом посте. Старые посты не меняются."
                checked={isActive}
                onChange={setIsActive}
              />
            </section>

            <ServiceInformer service="resources">
              Адрес, город и статус сохраняются кнопкой «Сохранить».
            </ServiceInformer>
            <AppButton
              type="button"
              service="resources"
              loading={saving}
              disabled={!addressCyrillic.trim() || saving || deleting}
              onClick={save}
            >
              Сохранить
            </AppButton>
            <AppButton
              type="button"
              variant="outline"
              disabled={saving || deleting}
              className="!border-destructive/40 !text-destructive"
              onClick={() => {
                setDeleteError(null);
                setConfirmOpen(true);
              }}
            >
              Удалить место
            </AppButton>
          </>
        ) : null}
      </div>

      <ServiceConfirmDialog
        open={confirmOpen}
        title="Удалить место?"
        body={`«${title}» пропадёт из справочника. Если хотите просто скрыть его из новых постов — снимите «Активно».`}
        confirmLabel="Удалить"
        busy={deleting}
        error={deleteError}
        onConfirm={remove}
        onCancel={() => setConfirmOpen(false)}
      />
    </ResourcesWorkspaceShell>
  );
}
