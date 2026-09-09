"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { AppButton } from "@/components/shared/app-button";

export function AdminLogoutButton() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  return (
    <AppButton
      type="button"
      variant="outline"
      disabled={loading}
      onClick={async () => {
        setLoading(true);
        try {
          await fetch("/api/admin/logout", { method: "POST" });
          router.replace("/admin");
          router.refresh();
        } finally {
          setLoading(false);
        }
      }}
    >
      {loading ? "Выход…" : "Выйти"}
    </AppButton>
  );
}
