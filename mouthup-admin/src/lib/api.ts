import { getApiUrl } from './api-url';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

function getRefreshToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('mouthup_admin_refresh');
}

export function getStoredToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('mouthup_admin_token');
}

function storeTokens(accessToken: string, refreshToken: string) {
  localStorage.setItem('mouthup_admin_token', accessToken);
  localStorage.setItem('mouthup_admin_refresh', refreshToken);
}

async function refreshAccessToken(): Promise<string | null> {
  const refresh = getRefreshToken();
  const apiUrl = getApiUrl();
  if (!refresh || !apiUrl) return null;
  try {
    const res = await fetch(`${apiUrl}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken: refresh }),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as AuthTokens;
    storeTokens(data.accessToken, data.refreshToken);
    return data.accessToken;
  } catch {
    return null;
  }
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {},
  retried = false,
): Promise<T> {
  const apiUrl = getApiUrl();
  if (!apiUrl) {
    throw new Error('NEXT_PUBLIC_API_URL is not configured');
  }

  const token = getStoredToken();
  let res: Response;
  try {
    res = await fetch(`${apiUrl}${path}`, {
      ...options,
      cache: 'no-store',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });
  } catch {
    throw new Error(`Cannot reach API at ${apiUrl}`);
  }

  if (res.status === 401 && !retried && path !== '/auth/login') {
    const newToken = await refreshAccessToken();
    if (newToken) return apiFetch(path, options, true);
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ message: res.statusText }));
    const msg = Array.isArray(err.message) ? err.message.join(', ') : err.message;
    throw new Error(msg ?? 'Request failed');
  }

  return res.json() as Promise<T>;
}

export async function login(email: string, password: string) {
  const res = await apiFetch<AuthTokens & { user: { role: string } }>('/auth/login', {
    method: 'POST',
    body: JSON.stringify({ login: email, password }),
  });
  storeTokens(res.accessToken, res.refreshToken);
  return res;
}

export async function getDashboard() {
  return apiFetch<{
    users: number;
    posts: number;
    listings: number;
    pendingReports: number;
    messages: number;
    verifiedUsers: number;
  }>('/admin/dashboard');
}

export async function getReports() {
  return apiFetch<
    {
      id: string;
      reason: string;
      targetType: string;
      createdAt: string;
      reporter: { username: string | null; email: string };
      targetPost?: { content: string; author: { username: string | null } };
      targetComment?: { content: string; author: { username: string | null } };
      targetUser?: { username: string | null; email: string };
    }[]
  >('/admin/reports');
}

export async function resolveReport(id: string, status: 'RESOLVED' | 'DISMISSED', adminNote?: string) {
  return apiFetch(`/admin/reports/${id}`, {
    method: 'PATCH',
    body: JSON.stringify({ status, adminNote }),
  });
}

export async function searchUsers(q: string) {
  return apiFetch<
    {
      id: string;
      email: string;
      username: string | null;
      screenName: string | null;
      bannedAt: string | null;
      banReason: string | null;
      createdAt: string;
      signupIp: string | null;
      signupCountry: string | null;
      signupRegion: string | null;
      signupCity: string | null;
      authProvider: string | null;
      isVerified: boolean;
      city: string | null;
      accountType: string | null;
      profession: string | null;
    }[]
  >(`/admin/users?q=${encodeURIComponent(q)}`);
}

export async function verifyUser(id: string) {
  return apiFetch<{ id: string; username: string | null; isVerified: boolean }>(`/admin/users/${id}/verify`, {
    method: 'PATCH',
  });
}

export async function unverifyUser(id: string) {
  return apiFetch<{ id: string; username: string | null; isVerified: boolean }>(`/admin/users/${id}/unverify`, {
    method: 'PATCH',
  });
}

export async function banUser(id: string, reason: string) {
  return apiFetch(`/admin/users/${id}/ban`, {
    method: 'PATCH',
    body: JSON.stringify({ reason }),
  });
}

export async function unbanUser(id: string) {
  return apiFetch(`/admin/users/${id}/unban`, { method: 'PATCH' });
}

export async function searchPosts(q: string, limit = 100) {
  return apiFetch<
    {
      id: string;
      title: string | null;
      content: string;
      listingType: string | null;
      listingStatus: string;
      price: string | null;
      currency: string;
      rentPeriod: string | null;
      swapFor: string | null;
      requestedProfession: string | null;
      location: string | null;
      viewCount: number;
      createdAt: string;
      author: { username: string | null; email: string; isBot: boolean; city: string | null };
      media: { type: string; url: string }[];
    }[]
  >(`/admin/posts?q=${encodeURIComponent(q)}&limit=${limit}`);
}

export async function deletePost(id: string) {
  return apiFetch(`/admin/posts/${id}`, { method: 'DELETE' });
}
