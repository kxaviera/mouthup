'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { banUser, getStoredToken, searchUsers, unbanUser } from '@/lib/api';

type UserRow = {
  id: string;
  email: string;
  username: string | null;
  bannedAt: string | null;
  createdAt: string;
  signupIp: string | null;
  signupCountry: string | null;
  signupRegion: string | null;
  signupCity: string | null;
  authProvider: string | null;
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

  useEffect(() => {
    if (!getStoredToken()) router.replace('/login');
  }, [router]);

  const loadUsers = useCallback(async (query = q) => {
    const res = await searchUsers(query);
    setUsers(res);
  }, [q]);

  useEffect(() => {
    if (getStoredToken()) {
      void loadUsers('');
    }
  }, [loadUsers]);

  async function handleBan(id: string) {
    await banUser(id, 'Violated community guidelines');
    setUsers((prev) =>
      prev.map((u) => (u.id === id ? { ...u, bannedAt: new Date().toISOString() } : u)),
    );
  }

  async function handleUnban(id: string) {
    await unbanUser(id);
    setUsers((prev) => prev.map((u) => (u.id === id ? { ...u, bannedAt: null } : u)));
  }

  return (
    <AdminShell>
      <h1 className="text-2xl font-bold">Users</h1>
      <p className="mt-1 text-sm text-zinc-500">
        Signup location and IP are captured automatically — users are not asked for this.
      </p>
      <div className="mt-6 flex gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && void loadUsers()}
          placeholder="Search by username or email"
          className="flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2 outline-none focus:border-white"
        />
        <button onClick={() => void loadUsers()} className="rounded-lg bg-white px-4 py-2 text-black">
          Search
        </button>
      </div>

      <div className="mt-6 overflow-x-auto rounded-xl border border-zinc-800">
        <table className="min-w-full text-left text-sm">
          <thead className="border-b border-zinc-800 bg-zinc-950 text-zinc-400">
            <tr>
              <th className="px-4 py-3 font-medium">User</th>
              <th className="px-4 py-3 font-medium">Location</th>
              <th className="px-4 py-3 font-medium">IP</th>
              <th className="px-4 py-3 font-medium">Signed up</th>
              <th className="px-4 py-3 font-medium">Status</th>
              <th className="px-4 py-3 font-medium" />
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id} className="border-b border-zinc-900 bg-zinc-950/50">
                <td className="px-4 py-3">
                  <p className="font-medium">{u.username ?? '—'}</p>
                  <p className="text-zinc-500">{u.email}</p>
                  {u.authProvider && (
                    <p className="text-xs text-zinc-600">{u.authProvider}</p>
                  )}
                </td>
                <td className="px-4 py-3 text-zinc-300">{formatLocation(u)}</td>
                <td className="px-4 py-3 font-mono text-xs text-zinc-400">{u.signupIp ?? '—'}</td>
                <td className="px-4 py-3 text-zinc-400">{formatDate(u.createdAt)}</td>
                <td className="px-4 py-3">
                  {u.bannedAt ? (
                    <span className="text-red-400">Banned</span>
                  ) : (
                    <span className="text-emerald-400">Active</span>
                  )}
                </td>
                <td className="px-4 py-3 text-right">
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
