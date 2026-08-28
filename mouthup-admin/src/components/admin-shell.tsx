'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';

const nav = [
  { href: '/dashboard', label: 'Dashboard' },
  { href: '/reports', label: 'Reports' },
  { href: '/users', label: 'Users' },
  { href: '/posts', label: 'Posts' },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();

  function logout() {
    localStorage.removeItem('mouthup_admin_token');
    localStorage.removeItem('mouthup_admin_refresh');
    router.push('/login');
  }

  return (
    <div className="flex min-h-screen bg-black text-white">
      <aside className="flex w-56 flex-col border-r border-zinc-800 bg-zinc-950 p-4">
        <div className="mb-8 px-2">
          <p className="text-lg font-bold tracking-tight">MouthUp</p>
          <p className="text-xs text-zinc-500">Admin Panel</p>
        </div>
        <nav className="flex flex-1 flex-col gap-1">
          {nav.map((item) => {
            const active = pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`rounded-lg px-3 py-2 text-sm transition ${
                  active ? 'bg-white text-black' : 'text-zinc-400 hover:bg-zinc-900 hover:text-white'
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
        <button
          onClick={logout}
          className="mt-4 rounded-lg px-3 py-2 text-left text-sm text-zinc-500 hover:bg-zinc-900 hover:text-white"
        >
          Logout
        </button>
      </aside>
      <main className="flex-1 overflow-auto p-8">{children}</main>
    </div>
  );
}

function StatCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-5">
      <p className="text-sm text-zinc-500">{label}</p>
      <p className="mt-2 text-3xl font-semibold">{value.toLocaleString()}</p>
    </div>
  );
}

export function StatGrid({ stats }: { stats: { users: number; posts: number; pendingReports: number; messages: number } }) {
  return (
    <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <StatCard label="Users" value={stats.users} />
      <StatCard label="Posts" value={stats.posts} />
      <StatCard label="Pending Reports" value={stats.pendingReports} />
      <StatCard label="Messages" value={stats.messages} />
    </div>
  );
}
