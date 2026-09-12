import { NextResponse } from "next/server";
import { isAdminRegisterAllowed } from "@/lib/admin-auth";

/**
 * Назначение админа через UI выключено.
 * Флаг только SQL: update profiles set is_site_admin = true where email = '…'
 */
export async function POST() {
  if (!isAdminRegisterAllowed()) {
    return NextResponse.json(
      {
        error:
          "Назначение админа через UI выключено. В SQL: update profiles set is_site_admin = true where email = '…'",
      },
      { status: 403 },
    );
  }
  return NextResponse.json({ error: "disabled" }, { status: 403 });
}
