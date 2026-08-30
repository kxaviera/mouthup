'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { banUser, getStoredToken, searchUsers, unbanUser, unverifyUser, verifyUser } from '@/lib/api';

type UserRow = {
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
};

function formatLocation(u: UserRow): string {
  const parts = [u.signupCity, u.signupRegion, u.signupCountry].filter(Boolean);
  return parts.length > 0 ? parts.join(', ') : '—';
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString();
}

export default function UsersPage() {
  const router = useRouter();
  const [q, setQ] = useState('');
  const [users, setUsers] = useState<UserRow[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!getStoredToken()) router.replace('/login');
  }, [router]);

  const loadUsers = useCallback(async (query = q) => {
    try {
      setError(null);
      const res = await searchUsers(query);
      setUsers(res);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users');
    }
  }, [q]);

  useEffect(() => {
    if (getStoredToken()) {
      void loadUsers('');
    }
  }, [loadUsers]);

  async function runAction(action: () => Promise<void>) {
    try {
      setError(null);
      await action();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Action failed');
    }
  }

  async function handleBan(id: string) {
    const reason = window.prompt('Ban reason (shown internally):', 'Violated community guidelines');
    if (reason === null) return;
    const trimmed = reason.trim();
    if (!trimmed) return;
    await runAction(async () => {
      await banUser(id, trimmed);
      setUsers((prev) =>
        prev.map((u) => (u.id === id ? { ...u, bannedAt: new Date().toISOString(), banReason: trimmed } : u)),
      );
    });
  }

  async function handleUnban(id: string) {
    await runAction(async () => {
      await unbanUser(id);
      setUsers((prev) => prev.map((u) => (u.id === id ? { ...u, bannedAt: null, banReason: null } : u)));
    });
  }

  async function handleVerify(id: string) {
    await runAction(async () => {
      await verifyUser(id);
      setUsers((prev) => prev.map((u) => (u.id === id ? { ...u, isVerified: true } : u)));
    });
  }

  async function handleUnverify(id: string) {
    await runAction(async () => {
      await unverifyUser(id);
      setUsers((prev) => prev.map((u) => (u.id === id ? { ...u, isVerified: false } : u)));
    });
  }

  return (
    <AdminShell>
      <h1 className="text-2xl font-bold">Users</h1>
      <p className="mt-1 text-sm text-zinc-500">
        Ban/unban users and grant verified badges for trusted sellers & service providers.
      </p>
      <div className="mt-6 flex gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && void loadUsers()}
          placeholder="Search username, screen name, or email"
          className="flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2 outline-none focus:border-white"
        />
        <button onClick={() => void loadUsers()} className="rounded-lg bg-white px-4 py-2 text-black">
          Search
        </button>
      </div>

      {error && (
        <p className="mt-4 rounded-lg border border-red-900 bg-red-950/40 px-4 py-3 text-sm text-red-300">{error}</p>
      )}

      <div className="mt-6 overflow-x-auto rounded-xl border border-zinc-800">
        <table className="min-w-full text-left text-sm">
          <thead className="border-b border-zinc-800 bg-zinc-950 text-zinc-400">
            <tr>
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Verified</th>
              <th className="px-4 py-3 font-medium">Location</th>
              <th className="px-4 py-3 font-medium">Signed up</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium" />
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b border-zinc-900 bg-zinc-950/50">
                <td className="px-4 py-3">
                  <p className="font-medium">{u.screenName ?? u.username ?? '—'}</p>
                  <p className="text-zinc-500">{u.username ? `@${u.username}` : u.email}</p>
                  {u.username && u.screenName && u.screenName !== u.username && (
                    <p className="text-xs text-zinc-600">{u.email}</p>
                  )}
                </td>
                <td className="px-4 py-3">
                  {u.isVerified ? (
                    <span className="rounded-full bg-sky-950 px-2 py-0.5 text-xs font-medium text-sky-300">Verified</span>
                  ) : (
                    <span className="text-zinc-600">—</span>
                  )}
                </td>
                <td className="px-4 py-3 text-zinc-300">{formatLocation(u)}</td>
                <td className="px-4 py-3 text-zinc-400">{formatDate(u.createdAt)}</td>
                <td className="px-4 py-3">
                  {u.bannedAt ? (
                    <div>
                      <span className="text-red-400">Banned</span>
                      {u.banReason && <p className="mt-0.5 max-w-[140px] truncate text-xs text-zinc-600" title={u.banReason}>{u.banReason}</p>}
                    </div>
                  ) : (
                    <span className="text-emerald-400">Active</span>
                  )}
                </td>
                <td className="px-4 py-3">
                  <div className="flex flex-wrap justify-end gap-2">
                    {u.isVerified ? (
                      <button
                        onClick={() => void handleUnverify(u.id)}
                        className="rounded-lg border border-zinc-700 px-3 py-1.5 text-sm hover:bg-zinc-900"
                      >
                        Unverify
                      </button>
                    ) : (
                      <button
                        onClick={() => void handleVerify(u.id)}
                        className="rounded-lg border border-sky-900 px-3 py-1.5 text-sm text-sky-300 hover:bg-sky-950"
                      >
                        Verify
                      </button>
                    )}
                    {u.bannedAt ? (
                      <button
                        onClick={() => void handleUnban(u.id)}
                        className="rounded-lg border border-zinc-700 px-3 py-1.5 text-sm hover:bg-zinc-900"
                      >
                        Unban
                      </button>
                    ) : (
                      <button
                        onClick={() => void handleBan(u.id)}
                        className="rounded-lg border border-red-900 px-3 py-1.5 text-sm text-red-400 hover:bg-red-950"
                      >
                        Ban
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {users.length === 0 && (
          <p className="px-4 py-8 text-center text-zinc-500">No users found.</p>
        )}
      </div>
    </AdminShell>
  );
}
