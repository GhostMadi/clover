"use client";

import { ArrowLeft, Trash2, X } from "lucide-react";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import { CropPreview } from "@/features/post-create/components/crop-preview";
import {
  ImageEditorControls,
  type EditorPanel,
} from "@/features/post-create/components/image-editor-controls";
import {
  ImageSelector,
  isAllowedPostImage,
  POST_IMAGE_ACCEPT,
} from "@/features/post-create/components/image-selector";
import type { ImageEditToolId } from "@/features/post-create/lib/image-edit-matrix";
import {
  newDraftEdit,
  newDraftId,
  type DraftPhoto,
} from "@/features/post-create/lib/post-create-model";
import {
  CLUSTER_COVER_MAX_PHOTOS,
  CLUSTER_SUBTITLE_MAX,
  CLUSTER_TITLE_MAX,
  createCluster,
} from "@/features/profile/lib/clusters-api";

type Step = "select" | "edit" | "compose" | "saving";

function revokePhoto(p: DraftPhoto | null) {
  if (p?.previewUrl.startsWith("blob:")) URL.revokeObjectURL(p.previewUrl);
}

/** Создание кластера: одно фото → редактор 1:1 → название → upload. */
export function CreateClusterFlow() {
  const router = useRouter();
  const fileRef = useRef<HTMLInputElement>(null);
  const photoRef = useRef<DraftPhoto | null>(null);
  const [step, setStep] = useState<Step>("select");
  const [photo, setPhoto] = useState<DraftPhoto | null>(null);
  photoRef.current = photo;
  const [title, setTitle] = useState("");
  const [subtitle, setSubtitle] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [editorPanel, setEditorPanel] = useState<EditorPanel>("effects");
  const [activeTool, setActiveTool] = useState<ImageEditToolId>("brightness");
  const [, startTransition] = useTransition();

  useEffect(() => {
    return () => revokePhoto(photoRef.current);
  }, []);

  const setCoverFile = (list: FileList | null, stayOn: Step = "select") => {
    const f = list?.[0];
    if (!f) return;
    if (!isAllowedPostImage(f)) {
      setError("Только JPEG, PNG или WebP");
      return;
    }
    revokePhoto(photo);
    const next: DraftPhoto = {
      id: newDraftId(),
      file: f,
      previewUrl: URL.createObjectURL(f),
      aspect: "1x1",
      zoom: 1,
      offsetX: 0,
      offsetY: 0,
      edit: newDraftEdit(),
    };
    setPhoto(next);
    setError(null);
    setStep(stayOn);
  };

  const removeCover = () => {
    revokePhoto(photo);
    setPhoto(null);
    setStep("select");
  };

  const patchPhoto = (patch: Partial<DraftPhoto>) => {
    setPhoto((prev) => (prev ? { ...prev, ...patch } : prev));
  };

  const close = () => {
    revokePhoto(photo);
    router.push("/app/profile");
  };

  const submit = () => {
    if (!photo || !title.trim()) return;
    setStep("saving");
    setError(null);
    startTransition(async () => {
      try {
        await createCluster({
          title,
          subtitle,
          cover: {
            file: photo.file,
            zoom: photo.zoom,
            offsetX: photo.offsetX,
            offsetY: photo.offsetY,
            edit: photo.edit,
          },
        });
        router.push("/app/profile");
        router.refresh();
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось создать");
        setStep("compose");
      }
    });
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
            {step === "select" && "Обложка кластера"}
            {step === "edit" && "Редактор"}
            {step === "compose" && "Новый кластер"}
            {step === "saving" && "Создаём…"}
          </h1>
          {step === "select" && photo ? (
            <button
              type="button"
              onClick={() => setStep("edit")}
              className="mr-1 rounded-full bg-brand px-3 py-1.5 text-[13px] font-bold text-on-brand"
            >
              Далее
            </button>
          ) : null}
          {step === "edit" && photo ? (
            <button
              type="button"
              onClick={() => setStep("compose")}
              className="mr-1 rounded-full bg-brand px-3 py-1.5 text-[13px] font-bold text-on-brand"
            >
              Далее
            </button>
          ) : null}
          {step === "select" && !photo ? (
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
            photos={photo ? [photo] : []}
            previewIndex={0}
            onPreviewIndex={() => undefined}
            onPickFiles={setCoverFile}
            onRemove={() => removeCover()}
            maxPhotos={CLUSTER_COVER_MAX_PHOTOS}
            previewAspect="1/1"
            emptyHint="Одно фото · обложка 1:1"
          />
        ) : null}

        {step === "edit" && photo ? (
          <div className="flex flex-1 flex-col gap-4 px-4 py-4 pb-8">
            <ImageEditorControls
              previewUrl={photo.previewUrl}
              edit={photo.edit}
              aspect="1x1"
              lockAspect
              zoom={photo.zoom}
              offsetX={photo.offsetX}
              offsetY={photo.offsetY}
              activeTool={activeTool}
              panel={editorPanel}
              onPanel={setEditorPanel}
              onActiveTool={setActiveTool}
              onEdit={(patch) => patchPhoto({ edit: { ...photo.edit, ...patch } })}
              onAspect={() => undefined}
              onZoom={(z) => patchPhoto({ zoom: z })}
              onOffset={(x, y) => patchPhoto({ offsetX: x, offsetY: y })}
            />

            <button
              type="button"
              onClick={() => fileRef.current?.click()}
              className="flex h-11 items-center justify-center gap-2 rounded-[14px] border border-line text-sm font-semibold text-destructive"
            >
              <Trash2 className="h-4 w-4" />
              Сменить фото
            </button>

            <input
              ref={fileRef}
              type="file"
              accept={POST_IMAGE_ACCEPT}
              className="hidden"
              onChange={(e) => {
                setCoverFile(e.target.files, "edit");
                e.target.value = "";
              }}
            />
          </div>
        ) : null}

        {(step === "compose" || step === "saving") && photo ? (
          <div className="flex flex-1 flex-col gap-4 px-4 py-4 pb-8">
            <div className="mx-auto w-full max-w-[320px] overflow-hidden rounded-[20px] border border-line bg-bg pointer-events-none">
              <CropPreview
                src={photo.previewUrl}
                edit={photo.edit}
                aspect="1x1"
                zoom={photo.zoom}
                offsetX={photo.offsetX}
                offsetY={photo.offsetY}
                onOffset={() => undefined}
              />
            </div>

            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Название</span>
              <input
                value={title}
                maxLength={CLUSTER_TITLE_MAX}
                disabled={step === "saving"}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="Например, Портфолио"
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none focus:border-brand disabled:opacity-50"
              />
            </label>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Описание</span>
              <textarea
                value={subtitle}
                maxLength={CLUSTER_SUBTITLE_MAX}
                disabled={step === "saving"}
                onChange={(e) => setSubtitle(e.target.value)}
                rows={3}
                placeholder="По желанию"
                className="w-full resize-none rounded-[14px] border border-line bg-bg px-4 py-3 text-[15px] text-ink outline-none focus:border-brand disabled:opacity-50"
              />
            </label>

            <AppButton
              type="button"
              loading={step === "saving"}
              disabled={!title.trim() || step === "saving"}
              onClick={submit}
            >
              Создать
            </AppButton>
          </div>
        ) : null}
      </div>
    </div>
  );
}
