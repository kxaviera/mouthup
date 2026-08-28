'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { banUser, getStoredToken, searchUsers, unbanUser } from '@/lib/api';

type UserRow = {
  id: string;
  email: string;
  username: string | null;
  bannedAt: string | null;
  createdAt: string;
};

export default function UsersPage() {
  const router = useRouter();
  const [q, setQ] = useState('');
  const [users, setUsers] = useState<UserRow[]>([]);

  useEffect(() => {
    if (!getStoredToken()) router.replace('/login');
  }, [router]);

  async function search() {
    const res = await searchUsers(q);
    setUsers(res);
  }

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
      <div className="mt-6 flex gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search by username or email"
          className="flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2 outline-none focus:border-white"
        />
        <button onClick={search} className="rounded-lg bg-white px-4 py-2 text-black">
          Search
        </button>
      </div>

      <div className="mt-6 space-y-2">
        {users.map((u) => (
          <div
            key={u.id}
            className="flex items-center justify-between rounded-xl border border-zinc-800 bg-zinc-950 p-4"
          >
            <div>
              <p className="font-medium">{u.username ?? '—'}</p>
              <p className="text-sm text-zinc-500">{u.email}</p>
              {u.bannedAt && <p className="text-xs text-red-400">Banned</p>}
            </div>
            {u.bannedAt ? (
              <button
                onClick={() => handleUnban(u.id)}
                className="rounded-lg border border-zinc-700 px-3 py-1.5 text-sm hover:bg-zinc-900"
              >
                Unban
              </button>
            ) : (
              <button
                onClick={() => handleBan(u.id)}
                className="rounded-lg border border-red-900 px-3 py-1.5 text-sm text-red-400 hover:bg-red-950"
              >
                Ban
              </button>
            )}
          </div>
        ))}
      </div>
    </AdminShell>
  );
}
