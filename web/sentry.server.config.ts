// This file configures the initialization of Sentry on the server.
// The config you add here will be used whenever the server handles a request.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: "https://d354c617e34fbcc5d9be1af10dad86a0@o4512063594168320.ingest.de.sentry.io/4512063615729744",

  // Local `next dev` / Cursor preview — не слать в Sentry (шум RSC abort).
  enabled: process.env.NODE_ENV === "production",

  tracesSampleRate: 0.2,

  // Next.js App Router: клиент ушёл / HMR оборвал RSC stream.
  ignoreErrors: ["The destination stream closed early"],
});
