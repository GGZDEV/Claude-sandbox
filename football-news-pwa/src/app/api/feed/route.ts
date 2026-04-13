import { NextRequest } from "next/server";
import Parser from "rss-parser";
import { sources } from "@/lib/sources";
import { Article, Source } from "@/lib/types";

const parser = new Parser({
  timeout: 10000,
  headers: {
    "User-Agent": "FootballNewsPWA/1.0",
  },
});

async function fetchFeed(source: Source): Promise<Article[]> {
  if (!source.feedUrl) return [];

  try {
    const feed = await parser.parseURL(source.feedUrl);
    return (feed.items || []).slice(0, 10).map((item, index) => ({
      id: `${source.id}-${index}-${Date.now()}`,
      title: item.title || "Sans titre",
      link: item.link || source.url,
      description: item.contentSnippet || item.content || "",
      pubDate: item.pubDate || new Date().toISOString(),
      source,
      imageUrl: item.enclosure?.url,
    }));
  } catch (error) {
    console.error(`Failed to fetch feed for ${source.name}:`, error);
    return [];
  }
}

export async function GET(request: NextRequest) {
  const sourceId = request.nextUrl.searchParams.get("source");

  const targetSources = sourceId
    ? sources.filter((s) => s.id === sourceId)
    : sources.filter((s) => s.feedUrl);

  const results = await Promise.allSettled(targetSources.map(fetchFeed));

  const articles: Article[] = results
    .filter((r): r is PromiseFulfilledResult<Article[]> => r.status === "fulfilled")
    .flatMap((r) => r.value)
    .sort((a, b) => new Date(b.pubDate).getTime() - new Date(a.pubDate).getTime());

  return Response.json({ articles, count: articles.length });
}
