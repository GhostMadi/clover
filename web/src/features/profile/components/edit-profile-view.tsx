"use client";

import {
  ArrowLeft,
  Camera,
  Check,
  ImagePlus,
  User,
} from "lucide-react";
import { useRouter } from "next/navigation";
import { useMemo, useRef, useState } from "react";
import {
  citiesForCountry,
  COUNTRY_OPTIONS,
} from "@/features/catalog/lib/locations";
import {
  MARKER_TAG_GROUPS,
  MARKER_TAGS,
  tagLabelRu,
  tagServiceKind,
} from "@/features/catalog/lib/marker-tags";
import {
  saveProfileEdit,
  saveUsername,
} from "@/features/profile/lib/edit-profile-api";
import {
  usernamePolicy,
  type Profile,
} from "@/features/profile/lib/profile-model";
import { SERVICE_ACCENT } from "@/lib/service-accent";

type EditProfileViewProps = {
  profile: Profile;
};

/** Экран редактирования профиля — как мобилка: правишь → сохраняешь → назад. */
export function EditProfileView({ profile }: EditProfileViewProps) {
  const router = useRouter();
  const [fullName, setFullName] = useState(profile.fullName ?? "");
  const [bio, setBio] = useState(profile.bio ?? "");
  const [username, setUsername] = useState(profile.username ?? "");
  const [countryCode, setCountryCode] = useState(profile.countryCode ?? "kz");
  const [cityCode, setCityCode] = useState(profile.cityCode ?? "");
  const [tagKeys, setTagKeys] = useState<Set<string>>(() => new Set(profile.tagKeys));
  const [avatarUrl, setAvatarUrl] = useState(profile.avatarUrl);
  const [coverUrl, setCoverUrl] = useState(profile.backgroundUrl);
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [coverFile, setCoverFile] = useState<File | null>(null);
  const [saving, setSaving] = useState(false);
  const [savingNick, setSavingNick] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [nickOpen, setNickOpen] = useState(false);
  const [nickDraft, setNickDraft] = useState(profile.username ?? "");
  const avatarInputRef = useRef<HTMLInputElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);

  const cities = useMemo(() => citiesForCountry(countryCode), [countryCode]);
  const policy = usernamePolicy({
    ...profile,
    username,
  });

  const showToast = (msg: string) => {
    setToast(msg);
    window.setTimeout(() => setToast(null), 2600);
  };

  const onCountry = (code: string) => {
    setCountryCode(code);
    const list = citiesForCountry(code);
    const keep = list.some((c) => c.code.toLowerCase() === cityCode.toLowerCase());
    if (!keep) setCityCode(list[0]?.code ?? "");
  };

  const toggleTag = (key: string) => {
    setTagKeys((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });
  };

  const onPickAvatar = (file: File | null) => {
    if (!file) return;
    if (avatarUrl?.startsWith("blob:")) URL.revokeObjectURL(avatarUrl);
    setAvatarFile(file);
    setAvatarUrl(URL.createObjectURL(file));
  };

  const onPickCover = (file: File | null) => {
    if (!file) return;
    if (coverUrl?.startsWith("blob:")) URL.revokeObjectURL(coverUrl);
    setCoverFile(file);
    setCoverUrl(URL.createObjectURL(file));
  };

  const onSave = () => {
    if (saving) return;
    setSaving(true);
    setError(null);
    void saveProfileEdit({
      fullName,
      bio,
      countryCode,
      cityCode: cityCode || null,
      tagKeys: [...tagKeys],
      avatarFile,
      backgroundFile: coverFile,
    })
      .then(() => {
        showToast("Профиль сохранён");
        router.push("/app/profile");
        router.refresh();
      })
      .catch((e: unknown) => {
        setError(e instanceof Error ? e.message : "Не удалось сохранить");
        setSaving(false);
      });
  };

  const onSaveNick = () => {
    if (savingNick || !policy.canChange) return;
    setSavingNick(true);
    setError(null);
    void saveUsername(nickDraft)
      .then(() => {
        const next = nickDraft.trim().replace(/^@/, "");
        setUsername(next);
        setNickOpen(false);
        showToast("Никнейм сохранён");
        router.refresh();
      })
      .catch((e: unknown) => {
        setError(e instanceof Error ? e.message : "Не удалось сменить ник");
      })
      .finally(() => setSavingNick(false));
  };

  return (
    <div className="min-h-[calc(100dvh-3rem-4.25rem)] bg-surface md:min-h-dvh">
      <div className="mx-auto w-full max-w-[640px]">
        <header className="sticky top-0 z-10 flex h-12 items-center gap-2 border-b border-line bg-surface/95 px-2 backdrop-blur-md">
          <button
            type="button"
            onClick={() => router.push("/app/profile")}
            className="flex h-10 w-10 items-center justify-center rounded-full text-ink hover:bg-bg"
            aria-label="Назад"
          >
            <ArrowLeft className="h-5 w-5" strokeWidth={2} />
          </button>
          <h1 className="min-w-0 flex-1 truncate text-[16px] font-bold text-ink">
            Редактировать профиль
          </h1>
          <button
            type="button"
            onClick={onSave}
            disabled={saving}
            className="mr-1 flex h-10 w-10 items-center justify-center rounded-full bg-brand text-on-brand transition hover:opacity-90 disabled:opacity-50"
            aria-label="Сохранить"
            title="Сохранить"
          >
            <Check className="h-5 w-5" strokeWidth={2.5} />
          </button>
        </header>

        {toast ? (
          <p className="mx-4 mt-3 rounded-[12px] bg-mint px-3 py-2 text-center text-[12px] font-semibold text-brand">
            {toast}
          </p>
        ) : null}
        {error ? (
          <p className="mx-4 mt-3 rounded-[12px] bg-destructive/10 px-3 py-2 text-center text-[12px] font-semibold text-destructive">
            {error}
          </p>
        ) : null}

        <div className="relative">
          <button
            type="button"
            onClick={() => coverInputRef.current?.click()}
            className="relative block aspect-[3/1] w-full overflow-hidden bg-mint"
          >
            {coverUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={coverUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="flex h-full w-full flex-col items-center justify-center gap-1 text-muted">
                <ImagePlus className="h-7 w-7" strokeWidth={1.75} />
                <span className="text-xs font-semibold">Сменить обложку</span>
              </span>
            )}
            <span className="absolute bottom-2 right-2 flex h-9 w-9 items-center justify-center rounded-full bg-surface/90 text-ink shadow-sm">
              <Camera className="h-4 w-4" strokeWidth={2} />
            </span>
          </button>
          <input
            ref={coverInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={(e) => {
              onPickCover(e.target.files?.[0] ?? null);
              e.target.value = "";
            }}
          />

          <button
            type="button"
            onClick={() => avatarInputRef.current?.click()}
            className="absolute -bottom-10 left-4 h-20 w-20 overflow-hidden rounded-full border-4 border-surface bg-mint shadow-sm sm:h-24 sm:w-24"
          >
            {avatarUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
            ) : (
              <span className="flex h-full w-full items-center justify-center">
                <User className="h-8 w-8 text-muted" strokeWidth={1.5} />
              </span>
            )}
            <span className="absolute inset-x-0 bottom-0 bg-ink/55 py-0.5 text-center text-[9px] font-bold text-on-media">
              Фото
            </span>
          </button>
          <input
            ref={avatarInputRef}
            type="file"
            accept="image/jpeg,image/png,image/webp"
            className="hidden"
            onChange={(e) => {
              onPickAvatar(e.target.files?.[0] ?? null);
              e.target.value = "";
            }}
          />
        </div>

        <div className="space-y-5 px-4 pb-28 pt-14 sm:px-5">
          <section className="space-y-3">
            <h2 className="text-[13px] font-bold uppercase tracking-wide text-muted">Основное</h2>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Имя</span>
              <input
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Как вас зовут"
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none focus:border-brand"
              />
            </label>

            <button
              type="button"
              onClick={() => {
                setNickDraft(username);
                setNickOpen(true);
              }}
              className="flex w-full items-center justify-between rounded-[14px] border border-line bg-bg px-4 py-3 text-left"
            >
              <div>
                <p className="text-sm font-semibold text-ink">Никнейм</p>
                <p className="mt-0.5 text-[14px] text-muted">
                  {username ? `@${username}` : "Не задан"}
                </p>
              </div>
              <span className="text-[13px] font-bold text-brand">Изменить</span>
            </button>

            <div className="rounded-[14px] border border-line bg-bg px-4 py-3">
              <p className="text-sm font-semibold text-ink">Email</p>
              <p className="mt-0.5 text-[14px] text-muted">{profile.email || "—"}</p>
            </div>

            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">О себе</span>
              <textarea
                value={bio}
                onChange={(e) => setBio(e.target.value)}
                rows={4}
                placeholder="Коротко о вас"
                className="w-full resize-none rounded-[14px] border border-line bg-bg px-4 py-3 text-[15px] text-ink outline-none focus:border-brand"
              />
            </label>
          </section>

          <section className="space-y-3">
            <h2 className="text-[13px] font-bold uppercase tracking-wide text-muted">Локация</h2>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Страна</span>
              <select
                value={countryCode}
                onChange={(e) => onCountry(e.target.value)}
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none focus:border-brand"
              >
                {COUNTRY_OPTIONS.map((c) => (
                  <option key={c.code} value={c.code}>
                    {c.label}
                  </option>
                ))}
              </select>
            </label>
            <label className="block">
              <span className="mb-1.5 block text-sm font-semibold text-ink">Город</span>
              <select
                value={cityCode}
                onChange={(e) => setCityCode(e.target.value)}
                className="h-12 w-full rounded-[14px] border border-line bg-bg px-4 text-[15px] text-ink outline-none focus:border-brand"
              >
                <option value="">Не выбран</option>
                {cities.map((c) => (
                  <option key={c.code} value={c.code}>
                    {c.label}
                  </option>
                ))}
              </select>
            </label>
          </section>

          <section className="space-y-3">
            <h2 className="text-[13px] font-bold uppercase tracking-wide text-muted">
              Теги аккаунта
            </h2>
            {MARKER_TAG_GROUPS.map((group) => {
              const tags = MARKER_TAGS.filter((t) => t.group === group.key);
              if (tags.length === 0) return null;
              return (
                <div key={group.key}>
                  <p className="mb-2 text-[13px] font-semibold text-ink">{group.label}</p>
                  <div className="flex flex-wrap gap-2">
                    {tags.map((tag) => {
                      const on = tagKeys.has(tag.key);
                      const label = tagLabelRu(tag.key);
                      const service = tagServiceKind(tag.key);
                      const accent = service ? SERVICE_ACCENT[service] : null;
                      const selectedCls = accent
                        ? `${accent.soft} ${accent.icon} ${accent.border} border`
                        : "bg-brand text-on-brand";
                      return (
                        <button
                          key={tag.key}
                          type="button"
                          onClick={() => toggleTag(tag.key)}
                          className={`rounded-full px-3 py-1.5 text-[13px] font-semibold transition ${
                            on
                              ? selectedCls
                              : "border border-line bg-bg text-ink hover:bg-mint"
                          }`}
                        >
                          {label}
                        </button>
                      );
                    })}
                  </div>
                </div>
              );
            })}
          </section>

          <button
            type="button"
            onClick={onSave}
            disabled={saving}
            className="h-12 w-full rounded-[14px] bg-brand text-[15px] font-bold text-on-brand transition hover:opacity-90 disabled:opacity-50"
          >
            {saving ? "Сохранение…" : "Сохранить"}
          </button>
        </div>
      </div>

      {nickOpen ? (
        <div className="fixed inset-0 z-50 flex items-end justify-center bg-ink/40 p-0 sm:items-center sm:p-4">
          <div className="w-full max-w-md rounded-t-[20px] bg-surface p-5 shadow-xl sm:rounded-[20px]">
            <h3 className="text-[17px] font-bold text-ink">Никнейм</h3>
            <p className="mt-1 text-[13px] text-muted">{policy.hint}</p>
            <div className="mt-4 flex items-center gap-2 rounded-[14px] border border-line bg-bg px-3">
              <span className="text-muted">@</span>
              <input
                value={nickDraft}
                onChange={(e) => setNickDraft(e.target.value.replace(/^@/, ""))}
                disabled={!policy.canChange}
                className="h-12 flex-1 bg-transparent text-[15px] text-ink outline-none disabled:opacity-50"
                placeholder="username"
                autoFocus
              />
            </div>
            <div className="mt-4 flex gap-2">
              <button
                type="button"
                onClick={() => setNickOpen(false)}
                className="h-11 flex-1 rounded-[14px] border border-line text-sm font-semibold text-ink"
              >
                Отмена
              </button>
              <button
                type="button"
                onClick={onSaveNick}
                disabled={savingNick || !policy.canChange || !nickDraft.trim()}
                className="h-11 flex-1 rounded-[14px] bg-brand text-sm font-bold text-on-brand disabled:opacity-50"
              >
                {savingNick ? "…" : "Сохранить"}
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
