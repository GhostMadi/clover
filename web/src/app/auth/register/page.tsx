"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { GoogleIcon } from "@/components/icons/google-icon";
import { AppButton } from "@/components/shared/app-button";
import { AppField } from "@/components/shared/app-field";
import {
  sendRegisterOtp,
  signInWithGoogle,
  updatePassword,
  verifyEmailOtp,
} from "@/features/auth/lib/auth-api";
import { AUTH_MESSAGES, MIN_PASSWORD_LENGTH } from "@/features/auth/lib/messages";

type Step = "email" | "otp" | "password";

export default function RegisterPage() {
  const router = useRouter();
  const [step, setStep] = useState<Step>("email");
  const [email, setEmail] = useState("");
  const [otp, setOtp] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function onEmail(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await sendRegisterOtp(email);
      setStep("otp");
    } catch (err) {
      setError(err instanceof Error ? err.message : AUTH_MESSAGES.generic);
    } finally {
      setLoading(false);
    }
  }

  async function onOtp(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await verifyEmailOtp(email, otp);
      setStep("password");
    } catch (err) {
      setError(err instanceof Error ? err.message : AUTH_MESSAGES.otpInvalid);
    } finally {
      setLoading(false);
    }
  }

  async function onPassword(e: FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await updatePassword(password);
      router.replace("/app");
      router.refresh();
    } catch (err) {
      setError(err instanceof Error ? err.message : AUTH_MESSAGES.generic);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="space-y-4">
      <div>
        <h1 className="font-display text-2xl font-semibold text-on-media">Регистрация</h1>
        <p className="mt-1 text-sm text-on-media/55">
          Как в приложении: email → код → пароль (минимум {MIN_PASSWORD_LENGTH} символов).
        </p>
      </div>

      {error ? (
        <p className="rounded-[14px] border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-error">
          {error}
        </p>
      ) : null}

      {step === "email" ? (
        <form onSubmit={onEmail} className="space-y-3.5">
          <AppField
            label="Email"
            hint="you@email.com"
            type="email"
            autoComplete="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={loading}
          />
          <AppButton type="submit" loading={loading}>
            Получить код
          </AppButton>
          <AppButton
            type="button"
            variant="google"
            loading={loading}
            onClick={async () => {
              setLoading(true);
              try {
                await signInWithGoogle();
              } catch (err) {
                setError(err instanceof Error ? err.message : AUTH_MESSAGES.googleFailed);
                setLoading(false);
              }
            }}
          >
            <span className="inline-flex items-center gap-2.5">
              <GoogleIcon />
              Войти через Google
            </span>
          </AppButton>
        </form>
      ) : null}

      {step === "otp" ? (
        <form onSubmit={onOtp} className="space-y-3.5">
          <AppField
            label="Код из письма"
            hint="6 цифр"
            inputMode="numeric"
            value={otp}
            onChange={(e) => setOtp(e.target.value)}
            disabled={loading}
          />
          <AppButton type="submit" loading={loading}>
            Подтвердить
          </AppButton>
        </form>
      ) : null}

      {step === "password" ? (
        <form onSubmit={onPassword} className="space-y-3.5">
          <AppField
            label="Придумайте пароль"
            hint="Минимум 8 символов"
            type="password"
            autoComplete="new-password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={loading}
          />
          <AppButton type="submit" loading={loading}>
            Создать аккаунт
          </AppButton>
        </form>
      ) : null}

      <p className="text-center text-sm text-on-media/55">
        Уже есть аккаунт?{" "}
        <Link href="/auth" className="font-bold text-brand">
          Войти
        </Link>
      </p>
    </div>
  );
}
