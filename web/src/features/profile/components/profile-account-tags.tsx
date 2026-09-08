import {
  isServicePowerGroup,
  tagByKey,
  tagLabelRu,
  tagServiceKind,
} from "@/features/catalog/lib/marker-tags";
import { SERVICE_ACCENT } from "@/lib/service-accent";

type Props = {
  tagKeys: string[];
  /** Силовые admin/worker — только на своём профиле. */
  showServicePowerTags?: boolean;
};

/**
 * Чипы account-тегов в шапке профиля (паритет с Flutter MarkerTagChip).
 * На чужом профиле силовые теги скрыты.
 */
export function ProfileAccountTags({
  tagKeys,
  showServicePowerTags = true,
}: Props) {
  const chips = tagKeys
    .map((key) => {
      const def = tagByKey(key);
      if (!def) return null;
      if (!showServicePowerTags && isServicePowerGroup(def.group)) return null;
      return def;
    })
    .filter((t): t is NonNullable<typeof t> => t != null);

  if (chips.length === 0) return null;

  return (
    <div className="mt-3 flex max-w-2xl flex-wrap gap-1.5 sm:mt-4">
      {chips.map((tag) => {
        const service = tagServiceKind(tag.key);
        const accent = service ? SERVICE_ACCENT[service] : null;
        const label = `#${tagLabelRu(tag.key).toLowerCase()}`;
        return (
          <span
            key={tag.key}
            className={
              accent
                ? `inline-flex rounded-lg border px-2.5 py-1 text-[11px] font-bold ${accent.soft} ${accent.icon} ${accent.border}`
                : "inline-flex rounded-lg bg-brand/10 px-2.5 py-1 text-[11px] font-bold text-brand"
            }
          >
            {label}
          </span>
        );
      })}
    </div>
  );
}
