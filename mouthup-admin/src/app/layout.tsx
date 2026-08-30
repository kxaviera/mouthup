import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'ISZI Admin',
  description: 'Admin panel for ISZI marketplace',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  );
}
