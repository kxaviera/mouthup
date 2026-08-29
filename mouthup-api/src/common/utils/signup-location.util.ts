import type { Request } from 'express';
import geoip from 'geoip-lite';
import { getClientIp } from './client-ip.util';

export type SignupLocation = {
  signupIp: string | null;
  signupCountry: string | null;
  signupRegion: string | null;
  signupCity: string | null;
};

/** Captured automatically from the HTTP request — no user input. */
export function getSignupLocation(req: Request): SignupLocation {
  const ip = getClientIp(req);
  if (!ip || ip === '127.0.0.1' || ip === '::1') {
    return {
      signupIp: ip,
      signupCountry: null,
      signupRegion: null,
      signupCity: null,
    };
  }

  const geo = geoip.lookup(ip);
  return {
    signupIp: ip,
    signupCountry: geo?.country ?? null,
    signupRegion: geo?.region ?? null,
    signupCity: geo?.city ?? null,
  };
}
