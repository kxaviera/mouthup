'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell, StatGrid } from '@/components/admin-shell';
import { getDashboard, getStoredToken } from '@/lib/api';
import {
  connectAdminRealtime,
  disconnectAdminRealtime,
  type AdminStats,
} from '@/lib/realtime';

export default function DashboardPage() {
  const router = useRouter();
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [live, setLive] = useState(false);

  const loadStats = useCallback(async () => {
    try {
      setStats(await getDashboard());
    } catch {
      router.replace('/login');
    }
  }, [router]);

  useEffect(() => {
    const token = getStoredToken();
    if (!token) {
      router.replace('/login');
      return;
    }

    void loadStats();

    connectAdminRealtime(token, {
      onConnect: () => setLive(true),
      onDisconnect: () => setLive(false),
      onStats: (next) => setStats(next),
      onRefresh: () => void loadStats(),
    });

    return () => {
      disconnectAdminRealtime();
      setLive(false);
    };
  }, [loadStats, router]);

  return (
    <AdminShell>
      <div className="flex items-center gap-3">
        <h1 className="text-2xl font-bold">Dashboard</h1>
        {live && (
          <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-800 bg-emerald-950 px-2.5 py-0.5 text-xs text-emerald-400">
            <span className="h-1.5 w-1.5 animate-pulse rounded-full bg-emerald-400" />
            Live
          </span>
        )}
      </div>
      <p className="mt-1 text-zinc-500">Platform overview — updates in real time</p>
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
