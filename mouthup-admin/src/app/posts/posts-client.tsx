'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/admin-shell';
import { deletePost, getStoredToken, searchPosts } from '@/lib/api';
import { formatListingPrice, listingTypeLabel } from '@/lib/listings';
import { connectAdminRealtime, disconnectAdminRealtime } from '@/lib/realtime';

const POLL_MS = 10_000;

type ListingRow = {
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
};

function listingHeadline(row: ListingRow): string {
  if (row.title?.trim()) return row.title.trim();
  const firstLine = row.content.split('\n').find((l) => l.trim());
  return firstLine?.trim() || 'Untitled listing';
}

export default function PostsClient() {
  const router = useRouter();
  const [q, setQ] = useState('');
  const [posts, setPosts] = useState<ListingRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [error, setError] = useState<string | null>(null);
  const queryRef = useRef(q);

  useEffect(() => {
    queryRef.current = q;
  }, [q]);

  useEffect(() => {
    if (!getStoredToken()) router.replace('/login');
  }, [router]);

  const loadPosts = useCallback(async (query: string, silent = false) => {
    if (silent) setRefreshing(true);
    else {
      setLoading(true);
      setError(null);
    }
    try {
      const res = await searchPosts(query);
      setPosts(res);
      setLastUpdated(new Date());
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load listings';
      if (!silent) setError(message);
    } finally {
      if (silent) setRefreshing(false);
      else setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (getStoredToken()) {
      void loadPosts('');
    }
  }, [loadPosts]);

  useEffect(() => {
    if (!getStoredToken()) return;

    const token = getStoredToken();
    if (token) {
      connectAdminRealtime(token, {
        onRefresh: () => void loadPosts(queryRef.current, true),
      });
    }

    const tick = () => {
      if (document.visibilityState === 'hidden') return;
      void loadPosts(queryRef.current, true);
    };

    const id = window.setInterval(tick, POLL_MS);
    return () => {
      window.clearInterval(id);
      disconnectAdminRealtime();
    };
  }, [loadPosts]);

  async function handleDelete(id: string) {
    if (!window.confirm('Delete this listing permanently?')) return;
    try {
      await deletePost(id);
      setPosts((prev) => prev.filter((p) => p.id !== id));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to delete listing');
    }
  }

  const marketplaceCount = posts.filter((p) => p.listingType).length;

  return (
    <AdminShell>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold">Marketplace listings</h1>
          <p className="mt-1 text-sm text-zinc-500">
            Live ISZI feed — title, price, location, and status. Refreshes every 10 seconds.
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
          placeholder="Search title, description, or location"
          className="flex-1 rounded-lg border border-zinc-700 bg-zinc-950 px-3 py-2 outline-none focus:border-white"
        />
        <button onClick={() => void loadPosts(q)} className="rounded-lg bg-white px-4 py-2 text-black">
          Search
        </button>
      </div>

      <div className="mt-6 space-y-2">
        {error && (
          <p className="rounded-lg border border-red-900 bg-red-950/40 px-4 py-3 text-sm text-red-300">
            {error}
          </p>
        )}
        {loading && <p className="text-zinc-500">Loading listings…</p>}
        {!loading && !error && posts.length === 0 && (
          <p className="text-zinc-500">No listings found.</p>
        )}
        {!loading && posts.length > 0 && (
          <p className="text-sm text-zinc-500">
            {posts.length} item(s) · {marketplaceCount} marketplace listing(s)
          </p>
        )}
        {posts.map((p) => {
          const typeLabel = listingTypeLabel(p.listingType);
          const priceLabel = formatListingPrice(p.price, p.currency, p.rentPeriod, p.listingType);
          const location = p.location ?? p.author.city;
          return (
            <div
              key={p.id}
              className="flex items-start justify-between gap-4 rounded-xl border border-zinc-800 bg-zinc-950 p-4"
            >
              <div className="min-w-0 flex-1">
                <div className="flex flex-wrap items-center gap-2">
                  {typeLabel ? (
                    <span className="rounded-full bg-zinc-900 px-2 py-0.5 text-xs font-medium text-zinc-300">
                      {typeLabel}
                    </span>
                  ) : (
                    <span className="rounded-full bg-zinc-900 px-2 py-0.5 text-xs text-zinc-500">Post</span>
                  )}
                  <span
                    className={`rounded-full px-2 py-0.5 text-xs font-medium ${
                      p.listingStatus === 'OPEN'
                        ? 'bg-emerald-950 text-emerald-300'
                        : 'bg-zinc-900 text-zinc-400'
                    }`}
                  >
                    {p.listingStatus === 'OPEN' ? 'Available' : 'Closed'}
                  </span>
                  {priceLabel ? (
                    <span className="text-sm font-semibold text-white">{priceLabel}</span>
                  ) : null}
                </div>

                <h2 className="mt-2 text-base font-semibold text-white">{listingHeadline(p)}</h2>

                <p className="mt-1 text-sm text-zinc-500">
                  {p.author.username ?? p.author.email}
                  {location ? ` · ${location}` : ''}
                  {' · '}
                  {new Date(p.createdAt).toLocaleString()}
                  {p.viewCount > 0 ? ` · ${p.viewCount} views` : ''}
                </p>

                {p.content.trim() && p.content.trim() !== listingHeadline(p) ? (
                  <p className="mt-2 whitespace-pre-wrap break-words text-sm text-zinc-300">{p.content}</p>
                ) : null}

                {p.listingType === 'SWAP' && p.swapFor?.trim() ? (
                  <p className="mt-1 text-sm text-zinc-400">Swap for: {p.swapFor}</p>
                ) : null}
                {p.listingType === 'SERVICE_REQUEST' && p.requestedProfession ? (
                  <p className="mt-1 text-sm text-zinc-400">Profession needed: {p.requestedProfession}</p>
                ) : null}

                {p.media?.length ? (
                  <div className="mt-3 flex flex-wrap gap-2">
                    {p.media.map((m, i) => (
                      <a
                        key={`${p.id}-${i}`}
                        href={m.url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="overflow-hidden rounded-lg border border-zinc-800"
                      >
                        {m.type === 'VIDEO' ? (
                          <span className="block px-3 py-2 text-xs text-sky-400 hover:underline">
                            Video {i + 1}
                          </span>
                        ) : (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img src={m.url} alt="" className="h-20 w-20 object-cover" />
                        )}
                      </a>
                    ))}
                  </div>
                ) : null}
              </div>
              <button
                onClick={() => void handleDelete(p.id)}
                className="shrink-0 rounded-lg border border-red-900 px-3 py-1.5 text-sm text-red-400 hover:bg-red-950"
              >
                Delete
              </button>
            </div>
          );
        })}
      </div>
    </AdminShell>
  );
}
