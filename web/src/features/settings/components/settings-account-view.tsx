"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState, useTransition } from "react";
import { AppButton } from "@/components/shared/app-button";
import { signOut } from "@/features/auth/lib/auth-api";
import {
  deleteAccount,
  hibernateAccount,
  listMyLoginEvents,
  type LoginEvent,
} from "@/features/settings/lib/account-api";
import {
  readLocale,
  readTheme,
  WEB_LOCALE_OPTIONS,
  writeLocale,
  writeTheme,
  type WebLocaleCode,
  type WebThemeMode,
} from "@/features/settings/lib/prefs";
import { SettingsShell } from "@/features/settings/components/settings-shell";

function Segmented<T extends string>({
  value,
  options,
  onChange,
}: {
  value: T;
  options: { value: T; label: string }[];
  onChange: (v: T) => void;
}) {
  return (
    <div
      className="grid gap-1 rounded-[14px] bg-bg p-1"
      style={{ gridTemplateColumns: `repeat(${options.length}, minmax(0, 1fr))` }}
    >
      {options.map((o) => {
        const on = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            className={`rounded-[12px] py-2.5 text-[13px] font-bold transition ${
              on ? "bg-surface text-ink shadow-sm" : "text-muted hover:text-ink"
            }`}
          >
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

export function SettingsAccountView() {
  const router = useRouter();
  const [theme, setTheme] = useState<WebThemeMode>("light");
  const [locale, setLocale] = useState<WebLocaleCode>("ru");
  const [confirmHibernate, setConfirmHibernate] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [loggingOut, setLoggingOut] = useState(false);
  const [hibernating, startHibernate] = useTransition();
  const [deleting, startDelete] = useTransition();
  const [logins, setLogins] = useState<LoginEvent[]>([]);

  useEffect(() => {
    setTheme(readTheme());
    setLocale(readLocale());
    void listMyLoginEvents(8)
      .then(setLogins)
      .catch(() => setLogins([]));
  }, []);

  const sessionBusy = loggingOut || hibernating || deleting;

  const onTheme = (mode: WebThemeMode) => {
    setTheme(mode);
    writeTheme(mode);
  };

  const onLocale = (code: WebLocaleCode) => {
    setLocale(code);
    writeLocale(code);
  };

  const onLogout = async () => {
    setLoggingOut(true);
    setError(null);
    try {
      await signOut();
      router.replace("/auth");
      router.refresh();
    } catch {
      setError("Не удалось выйти");
      setLoggingOut(false);
    }
  };

  const onHibernate = () => {
    setError(null);
    startHibernate(async () => {
      try {
        await hibernateAccount();
        router.replace("/auth");
        router.refresh();
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось усыпить аккаунт");
        setConfirmHibernate(false);
      }
    });
  };

  const onDelete = () => {
    setError(null);
    startDelete(async () => {
      try {
        await deleteAccount();
        router.replace("/auth");
        router.refresh();
      } catch (e: unknown) {
        setError(e instanceof Error ? e.message : "Не удалось удалить аккаунт");
        setConfirmDelete(false);
      }
    });
  };

  return (
    <SettingsShell title="Аккаунт">
      <div className="space-y-6 px-4 py-5 pb-10">
        {error ? (
          <p className="rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}

        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Оформление
          </p>
          <div className="space-y-4 rounded-[16px] border border-line px-3.5 py-4">
            <div>
              <p className="mb-2 text-[14px] font-semibold text-ink">Тема</p>
              <Segmented
                value={theme}
                onChange={onTheme}
                options={[
                  { value: "light", label: "Белая" },
                  { value: "dark", label: "Чёрная" },
                ]}
              />
            </div>
            <div>
              <p className="mb-2 text-[14px] font-semibold text-ink">Язык</p>
              <Segmented
                value={locale}
                onChange={onLocale}
                options={WEB_LOCALE_OPTIONS.map((o) => ({
                  value: o.code,
                  label: o.label,
                }))}
              />
              <p className="mt-2 text-[11px] leading-snug text-muted">
                Сохраняется на этом устройстве. Полный перевод интерфейса — позже.
              </p>
            </div>
          </div>
        </section>

        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Недавние входы
          </p>
          <div className="rounded-[16px] border border-line px-3.5 py-3">
            {logins.length === 0 ? (
              <p className="py-2 text-[13px] text-muted">Пока нет записей</p>
            ) : (
              <ul className="divide-y divide-line">
                {logins.map((e) => {
                  const where =
                    e.deviceLabel ||
                    (e.client === "web"
                      ? "Веб"
                      : e.platform === "ios"
                        ? "iOS"
                        : e.platform === "android"
                          ? "Android"
                          : e.client);
                  const when = e.createdAt
                    ? new Date(e.createdAt).toLocaleString("ru-RU", {
                        day: "numeric",
                        month: "short",
                        hour: "2-digit",
                        minute: "2-digit",
                      })
                    : "";
                  return (
                    <li key={e.id} className="flex items-center justify-between gap-3 py-2.5">
                      <span className="min-w-0 truncate text-[13px] font-semibold text-ink">
                        {where}
                        <span className="ml-2 text-[11px] font-medium text-muted">
                          {e.role === "primary" ? "главный" : "гость"}
                          {e.status === "revoked"
                            ? " · прерван"
                            : e.status === "confirmed"
                              ? " · ок"
                              : ""}
                        </span>
                      </span>
                      <span className="shrink-0 text-[11px] text-muted">{when}</span>
                    </li>
                  );
                })}
              </ul>
            )}
            <p className="mt-2 text-[11px] leading-snug text-muted">
              Первый вход — главный. Остальные устройства — гости: в колокольчике можно
              подтвердить («это я»), прервать сессию или сменить пароль.
            </p>
          </div>
        </section>

        <section>
          <p className="mb-2 px-1 text-[12px] font-bold uppercase tracking-wide text-muted">
            Сессия
          </p>
          <div className="space-y-3">
            <AppButton
              type="button"
              loading={loggingOut}
              disabled={sessionBusy}
              variant="outline"
              onClick={() => void onLogout()}
            >
              Выйти из аккаунта
            </AppButton>
            <AppButton
              type="button"
              disabled={sessionBusy}
              variant="outline"
              className="!border-destructive/40 !text-destructive hover:!bg-destructive/10"
              onClick={() => setConfirmHibernate(true)}
            >
              Усыпить аккаунт
            </AppButton>
            <AppButton
              type="button"
              disabled={sessionBusy}
              variant="outline"
              className="!border-destructive/40 !text-destructive hover:!bg-destructive/10"
              onClick={() => setConfirmDelete(true)}
            >
              Деактивировать аккаунт
            </AppButton>
            <p className="px-1 text-[11px] leading-snug text-muted">
              Сон и деактивация скрывают профиль из лент — данные не стираются каскадом.
              При следующем входе аккаунт просыпается. Безвозвратное удаление данных —
              через поддержку на /delete-account.
            </p>
          </div>
        </section>
      </div>

      {confirmHibernate ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 p-4 sm:items-center">
          <div
            role="dialog"
            aria-modal
            className="w-full max-w-sm rounded-[20px] border border-line bg-surface p-5 shadow-xl"
          >
            <p className="text-[16px] font-bold text-ink">Усыпить аккаунт?</p>
            <p className="mt-2 text-[13px] leading-relaxed text-muted">
              Профиль и публикации временно скроются из лент и поиска. Данные не удаляются —
              при следующем входе аккаунт проснётся. Повторный сон — не чаще раза в 30 дней.
            </p>
            <div className="mt-5 flex gap-2">
              <AppButton
                type="button"
                disabled={hibernating}
                variant="outline"
                onClick={() => setConfirmHibernate(false)}
              >
                Отмена
              </AppButton>
              <AppButton
                type="button"
                loading={hibernating}
                className="!bg-destructive !text-on-media hover:!bg-destructive/90"
                onClick={onHibernate}
              >
                Усыпить
              </AppButton>
            </div>
          </div>
        </div>
      ) : null}

      {confirmDelete ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 p-4 sm:items-center">
          <div
            role="dialog"
            aria-modal
            className="w-full max-w-sm rounded-[20px] border border-line bg-surface p-5 shadow-xl"
          >
            <p className="text-[16px] font-bold text-ink">Деактивировать аккаунт?</p>
            <p className="mt-2 text-[13px] leading-relaxed text-muted">
              Профиль и публикации скроются из лент, как при сне. Это не безвозвратное
              удаление — при следующем входе аккаунт снова активен. Чтобы навсегда удалить
              данные, напишите в поддержку на /delete-account.
            </p>
            <div className="mt-5 flex gap-2">
              <AppButton
                type="button"
                disabled={deleting}
                variant="outline"
                onClick={() => setConfirmDelete(false)}
              >
                Отмена
              </AppButton>
              <AppButton
                type="button"
                loading={deleting}
                className="!bg-destructive !text-on-media hover:!bg-destructive/90"
                onClick={onDelete}
              >
                Деактивировать
              </AppButton>
            </div>
          </div>
        </div>
      ) : null}
    </SettingsShell>
  );
}
