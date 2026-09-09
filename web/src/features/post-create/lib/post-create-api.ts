"use client";

import { createClient } from "@/lib/supabase/client";
import { exportCroppedJpeg } from "@/features/post-create/lib/image-crop";
import {
  aspectStorageMarker,
  type DraftPhoto,
  type SavedLocation,
} from "@/features/post-create/lib/post-create-model";
import { setPostProfileFilters } from "@/features/resources/lib/profile-filters-api";
import { deleteFromR2, uploadToR2 } from "@/lib/r2-storage";

export type PublishPostInput = {
  photos: DraftPhoto[];
  title: string;
  description: string;
  textEmoji: string;
  tagKeys: string[];
  /** Ключи витрины `categoryId:label`. */
  profileFilterKeys?: string[];
  /** Привязка услуги записи (0..1). */
  bookingServiceId?: string | null;
  /** If set with location → event */
  eventStartIso?: string | null;
  eventDurationMinutes?: number | null;
  location?: SavedLocation | null;
  onProgress?: (pct: number) => void;
};

export type PublishPostResult = {
  postId: string;
  markerId: string | null;
};

function newMediaId(): string {
  return crypto.randomUUID().replace(/-/g, "");
}

function formatPgInterval(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m} minutes`;
  if (m === 0) return `${h} hours`;
  return `${h} hours ${m} minutes`;
}

async function resolveTagIds(keys: string[]): Promise<string[]> {
  const supabase = createClient();
  const normalized = [...new Set(keys.map((k) => k.trim()).filter(Boolean))];
  if (!normalized.length) return [];
  const { data, error } = await supabase
    .from("marker_tags")
    .select("id, key")
    .in("key", normalized);
  if (error) throw error;
  return (data ?? [])
    .map((r) => String((r as { id?: string }).id ?? "").trim())
    .filter(Boolean);
}

async function setPostTags(postId: string, tagKeys: string[]) {
  const supabase = createClient();
  const ids = await resolveTagIds(tagKeys);
  await supabase.from("post_tag_links").delete().eq("post_id", postId);
  if (!ids.length) return;
  const { error } = await supabase.from("post_tag_links").insert(
    ids.map((tag_id) => ({ post_id: postId, tag_id })),
  );
  if (error) throw error;
}

async function setMarkerTags(markerId: string, tagKeys: string[]) {
  const supabase = createClient();
  const ids = await resolveTagIds(tagKeys);
  await supabase.from("marker_tag_links").delete().eq("marker_id", markerId);
  if (!ids.length) return;
  const { error } = await supabase.from("marker_tag_links").insert(
    ids.map((tag_id) => ({ marker_id: markerId, tag_id })),
  );
  if (error) throw error;
}

export async function publishPost(input: PublishPostInput): Promise<PublishPostResult> {
  if (input.photos.length === 0) throw new Error("Добавьте хотя бы одно фото");

  const isEvent = Boolean(input.eventStartIso && input.eventDurationMinutes);
  if (isEvent) {
    if (!input.textEmoji.trim()) throw new Error("Выберите эмодзи");
    if (!input.location) throw new Error("Выберите местоположение");
    const lat = input.location.latitude;
    const lng = input.location.longitude;
    if (lat == null || lng == null) throw new Error("У места нет координат");
    const mins = input.eventDurationMinutes ?? 0;
    if (mins < 1 || mins > 24 * 60) throw new Error("Длительность события: от 1 мин до 24 ч");
  }

  const supabase = createClient();
  const {
    data: { session },
  } = await supabase.auth.getSession();
  const uid = session?.user.id;
  if (!uid) throw new Error("Нет сессии");

  const report = (n: number) => input.onProgress?.(Math.max(0, Math.min(100, n)));
  report(4);

  let markerId: string | null = null;
  const uploadedUrls: string[] = [];
  let postId: string | null = null;

  try {
    if (isEvent && input.location) {
      const loc = input.location;
      const lat = loc.latitude!;
      const lng = loc.longitude!;
      const markerInsert: Record<string, unknown> = {
        owner_id: uid,
        text_emoji: input.textEmoji.trim(),
        location_id: loc.id,
        location: `SRID=4326;POINT(${lng} ${lat})`,
        event_time: new Date(input.eventStartIso!).toISOString(),
        duration: formatPgInterval(input.eventDurationMinutes!),
      };
      if (loc.addressPrimary) markerInsert.address_primary = loc.addressPrimary;
      if (loc.addressCyrillic) markerInsert.address_cyrillic = loc.addressCyrillic;
      if (loc.countryCode && loc.cityCode) {
        markerInsert.country_code = loc.countryCode;
        markerInsert.city_code = loc.cityCode;
      }

      const { data: markerRow, error: mErr } = await supabase
        .from("markers")
        .insert(markerInsert)
        .select("id")
        .single();
      if (mErr) throw mErr;
      markerId = String(markerRow?.id ?? "").trim() || null;
      if (!markerId) throw new Error("Не удалось создать маркер");
      report(10);
    }

    const postInsert: Record<string, unknown> = {
      user_id: uid,
      title: input.title.trim() || null,
      description: input.description.trim() || null,
    };
    if (input.textEmoji.trim()) postInsert.text_emoji = input.textEmoji.trim();
    if (input.location) postInsert.location_id = input.location.id;
    if (markerId) postInsert.marker_id = markerId;
    if (input.bookingServiceId?.trim()) {
      postInsert.booking_service_id = input.bookingServiceId.trim();
    }

    const { data: postRow, error: pErr } = await supabase
      .from("posts")
      .insert(postInsert)
      .select("id")
      .single();
    if (pErr) throw pErr;
    postId = String(postRow?.id ?? "").trim();
    if (!postId) throw new Error("Не удалось создать пост");
    report(16);

    const mediaRows: Record<string, unknown>[] = [];
    let coverUrl: string | null = null;
    const total = input.photos.length;

    for (let i = 0; i < total; i++) {
      const photo = input.photos[i]!;
      const jpeg = await exportCroppedJpeg({
        file: photo.file,
        aspect: photo.aspect,
        zoom: photo.zoom,
        offsetX: photo.offsetX,
        offsetY: photo.offsetY,
        edit: photo.edit,
      });
      const mediaId = newMediaId();
      const fileName = `${mediaId}${aspectStorageMarker(photo.aspect)}.jpg`;

      const uploaded = await uploadToR2({
        file: jpeg,
        fileName,
        folder: `post_media/${postId}`,
        contentType: "image/jpeg",
      });
      uploadedUrls.push(uploaded.stablePublicUrl);

      const url = uploaded.publicUrl;
      if (!coverUrl) coverUrl = url;
      mediaRows.push({
        post_id: postId,
        url,
        type: "image",
        sort_order: i,
      });
      report(16 + Math.round(((i + 1) / total) * 70));
    }

    const { error: mediaErr } = await supabase.from("post_media").insert(mediaRows);
    if (mediaErr) throw mediaErr;

    if (markerId && coverUrl) {
      await supabase.from("markers").update({ cover_image_url: coverUrl }).eq("id", markerId);
    }

    if (input.tagKeys.length) {
      await setPostTags(postId, input.tagKeys);
      if (markerId) await setMarkerTags(markerId, input.tagKeys);
    }

    if (input.profileFilterKeys?.length) {
      await setPostProfileFilters(postId, input.profileFilterKeys);
    }

    report(100);
    return { postId, markerId };
  } catch (e) {
    if (uploadedUrls.length) {
      await deleteFromR2({ urls: uploadedUrls });
    }
    if (postId) {
      try {
        await supabase.from("posts").delete().eq("id", postId);
      } catch {
        /* ignore */
      }
    }
    if (markerId) {
      try {
        await supabase.from("markers").delete().eq("id", markerId);
      } catch {
        /* ignore */
      }
    }
    throw e;
  }
}
