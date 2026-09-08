"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export function SupportRequestForm() {
  const [contact, setContact] = useState("");
  const [message, setMessage] = useState("");
  const [busy, setBusy] = useState(false);
  const [done, setDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const onSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const c = contact.trim();
    const m = message.trim();
    if (c.length < 2 || m.length < 10) {
      setError("Укажите контакт и опишите проблему подробнее (от 10 символов).");
      return;
    }
    setBusy(true);
    try {
      const supabase = createClient();
      const {
        data: { user },
      } = await supabase.auth.getUser();
      const { error: insertError } = await supabase.from("support_requests").insert({
        contact: c,
        message: m,
        user_id: user?.id ?? null,
        source: "web",
        status: "new",
      });
      if (insertError) throw insertError;
      setDone(true);
      setContact("");
      setMessage("");
    } catch {
      setError("Не удалось отправить. Попробуйте позже или обновите страницу.");
    } finally {
      setBusy(false);
    }
  };

  if (done) {
    return (
      <div className="rounded-[16px] border border-line bg-mint px-4 py-5 text-[14px] leading-relaxed text-ink">
        Заявка отправлена. Мы ответим на указанный контакт, когда разберём обращение.
      </div>
    );
  }

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div>
        <label htmlFor="support-contact" className="mb-1.5 block text-[13px] font-semibold text-ink">
          Ник или email для ответа
        </label>
        <input
          id="support-contact"
          type="text"
          autoComplete="email"
          value={contact}
          onChange={(e) => setContact(e.target.value)}
          disabled={busy}
          className="h-11 w-full rounded-[12px] border border-line bg-surface px-3.5 text-[15px] text-ink outline-none placeholder:text-muted focus:border-brand/40 disabled:opacity-60"
          placeholder="например @nickname или you@mail.com"
        />
      </div>
      <div>
        <label htmlFor="support-message" className="mb-1.5 block text-[13px] font-semibold text-ink">
          Что случилось
        </label>
        <textarea
          id="support-message"
          rows={5}
          value={message}
          onChange={(e) => setMessage(e.target.value)}
          disabled={busy}
          className="w-full resize-y rounded-[12px] border border-line bg-surface px-3.5 py-3 text-[15px] text-ink outline-none placeholder:text-muted focus:border-brand/40 disabled:opacity-60"
          placeholder="Устройство (iOS / Android), коротко суть и как повторить"
        />
      </div>
      {error ? <p className="text-[13px] text-destructive">{error}</p> : null}
      <button
        type="submit"
        disabled={busy}
        className="inline-flex h-11 items-center rounded-[14px] bg-brand px-6 text-sm font-semibold text-ink transition hover:opacity-90 disabled:opacity-60"
      >
        {busy ? "Отправка…" : "Отправить"}
      </button>
    </form>
  );
}
