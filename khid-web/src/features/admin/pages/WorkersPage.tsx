import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, Star, ShieldCheck, Wifi, WifiOff } from 'lucide-react';
import { adminApi, type ListParams } from '../api';
import { useDebounced } from '../../../hooks/useDebounced';
import { Input, Badge, Button } from '../../../components/ui';
import { Pagination } from '../../../components/ui/Pagination';
import { useToast } from '../../../components/ui/toast';
import { PageHeader, TableCard, Th, Td, LoadingRows, EmptyState } from '../components/shared';
import { initials } from '../../../lib/format';
import type { AdminUser } from '../../../lib/types';
import type { ApiError } from '../../../lib/api';

export function WorkersPage() {
  const { t } = useTranslation();
  const toast = useToast();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const debounced = useDebounced(search);

  const params: ListParams = { page, limit: 15, search: debounced || undefined };
  const { data, isLoading } = useQuery({
    queryKey: ['admin-workers', params],
    queryFn: () => adminApi.workers(params),
  });

  const invalidate = () => void qc.invalidateQueries({ queryKey: ['admin-workers'] });
  const onErr = (e: unknown) => toast((e as ApiError)?.message ?? t('common.error'), 'error');

  const verifyMut = useMutation({
    mutationFn: ({ id, v }: { id: string; v: boolean }) => adminApi.setVerified(id, v),
    onSuccess: invalidate,
    onError: onErr,
  });
  const onlineMut = useMutation({
    mutationFn: ({ id, v }: { id: string; v: boolean }) => adminApi.setOnline(id, v),
    onSuccess: invalidate,
    onError: onErr,
  });

  return (
    <div>
      <PageHeader title={t('admin.workers.title')} />

      <div className="mb-4 max-w-md">
        <div className="relative">
          <Search className="pointer-events-none absolute inset-y-0 start-3 my-auto h-4 w-4 text-content-tertiary" />
          <Input
            className="ps-9"
            placeholder={t('admin.workers.search')}
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
        </div>
      </div>

      {isLoading ? (
        <LoadingRows />
      ) : !data || data.items.length === 0 ? (
        <EmptyState />
      ) : (
        <>
          <TableCard>
            <thead>
              <tr>
                <Th>{t('admin.workers.title')}</Th>
                <Th>{t('admin.workers.profession')}</Th>
                <Th>{t('admin.workers.rating')}</Th>
                <Th>{t('admin.workers.jobs')}</Th>
                <Th>{t('admin.users.status')}</Th>
                <Th className="text-end">{t('admin.users.actions')}</Th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((w: AdminUser) => (
                <tr key={w._id} className="transition hover:bg-surface-variant/50">
                  <Td>
                    <div className="flex items-center gap-3">
                      <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-violet/12 text-xs font-bold text-violet">
                        {initials(w.name) || '?'}
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5 font-semibold text-content">
                          <span className="truncate">{w.name}</span>
                          {w.isVerified && <ShieldCheck className="h-3.5 w-3.5 text-success" />}
                        </div>
                        <div className="truncate text-xs text-content-tertiary">{w.phoneNumber || w.email || '—'}</div>
                      </div>
                    </div>
                  </Td>
                  <Td>
                    <Badge tone="primary">{w.profession ?? '—'}</Badge>
                  </Td>
                  <Td>
                    <span className="inline-flex items-center gap-1 text-sm font-semibold text-content">
                      <Star className="h-3.5 w-3.5 fill-warning text-warning" />
                      {w.averageRating.toFixed(1)}
                      <span className="text-xs font-normal text-content-tertiary">({w.ratingCount})</span>
                    </span>
                  </Td>
                  <Td>
                    <span className="text-sm text-content">{w.jobsCompleted}</span>
                  </Td>
                  <Td>
                    {w.isOnline ? (
                      <Badge tone="success">{t('admin.workers.online')}</Badge>
                    ) : (
                      <Badge tone="neutral">{t('admin.workers.offline')}</Badge>
                    )}
                  </Td>
                  <Td className="text-end">
                    <div className="flex justify-end gap-2">
                      <Button
                        size="sm"
                        variant={w.isVerified ? 'soft' : 'outline'}
                        onClick={() => verifyMut.mutate({ id: w._id, v: !w.isVerified })}
                        title={w.isVerified ? t('admin.workers.unverify') : t('admin.workers.verify')}
                      >
                        <ShieldCheck className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="outline"
                        onClick={() => onlineMut.mutate({ id: w._id, v: !w.isOnline })}
                        title={w.isOnline ? t('admin.workers.set_offline') : t('admin.workers.set_online')}
                      >
                        {w.isOnline ? <WifiOff className="h-4 w-4" /> : <Wifi className="h-4 w-4" />}
                      </Button>
                    </div>
                  </Td>
                </tr>
              ))}
            </tbody>
          </TableCard>
          <Pagination page={data.page} pages={data.pages} total={data.total} onPage={setPage} />
        </>
      )}
    </div>
  );
}
