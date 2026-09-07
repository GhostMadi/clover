"use client";

import { useEffect, useState } from "react";
import { EVENT_FILTER_EMOJIS } from "@/features/catalog/lib/event-emojis";

const ALLOWED = new Set<string>(EVENT_FILTER_EMOJIS);

function firstGrapheme(value: string): string {
  if (typeof Intl !== "undefined" && "Segmenter" in Intl) {
    return [...new Intl.Segmenter(undefined, { granularity: "grapheme" }).segment(value)][0]
      ?.segment ?? "";
  }
  return Array.from(value)[0] ?? "";
}

function normalizeAllowedEmoji(raw: string): string | null {
  const g = firstGrapheme(raw.trim());
  if (!g) return null;
  return ALLOWED.has(g) ? g : null;
}

type EventEmojiFieldProps = {
  value: string | null;
  onChange: (emoji: string | null) => void;
};

/** Поле эмодзи + лента: значение только из списка (как AppSmilePicker). */
export function EventEmojiField({ value, onChange }: EventEmojiFieldProps) {
  const [text, setText] = useState(value ?? "");

  useEffect(() => {
    setText(value ?? "");
  }, [value]);

  const commit = (next: string) => {
    const allowed = normalizeAllowedEmoji(next);
    setText(allowed ?? "");
    onChange(allowed);
  };

  return (
    <div>
      <p className="mb-2 text-[13px] font-semibold text-muted">Эмодзи ивента</p>
      <input
        type="text"
        inputMode="text"
        autoComplete="off"
        spellCheck={false}
        placeholder="Любое — оставьте пустым"
        value={text}
        onChange={(e) => {
          const raw = e.target.value;
          if (!raw.trim()) {
            setText("");
            onChange(null);
            return;
          }
          const g = firstGrapheme(raw);
          // Пока вводят — показываем только первый символ; принимаем, если он в списке
          setText(g);
          onChange(ALLOWED.has(g) ? g : null);
        }}
        onBlur={() => commit(text)}
        className="h-11 w-full rounded-[12px] border border-line bg-surface px-3.5 text-[16px] font-semibold text-ink outline-none placeholder:font-normal placeholder:text-muted focus:border-brand/40"
        aria-label="Эмодзи ивента"
      />
      <p className="mt-1.5 text-[12px] text-muted">Выберите из ленты или введите эмодзи из списка</p>
      <div className="-mx-0.5 mt-2.5 flex gap-2 overflow-x-auto pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
        {EVENT_FILTER_EMOJIS.map((emoji) => {
          const selected = value === emoji;
          return (
            <button
              key={emoji}
              type="button"
              onClick={() => commit(selected ? "" : emoji)}
              className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-[14px] text-[22px] transition ${
                selected
                  ? "bg-mint ring-1 ring-brand/30"
                  : "bg-[color-mix(in_srgb,var(--bg)_75%,white)] hover:bg-mint/60"
              }`}
              aria-pressed={selected}
            >
              {emoji}
            </button>
          );
        })}
      </div>
    </div>
  );
}
