"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { BookingListShimmer } from "@/features/booking/components/booking-shimmers";
import {
  bookingPointBase,
  readLastBookingPointId,
} from "@/features/booking/lib/booking-prefs";
import { listBookingPoints } from "@/features/booking/lib/points-api";
import { createClient } from "@/lib/supabase/client";

/** Старые URL → точка / entry. */
export function BookingLegacyRedirect({ suffix }: { suffix: string }) {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      if (cancelled) return;
      const uid = session?.user.id ?? null;
      let id = readLastBookingPointId(uid);
      if (!id) {
        try {
          const points = await listBookingPoints();
          id = points[0]?.id ?? null;
        } catch {
          id = null;
        }
      }
      if (cancelled) return;
      if (id) {
        router.replace(`${bookingPointBase(id)}${suffix}`);
      } else {
        router.replace("/app/settings/booking/points");
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [router, suffix]);

  return (
    <div className="px-4 py-8">
      <BookingListShimmer rows={3} />
    </div>
  );
}
