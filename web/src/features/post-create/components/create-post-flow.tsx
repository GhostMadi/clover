"use client";

import {
  ArrowLeft,
  Check,
  ImagePlus,
  Trash2,
  X,
} from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useMemo, useRef, useState } from "react";
import { AppCheckboxRow } from "@/components/shared/app-checkbox";
import { AppDateTimePicker } from "@/components/shared/app-date-picker";
import { EventEmojiField } from "@/features/feed/components/event-emoji-field";
import {
  MARKER_TAG_GROUPS,
  MARKER_TAGS,
  tagLabelRu,
} from "@/features/catalog/lib/marker-tags";
import {
  ImageSelector,
  isAllowedPostImage,
  POST_IMAGE_ACCEPT,
} from "@/features/post-create/components/image-selector";
import {
  ImageEditorControls,
  type EditorPanel,
} from "@/features/post-create/components/image-editor-controls";
import { FilteredImage } from "@/features/post-create/components/filtered-image";
import { publishPost } from "@/features/post-create/lib/post-create-api";
import { listMyServices } from "@/features/booking/lib/services-api";
import type { BookingService } from "@/features/booking/lib/booking-model";
import { formatPriceKzt } from "@/features/booking/lib/booking-format";
import { listMyLocations } from "@/features/post-create/lib/locations-api";
import type { ImageEditToolId } from "@/features/post-create/lib/image-edit-matrix";
import {
  newDraftEdit,
  newDraftId,
  POST_CREATE_MAX_PHOTOS,
  POST_DESCRIPTION_MAX,
  POST_TITLE_MAX,
  type DraftPhoto,
  type SavedLocation,
} from "@/features/post-create/lib/post-create-model";
import type { PostAspectRatioKind } from "@/features/post/lib/aspect-ratio";
import {
  filterSelectionKey,
  listProfileFilterCategories,
  type ProfileFilterCategory,
} from "@/features/resources/lib/profile-filters-api";
import { createClient } from "@/lib/supabase/client";

type Step = "select" | "edit" | "compose" | "publishing";

function revokeAll(photos: DraftPhoto[]) {
  for (const p of photos) {
    if (p.previewUrl.startsWith("blob:")) URL.revokeObjectURL(p.previewUrl);
  }
}

