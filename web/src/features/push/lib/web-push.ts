"use client";

import { initializeApp, getApps, type FirebaseApp } from "firebase/app";
import {
  getMessaging,
  getToken,
  deleteToken,
  isSupported,
  type Messaging,
} from "firebase/messaging";
import { createClient } from "@/lib/supabase/client";
import {
  getFirebaseVapidKey,
  getFirebaseWebConfig,
  isWebPushConfigured,
} from "@/lib/firebase/config";

const TABLE = "push_device_tokens";
const PLATFORM = "web";
const TOKEN_STORAGE_KEY = "clover_web_fcm_token";

let appSingleton: FirebaseApp | null = null;
let messagingSingleton: Messaging | null = null;
let syncInFlight: Promise<void> | null = null;

function readStoredToken(): string | null {
  try {
    return localStorage.getItem(TOKEN_STORAGE_KEY)?.trim() || null;
  } catch {
    return null;
  }
}

function writeStoredToken(token: string | null) {
  try {
    if (token) localStorage.setItem(TOKEN_STORAGE_KEY, token);
    else localStorage.removeItem(TOKEN_STORAGE_KEY);
  } catch {
    // ignore
  }
}

async function getFirebaseApp(): Promise<FirebaseApp | null> {
  const config = getFirebaseWebConfig();
  if (!config) return null;
  if (appSingleton) return appSingleton;
  appSingleton = getApps().length ? getApps()[0]! : initializeApp(config);
  return appSingleton;
}

async function getFirebaseMessaging(): Promise<Messaging | null> {
  if (typeof window === "undefined") return null;
  if (!(await isSupported())) return null;
  if (messagingSingleton) return messagingSingleton;
  const app = await getFirebaseApp();
  if (!app) return null;
  messagingSingleton = getMessaging(app);
  return messagingSingleton;
}

/**
 * After login / cabinet mount: permission → FCM token → upsert platform=web.
 * No-ops when Firebase web env is incomplete (see lib/firebase/config.ts).
 */
export async function syncWebPushForCurrentUser(): Promise<void> {
  if (!isWebPushConfigured()) return;
  if (typeof window === "undefined" || !("Notification" in window)) return;

  if (syncInFlight) return syncInFlight;
  syncInFlight = (async () => {
    const supabase = createClient();
    const {
      data: { session },
    } = await supabase.auth.getSession();
    const userId = session?.user.id;
    if (!userId) return;

    const messaging = await getFirebaseMessaging();
    const vapidKey = getFirebaseVapidKey();
    if (!messaging || !vapidKey) return;

    const permission =
      Notification.permission === "granted"
        ? "granted"
        : await Notification.requestPermission();
    if (permission !== "granted") return;

    const sw = await navigator.serviceWorker.register("/firebase-messaging-sw.js", {
      scope: "/",
    });
    await navigator.serviceWorker.ready;

    const token = await getToken(messaging, {
      vapidKey,
      serviceWorkerRegistration: sw,
    });
    if (!token) return;

    writeStoredToken(token);
    await supabase.from(TABLE).upsert(
      {
        user_id: userId,
        token,
        platform: PLATFORM,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "user_id,platform" },
    );
  })()
    .catch(() => {
      // ignore — in-app notifications still work
    })
    .finally(() => {
      syncInFlight = null;
    });

  return syncInFlight;
}

/** Before auth.signOut — delete this browser's web token from push_device_tokens. */
export async function detachWebPushForSignOut(): Promise<void> {
  const token = readStoredToken();
  writeStoredToken(null);

  try {
    const supabase = createClient();
    if (token) {
      await supabase.from(TABLE).delete().eq("token", token).eq("platform", PLATFORM);
    } else {
      const {
        data: { session },
      } = await supabase.auth.getSession();
      const userId = session?.user.id;
      if (userId) {
        await supabase.from(TABLE).delete().eq("user_id", userId).eq("platform", PLATFORM);
      }
    }
  } catch {
    // ignore
  }

  try {
    if (!isWebPushConfigured()) return;
    const messaging = await getFirebaseMessaging();
    if (messaging) await deleteToken(messaging);
  } catch {
    // ignore
  }
}
