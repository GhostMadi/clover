"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { AppButton } from "@/components/shared/app-button";
import { BookingFormShimmer } from "@/features/booking/components/booking-shimmers";
import { BookingWorkspaceShell } from "@/features/booking/components/booking-workspace-shell";
import {
  createService,
  getMyService,
  updateService,
  type ServiceDraft,
} from "@/features/booking/lib/services-api";
import { listMyStaff } from "@/features/booking/lib/staff-api";
import type { BookingStaff } from "@/features/booking/lib/booking-model";

type Props = { mode: "new" | "edit"; serviceId?: string };

const emptyDraft = (): ServiceDraft => ({
  title: "",
  emojiText: "💈",
  description: "",
  durationMinutes: 60,
  bufferAfterMinutes: 0,
  price: 0,
  maxParticipants: 1,
  isActive: true,
  bonusPayPercent: 0,
  bonusEarnAmount: 0,
  staffIds: [],
});

export function ServiceEditView({ mode, serviceId }: Props) {
  const router = useRouter();
  const [draft, setDraft] = useState<ServiceDraft>(emptyDraft);
  const [staff, setStaff] = useState<BookingStaff[]>([]);
  const [loading, setLoading] = useState(mode === "edit");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    void listMyStaff(true).then((list) => {
      if (!cancelled) setStaff(list);
    });
    if (mode === "edit" && serviceId) {
      void getMyService(serviceId)
        .then((s) => {
          if (cancelled || !s) return;
          setDraft({
            title: s.title,
            emojiText: s.emojiText,
            description: s.description ?? "",
            durationMinutes: s.durationMinutes,
            bufferAfterMinutes: s.bufferAfterMinutes,
            price: s.price,
            maxParticipants: s.maxParticipants,
            isActive: s.isActive,
            bonusPayPercent: s.bonusPayPercent,
            bonusEarnAmount: s.bonusEarnAmount,
            staffIds: s.executorIds,
          });
        })
        .catch((e: unknown) => {
          if (!cancelled) setError(e instanceof Error ? e.message : "Ошибка");
        })
        .finally(() => {
          if (!cancelled) setLoading(false);
        });
    }
    return () => {
      cancelled = true;
    };
  }, [mode, serviceId]);

  const set = <K extends keyof ServiceDraft>(key: K, value: ServiceDraft[K]) =>
    setDraft((d) => ({ ...d, [key]: value }));

  const toggleStaff = (id: string) => {
    setDraft((d) => ({
      ...d,
      staffIds: d.staffIds.includes(id)
        ? d.staffIds.filter((x) => x !== id)
        : [...d.staffIds, id],
    }));
  };

  const save = async () => {
    if (!draft.title.trim()) {
      setError("Укажите название");
      return;
    }
    if (draft.staffIds.length === 0) {
      setError("Выберите хотя бы одного мастера");
      return;
    }
    setSaving(true);
    setError(null);
    try {
      if (mode === "new") await createService(draft);
      else if (serviceId) await updateService(serviceId, draft);
      router.push("/app/settings/booking/services");
      router.refresh();
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось сохранить");
      setSaving(false);
    }
  };

  return (
    <BookingWorkspaceShell
      title={mode === "new" ? "Новая услуга" : "Услуга"}
      backHref="/app/settings/booking/services"
    >
      <div className="mx-auto max-w-2xl space-y-4">
        {loading ? (
          <BookingFormShimmer />
        ) : (
          <>
            <Field label="Название">
              <input
                value={draft.title}
                onChange={(e) => set("title", e.target.value)}
                className={inputCls}
              />
            </Field>
            <Field label="Emoji">
              <input
                value={draft.emojiText}
                onChange={(e) => set("emojiText", e.target.value.slice(0, 8))}
                className={inputCls}
              />
            </Field>
            <Field label="Описание">
              <textarea
                value={draft.description}
                onChange={(e) => set("description", e.target.value)}
                rows={3}
                className={`${inputCls} h-auto py-3`}
              />
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="Длительность, мин">
                <input
                  type="number"
                  min={5}
                  value={draft.durationMinutes}
                  onChange={(e) => set("durationMinutes", Number(e.target.value) || 0)}
                  className={inputCls}
                />
              </Field>
              <Field label="Буфер после, мин">
                <input
                  type="number"
                  min={0}
                  value={draft.bufferAfterMinutes}
                  onChange={(e) => set("bufferAfterMinutes", Number(e.target.value) || 0)}
                  className={inputCls}
                />
              </Field>
              <Field label="Цена, ₸">
                <input
                  type="number"
                  min={0}
                  value={draft.price}
                  onChange={(e) => set("price", Number(e.target.value) || 0)}
                  className={inputCls}
                />
              </Field>
              <Field label="Участников max">
                <input
                  type="number"
                  min={1}
                  value={draft.maxParticipants}
                  onChange={(e) => set("maxParticipants", Number(e.target.value) || 1)}
                  className={inputCls}
                />
              </Field>
              <Field label="Бонусы % оплаты">
                <input
                  type="number"
                  min={0}
                  max={100}
                  value={draft.bonusPayPercent}
                  onChange={(e) => set("bonusPayPercent", Number(e.target.value) || 0)}
                  className={inputCls}
                />
              </Field>
              <Field label="Начисление бонусов">
                <input
                  type="number"
                  min={0}
                  value={draft.bonusEarnAmount}
                  onChange={(e) => set("bonusEarnAmount", Number(e.target.value) || 0)}
                  className={inputCls}
                />
              </Field>
            </div>

            <div>
              <p className="mb-2 text-[12px] font-bold uppercase tracking-wide text-muted">
                Мастера
              </p>
              {staff.length === 0 ? (
                <p className="text-sm text-muted">
                  Сначала добавьте мастера на экране списка услуг.
                </p>
              ) : (
                <div className="flex flex-wrap gap-2">
                  {staff.map((s) => {
                    const on = draft.staffIds.includes(s.id);
                    return (
                      <button
                        key={s.id}
                        type="button"
                        onClick={() => toggleStaff(s.id)}
                        className={`rounded-full px-3 py-1.5 text-[13px] font-semibold ${
                          on
                            ? "bg-svc-booking-ink text-on-media"
                            : "border border-line bg-surface"
                        }`}
                      >
                        {s.displayName}
                      </button>
                    );
                  })}
                </div>
              )}
            </div>

            {mode === "edit" ? (
              <label className="flex items-center justify-between rounded-[14px] border border-line bg-surface px-3.5 py-3">
                <span className="text-[14px] font-semibold text-ink">Активна</span>
                <input
                  type="checkbox"
                  checked={draft.isActive}
                  onChange={(e) => set("isActive", e.target.checked)}
                />
              </label>
            ) : null}

            {error ? <p className="text-sm text-destructive">{error}</p> : null}

            <AppButton service="booking" loading={saving} onClick={() => void save()}>
              Сохранить
            </AppButton>
          </>
        )}
      </div>
    </BookingWorkspaceShell>
  );
}

const inputCls =
  "h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[14px] text-ink outline-none placeholder:text-muted focus:border-svc-booking-ink/50 [&_option]:bg-surface [&_option]:text-ink";

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-[12px] font-bold uppercase tracking-wide text-muted">
        {label}
      </span>
      {children}
    </label>
  );
}
