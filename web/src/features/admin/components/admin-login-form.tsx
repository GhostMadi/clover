"use client";

import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { AppButton } from "@/components/shared/app-button";

export function AdminLoginForm() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await fetch("/api/admin/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });
      const data = (await res.json().catch(() => ({}))) as { error?: string };
      if (!res.ok) {
        setError(data.error ?? "Не удалось войти");
        return;
      }
      router.replace("/admin/home");
      router.refresh();
    } catch {
      setError("Сеть недоступна");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="flex w-full max-w-sm flex-col gap-3">
      <label className="flex flex-col gap-1.5">
        <span className="text-[12px] font-semibold text-muted">Email</span>
        <input
          type="email"
          autoComplete="username"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="h-11 rounded-[14px] border border-line bg-surface px-3.5 text-[15px] text-ink outline-none focus:border-brand"
        />
      </label>
      <label className="flex flex-col gap-1.5">
        <span className="text-[12px] font-semibold text-muted">Пароль</span>
        <input
          type="password"
          autoComplete="current-password"
          required
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="h-11 rounded-[14px] border border-line bg-surface px-3.5 text-[15px] text-ink outline-none focus:border-brand"
        />
      </label>
      {error ? <p className="text-[13px] font-medium text-destructive">{error}</p> : null}
      <AppButton type="submit" disabled={loading}>
        {loading ? "Вход…" : "Войти"}
      </AppButton>
    </form>
  );
}
