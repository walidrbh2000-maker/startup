import { useEffect, type ReactNode } from 'react';
import { Navigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import { ShieldAlert } from 'lucide-react';
import { useAuth } from '../../../lib/auth';
import { adminApi } from '../api';
import { Button, Centered, Spinner } from '../../../components/ui';
import type { ApiError } from '../../../lib/api';

/**
 * Gate for /admin/*. Requires a signed-in Firebase user AND a successful
 * /admin/stats probe (which the backend AdminGuard only allows for role=admin).
 * A 403 renders an "insufficient privileges" screen rather than looping.
 */
export function RequireAdmin({ children }: { children: ReactNode }) {
  const { t } = useTranslation();
  const { user, initializing, signOut, ensureInit } = useAuth();

  // Kick off the lazy Firebase load the moment the admin gate mounts.
  useEffect(() => ensureInit(), [ensureInit]);

  const probe = useQuery({
    queryKey: ['admin-access', user?.uid],
    queryFn: () => adminApi.stats(),
    enabled: Boolean(user),
    retry: false,
    staleTime: 60_000,
  });

  if (initializing) {
    return (
      <Centered>
        <Spinner />
      </Centered>
    );
  }

  if (!user) return <Navigate to="/admin/login" replace />;

  if (probe.isLoading) {
    return (
      <Centered>
        <Spinner />
      </Centered>
    );
  }

  if (probe.isError) {
    const status = (probe.error as unknown as ApiError)?.status;
    // 403 → authenticated but not an admin. Anything else → also block, but the
    // message stays the same to avoid leaking backend detail.
    return (
      <div className="flex min-h-screen items-center justify-center bg-bg px-4">
        <div className="card max-w-md p-8 text-center">
          <div className="mx-auto grid h-14 w-14 place-items-center rounded-2xl bg-danger/12 text-danger">
            <ShieldAlert className="h-7 w-7" />
          </div>
          <h2 className="mt-4 font-display text-xl font-bold text-content">
            {t('admin.login.forbidden')}
          </h2>
          <p className="mt-2 text-sm text-content-secondary">
            {user.email}
            {status ? ` · ${status}` : ''}
          </p>
          <Button variant="outline" className="mt-6" onClick={() => void signOut()}>
            {t('admin.nav.logout')}
          </Button>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
