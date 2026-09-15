import { CabinetShell } from "@/features/cabinet/components/cabinet-shell";
import { WebPushBootstrap } from "@/features/push/components/web-push-bootstrap";

export default function CabinetLayout({ children }: { children: React.ReactNode }) {
  return (
    <CabinetShell>
      <WebPushBootstrap />
      {children}
    </CabinetShell>
  );
}
