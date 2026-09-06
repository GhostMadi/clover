/** Подписи страны/города на клиенте — как enum в мобилке (`profile-data.md`). */

const COUNTRIES: Record<string, string> = {
  kz: "Казахстан",
  ru: "Россия",
};

const CITIES: Record<string, Record<string, string>> = {
  kz: {
    almaty: "Алматы",
    astana: "Астана",
    shymkent: "Шымкент",
  },
  ru: {
    kazan: "Казань",
    moscow: "Москва",
    saintpetersburg: "Санкт-Петербург",
  },
};

export function locationLine(countryCode?: string | null, cityCode?: string | null): string {
  const cc = countryCode?.trim().toLowerCase() ?? "";
  const cityRaw = cityCode?.trim() ?? "";
  const cityKey = cityRaw.toLowerCase();
  const country = cc ? COUNTRIES[cc] : undefined;
  const city = cc && cityKey ? CITIES[cc]?.[cityKey] ?? cityRaw : undefined;

  if (city && country) return `${country}, ${city}`;
  if (city) return city;
  if (country) return country;
  return "";
}
