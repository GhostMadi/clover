"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import {
  bookingPointBase,
  readBookingPointsCache,
  readLastBookingPointId,
  writeLastBookingPointId,
} from "@/features/booking/lib/booking-prefs";
import { listBookingPoints } from "@/features/booking/lib/points-api";
import { createClient } from "@/lib/supabase/client";

/**
 * `/app/settings/booking`
 * - Last точка → сразу inbox (без списка).
 * - Первый раз → `/points`.
 */
export function BookingEntryRedirect() {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      if (cancelled) return;
      const userId = session?.user.id ?? null;
      const last = readLastBookingPointId(userId);

      if (last) {
        router.replace(`${bookingPointBase(last)}/inbox`);
        return;
      }

      const cached = readBookingPointsCache(userId);
      if (cached?.length === 1 && cached[0]) {
        writeLastBookingPointId(userId, cached[0].id);
        router.replace(`${bookingPointBase(cached[0].id)}/inbox`);
        return;
      }

      if (cached && cached.length > 1) {
        router.replace("/app/settings/booking/points");
        return;
      }

      // Сеть: создать/подтянуть точки
      try {
        const points = await listBookingPoints();
        if (cancelled) return;
        if (points.length === 1) {
          writeLastBookingPointId(userId, points[0]!.id);
          router.replace(`${bookingPointBase(points[0]!.id)}/inbox`);
          return;
        }
        if (points.length === 0) {
          router.replace("/app/settings/booking/points");
          return;
        }
        router.replace("/app/settings/booking/points");
      } catch {
        if (!cancelled) router.replace("/app/settings/booking/points");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [router]);

  return (
    <div className="px-4 py-8">
      <BookingListShimmer rows={3} />
    </div>
  );
}
