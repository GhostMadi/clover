// This file configures the initialization of Sentry on the client.
// The added config here will be used whenever a users loads a page in their browser.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: "https://d354c617e34fbcc5d9be1af10dad86a0@o4512063594168320.ingest.de.sentry.io/4512063615729744",

  enabled: process.env.NODE_ENV === "production",

  integrations: [Sentry.replayIntegration()],

  tracesSampleRate: 0.2,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,

  ignoreErrors: ["The destination stream closed early"],
});

export const onRouterTransitionStart = Sentry.captureRouterTransitionStart;
