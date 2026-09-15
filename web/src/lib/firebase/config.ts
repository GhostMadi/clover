/**
 * Firebase Web (FCM) — public client config via NEXT_PUBLIC_*.
 *
 * Create a Web app in Firebase Console (project clover-52112) then set in Vercel / .env.local:
 *   NEXT_PUBLIC_FIREBASE_API_KEY
 *   NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN   (usually clover-52112.firebaseapp.com)
 *   NEXT_PUBLIC_FIREBASE_PROJECT_ID    (clover-52112)
 *   NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET (clover-52112.firebasestorage.app)
 *   NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID (1044695605376)
 *   NEXT_PUBLIC_FIREBASE_APP_ID        (1:…:web:…)
 *   NEXT_PUBLIC_FIREBASE_VAPID_KEY     (Cloud Messaging → Web Push certificates)
 *
 * Do not commit secrets; these keys are publishable client config only.
 */

export type FirebaseWebConfig = {
  apiKey: string;
  authDomain: string;
  projectId: string;
  storageBucket: string;
  messagingSenderId: string;
  appId: string;
};

function trim(value: string | undefined): string {
  return value?.trim() ?? "";
}

export function getFirebaseWebConfig(): FirebaseWebConfig | null {
  const apiKey = trim(process.env.NEXT_PUBLIC_FIREBASE_API_KEY);
  const authDomain = trim(process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN);
  const projectId = trim(process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID);
  const storageBucket = trim(process.env.NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET);
  const messagingSenderId = trim(process.env.NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID);
  const appId = trim(process.env.NEXT_PUBLIC_FIREBASE_APP_ID);

  if (!apiKey || !authDomain || !projectId || !messagingSenderId || !appId) {
    return null;
  }

  return {
    apiKey,
    authDomain,
    projectId,
    storageBucket: storageBucket || `${projectId}.firebasestorage.app`,
    messagingSenderId,
    appId,
  };
}

export function getFirebaseVapidKey(): string | null {
  const key = trim(process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY);
  return key || null;
}

export function isWebPushConfigured(): boolean {
  return getFirebaseWebConfig() !== null && getFirebaseVapidKey() !== null;
}
