import type { Metadata } from "next";
import { HonestQuizGame } from "@/features/honest-quiz/components/honest-quiz-game";

export const metadata: Metadata = {
  title: "Для тебя",
  robots: { index: false, follow: false },
};

export default function HonestQuizPage() {
  return (
    <main className="min-h-dvh bg-bg text-ink antialiased">
      <HonestQuizGame />
    </main>
  );
}
