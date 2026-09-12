"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { FormEvent, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppField } from "@/components/shared/app-field";
import { AuthOtpStep } from "@/features/auth/components/auth-otp-step";
import { sendForgotOtp, updatePassword, verifyEmailOtp } from "@/features/auth/lib/auth-api";
import { AUTH_MESSAGES, MIN_PASSWORD_LENGTH } from "@/features/auth/lib/messages";

type Step = "email" | "otp" | "password";

export default function ForgotPasswordPage() {
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
      await sendForgotOtp(email);
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
        <h1 className="font-display text-2xl font-semibold text-on-media">Сброс пароля</h1>
        <p className="mt-1 text-sm text-on-media/55">
          Email → код → новый пароль (как в приложении, минимум {MIN_PASSWORD_LENGTH}).
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
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={loading}
          />
          <AppButton type="submit" loading={loading}>
            Отправить код
          </AppButton>
        </form>
      ) : null}

      {step === "otp" ? (
        <AuthOtpStep
          email={email.trim().toLowerCase()}
          otp={otp}
          onOtpChange={setOtp}
          loading={loading}
          onVerify={onOtp}
          onResend={() => sendForgotOtp(email)}
        />
      ) : null}

      {step === "password" ? (
        <form onSubmit={onPassword} className="space-y-3.5">
          <AppField
            label="Новый пароль"
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            disabled={loading}
          />
          <AppButton type="submit" loading={loading}>
            Сохранить и войти
          </AppButton>
        </form>
      ) : null}

      <p className="text-center text-sm text-on-media/55">
        <Link href="/auth" className="font-bold text-brand">
          Назад ко входу
        </Link>
      </p>
    </div>
  );
}
