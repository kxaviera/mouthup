'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { deletePost, getStoredToken, searchPosts } from '@/lib/api';

type PostRow = {
  id: string;
  content: string;
  createdAt: string;
  author: { username: string | null };
};

export default function PostsPage() {
  const router = useRouter();
  const [q, setQ] = useState('');
  const [posts, setPosts] = useState<PostRow[]>([]);

  useEffect(() => {
    if (!getStoredToken()) router.replace('/login');
  }, [router]);

  async function search() {
    const res = await searchPosts(q);
    setPosts(res);
  }

  async function handleDelete(id: string) {
    await deletePost(id);
    setPosts((prev) => prev.filter((p) => p.id !== id));
  }

  return (
    <AdminShell>
      <h1 className="text-2xl font-bold">Posts</h1>
      <div className="mt-6 flex gap-2">
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search post content"
          className="flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2 outline-none focus:border-white"
        />
        <button onClick={search} className="rounded-lg bg-white px-4 py-2 text-black">
          Search
        </button>
      </div>

      <div className="mt-6 space-y-2">
        {posts.map((p) => (
          <div
            key={p.id}
            className="flex items-start justify-between gap-4 rounded-xl border border-zinc-800 bg-zinc-950 p-4"
          >
            <div>
              <p className="text-sm text-zinc-500">
                {p.author.username} · {new Date(p.createdAt).toLocaleString()}
              </p>
              <p className="mt-1">{p.content}</p>
            </div>
            <button
              onClick={() => handleDelete(p.id)}
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
