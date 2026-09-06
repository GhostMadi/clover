"use client";

import { ImagePlus } from "lucide-react";
import { useRef } from "react";
import type { DraftPhoto } from "@/features/post-create/lib/post-create-model";
import { POST_CREATE_MAX_PHOTOS } from "@/features/post-create/lib/post-create-model";

export const POST_IMAGE_ACCEPT =
  "image/jpeg,image/jpg,image/png,image/webp,.jpg,.jpeg,.png,.webp";

const ALLOWED_MIME = new Set([
  "image/jpeg",
  "image/jpg",
  "image/png",
  "image/webp",
]);

const ALLOWED_EXT = /\.(jpe?g|png|webp)$/i;

export function isAllowedPostImage(file: File): boolean {
  const type = (file.type || "").toLowerCase();
  if (ALLOWED_MIME.has(type)) return true;
  if (!type || type === "application/octet-stream") {
    return ALLOWED_EXT.test(file.name);
  }
  return false;
}

type ImageSelectorProps = {
  photos: DraftPhoto[];
  previewIndex: number;
  onPreviewIndex: (index: number) => void;
  onPickFiles: (files: FileList | null) => void;
  onRemove: (id: string) => void;
  /** Лимит кадров (пост 15, кластер 1). */
  maxPhotos?: number;
  /** CSS aspect для верхнего превью: `4/3` | `1/1`. */
  previewAspect?: "4/3" | "1/1";
  emptyHint?: string;
};

/**
 * Как `AppImageSelectorPage`: сверху превью, снизу сетка фото с компьютера.
 */
export function ImageSelector({
  photos,
  previewIndex,
  onPreviewIndex,
  onPickFiles,
  onRemove,
  maxPhotos = POST_CREATE_MAX_PHOTOS,
  previewAspect = "4/3",
  emptyHint,
}: ImageSelectorProps) {
  const fileRef = useRef<HTMLInputElement>(null);
  const preview = photos[previewIndex] ?? photos[0] ?? null;
  const room = maxPhotos - photos.length;
  const aspectClass = previewAspect === "1/1" ? "aspect-square" : "aspect-[4/3]";
  const hint =
    emptyHint ??
    (maxPhotos === 1
      ? "JPEG, PNG или WebP · одно фото"
      : `JPEG, PNG или WebP · до ${maxPhotos}`);

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <div className="shrink-0 bg-mint/80">
        <div
          className={`relative mx-auto w-full max-w-[640px] overflow-hidden bg-line/40 ${aspectClass}`}
        >
          {preview ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={preview.previewUrl}
              alt=""
              className="absolute inset-0 h-full w-full object-cover"
            />
          ) : (
            <div className="absolute inset-0 flex flex-col items-center justify-center gap-2 px-6 text-center">
              <ImagePlus className="h-9 w-9 text-muted" strokeWidth={1.6} />
              <p className="text-[15px] font-semibold text-ink">Выберите фото</p>
              <p className="text-[13px] text-muted">{hint}</p>
            </div>
          )}
        </div>
      </div>

      <div className="flex shrink-0 items-center justify-between border-b border-line px-4 py-2.5">
        <p className="text-[14px] font-bold text-ink">С компьютера</p>
        <button
          type="button"
          disabled={room <= 0}
          onClick={() => fileRef.current?.click()}
          className="text-[13px] font-bold text-brand disabled:opacity-40"
        >
          {photos.length
            ? maxPhotos === 1
              ? "Сменить фото"
              : "Добавить ещё"
            : "Выбрать файлы"}
        </button>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto bg-bg">
        {photos.length === 0 ? (
          <button
            type="button"
            onClick={() => fileRef.current?.click()}
            className="flex h-full min-h-[220px] w-full flex-col items-center justify-center gap-3 px-6 py-10 text-center transition hover:bg-mint/40"
          >
            <div className="flex h-16 w-16 items-center justify-center rounded-[18px] bg-mint">
              <ImagePlus className="h-7 w-7 text-brand" strokeWidth={1.75} />
            </div>
            <span className="text-[15px] font-bold text-ink">Открыть файлы</span>
            <span className="max-w-xs text-[13px] text-muted">{hint}</span>
          </button>
        ) : (
          <div className="grid grid-cols-4 gap-0.5 p-0.5">
            {photos.map((p, i) => {
              const active = i === previewIndex;
              return (
                <button
                  key={p.id}
                  type="button"
                  onClick={() => onPreviewIndex(i)}
                  onDoubleClick={() => onRemove(p.id)}
                  className={`relative aspect-square overflow-hidden ${
                    active ? "ring-2 ring-inset ring-brand" : ""
                  }`}
                  title="Двойной клик — удалить"
                >
                  {/* eslint-disable-next-line @next/next/no-img-element */}
                  <img src={p.previewUrl} alt="" className="h-full w-full object-cover" />
                  {active ? (
                    <span className="absolute inset-0 bg-brand/25" aria-hidden />
                  ) : null}
                  <span className="absolute right-1 top-1 flex h-5 min-w-5 items-center justify-center rounded-full bg-brand px-1 text-[11px] font-bold text-on-brand">
                    {i + 1}
                  </span>
                </button>
              );
            })}
            {room > 0 ? (
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                className="flex aspect-square items-center justify-center bg-surface text-muted transition hover:bg-mint hover:text-brand"
                aria-label="Добавить фото"
              >
                <ImagePlus className="h-6 w-6" strokeWidth={1.75} />
              </button>
            ) : null}
          </div>
        )}
      </div>

      <input
        ref={fileRef}
        type="file"
        accept={POST_IMAGE_ACCEPT}
        multiple={maxPhotos > 1}
        className="hidden"
        onChange={(e) => {
          onPickFiles(e.target.files);
          e.target.value = "";
        }}
      />
    </div>
  );
}
