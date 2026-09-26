import { PointVisualBindView } from "@/features/booking/components/point-visual-bind-view";

type Props = { params: Promise<{ pointId: string }> };

export default async function BookingPointVisualPage({ params }: Props) {
  const { pointId } = await params;
  return <PointVisualBindView pointId={pointId} />;
}
