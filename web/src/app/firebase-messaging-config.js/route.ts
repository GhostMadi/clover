/**
 * Public Firebase web config for the FCM service worker.
 * Values come from NEXT_PUBLIC_FIREBASE_* (see SPEC_PUSH_FCM.md §5).
 */
import { getFirebaseWebConfig, isWebPushConfigured } from "@/lib/firebase/config";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";

export function GET() {
  const config = isWebPushConfigured() ? getFirebaseWebConfig() : null;
  const body = `/* Clover — do not commit secrets; publishable client config only */
self.__CLOVER_FIREBASE_CONFIG__ = ${JSON.stringify(config)};
`;
  return new Response(body, {
    headers: {
      "Content-Type": "application/javascript; charset=utf-8",
      "Cache-Control": "no-cache, no-store, must-revalidate",
    },
  });
}
