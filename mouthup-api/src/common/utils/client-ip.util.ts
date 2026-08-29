import type { Request } from 'express';

function normalizeIp(raw: string): string {
  const trimmed = raw.trim();
  if (trimmed.startsWith('::ffff:')) {
    return trimmed.slice(7);
  }
  return trimmed;
}

/** Best-effort client IP (works behind nginx when trust proxy is enabled). */
export function getClientIp(req: Request): string | null {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    const first = forwarded.split(',')[0]?.trim();
    if (first) return normalizeIp(first);
  }

  const realIp = req.headers['x-real-ip'];
  if (typeof realIp === 'string' && realIp.length > 0) {
    return normalizeIp(realIp);
  }

  const ip = req.ip ?? req.socket?.remoteAddress;
  if (!ip) return null;
  return normalizeIp(ip);
}
