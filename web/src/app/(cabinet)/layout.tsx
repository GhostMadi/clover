import { CabinetShell } from "@/features/cabinet/components/cabinet-shell";

export default function CabinetLayout({ children }: { children: React.ReactNode }) {
  return <CabinetShell>{children}</CabinetShell>;
}
