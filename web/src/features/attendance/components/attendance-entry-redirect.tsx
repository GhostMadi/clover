"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import {
  readAttendanceHubCache,
  readLastAttendanceWorkplaceId,
  writeLastAttendanceWorkplaceId,
} from "@/features/attendance/lib/attendance-prefs";
import { createClient } from "@/lib/supabase/client";

/**
 * `/app/settings/attendance`
 * - Уже заходил → сразу детальный workspace last-компании (без загрузки списка).
 * - Первый раз → `/companies` выбрать компанию.
 */
export function AttendanceEntryRedirect() {
  const router = useRouter();

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const {
        data: { session },
      } = await createClient().auth.getSession();
      if (cancelled) return;

      const userId = session?.user.id ?? null;
      const last = readLastAttendanceWorkplaceId(userId);

      if (last) {
        router.replace(`/app/settings/attendance/w/${last}`);
        return;
      }

      const cached = readAttendanceHubCache(userId);
      const only =
        cached?.workplaces?.length === 1 ? cached.workplaces[0] : null;
      if (only) {
        writeLastAttendanceWorkplaceId(userId, only.id);
        router.replace(`/app/settings/attendance/w/${only.id}`);
        return;
      }

      router.replace("/app/settings/attendance/companies");
    })();
    return () => {
      cancelled = true;
    };
  }, [router]);

  return (
    <div className="px-4 py-8">
      <AttendanceListShimmer rows={3} />
    </div>
  );
}
