"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { FormEvent, Suspense, useState } from "react";
import { GoogleIcon } from "@/components/icons/google-icon";
import { AppButton } from "@/components/shared/app-button";
import { AppField } from "@/components/shared/app-field";
import { loginWithPassword, signInWithGoogle } from "@/features/auth/lib/auth-api";
import { AUTH_MESSAGES } from "@/features/auth/lib/messages";

function LoginForm() {
  const router = useRouter();
  const search = useSearchParams();
  const next = search.get("next") || "/app";
  const oauthError = search.get("error") === "oauth";

  const [identifier, setIdentifier] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(oauthError ? AUTH_MESSAGES.googleFailed : "");

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await loginWithPassword(identifier, password);
      router.replace(next);
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : AUTH_MESSAGES.generic);
    } finally {
      setLoading(false);
    }
  }

  async function onGoogle() {
    setError("");
    setLoading(true);
    try {
      await signInWithGoogle();
    } catch (err) {
      setError(err instanceof Error ? err.message : AUTH_MESSAGES.googleFailed);
      setLoading(false);
    }
  }

  return (
    <form onSubmit={onSubmit} className="space-y-3.5">
      <div className="mb-2 lg:mb-4">
        <h1 className="font-display text-2xl font-semibold text-on-media">Вход</h1>
        <p className="mt-1 text-sm text-on-media/50 lg:hidden">Ник или email, как в приложении</p>
      </div>
      <AppField
        label="Ник или email"
        hint="@username или email"
        autoComplete="username"
        value={identifier}
        onChange={(e) => setIdentifier(e.target.value)}
        disabled={loading}
      />
      <div className="relative">
        <AppField
          label="Пароль"
          hint="••••••••"
          type={showPassword ? "text" : "password"}
          autoComplete="current-password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          disabled={loading}
        />
        <button
          type="button"
          className="absolute top-[2.35rem] right-3 text-xs font-semibold text-brand"
          onClick={() => setShowPassword((v) => !v)}
        >
          {showPassword ? "Скрыть" : "Показать"}
        </button>
      </div>

      <div className="flex justify-end">
        <Link href="/auth/forgot" className="text-[13px] font-semibold text-brand">
          Забыли пароль?
        </Link>
      </div>

      {error ? (
        <p className="rounded-[14px] border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-error">
          {error}
        </p>
      ) : null}

      <AppButton type="submit" loading={loading}>
        Войти
      </AppButton>

      <p className="pt-1 text-center text-sm text-on-media/55">
        Нет аккаунта?{" "}
        <Link href="/auth/register" className="font-bold text-brand">
          Создать
        </Link>
      </p>

      <div className="flex items-center gap-3 py-3">
        <div className="h-px flex-1 bg-on-media/10" />
        <span className="text-xs tracking-wide text-on-media/40 uppercase">или</span>
        <div className="h-px flex-1 bg-on-media/10" />
      </div>

      <AppButton type="button" variant="google" loading={loading} onClick={onGoogle}>
        <span className="inline-flex items-center gap-2.5">
          <GoogleIcon />
          Войти через Google
        </span>
      </AppButton>
    </form>
  );
}

export default function AuthLoginPage() {
  return (
    <Suspense fallback={<div className="h-40 animate-pulse rounded-[14px] bg-on-media/5" />}>
      <LoginForm />
    </Suspense>
  );
}
