import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { Star } from 'lucide-react';
import { adminApi, type ListParams } from '../api';
import { Select } from '../../../components/ui';
import { Pagination } from '../../../components/ui/Pagination';
import {
  PageHeader,
  TableCard,
  Th,
  Td,
  LoadingRows,
  EmptyState,
  BidStatusBadge,
} from '../components/shared';
import { formatDate, formatPrice } from '../../../lib/format';
import { useTheme } from '../../../lib/theme';
import type { WorkerBid } from '../../../lib/types';

const STATUSES = ['pending', 'accepted', 'declined', 'withdrawn', 'expired'];

export function BidsPage() {
  const { t } = useTranslation();
  const { lang } = useTheme();
  const [page, setPage] = useState(1);
  const [status, setStatus] = useState('');

  const params: ListParams = { page, limit: 15, status: status || undefined };
  const { data, isLoading } = useQuery({
    queryKey: ['admin-bids', params],
    queryFn: () => adminApi.bids(params),
  });

  return (
    <div>
      <PageHeader title={t('admin.bids.title')} />

      <div className="mb-4 max-w-xs">
        <Select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
        >
          <option value="">{t('admin.bids.all_status')}</option>
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s}
            </option>
          ))}
        </Select>
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
                <Th>{t('admin.bids.worker')}</Th>
                <Th>{t('admin.bids.price')}</Th>
                <Th>{t('admin.bids.duration')}</Th>
                <Th>{t('admin.users.status')}</Th>
                <Th>{t('admin.bids.message')}</Th>
                <Th>{t('admin.users.joined')}</Th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((b: WorkerBid) => (
                <tr key={b._id} className="transition hover:bg-surface-variant/50">
                  <Td>
                    <div className="font-semibold text-content">{b.workerName}</div>
                    <div className="flex items-center gap-1 text-xs text-content-tertiary">
                      <Star className="h-3 w-3 fill-warning text-warning" />
                      {b.workerAverageRating.toFixed(1)} · {b.workerJobsCompleted}
                    </div>
                  </Td>
                  <Td>
                    <span className="whitespace-nowrap font-semibold text-content">
                      {formatPrice(b.proposedPrice)}
                    </span>
                  </Td>
                  <Td>
                    <span className="whitespace-nowrap text-sm text-content-secondary">
                      {b.estimatedMinutes} {t('admin.bids.minutes')}
                    </span>
                  </Td>
                  <Td>
                    <BidStatusBadge status={b.status} />
                  </Td>
                  <Td>
                    <span className="line-clamp-1 block max-w-[220px] text-xs text-content-secondary">
                      {b.message ?? '—'}
                    </span>
                  </Td>
                  <Td>
                    <span className="whitespace-nowrap text-xs text-content-secondary">
                      {formatDate(b.createdAt, lang)}
                    </span>
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
