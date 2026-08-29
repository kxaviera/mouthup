'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { deletePost, getStoredToken, searchPosts } from '@/lib/api';

const POLL_MS = 10_000;

type PostRow = {
  id: string;
  content: string;
  createdAt: string;
  author: { username: string | null; email: string; isBot: boolean };
  media: { type: string; url: string }[];
};

export default function PostsPage() {
  const router = useRouter();
  const [q, setQ] = useState('');
  const [posts, setPosts] = useState<PostRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const queryRef = useRef(q);

  useEffect(() => {
    queryRef.current = q;
  }, [q]);

  useEffect(() => {
    if (!getStoredToken()) router.replace('/login');
  }, [router]);

  const loadPosts = useCallback(async (query: string, silent = false) => {
    if (silent) setRefreshing(true);
    else setLoading(true);
    try {
      const res = await searchPosts(query);
      setPosts(res);
      setLastUpdated(new Date());
    } finally {
      if (silent) setRefreshing(false);
      else setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (!getStoredToken()) return;
    void loadPosts('');
  }, [loadPosts]);

  useEffect(() => {
    if (!getStoredToken()) return;

    const tick = () => {
      if (document.visibilityState === 'hidden') return;
      void loadPosts(queryRef.current, true);
    };

    const id = window.setInterval(tick, POLL_MS);
    return () => window.clearInterval(id);
  }, [loadPosts]);

  async function handleDelete(id: string) {
    await deletePost(id);
    setPosts((prev) => prev.filter((p) => p.id !== id));
  }

  return (
    <AdminShell>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Posts</h1>
          <p className="mt-1 text-sm text-zinc-500">
            Live feed refreshes every 10 seconds. Search to filter by content.
          </p>
        </div>
        <div className="flex items-center gap-2 text-sm text-zinc-500">
          <span
            className={`inline-block h-2 w-2 rounded-full ${refreshing ? 'animate-pulse bg-amber-400' : 'bg-emerald-500'}`}
            aria-hidden
          />
          {lastUpdated ? (
            <span>Updated {lastUpdated.toLocaleTimeString()}</span>
          ) : (
            <span>Waiting for first load…</span>
          )}
        </div>
      </div>

      <div className="mt-6 flex gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && void loadPosts(q)}
          placeholder="Search post content"
          className="flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2 outline-none focus:border-white"
        />
        <button onClick={() => void loadPosts(q)} className="rounded-lg bg-white px-4 py-2 text-black">
          Search
        </button>
      </div>

      <div className="mt-6 space-y-2">
        {loading && <p className="text-zinc-500">Loading posts…</p>}
        {!loading && posts.length === 0 && (
          <p className="text-zinc-500">No posts found.</p>
        )}
        {posts.map((p) => (
          <div
            key={p.id}
            className="flex items-start justify-between gap-4 rounded-xl border border-zinc-800 bg-zinc-950 p-4"
          >
            <div className="min-w-0 flex-1">
              <p className="text-sm text-zinc-500">
                {p.author.username ?? p.author.email}
                {p.author.isBot ? ' · bot' : ''}
                {' · '}
                {new Date(p.createdAt).toLocaleString()}
              </p>
              <p className="mt-1 whitespace-pre-wrap break-words">{p.content}</p>
              {p.media.length > 0 && (
                <div className="mt-2 flex flex-wrap gap-2">
                  {p.media.map((m, i) => (
                    <a
                      key={`${p.id}-${i}`}
                      href={m.url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-sky-400 hover:underline"
                    >
                      {m.type === 'VIDEO' ? 'Video' : 'Image'} {i + 1}
                    </a>
                  ))}
                </div>
              )}
            </div>
            <button
              onClick={() => void handleDelete(p.id)}
              className="shrink-0 rounded-lg border border-red-900 px-3 py-1.5 text-sm text-red-400 hover:bg-red-950"
            >
              Delete
            </button>
          </div>
        ))}
      </div>
    </AdminShell>
  );
}
