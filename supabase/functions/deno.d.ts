/** Deno Edge Runtime globals — for IDE/typecheck only (Supabase Functions run on Deno). */
declare const Deno: {
  readonly env: {
    get(key: string): string | undefined;
  };
  serve(handler: (request: Request) => Response | Promise<Response>): void;
};
