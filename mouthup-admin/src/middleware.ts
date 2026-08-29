import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const NO_CACHE_PATHS = ['/posts', '/dashboard', '/users', '/reports'];

export function middleware(request: NextRequest) {
  const path = request.nextUrl.pathname;
  const shouldDisableCache = NO_CACHE_PATHS.some(
    (prefix) => path === prefix || path.startsWith(`${prefix}/`),
  );

  if (!shouldDisableCache) {
    return NextResponse.next();
  }

  const response = NextResponse.next();
  response.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate');
  response.headers.set('Pragma', 'no-cache');
  response.headers.set('Expires', '0');
  return response;
}

export const config = {
  matcher: ['/posts/:path*', '/dashboard/:path*', '/users/:path*', '/reports/:path*'],
};
