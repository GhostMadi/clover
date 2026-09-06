/** Справочник стран/городов для фильтров — ключи EN, подписи на клиенте. */

export type CountryOption = { code: string; label: string };
export type CityOption = { code: string; label: string; countryCode: string };

export const COUNTRY_OPTIONS: CountryOption[] = [
  { code: "kz", label: "Казахстан" },
  { code: "ru", label: "Россия" },
];

export const CITY_OPTIONS: CityOption[] = [
  { code: "almaty", label: "Алматы", countryCode: "kz" },
  { code: "astana", label: "Астана", countryCode: "kz" },
  { code: "shymkent", label: "Шымкент", countryCode: "kz" },
  { code: "kazan", label: "Казань", countryCode: "ru" },
  { code: "moscow", label: "Москва", countryCode: "ru" },
  { code: "saintPetersburg", label: "Санкт-Петербург", countryCode: "ru" },
];

export function citiesForCountry(countryCode: string): CityOption[] {
  const cc = countryCode.trim().toLowerCase();
  return CITY_OPTIONS.filter((c) => c.countryCode === cc);
}

export function cityLabel(countryCode?: string | null, cityCode?: string | null): string | null {
  const cc = countryCode?.trim().toLowerCase() ?? "";
  const city = cityCode?.trim() ?? "";
  if (!cc || !city) return null;
  const hit = CITY_OPTIONS.find(
    (c) => c.countryCode === cc && c.code.toLowerCase() === city.toLowerCase(),
  );
  return hit?.label ?? city;
}

export function countryLabel(countryCode?: string | null): string | null {
  const cc = countryCode?.trim().toLowerCase() ?? "";
  if (!cc) return null;
  return COUNTRY_OPTIONS.find((c) => c.code === cc)?.label ?? cc;
}
