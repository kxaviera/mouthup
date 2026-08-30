/** API base URL — env at build time, or derived from admin.* hostname at runtime. */
export function getApiUrl(): string {
  const fromEnv = process.env.NEXT_PUBLIC_API_URL?.trim();
  if (fromEnv) return fromEnv.replace(/\/$/, '');

  if (typeof window !== 'undefined') {
    const { protocol, hostname } = window.location;
    if (hostname.startsWith('admin.')) {
      return `${protocol}//api.${hostname.slice('admin.'.length)}/api/v1`;
    }
  }

  if (process.env.NODE_ENV !== 'production') {
    return 'http://localhost:3000/api/v1';
  }

  return '';
}

export function getSocketBaseUrl(): string {
  return getApiUrl().replace(/\/api\/v1\/?$/, '');
}
