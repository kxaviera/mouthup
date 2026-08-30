const API_URL =
  process.env.NEXT_PUBLIC_API_URL ??
  (process.env.NODE_ENV === 'production' ? '' : 'http://localhost:3000/api/v1');

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
  if (!refresh || !API_URL) return null;
  try {
    const res = await fetch(`${API_URL}/auth/refresh`, {
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
  if (!API_URL) {
    throw new Error('NEXT_PUBLIC_API_URL is not configured');
  }

  const token = getStoredToken();
  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}`, {
      ...options,
      cache: 'no-store',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
      },
    });
  } catch {
    throw new Error(`Cannot reach API at ${API_URL}`);
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
  return apiFetch<{ users: number; posts: number; pendingReports: number; messages: number; verifiedUsers: number }>(
    '/admin/dashboard',
  );
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
      content: string;
      createdAt: string;
      author: { username: string | null; email: string; isBot: boolean };
      media: { type: string; url: string }[];
    }[]
  >(`/admin/posts?q=${encodeURIComponent(q)}&limit=${limit}`);
}

export async function deletePost(id: string) {
  return apiFetch(`/admin/posts/${id}`, { method: 'DELETE' });
}
