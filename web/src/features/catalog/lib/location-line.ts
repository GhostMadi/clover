import { locationLine } from "@/features/profile/lib/location";
import { cityLabel, COUNTRY_OPTIONS } from "@/features/catalog/lib/locations";

/** Совместимость: строка локации для профиля. */
export function profileLocationLine(countryCode?: string | null, cityCode?: string | null): string {
  const city = cityLabel(countryCode, cityCode);
  const country = COUNTRY_OPTIONS.find((c) => c.code === countryCode?.trim().toLowerCase())?.label;
  if (city && country) return `${country}, ${city}`;
  if (city) return city;
  if (country) return country;
  return locationLine(countryCode, cityCode);
}
