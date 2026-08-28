'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell, StatGrid } from '@/components/admin-shell';
import { getDashboard, getStoredToken } from '@/lib/api';

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<{ users: number; posts: number; pendingReports: number; messages: number } | null>(null);

  useEffect(() => {
    if (!getStoredToken()) {
      router.replace('/login');
      return;
    }
    getDashboard().then(setStats).catch(() => router.replace('/login'));
  }, [router]);

  return (
    <AdminShell>
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <p className="mt-1 text-zinc-500">Platform overview</p>
      <div className="mt-8">
        {stats ? (
          <StatGrid stats={stats} />
        ) : (
          <p className="text-zinc-500">Loading stats…</p>
        )}
      </div>
    </AdminShell>
  );
}
