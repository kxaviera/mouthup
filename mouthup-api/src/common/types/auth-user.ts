import { UserRole } from '@prisma/client';

export interface AuthUser {
  id: string;
  email: string;
  username: string | null;
  role: UserRole;
  emailVerified: boolean;
  onboardingDone: boolean;
  bannedAt: Date | null;
}
