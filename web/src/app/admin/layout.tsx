import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Admin · Clover",
  robots: { index: false, follow: false },
};

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-dvh bg-bg text-ink antialiased">
      {children}
    </div>
  );
}
