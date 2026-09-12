"use client";

import { Plus, SlidersHorizontal, Trash2 } from "lucide-react";
import { useCallback, useEffect, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import {
  deleteProfileFilterCategory,
  listProfileFilterCategories,
  upsertProfileFilterCategory,
  type ProfileFilterCategory,
} from "@/features/resources/lib/profile-filters-api";
import {
  readResourcesProfileFiltersCache,
  writeResourcesProfileFiltersCache,
} from "@/features/resources/lib/resources-prefs";
import { ResourcesWorkspaceShell } from "@/features/resources/components/resources-workspace-shell";
import { getSessionUserId } from "@/lib/run-service-swr";

export function ProfileFiltersSettingsView() {
  const [uid, setUid] = useState<string | null>(null);
  const [items, setItems] = useState<ProfileFilterCategory[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [editing, setEditing] = useState<ProfileFilterCategory | null>(null);
  const [creating, setCreating] = useState(false);
  const [name, setName] = useState("");
  const [valuesText, setValuesText] = useState("");
  const [saving, setSaving] = useState(false);
  const [, startTransition] = useTransition();

  const load = useCallback(async (profileId: string, opts?: { soft?: boolean }) => {
    if (!opts?.soft) setLoading(true);
    setError(null);
    try {
      const list = await listProfileFilterCategories(profileId);
      setItems(list);
      writeResourcesProfileFiltersCache(profileId, list);
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : "Не удалось загрузить");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      const id = await getSessionUserId();
      setUid(id);
      if (!id) {
        setLoading(false);
        return;
      }
      const cached = readResourcesProfileFiltersCache(id);
      if (cached) {
        setItems(cached);
        setLoading(false);
        await load(id, { soft: true });
      } else {
        await load(id);
      }
    })();
  }, [load]);

  const openCreate = () => {
    setEditing(null);
    setCreating(true);
    setName("");
    setValuesText("");
    setError(null);
  };

  const openEdit = (c: ProfileFilterCategory) => {
    setCreating(false);
    setEditing(c);
    setName(c.name);
    setValuesText(c.values.join("\n"));
    setError(null);
  };

  const closeForm = () => {
    setCreating(false);
    setEditing(null);
    setName("");
    setValuesText("");
  };

  const save = () => {
    if (!uid) return;
    const values = valuesText
      .split(/[\n,]/)
      .map((v) => v.trim())
      .filter(Boolean);
    setSaving(true);
    setError(null);
    startTransition(async () => {
      try {
        await upsertProfileFilterCategory({
          name,
          values,
          categoryId: editing?.id,
        });
        closeForm();
        load(uid);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось сохранить");
      } finally {
        setSaving(false);
      }
    });
  };

  const remove = (c: ProfileFilterCategory) => {
    if (!uid || !confirm(`Удалить категорию «${c.name}»?`)) return;
    startTransition(async () => {
      try {
        await deleteProfileFilterCategory(c.id);
        if (editing?.id === c.id) closeForm();
        load(uid);
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось удалить");
      }
    });
  };

  const formOpen = creating || Boolean(editing);

  return (
    <ResourcesWorkspaceShell
      title="Фильтры"
      backHref="/app/settings/resources"
      trailing={
        !formOpen ? (
          <button
            type="button"
            onClick={openCreate}
            className="mr-1 flex h-10 w-10 items-center justify-center rounded-full text-svc-resources-ink hover:bg-svc-resources"
            aria-label="Добавить"
          >
            <Plus className="h-5 w-5" strokeWidth={2.5} />
          </button>
        ) : null
      }
    >
      <div className="pb-6">
        {error ? (
          <p className="mb-3 rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}

        {formOpen ? (
          <div className="mb-6 space-y-3 rounded-[16px] border border-line bg-surface p-4">
            <p className="text-[14px] font-bold text-svc-resources-ink">
              {editing ? "Редактировать категорию" : "Новая категория"}
            </p>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Название</span>
              <input
                value={name}
                onChange={(e) => setName(e.target.value)}
                maxLength={64}
                placeholder="Например, Услуга"
                className="h-11 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">
                Значения (с новой строки)
              </span>
              <textarea
                value={valuesText}
                onChange={(e) => setValuesText(e.target.value)}
                rows={5}
                placeholder={"Стрижка\nОкрашивание"}
                className="w-full resize-none rounded-[14px] border border-line bg-bg px-3 py-2 text-[15px] text-ink outline-none focus:border-svc-resources-ink"
              />
            </label>
            <div className="flex gap-2">
              <AppButton
                type="button"
                variant="outline"
                className="flex-1"
                disabled={saving}
                onClick={closeForm}
              >
                Отмена
              </AppButton>
              <AppButton
                type="button"
               
                className="flex-1"
                loading={saving}
                disabled={saving || !name.trim()}
                onClick={save}
              >
                Сохранить
              </AppButton>
            </div>
          </div>
        ) : null}

        {loading ? (
          <p className="py-16 text-center text-sm text-muted">Загрузка…</p>
        ) : items.length === 0 && !formOpen ? (
          <div className="py-16 text-center">
            <SlidersHorizontal
              className="mx-auto h-8 w-8 text-svc-resources-ink/50"
              strokeWidth={1.5}
            />
            <p className="mt-3 text-sm font-semibold text-ink">Нет категорий</p>
            <button
              type="button"
              onClick={openCreate}
              className="mt-2 text-[13px] font-bold text-svc-resources-ink"
            >
              Создать фильтр
            </button>
          </div>
        ) : (
          <ul className="space-y-2">
            {items.map((c) => (
              <li
                key={c.id}
                className="rounded-[16px] border border-line bg-surface px-3.5 py-3"
              >
                <div className="flex items-start gap-2">
                  <button
                    type="button"
                    onClick={() => openEdit(c)}
                    className="min-w-0 flex-1 text-left"
                  >
                    <p className="text-[15px] font-bold text-ink">{c.name}</p>
                    <p className="mt-1 text-[12px] text-muted">
                      {c.values.length ? c.values.join(" · ") : "Нет значений"}
                    </p>
                  </button>
                  <button
                    type="button"
                    onClick={() => remove(c)}
                    className="flex h-9 w-9 items-center justify-center rounded-full text-destructive hover:bg-destructive/10"
                    aria-label="Удалить"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </ResourcesWorkspaceShell>
  );
}
