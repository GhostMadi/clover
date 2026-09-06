"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { AppButton } from "@/components/shared/app-button";
import { signOut } from "@/features/auth/lib/auth-api";

export function SignOutButton() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);

  return (
    <AppButton
      variant="outline"
      className="!w-auto !min-w-[140px] !border-destructive/40 !text-destructive hover:!bg-destructive/10"
      loading={loading}
      onClick={async () => {
        setLoading(true);
        await signOut();
        router.replace("/auth");
        router.refresh();
      }}
    >
      Выйти
    </AppButton>
  );
}
