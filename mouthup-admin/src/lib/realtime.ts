import { io, Socket } from 'socket.io-client';
import { getSocketBaseUrl } from './api-url';

export type AdminStats = {
  users: number;
  posts: number;
  listings: number;
  pendingReports: number;
  messages: number;
  verifiedUsers: number;
};

let socket: Socket | null = null;

export function connectAdminRealtime(
  token: string,
  handlers: {
    onStats?: (stats: AdminStats) => void;
    onRefresh?: () => void;
    onConnect?: () => void;
    onDisconnect?: () => void;
  },
) {
  disconnectAdminRealtime();

  socket = io(`${getSocketBaseUrl()}/realtime`, {
    transports: ['websocket'],
    auth: { token },
    reconnection: true,
    reconnectionAttempts: 10,
    reconnectionDelay: 2000,
  });

  socket.on('connect', () => handlers.onConnect?.());
  socket.on('disconnect', () => handlers.onDisconnect?.());
  socket.on('admin:stats', (stats: AdminStats) => handlers.onStats?.(stats));
  socket.on('admin:refresh', () => handlers.onRefresh?.());

  return socket;
}

export function disconnectAdminRealtime() {
  socket?.disconnect();
  socket = null;
}

export function isAdminRealtimeConnected() {
  return socket?.connected ?? false;
}
