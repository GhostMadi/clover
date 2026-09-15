"use client";

import { useEffect } from "react";
import { syncWebPushForCurrentUser } from "@/features/push/lib/web-push";

/** Registers FCM web token once the cabinet shell mounts (logged-in). */
export function WebPushBootstrap() {
  useEffect(() => {
    void syncWebPushForCurrentUser();
  }, []);
  return null;
}