/** Мастер создания поста: фото → кроп → карточка → публикация. */
export function CreatePostFlow() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const [step, setStep] = useState<Step>("select");
  const [photos, setPhotos] = useState<DraftPhoto[]>([]);
  const photosRef = useRef(photos);
  photosRef.current = photos;
  const [editIndex, setEditIndex] = useState(0);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [emoji, setEmoji] = useState<string | null>(null);
  const [tagKeys, setTagKeys] = useState<Set<string>>(new Set());
  const [profileFilterKeys, setProfileFilterKeys] = useState<Set<string>>(new Set());
  const [profileFilterCats, setProfileFilterCats] = useState<ProfileFilterCategory[]>([]);
  const [bookingServices, setBookingServices] = useState<BookingService[]>([]);
  const [bookingServiceId, setBookingServiceId] = useState("");
  const [asEvent, setAsEvent] = useState(false);
  const [eventStart, setEventStart] = useState<Date | null>(null);
  const [durationMin, setDurationMin] = useState(60);
  const [locations, setLocations] = useState<SavedLocation[]>([]);
  const [locationId, setLocationId] = useState<string>("");
  const [progress, setProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);
  const [editorPanel, setEditorPanel] = useState<EditorPanel>("effects");
  const [activeTool, setActiveTool] = useState<ImageEditToolId>("brightness");

  useEffect(() => {
    void listMyLocations()
      .then(setLocations)
      .catch(() => setLocations([]));
    void createClient()
      .auth.getSession()
      .then(({ data }) => {
        const id = data.session?.user.id;
        if (!id) return;
        return listProfileFilterCategories(id).then(setProfileFilterCats);
      })
      .catch(() => setProfileFilterCats([]));
    void listMyServices()
      .then((list) => setBookingServices(list.filter((s) => s.isActive)))
      .catch(() => setBookingServices([]));
    return () => revokeAll(photosRef.current);
  }, []);

  const current = photos[editIndex] ?? null;
  const selectedLocation = locations.find((l) => l.id === locationId) ?? null;

  const canPublish = photos.length > 0;

  const publishBlock = useMemo(() => {
    if (!photos.length) return "Добавьте хотя бы одно фото";
    if (!asEvent) return null;
    if (!emoji) return "Выберите эмодзи";
    if (!selectedLocation) return "Выберите местоположение";
    if (selectedLocation.latitude == null || selectedLocation.longitude == null) {
      return "У места нет координат";
    }
    if (!eventStart) return "Укажите начало события";
    if (durationMin < 1 || durationMin > 24 * 60) return "Длительность: 1 мин – 24 ч";
    return null;
  }, [asEvent, durationMin, emoji, eventStart, photos.length, selectedLocation]);

  const addFiles = (list: FileList | null) => {
    if (!list?.length) return;
    const room = POST_CREATE_MAX_PHOTOS - photos.length;
    const next: DraftPhoto[] = [];
    let skipped = 0;
    for (const file of Array.from(list)) {
      if (next.length >= room) break;
      if (!isAllowedPostImage(file)) {
        skipped += 1;
        continue;
      }
      next.push({
        id: newDraftId(),
        file,
        previewUrl: URL.createObjectURL(file),
        aspect: "4x3",
        zoom: 1,
        offsetX: 0,
        offsetY: 0,
        edit: newDraftEdit(),
      });
    }
    if (!next.length) {
      setError(
        skipped
          ? "Только JPEG, PNG или WebP"
          : "Выберите изображения (до 15 фото)",
      );
      return;
    }
    setError(
      skipped > 0
        ? `Пропущено ${skipped}: нужны JPEG / PNG / WebP`
        : null,
    );
    setPhotos((prev) => {
      const merged = [...prev, ...next];
      setEditIndex(prev.length);
      return merged;
    });
    setStep("select");
  };

  const removePhoto = (id: string) => {
    setPhotos((prev) => {
      const hit = prev.find((p) => p.id === id);
      if (hit?.previewUrl.startsWith("blob:")) URL.revokeObjectURL(hit.previewUrl);
      const next = prev.filter((p) => p.id !== id);
      if (next.length === 0) setStep("select");
      else setEditIndex((i) => Math.min(i, next.length - 1));
      return next;
    });
  };

  const patchCurrent = (patch: Partial<DraftPhoto>) => {
    setPhotos((prev) =>
      prev.map((p, i) => (i === editIndex ? { ...p, ...patch } : p)),
    );
  };

  const goCompose = () => {
    if (!photos.length) return;
    setStep("compose");
  };

  const onPublish = () => {
    if (!canPublish || publishBlock) {
      setError(publishBlock);
      return;
    }
    setStep("publishing");
    setProgress(0);
    setError(null);
    const startIso = asEvent && eventStart ? eventStart.toISOString() : null;
    void publishPost({
      photos,
      title,
      description,
      textEmoji: emoji ?? "",
      tagKeys: [...tagKeys],
      profileFilterKeys: [...profileFilterKeys],
      bookingServiceId: bookingServiceId || null,
      eventStartIso: startIso,
      eventDurationMinutes: asEvent ? durationMin : null,
      location: selectedLocation,
      onProgress: setProgress,
    })
      .then((res) => {
        router.push(`/app/posts/${res.postId}`);
        router.refresh();
      })
      .catch((e: unknown) => {
        setError(e instanceof Error ? e.message : "Не удалось опубликовать");
        setStep("compose");
      });
  };

  const close = () => {
    revokeAll(photos);
    router.push("/app/profile");
  };

  return (
    <div className="flex min-h-[calc(100dvh-3rem-4.25rem)] flex-col bg-surface md:min-h-dvh">
      <div className="mx-auto flex w-full max-w-[640px] flex-1 flex-col">
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-surface/95 px-2 backdrop-blur-md">
          <button
            type="button"
            onClick={() => {
              if (step === "compose") setStep("edit");
              else if (step === "edit") setStep("select");
              else close();
            }}
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </button>
          <h1 className="min-w-0 flex-1 truncate text-[16px] font-bold text-ink">
            {step === "select" &&
              (photos.length
                ? `Новая публикация (${photos.length}/${POST_CREATE_MAX_PHOTOS})`
                : "Новая публикация")}
            {step === "edit" && "Редактор"}
            {step === "compose" && "Публикация"}
            {step === "publishing" && "Публикуем…"}
          </h1>
          {step === "select" && photos.length > 0 ? (
            <button
              type="button"
              onClick={() => setStep("edit")}
              className="mr-1 rounded-full bg-brand px-3 py-1.5 text-[13px] font-bold text-on-brand"
            >
              Далее
            </button>
          ) : null}
          {step === "edit" ? (
            <button
              type="button"
              onClick={goCompose}
              className="mr-1 rounded-full bg-brand px-3 py-1.5 text-[13px] font-bold text-on-brand"
            >
              Далее
            </button>
          ) : null}
          {step === "compose" ? (
            <button
              type="button"
              onClick={onPublish}
              disabled={Boolean(publishBlock)}
              className="mr-1 flex h-10 w-10 items-center justify-center rounded-full bg-brand text-on-brand disabled:opacity-40"
              aria-label="Опубликовать"
            >
              <Check className="h-5 w-5" strokeWidth={2.5} />
            </button>
          ) : null}
          {step === "select" && photos.length === 0 ? (
            <button
              type="button"
              onClick={close}
              className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
              aria-label="Закрыть"
            >
              <X className="h-5 w-5" strokeWidth={2} />
            </button>
          ) : null}
        </header>

        {error ? (
          <p className="mx-4 mt-3 rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}

        {step === "select" ? (
          <ImageSelector
            photos={photos}
            previewIndex={editIndex}
            onPreviewIndex={setEditIndex}
            onPickFiles={addFiles}
            onRemove={removePhoto}
          />
        ) : null}

        {step === "edit" && current ? (
          <div className="flex flex-1 flex-col gap-4 px-4 py-4 pb-8">
            <ImageEditorControls
              previewUrl={current.previewUrl}
              edit={current.edit}
              aspect={current.aspect}
              zoom={current.zoom}
              offsetX={current.offsetX}
              offsetY={current.offsetY}
              activeTool={activeTool}
              panel={editorPanel}
              onPanel={setEditorPanel}
              onActiveTool={setActiveTool}
              onEdit={(patch) =>
                patchCurrent({ edit: { ...current.edit, ...patch } })
              }
              onAspect={(kind) =>
                patchCurrent({
                  aspect: kind as PostAspectRatioKind,
                  zoom: 1,
                  offsetX: 0,
                  offsetY: 0,
                })
              }
              onZoom={(z) => patchCurrent({ zoom: z })}
              onOffset={(x, y) => patchCurrent({ offsetX: x, offsetY: y })}
            />

            <div className="flex gap-2 overflow-x-auto pb-1">
              {photos.map((p, i) => (
                <button
                  key={p.id}
                  type="button"
                  onClick={() => setEditIndex(i)}
                  className={`relative h-16 w-16 shrink-0 overflow-hidden rounded-[12px] border-2 ${
                    i === editIndex ? "border-brand" : "border-transparent"
                  }`}
                >
                  <FilteredImage
                    src={p.previewUrl}
                    settings={p.edit}
                    className="h-full w-full object-cover"
                  />
                </button>
              ))}
              {photos.length < POST_CREATE_MAX_PHOTOS ? (
                <button
                  type="button"
                  onClick={() => fileRef.current?.click()}
                  className="flex h-16 w-16 shrink-0 items-center justify-center rounded-[12px] border border-dashed border-line bg-bg text-muted"
                >
                  <ImagePlus className="h-5 w-5" />
                </button>
              ) : null}
            </div>

            <button
              type="button"
              onClick={() => removePhoto(current.id)}
              className="flex h-11 items-center justify-center gap-2 rounded-[14px] border border-line text-sm font-semibold text-destructive"
            >
              <Trash2 className="h-4 w-4" />
              Удалить кадр
            </button>

            <input
              ref={fileRef}
              type="file"
              accept={POST_IMAGE_ACCEPT}
              multiple
              className="hidden"
              onChange={(e) => {
                addFiles(e.target.files);
                e.target.value = "";
              }}
            />
          </div>
        ) : null}

        {step === "compose" ? (
          <div className="flex flex-1 flex-col gap-5 px-4 py-4 pb-28">
            <div className="overflow-hidden rounded-[16px] bg-bg">
              <div className="flex gap-1 overflow-x-auto p-1">
                {photos.map((p) => (
                  <FilteredImage
                    key={p.id}
                    src={p.previewUrl}
                    settings={p.edit}
                    className="h-28 w-auto max-w-[40%] shrink-0 rounded-[12px] object-cover"
                  />
                ))}
              </div>
            </div>

            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Заголовок</span>
              <input
                value={title}
                maxLength={POST_TITLE_MAX}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="О чём пост"
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none focus:border-brand"
              />
            </label>

            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Описание</span>
              <textarea
                value={description}
                maxLength={POST_DESCRIPTION_MAX}
                onChange={(e) => setDescription(e.target.value)}
                rows={4}
                placeholder="Подпись"
                className="w-full resize-none rounded-[14px] border border-line bg-bg px-4 py-3 text-[15px] text-ink outline-none focus:border-brand"
              />
            </label>

            <div>
              <p className="mb-2 text-sm font-semibold text-ink">Эмодзи</p>
              <EventEmojiField value={emoji} onChange={setEmoji} />
            </div>

            <div>
              <p className="mb-2 text-sm font-semibold text-ink">Теги</p>
              <div className="flex flex-wrap gap-2">
                {MARKER_TAGS.filter((t) =>
                  ["place", "event", "format", "conditions", "type"].includes(t.group),
                )
                  .slice(0, 24)
                  .map((tag) => {
                    const on = tagKeys.has(tag.key);
                    return (
                      <button
                        key={tag.key}
                        type="button"
                        onClick={() =>
                          setTagKeys((prev) => {
                            const next = new Set(prev);
                            if (next.has(tag.key)) next.delete(tag.key);
                            else next.add(tag.key);
                            return next;
                          })
                        }
                        className={`rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                          on ? "bg-brand text-on-brand" : "border border-line bg-bg text-ink"
                        }`}
                      >
                        {tagLabelRu(tag.key)}
                      </button>
                    );
                  })}
              </div>
              <details className="mt-2">
                <summary className="cursor-pointer text-[13px] font-semibold text-brand">
                  Все теги
                </summary>
                <div className="mt-3 space-y-3">
                  {MARKER_TAG_GROUPS.map((g) => {
                    const tags = MARKER_TAGS.filter((t) => t.group === g.key);
                    if (!tags.length) return null;
                    return (
                      <div key={g.key}>
                        <p className="mb-1.5 text-[12px] font-bold text-muted">{g.label}</p>
                        <div className="flex flex-wrap gap-2">
                          {tags.map((tag) => {
                            const on = tagKeys.has(tag.key);
                            return (
                              <button
                                key={tag.key}
                                type="button"
                                onClick={() =>
                                  setTagKeys((prev) => {
                                    const next = new Set(prev);
                                    if (next.has(tag.key)) next.delete(tag.key);
                                    else next.add(tag.key);
                                    return next;
                                  })
                                }
                                className={`rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                                  on ? "bg-brand text-on-brand" : "border border-line bg-bg text-ink"
                                }`}
                              >
                                {tagLabelRu(tag.key)}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </details>
            </div>

            <AppCheckboxRow
              title="Это ивент"
              subtitle="Период + место → точка на карте"
              checked={asEvent}
              onChange={setAsEvent}
            >
              {asEvent ? (
                <div className="mt-4 space-y-3 border-t border-line pt-4">
                  <AppDateTimePicker
                    label="Начало"
                    hint="Выберите дату и время"
                    value={eventStart}
                    onChange={setEventStart}
                    clearable={false}
                  />
                  <div>
                    <span className="mb-1.5 block text-sm font-semibold text-ink">
                      Длительность
                    </span>
                    <div className="mb-2 flex flex-wrap gap-2">
                      {[
                        { m: 30, label: "30 мин" },
                        { m: 60, label: "1 ч" },
                        { m: 120, label: "2 ч" },
                        { m: 180, label: "3 ч" },
                        { m: 1440, label: "сутки" },
                      ].map((d) => (
                        <button
                          key={d.m}
                          type="button"
                          onClick={() => setDurationMin(d.m)}
                          className={`rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                            durationMin === d.m
                              ? "bg-brand text-on-brand"
                              : "border border-line bg-surface text-ink"
                          }`}
                        >
                          {d.label}
                        </button>
                      ))}
                    </div>
                    <input
                      type="number"
                      min={1}
                      max={1440}
                      value={durationMin}
                      onChange={(e) => setDurationMin(Number(e.target.value) || 1)}
                      className="h-12 w-full rounded-[14px] border border-line bg-surface px-3 text-[15px] text-ink outline-none focus:border-brand"
                      aria-label="Длительность в минутах"
                    />
                  </div>
                </div>
              ) : null}
            </AppCheckboxRow>

            <div>
              <p className="mb-2 text-sm font-semibold text-ink">Место</p>
              <select
                value={locationId}
                onChange={(e) => setLocationId(e.target.value)}
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink outline-none focus:border-brand"
              >
                <option value="">Не выбрано</option>
                {locations.map((l) => (
                  <option key={l.id} value={l.id}>
                    {l.addressPrimary}
                  </option>
                ))}
              </select>
              <Link
                href="/app/settings/resources/locations/new"
                className="mt-1.5 inline-block text-[12px] font-bold text-svc-resources-ink"
              >
                Добавить место в Ресурсах
              </Link>
            </div>

            {profileFilterCats.length > 0 ? (
              <div>
                <p className="mb-2 text-sm font-semibold text-ink">Фильтры витрины</p>
                <div className="flex flex-wrap gap-1.5">
                  {profileFilterCats.flatMap((c) =>
                    c.values.map((label) => {
                      const key = filterSelectionKey(c.id, label);
                      const on = profileFilterKeys.has(key);
                      return (
                        <button
                          key={key}
                          type="button"
                          onClick={() => {
                            setProfileFilterKeys((prev) => {
                              const next = new Set(prev);
                              if (next.has(key)) next.delete(key);
                              else next.add(key);
                              return next;
                            });
                          }}
                          className={`rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                            on
                              ? "bg-svc-resources-ink text-on-media"
                              : "bg-svc-resources text-svc-resources-ink"
                          }`}
                        >
                          {c.name}: {label}
                        </button>
                      );
                    }),
                  )}
                </div>
              </div>
            ) : null}

            {bookingServices.length > 0 ? (
              <div>
                <p className="mb-2 text-sm font-semibold text-ink">Услуга для записи</p>
                <select
                  value={bookingServiceId}
                  onChange={(e) => setBookingServiceId(e.target.value)}
                  className="h-12 w-full rounded-[14px] border border-line bg-bg px-3 text-[15px] text-ink outline-none focus:border-svc-booking-ink/50"
                >
                  <option value="">Без услуги</option>
                  {bookingServices.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.emojiText} {s.title} · {formatPriceKzt(s.price)}
                    </option>
                  ))}
                </select>
              </div>
            ) : null}

            <button
              type="button"
              onClick={onPublish}
              disabled={Boolean(publishBlock)}
              className="h-12 w-full rounded-[14px] bg-brand text-[15px] font-bold text-on-brand disabled:opacity-40"
            >
              Опубликовать
            </button>
            {publishBlock ? (
              <p className="text-center text-[12px] text-muted">{publishBlock}</p>
            ) : null}
          </div>
        ) : null}

        {step === "publishing" ? (
          <div className="flex flex-1 flex-col items-center justify-center gap-4 px-8">
            <div className="h-2 w-full max-w-xs overflow-hidden rounded-full bg-line">
              <div
                className="h-full rounded-full bg-brand transition-[width] duration-200"
                style={{ width: `${progress}%` }}
              />
            </div>
            <p className="text-sm font-semibold text-ink">{progress}%</p>
            <p className="text-center text-[13px] text-muted">
              Загружаем фото и публикуем…
            </p>
          </div>
        ) : null}
      </div>
    </div>
  );
}
