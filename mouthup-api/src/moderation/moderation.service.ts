import { Injectable } from '@nestjs/common';

const BLOCKED_PATTERNS = [
  /\b(porn|xxx|nude|naked|sex\s*tape|onlyfans)\b/i,
  /\b(child\s*porn|cp\b|underage)\b/i,
];

@Injectable()
export class ModerationService {
  async check(content: string): Promise<{ allowed: boolean; reason?: string }> {
    const trimmed = content.trim();
    if (!trimmed) return { allowed: false, reason: 'Content is empty' };

    for (const pattern of BLOCKED_PATTERNS) {
      if (pattern.test(trimmed)) {
        return { allowed: false, reason: 'Content violates community guidelines' };
      }
    }

    return { allowed: true };
  }
}
