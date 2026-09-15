/* Clover web FCM background worker.
 * Config: /firebase-messaging-config.js (NEXT_PUBLIC_FIREBASE_* baked at request time).
 * See docs/supabase/SPEC_PUSH_FCM.md §5.
 */
importScripts("/firebase-messaging-config.js");
importScripts("https://www.gstatic.com/firebasejs/11.10.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/11.10.0/firebase-messaging-compat.js");

const config = self.__CLOVER_FIREBASE_CONFIG__;
if (config && config.apiKey && config.appId) {
  firebase.initializeApp(config);
  const messaging = firebase.messaging();
  messaging.onBackgroundMessage((payload) => {
    const title = payload.notification?.title || payload.data?.title || "Clover";
    const bodyText = payload.notification?.body || payload.data?.body || "";
    const data = payload.data || {};
    self.registration.showNotification(title, {
      body: bodyText,
      icon: "/logo.png",
      data,
    });
  });
}

function openUrlFromPayload(data) {
  if (!data || typeof data !== "object") return "/app/notifications";
  const kind = String(data.kind || "").trim();
  const bookingId = String(data.booking_id || "").trim();
  const workplaceId = String(data.workplace_id || "").trim();
  const postId = String(data.post_id || "").trim();
  const actorId = String(data.actor_id || data.user_id || "").trim();

  if (postId) return `/app/posts/${postId}`;
  if (kind.startsWith("booking_")) {
    const forHost = data.for_host === true || data.for_host === "true";
    if (forHost || kind.includes("_host") || kind === "booking_visit_started" || kind === "booking_visit_needs_close") {
      return bookingId
        ? `/app/settings/booking/inbox/${bookingId}`
        : "/app/settings/booking/inbox";
    }
    return bookingId
      ? `/app/settings/booking/my/${bookingId}`
      : "/app/settings/booking/my";
  }
  if (kind === "attendance_correction" && workplaceId) {
    return `/app/settings/attendance/w/${workplaceId}/corrections`;
  }
  if (kind.startsWith("attendance_") && workplaceId) {
    return `/app/settings/attendance/w/${workplaceId}`;
  }
  if (actorId && (kind === "user_follow" || kind === "follow")) {
    return `/app/u/${actorId}`;
  }
  return "/app/notifications";
}

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  const url = openUrlFromPayload(event.notification.data || {});
  event.waitUntil(
    clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const client of list) {
        if ("focus" in client) {
          client.navigate(url);
          return client.focus();
        }
      }
      if (clients.openWindow) return clients.openWindow(url);
    }),
  );
});
