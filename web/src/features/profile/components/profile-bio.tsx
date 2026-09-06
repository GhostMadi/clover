"use client";

import { useState } from "react";

/** Сворачиваемое био как в мобилке (порог ~90 символов). */
export function ProfileBio({ text }: { text: string }) {
  const [expanded, setExpanded] = useState(false);
  const long = text.length > 90;
  const shown = long && !expanded ? `${text.slice(0, 90)}...` : text;

  return (
    <button
      type="button"
      onClick={() => long && setExpanded((v) => !v)}
      className={`text-left text-sm leading-relaxed text-ink ${long ? "cursor-pointer" : "cursor-default"}`}
    >
      {shown}
      {long && !expanded ? <span className="font-bold text-brand"> еще</span> : null}
    </button>
  );
}
