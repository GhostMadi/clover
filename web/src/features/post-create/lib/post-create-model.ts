import type { PostAspectRatioKind } from "@/features/post/lib/aspect-ratio";
import {
  ASPECT_1X1,
  ASPECT_4X3,
  ASPECT_9X16,
  ASPECT_16X9,
} from "@/features/post/lib/aspect-ratio";
import {
  DEFAULT_IMAGE_EDIT,
  type ImageEditSettings,
} from "@/features/post-create/lib/image-edit-matrix";

export const POST_CREATE_MAX_PHOTOS = 15;
export const POST_TITLE_MAX = 120;
export const POST_DESCRIPTION_MAX = 2000;

export const POST_ASPECT_OPTIONS = [
  ASPECT_1X1,
  ASPECT_4X3,
  ASPECT_16X9,
  ASPECT_9X16,
] as const;

export type DraftPhoto = {
  id: string;
  file: File;
  previewUrl: string;
  aspect: PostAspectRatioKind;
  /** 1 = cover, >1 zoom in */
  zoom: number;
  /** pan offset in normalized coords -0.5…0.5 */
  offsetX: number;
  offsetY: number;
  edit: ImageEditSettings;
};

export type SavedLocation = {
  id: string;
  addressPrimary: string;
  addressCyrillic: string | null;
  latitude: number | null;
  longitude: number | null;
  countryCode: string | null;
  cityCode: string | null;
};

export function aspectStorageMarker(kind: PostAspectRatioKind): string {
  return `__ar-${kind}`;
}

export function newDraftId(): string {
  return typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `p-${Date.now()}-${Math.random().toString(16).slice(2)}`;
}

export function newDraftEdit(): ImageEditSettings {
  return { ...DEFAULT_IMAGE_EDIT };
}
