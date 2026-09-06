import { type InputHTMLAttributes } from "react";

/** Поле на тёмном auth-фоне (`bg-auth`): текст/бордер через `--on-media`. */
export function AppField({
  label,
  hint,
  error,
  className = "",
  ...props
}: InputHTMLAttributes<HTMLInputElement> & {
  label: string;
  hint?: string;
  error?: string;
}) {
  return (
    <label className={`block ${className}`}>
      <span className="mb-2 block text-sm font-semibold text-on-media/75">{label}</span>
      <input
        className="h-[52px] w-full rounded-[14px] border border-on-media/12 bg-on-media/[0.06] px-4 text-[15px] text-on-media outline-none transition placeholder:text-on-media/35 focus:border-brand focus:shadow-[var(--focus-ring-brand)] disabled:opacity-50"
        placeholder={hint}
        {...props}
      />
      {error ? <span className="mt-1.5 block text-xs text-error">{error}</span> : null}
    </label>
  );
}
