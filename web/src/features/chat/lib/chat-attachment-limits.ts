/** Лимиты вложений чата — как на мобилке / исходный bucket chat_media. */

/** Сколько файлов за одно сообщение (фото: maxSelectionCount: 10). */
export const CHAT_MAX_FILES_PER_MESSAGE = 10;

/** 10 MiB на файл — как в миграции bucket (aligned with client validation). */
export const CHAT_MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

/** Длинная сторона фото после сжатия (ChatImageCompress.maxSide). */
export const CHAT_IMAGE_MAX_SIDE = 1080;

/** JPEG quality ≈ 78% (ChatImageCompress.jpegQuality). */
export const CHAT_JPEG_QUALITY = 0.78;

/** Разрешённые MIME — исходный allowlist bucket chat_media. */
export const CHAT_ALLOWED_MIME_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "image/gif",
  "image/heic",
  "image/heif",
  "video/mp4",
  "video/quicktime",
  "application/pdf",
] as const;

export type ChatAllowedMime = (typeof CHAT_ALLOWED_MIME_TYPES)[number];

export const CHAT_PHOTO_ACCEPT =
  "image/jpeg,image/png,image/webp,image/gif,image/heic,image/heif,.jpg,.jpeg,.png,.webp,.gif,.heic,.heif";

export const CHAT_DOCUMENT_ACCEPT =
  "image/jpeg,image/png,image/webp,image/gif,image/heic,image/heif,video/mp4,video/quicktime,application/pdf,.jpg,.jpeg,.png,.webp,.gif,.heic,.heif,.mp4,.mov,.pdf";

export function mimeFromFilename(filename: string, fallback?: string | null): string {
  const lower = filename.toLowerCase();
  if (lower.endsWith(".jpg") || lower.endsWith(".jpeg")) return "image/jpeg";
  if (lower.endsWith(".png")) return "image/png";
  if (lower.endsWith(".webp")) return "image/webp";
  if (lower.endsWith(".gif")) return "image/gif";
  if (lower.endsWith(".heic") || lower.endsWith(".heif")) return "image/heic";
  if (lower.endsWith(".pdf")) return "application/pdf";
  if (lower.endsWith(".mp4")) return "video/mp4";
  if (lower.endsWith(".mov")) return "video/quicktime";
  const ext = fallback?.trim().toLowerCase();
  if (ext === "pdf") return "application/pdf";
  return "application/octet-stream";
}

export function normalizeMime(raw: string | null | undefined, filename: string): string {
  const t = (raw ?? "").trim().toLowerCase();
  if (t && t !== "application/octet-stream") return t;
  return mimeFromFilename(filename);
}

export function isAllowedChatMime(mime: string): boolean {
  const m = mime.trim().toLowerCase();
  if ((CHAT_ALLOWED_MIME_TYPES as readonly string[]).includes(m)) return true;
  // некоторые браузеры отдают image/jpg
  if (m === "image/jpg") return true;
  return false;
}

export function isImageMime(mime: string): boolean {
  return mime.trim().toLowerCase().startsWith("image/");
}

export function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export type PendingChatFile = {
  id: string;
  file: File;
  filename: string;
  mime: string;
  sizeBytes: number;
  previewUrl: string | null;
};

export type AttachValidateError =
  | "too_many"
  | "too_large"
  | "bad_type"
  | "empty";

export function validateChatFiles(
  files: File[],
  alreadyCount: number,
): { ok: PendingChatFile[]; errors: { name: string; reason: AttachValidateError }[] } {
  const errors: { name: string; reason: AttachValidateError }[] = [];
  const ok: PendingChatFile[] = [];
  const room = Math.max(0, CHAT_MAX_FILES_PER_MESSAGE - alreadyCount);

  for (const file of files) {
    if (ok.length >= room) {
      errors.push({ name: file.name, reason: "too_many" });
      continue;
    }
    if (!file.size) {
      errors.push({ name: file.name || "файл", reason: "empty" });
      continue;
    }
    if (file.size > CHAT_MAX_FILE_SIZE_BYTES) {
      errors.push({ name: file.name || "файл", reason: "too_large" });
      continue;
    }
    const mime = normalizeMime(file.type, file.name);
    if (!isAllowedChatMime(mime)) {
      errors.push({ name: file.name || "файл", reason: "bad_type" });
      continue;
    }
    const id =
      typeof crypto !== "undefined" && "randomUUID" in crypto
        ? crypto.randomUUID()
        : `f-${Date.now()}-${ok.length}`;
    ok.push({
      id,
      file,
      filename: file.name.trim() || "file.bin",
      mime: mime === "image/jpg" ? "image/jpeg" : mime,
      sizeBytes: file.size,
      previewUrl: isImageMime(mime) ? URL.createObjectURL(file) : null,
    });
  }

  return { ok, errors };
}

export function attachErrorMessage(reason: AttachValidateError): string {
  switch (reason) {
    case "too_many":
      return `Не больше ${CHAT_MAX_FILES_PER_MESSAGE} файлов за раз`;
    case "too_large":
      return `Файл больше ${CHAT_MAX_FILE_SIZE_BYTES / (1024 * 1024)} МБ`;
    case "bad_type":
      return "Тип файла не поддерживается (фото, PDF, MP4/MOV)";
    case "empty":
      return "Пустой файл";
  }
}

/** Сжатие фото как ChatImageCompress (длинная сторона 1080, JPEG ~78). */
export async function compressChatImage(file: File, mime: string): Promise<File> {
  if (!isImageMime(mime) || mime === "image/gif" || mime === "image/heic" || mime === "image/heif") {
    return file;
  }

  try {
    const bitmap = await createImageBitmap(file);
    const { width, height } = bitmap;
    const maxSide = Math.max(width, height);
    const scale = maxSide > CHAT_IMAGE_MAX_SIDE ? CHAT_IMAGE_MAX_SIDE / maxSide : 1;
    const w = Math.max(1, Math.round(width * scale));
    const h = Math.max(1, Math.round(height * scale));
    const canvas = document.createElement("canvas");
    canvas.width = w;
    canvas.height = h;
    const ctx = canvas.getContext("2d");
    if (!ctx) {
      bitmap.close();
      return file;
    }
    ctx.drawImage(bitmap, 0, 0, w, h);
    bitmap.close();

    const blob = await new Promise<Blob | null>((resolve) => {
      canvas.toBlob((b) => resolve(b), "image/jpeg", CHAT_JPEG_QUALITY);
    });
    if (!blob || blob.size === 0) return file;

    const base = file.name.replace(/\.[^.]+$/, "") || "photo";
    return new File([blob], `${base}.jpg`, { type: "image/jpeg" });
  } catch {
    return file;
  }
}

export async function prepareUploads(pending: PendingChatFile[]): Promise<File[]> {
  const out: File[] = [];
  for (const item of pending) {
    if (isImageMime(item.mime)) {
      out.push(await compressChatImage(item.file, item.mime));
    } else {
      out.push(item.file);
    }
  }
  return out;
}
