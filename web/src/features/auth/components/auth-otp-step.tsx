"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { AppField } from "@/components/shared/app-field";
import {
  AuthOtpRateLimitError,
  emailOtpRetryAfterSeconds,
} from "@/features/auth/lib/auth-api";
import { AUTH_MESSAGES } from "@/features/auth/lib/messages";

type Props = {
  email: string;
  otp: string;
  onOtpChange: (value: string) => void;
  loading: boolean;
  onVerify: (e: FormEvent) => void;
  onResend: () => Promise<void>;
};

function formatCooldown(total: number) {
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export function AuthOtpStep({
  email,
  otp,
  onOtpChange,
  loading,
  onVerify,
  onResend,
}: Props) {
  const [secondsLeft, setSecondsLeft] = useState(0);
  const [bootstrapping, setBootstrapping] = useState(true);
  const [resending, setResending] = useState(false);
  const [localError, setLocalError] = useState("");

  const startCooldown = useCallback((sec: number) => {
    setSecondsLeft(Math.max(0, Math.ceil(sec)));
  }, []);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      const left = await emailOtpRetryAfterSeconds(email);
      if (cancelled) return;
      startCooldown(left);
      setBootstrapping(false);
    })();
    return () => {
      cancelled = true;
    };
  }, [email, startCooldown]);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const id = window.setInterval(() => {
      setSecondsLeft((v) => (v <= 1 ? 0 : v - 1));
    }, 1000);
    return () => window.clearInterval(id);
  }, [secondsLeft > 0]); // eslint-disable-line react-hooks/exhaustive-deps -- tick while cooling

  async function handleResend() {
    if (loading || resending || bootstrapping || secondsLeft > 0) return;
    setLocalError("");
    setResending(true);
    try {
      await onResend();
      const left = await emailOtpRetryAfterSeconds(email);
      startCooldown(left > 0 ? left : 0);
    } catch (err) {
      if (err instanceof AuthOtpRateLimitError) {
        startCooldown(err.retryAfterSeconds);
        setLocalError(err.message);
      } else {
        setLocalError(err instanceof Error ? err.message : AUTH_MESSAGES.generic);
      }
    } finally {
      setResending(false);
    }
  }

  const cooling = bootstrapping || secondsLeft > 0;
  const busy = loading || resending;

  return (
    <form onSubmit={onVerify} className="space-y-3.5">
      <p className="text-sm text-on-media/70">
        Код отправлен на <span className="font-semibold text-on-media">{email}</span>
        <br />
        <span className="text-on-media/55">Письмо с welcome@clover.com.kz</span>
      </p>
      {localError ? (
        <p className="rounded-[14px] border border-destructive/30 bg-destructive/10 px-3 py-2 text-sm text-error">
          {localError}
        </p>
      ) : null}
      <AppField
        label="Код из письма"
        hint="6 цифр"
        inputMode="numeric"
        value={otp}
        onChange={(e) => onOtpChange(e.target.value)}
        disabled={busy}
      />
      <AppButton type="submit" loading={loading}>
        Подтвердить
      </AppButton>
      <AppButton
        type="button"
        variant="outline"
        disabled={busy || cooling}
        loading={resending}
        onClick={() => void handleResend()}
      >
        {cooling && secondsLeft > 0
          ? `Повтор через ${formatCooldown(secondsLeft)}`
          : "Отправить код ещё раз"}
      </AppButton>
    </form>
  );
}
