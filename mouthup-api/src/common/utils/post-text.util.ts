export function extractHashtags(text: string): string[] {
  const matches = text.match(/#[\w]{2,30}/g) ?? [];
  const tags = matches.map((t) => t.slice(1).toLowerCase());
  return [...new Set(tags)].slice(0, 10);
}

export function countWords(text: string): number {
  return text.trim().split(/\s+/).filter(Boolean).length;
}

export const MAX_POST_WORDS = 250;
