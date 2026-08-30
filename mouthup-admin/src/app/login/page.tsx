'use client';

import { useRouter } from 'next/navigation';
import { FormEvent, useState } from 'react';
import { login } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('admin@mouthup.app');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await login(email, password);
      if (res.user.role !== 'ADMIN' && res.user.role !== 'SUPER_ADMIN') {
        throw new Error('Not an admin account');
      }
      localStorage.setItem('mouthup_admin_token', res.accessToken);
      localStorage.setItem('mouthup_admin_refresh', res.refreshToken);
      router.push('/dashboard');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-black px-4">
      <form
        onSubmit={onSubmit}
        className="w-full max-w-sm rounded-2xl border border-zinc-800 bg-zinc-950 p-8"
      >
        <h1 className="text-2xl font-bold text-white">ISZI Admin</h1>
        <p className="mt-1 text-sm text-zinc-500">Sign in to manage the ISZI marketplace</p>

        <label className="mt-6 block text-sm text-zinc-400">Email</label>
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="mt-1 w-full rounded-lg border border-zinc-700 bg-black px-3 py-2 text-white outline-none focus:border-white"
          required
        />

        <label className="mt-4 block text-sm text-zinc-400">Password</label>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="mt-1 w-full rounded-lg border border-zinc-700 bg-black px-3 py-2 text-white outline-none focus:border-white"
          required
        />

        {error && <p className="mt-4 text-sm text-red-400">{error}</p>}

        <button
          type="submit"
          disabled={loading}
          className="mt-6 w-full rounded-lg bg-white py-2.5 font-medium text-black disabled:opacity-50"
        >
          {loading ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
