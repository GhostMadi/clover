// This file configures the initialization of Sentry for edge features (middleware, edge routes, and so on).
// The config you add here will be used whenever one of the edge features is loaded.
// Note that this config is unrelated to the Vercel Edge Runtime and is also required when running locally.
// https://docs.sentry.io/platforms/javascript/guides/nextjs/

import * as Sentry from "@sentry/nextjs";

Sentry.init({
  dsn: "https://d354c617e34fbcc5d9be1af10dad86a0@o4512063594168320.ingest.de.sentry.io/4512063615729744",

  enabled: process.env.NODE_ENV === "production",

  tracesSampleRate: 0.2,

  ignoreErrors: ["The destination stream closed early"],
});
