'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { getReports, getStoredToken, resolveReport } from '@/lib/api';

type Report = {
  id: string;
  reason: string;
  targetType: string;
  createdAt: string;
  reporter: { username: string | null; email: string };
  targetPost?: { content: string; author: { username: string | null } };
  targetComment?: { content: string; author: { username: string | null } };
  targetUser?: { username: string | null; email: string };
};

export default function ReportsPage() {
  const router = useRouter();
  const [reports, setReports] = useState<Report[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!getStoredToken()) {
      router.replace('/login');
      return;
    }
    getReports()
      .then(setReports)
      .catch((err) => {
        setError(err instanceof Error ? err.message : 'Failed to load reports');
      });
  }, [router]);

  async function handleResolve(id: string, status: 'RESOLVED' | 'DISMISSED') {
    try {
      setError(null);
      await resolveReport(id, status);
      setReports((prev) => prev.filter((r) => r.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to update report');
    }
  }

  return (
    <AdminShell>
      <h1 className="text-2xl font-bold">Reports</h1>
      <p className="mt-1 text-zinc-500">Review flagged content</p>

      {error && (
        <p className="mt-4 rounded-lg border border-red-900 bg-red-950/40 px-4 py-3 text-sm text-red-300">{error}</p>
      )}

      <div className="mt-8 space-y-3">
        {reports.length === 0 && <p className="text-zinc-500">No pending reports</p>}
        {reports.map((r) => (
          <div key={r.id} className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
            <div className="flex items-start justify-between gap-4">
              <div>
                <p className="text-sm text-zinc-500">
                  {r.targetType} · {new Date(r.createdAt).toLocaleString()}
                </p>
                <p className="mt-1 font-medium">{r.reason}</p>
                {r.targetPost && (
                  <p className="mt-2 text-sm text-zinc-400">
                    Post by {r.targetPost.author.username}: {r.targetPost.content.slice(0, 120)}
                  </p>
                )}
                {r.targetComment && (
                  <p className="mt-2 text-sm text-zinc-400">
                    Comment by {r.targetComment.author.username}: {r.targetComment.content.slice(0, 120)}
                  </p>
                )}
                {r.targetUser && (
                  <p className="mt-2 text-sm text-zinc-400">
                    User: {r.targetUser.username ?? r.targetUser.email}
                  </p>
                )}
                <p className="mt-1 text-xs text-zinc-600">
                  Reported by {r.reporter.username ?? r.reporter.email}
                </p>
              </div>
              <div className="flex shrink-0 gap-2">
                <button
                  onClick={() => handleResolve(r.id, 'DISMISSED')}
                  className="rounded-lg border border-zinc-700 px-3 py-1.5 text-sm hover:bg-zinc-900"
                >
                  Dismiss
                </button>
                <button
                  onClick={() => handleResolve(r.id, 'RESOLVED')}
                  className="rounded-lg bg-white px-3 py-1.5 text-sm text-black"
                >
                  Resolve
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </AdminShell>
  );
}
