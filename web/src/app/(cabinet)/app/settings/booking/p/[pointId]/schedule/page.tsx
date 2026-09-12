import { redirect } from "next/navigation";

type Props = { params: Promise<{ pointId: string }> };

/** Старый URL → настройки / расписание. */
export default async function BookingPointScheduleRedirect({ params }: Props) {
  const { pointId } = await params;
  redirect(`/app/settings/booking/p/${pointId}/settings/schedule`);
}
