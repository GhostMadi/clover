"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { VenuePlanEditorView } from "@/features/venue/components/venue-plan-editor-view";
import {
  getSpacePlan,
  touchSpacePlan,
  type SpacePlanMeta,
} from "@/features/resources/lib/space-plans-mock";

const LIST_HREF = "/app/settings/resources/space-plans";

/** Редактор схемы из Ресурсов (тот же canvas, что у Брони). */
export function SpacePlanEditorPage({ planId }: { planId: string }) {
  const [meta, setMeta] = useState<SpacePlanMeta | null | undefined>(undefined);

  useEffect(() => {
    const found = getSpacePlan(planId);
    setMeta(found);
    if (found) touchSpacePlan(planId);
  }, [planId]);

  if (meta === undefined) {
    return <div className="fixed inset-0 z-[80] bg-bg" />;
  }

  if (!meta) {
    return (
      <div className="flex min-h-[50vh] flex-col items-center justify-center gap-3 px-4">
        <p className="text-[15px] font-semibold text-ink">Схема не найдена</p>
        <Link href={LIST_HREF} className="text-[13px] font-bold text-svc-resources-ink underline">
          К списку схем
        </Link>
      </div>
    );
  }

  return (
    <VenuePlanEditorView venueId={planId} venueName={meta.title} backHref={LIST_HREF} />
  );
}
