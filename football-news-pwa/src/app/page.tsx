import { ArticleList } from "@/components/ArticleList";
import { mockArticles } from "@/lib/mock-articles";

export default function Home() {
  return (
    <div className="min-h-screen bg-black text-zinc-100">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-zinc-800 bg-black/80 backdrop-blur-lg">
        <div className="mx-auto flex max-w-2xl items-center justify-between px-4 py-3">
          <div className="flex items-center gap-2">
            <span className="text-xl" role="img" aria-label="football">
              ⚽
            </span>
            <h1 className="text-lg font-bold tracking-tight text-white">FootballFeed</h1>
          </div>
          <span className="rounded-full border border-zinc-700 px-2 py-0.5 text-xs text-zinc-500">
            MVP
          </span>
        </div>
      </header>

      {/* Main content */}
      <main className="mx-auto max-w-2xl px-4 py-6">
        <ArticleList articles={mockArticles} />
      </main>

      {/* Footer */}
      <footer className="border-t border-zinc-800 py-6 text-center text-xs text-zinc-600">
        FootballFeed — Agrégateur anti-putaclic
      </footer>
    </div>
  );
}
