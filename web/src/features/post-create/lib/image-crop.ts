/** Кроп фото в JPEG с выбранным aspect + цветовая матрица (эффекты). */

import type { PostAspectRatioKind } from "@/features/post/lib/aspect-ratio";
import {
  ASPECT_1X1,
  ASPECT_4X3,
  ASPECT_9X16,
  ASPECT_16X9,
} from "@/features/post/lib/aspect-ratio";
import {
  applyColorMatrixToImageData,
  composedColorMatrix,
  isIdentityEdit,
  type ImageEditSettings,
} from "@/features/post-create/lib/image-edit-matrix";

const MAX_SIDE = 1440;
const JPEG_QUALITY = 0.88;

function ratioOf(kind: PostAspectRatioKind): number {
  switch (kind) {
    case "1x1":
      return ASPECT_1X1.ratio;
    case "4x3":
      return ASPECT_4X3.ratio;
    case "16x9":
      return ASPECT_16X9.ratio;
    case "9x16":
      return ASPECT_9X16.ratio;
  }
}

export async function exportCroppedJpeg(opts: {
  file: File;
  aspect: PostAspectRatioKind;
  zoom?: number;
  offsetX?: number;
  offsetY?: number;
  edit?: ImageEditSettings;
}): Promise<File> {
  const zoom = Math.max(1, opts.zoom ?? 1);
  const offsetX = opts.offsetX ?? 0;
  const offsetY = opts.offsetY ?? 0;
  const targetRatio = ratioOf(opts.aspect);

  const bitmap = await createImageBitmap(opts.file);
  const srcW = bitmap.width;
  const srcH = bitmap.height;
  const srcRatio = srcW / srcH;

  let cropW: number;
  let cropH: number;
  if (srcRatio > targetRatio) {
    cropH = srcH;
    cropW = srcH * targetRatio;
  } else {
    cropW = srcW;
    cropH = srcW / targetRatio;
  }

  cropW /= zoom;
  cropH /= zoom;

  const maxOffsetX = (srcW - cropW) / 2;
  const maxOffsetY = (srcH - cropH) / 2;
  // positive offset = картинка сдвинута вниз/вправо в превью → виден верх/лево исходника
  const cx = srcW / 2 - offsetX * maxOffsetX * 2;
  const cy = srcH / 2 - offsetY * maxOffsetY * 2;
  const sx = Math.max(0, Math.min(srcW - cropW, cx - cropW / 2));
  const sy = Math.max(0, Math.min(srcH - cropH, cy - cropH / 2));

  let outW = Math.round(cropW);
  let outH = Math.round(cropH);
  const long = Math.max(outW, outH);
  if (long > MAX_SIDE) {
    const scale = MAX_SIDE / long;
    outW = Math.max(1, Math.round(outW * scale));
    outH = Math.max(1, Math.round(outH * scale));
  }

  const canvas = document.createElement("canvas");
  canvas.width = outW;
  canvas.height = outH;
  const ctx = canvas.getContext("2d", { willReadFrequently: true });
  if (!ctx) {
    bitmap.close();
    throw new Error("Canvas недоступен");
  }
  ctx.drawImage(bitmap, sx, sy, cropW, cropH, 0, 0, outW, outH);
  bitmap.close();

  if (opts.edit && !isIdentityEdit(opts.edit)) {
    const imageData = ctx.getImageData(0, 0, outW, outH);
    applyColorMatrixToImageData(imageData, composedColorMatrix(opts.edit));
    ctx.putImageData(imageData, 0, 0);
  }

  const blob = await new Promise<Blob | null>((resolve) => {
    canvas.toBlob((b) => resolve(b), "image/jpeg", JPEG_QUALITY);
  });
  if (!blob) throw new Error("Не удалось сохранить фото");

  const base = opts.file.name.replace(/\.[^.]+$/, "") || "photo";
  return new File([blob], `${base}.jpg`, { type: "image/jpeg" });
}
