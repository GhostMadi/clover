import { AttendanceListShimmer } from "@/features/attendance/components/attendance-shimmers";
import { SettingsShell } from "@/features/settings/components/settings-shell";

export default function AttendanceSettingsLoading() {
  return (
    <SettingsShell title="Посещаемость" service="attendance">
      <div className="px-4 py-5">
        <AttendanceListShimmer />
      </div>
    </SettingsShell>
  );
}
