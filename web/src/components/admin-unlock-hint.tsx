"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";

const UNLOCK_TAPS = 15;

/** 15 тапов по «© …» → /admin (см. docs/business/website-admin.md). */
export function AdminUnlockHint({ label }: { label: string }) {
  const router = useRouter();
  const [taps, setTaps] = useState(0);

  return (
    <button
      type="button"
      className="cursor-default select-none text-left text-[12px] text-muted"
      aria-label={label}
      onClick={() => {
        const next = taps + 1;
        if (next >= UNLOCK_TAPS) {
          setTaps(0);
          try {
            sessionStorage.setItem("clover_admin_gate", "1");
          } catch {
            /* ignore */
          }
          router.push("/admin");
          return;
        }
        setTaps(next);
      }}
    >
      {label}
    </button>
  );
}
