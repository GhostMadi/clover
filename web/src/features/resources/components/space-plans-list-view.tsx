"use client";

import { ChevronDown, LayoutTemplate, Pencil, Plus, Trash2 } from "lucide-react";
import { useRouter } from "next/navigation";
import { useCallback, useEffect, useState } from "react";
import { AppButton, AppButtonLink } from "@/components/shared/app-button";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";
import {
  createSpacePlan,
  deleteSpacePlan,
  listSpacePlans,
  setSpacePlanStatus,
  spacePlanStatusLabel,
  type SpacePlanMeta,
} from "@/features/resources/lib/space-plans-mock";
import { ServiceEmpty, ServiceListShimmer } from "@/features/shared/components/service-page";

const BASE = "/app/settings/resources/space-plans";

function formatUpdated(iso: string): string {
  try {
    return new Intl.DateTimeFormat("ru-RU", {
      day: "numeric",
      month: "short",
      hour: "2-digit",
      minute: "2-digit",
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}

/** Список схем пространства (мок localStorage). */
export function SpacePlansListView() {
  const router = useRouter();
  const [items, setItems] = useState<SpacePlanMeta[] | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [templatesOpen, setTemplatesOpen] = useState(false);

  const refresh = useCallback(() => {
    setItems(listSpacePlans());
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  const onCreate = (starter: "empty" | "cafe" | "cinema" | "crazy_emoji" = "empty") => {
    const titles = {
      empty: "Новая схема",
      cafe: "Зал кафе",
      cinema: "Кинозал",
      crazy_emoji: "Emoji Carnival",
    };
    const plan = createSpacePlan({
      title: titles[starter],
      starter,
    });
    setTemplatesOpen(false);
    router.push(`${BASE}/${plan.id}/edit`);
  };

  const onToggleStatus = (plan: SpacePlanMeta) => {
    setBusyId(plan.id);
    setSpacePlanStatus(plan.id, plan.status === "published" ? "draft" : "published");
    refresh();
    setBusyId(null);
  };

  const onDelete = (plan: SpacePlanMeta) => {
    if (!window.confirm(`Удалить схему «${plan.title}»?`)) return;
    setBusyId(plan.id);
    deleteSpacePlan(plan.id);
    refresh();
    setBusyId(null);
  };

  return (
    <ResourcesWorkspaceShell
      title="Схемы пространства"
      lead="Общий ресурс: рисуете зал один раз — подключаете к сервисам."
      trailing={
        <AppButton
          size="icon"
          service="resources"
          aria-label="Новая схема"
          title="Новая схема"
          onClick={() => onCreate("empty")}
        >
          <Plus strokeWidth={2.5} />
        </AppButton>
      }
    >
      <div className="mx-auto max-w-3xl space-y-4 pb-10">
        {items === null ? (
          <ServiceListShimmer rows={3} />
        ) : items.length === 0 ? (
          <ServiceEmpty
            action={
              <div className="flex flex-wrap justify-center gap-2">
                <AppButton service="resources" size="row" className="gap-1.5" onClick={() => onCreate()}>
                  <Plus className="h-4 w-4" strokeWidth={2.5} />
                  Создать
                </AppButton>
                <AppButton
                  service="resources"
                  size="row"
                  variant="outline"
                  onClick={() => onCreate("cafe")}
                >
                  Из шаблона кафе
                </AppButton>
              </div>
            }
          >
            Пока нет схем.
          </ServiceEmpty>
        ) : (
          <>
            <div className="flex flex-wrap items-center gap-2">
              <AppButton service="resources" size="row" className="gap-1.5" onClick={() => onCreate("empty")}>
                <Plus className="h-4 w-4" strokeWidth={2.5} />
                Создать
              </AppButton>
              <div className="relative">
                <AppButton
                  service="resources"
                  size="row"
                  variant="outline"
                  className="gap-1.5"
                  onClick={() => setTemplatesOpen((v) => !v)}
                >
                  Из шаблона
                  <ChevronDown className="h-3.5 w-3.5" />
                </AppButton>
                {templatesOpen ? (
                  <>
                    <button
                      type="button"
                      className="fixed inset-0 z-10 cursor-default"
                      aria-label="Закрыть"
                      onClick={() => setTemplatesOpen(false)}
                    />
                    <div className="absolute left-0 top-full z-20 mt-1 w-44 rounded-[14px] border border-line bg-surface p-1.5 shadow-elevate-md">
                      {(
                        [
                          ["cafe", "Кафе"],
                          ["cinema", "Кино"],
                          ["crazy_emoji", "Emoji chaos"],
                        ] as const
                      ).map(([id, label]) => (
                        <button
                          key={id}
                          type="button"
                          className="flex w-full rounded-[10px] px-2.5 py-2 text-left text-[13px] font-semibold text-ink hover:bg-surface-soft"
                          onClick={() => onCreate(id)}
                        >
                          {label}
                        </button>
                      ))}
                    </div>
                  </>
                ) : null}
              </div>
            </div>

            <ul className="space-y-2">
              {items.map((plan) => {
                const busy = busyId === plan.id;
                return (
                  <li
                    key={plan.id}
                    className="flex items-center gap-3 rounded-[14px] border border-line bg-surface px-3 py-2.5"
                  >
                    <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[12px] bg-svc-resources text-svc-resources-ink">
                      <LayoutTemplate className="h-5 w-5" strokeWidth={2} />
                    </span>
                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <p className="truncate text-[15px] font-semibold text-ink">{plan.title}</p>
                        <span
                          className={
                            plan.status === "published"
                              ? "rounded-full bg-svc-resources px-2 py-0.5 text-[11px] font-bold text-svc-resources-ink"
                              : "rounded-full bg-muted/20 px-2 py-0.5 text-[11px] font-bold text-muted"
                          }
                        >
                          {spacePlanStatusLabel(plan.status)}
                        </span>
                      </div>
                      <p className="mt-0.5 text-[12px] text-muted">
                        {plan.floorCount} эт. · {formatUpdated(plan.updatedAt)}
                      </p>
                    </div>
                    <div className="flex shrink-0 items-center gap-1.5">
                      <AppButtonLink
                        href={`${BASE}/${plan.id}/edit`}
                        service="resources"
                        size="row"
                        className="gap-1.5"
                      >
                        <Pencil className="h-3.5 w-3.5" strokeWidth={2.5} />
                        Открыть
                      </AppButtonLink>
                      <AppButton
                        service="resources"
                        size="row"
                        variant="outline"
                        disabled={busy}
                        onClick={() => onToggleStatus(plan)}
                      >
                        {plan.status === "published" ? "Снять" : "Опубликовать"}
                      </AppButton>
                      <AppButton
                        service="resources"
                        size="icon"
                        variant="ghost"
                        disabled={busy}
                        className="text-destructive"
                        title="Удалить"
                        aria-label="Удалить"
                        onClick={() => onDelete(plan)}
                      >
                        <Trash2 className="h-4 w-4" strokeWidth={2} />
                      </AppButton>
                    </div>
                  </li>
                );
              })}
            </ul>
          </>
        )}
      </div>
    </ResourcesWorkspaceShell>
  );
}
