import { useState, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, XCircle, Eye } from 'lucide-react';
import { adminApi, type ListParams } from '../api';
import { useDebounced } from '../../../hooks/useDebounced';
import { Input, Select, Button } from '../../../components/ui';
import { Pagination } from '../../../components/ui/Pagination';
import { Modal } from '../../../components/ui/Modal';
import { useToast } from '../../../components/ui/toast';
import {
  PageHeader,
  TableCard,
  Th,
  Td,
  LoadingRows,
  EmptyState,
  ServiceStatusBadge,
} from '../components/shared';
import { formatDate, formatPrice } from '../../../lib/format';
import { useTheme } from '../../../lib/theme';
import type { ServiceRequest } from '../../../lib/types';
import type { ApiError } from '../../../lib/api';

const STATUSES = [
  'open',
  'awaitingSelection',
  'bidSelected',
  'inProgress',
  'completed',
  'cancelled',
  'expired',
];

export function RequestsPage() {
  const { t } = useTranslation();
  const { lang } = useTheme();
  const toast = useToast();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('');
  const [detail, setDetail] = useState<ServiceRequest | null>(null);
  const debounced = useDebounced(search);

  const params: ListParams = { page, limit: 15, search: debounced || undefined, status: status || undefined };
  const { data, isLoading } = useQuery({
    queryKey: ['admin-requests', params],
    queryFn: () => adminApi.requests(params),
  });

  const cancelMut = useMutation({
    mutationFn: (id: string) => adminApi.cancelRequest(id),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['admin-requests'] });
      void qc.invalidateQueries({ queryKey: ['admin-stats'] });
    },
    onError: (e: unknown) => toast((e as ApiError)?.message ?? t('common.error'), 'error'),
  });

  return (
    <div>
      <PageHeader title={t('admin.requests.title')} />

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <div className="relative min-w-[220px] flex-1">
          <Search className="pointer-events-none absolute inset-y-0 start-3 my-auto h-4 w-4 text-content-tertiary" />
          <Input
            className="ps-9"
            placeholder={t('admin.requests.search')}
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
        </div>
        <Select
          value={status}
          onChange={(e) => {
            setStatus(e.target.value);
            setPage(1);
          }}
          className="w-52"
        >
          <option value="">{t('admin.requests.all_status')}</option>
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
                <Th>{t('admin.requests.request')}</Th>
                <Th>{t('admin.requests.client')}</Th>
                <Th>{t('admin.users.status')}</Th>
                <Th>{t('admin.requests.bids')}</Th>
                <Th>{t('admin.requests.price')}</Th>
                <Th>{t('admin.users.joined')}</Th>
                <Th className="text-end">{t('admin.users.actions')}</Th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((r: ServiceRequest) => (
                <tr key={r._id} className="transition hover:bg-surface-variant/50">
                  <Td>
                    <div className="min-w-0">
                      <div className="truncate font-semibold text-content">{r.title}</div>
                      <div className="truncate text-xs text-content-tertiary">{r.serviceType}</div>
                    </div>
                  </Td>
                  <Td>
                    <div className="text-xs text-content-secondary">{r.userName}</div>
                  </Td>
                  <Td>
                    <ServiceStatusBadge status={r.status} />
                  </Td>
                  <Td>
                    <span className="text-sm text-content">{r.bidCount}</span>
                  </Td>
                  <Td>
                    <span className="whitespace-nowrap text-sm text-content">
                      {formatPrice(r.finalPrice ?? r.agreedPrice)}
                    </span>
                  </Td>
                  <Td>
                    <span className="whitespace-nowrap text-xs text-content-secondary">
                      {formatDate(r.createdAt, lang)}
                    </span>
                  </Td>
                  <Td className="text-end">
                    <div className="flex justify-end gap-2">
                      <Button size="sm" variant="ghost" onClick={() => setDetail(r)} title={t('admin.requests.view')}>
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="danger"
                        onClick={() => {
                          if (confirm(t('admin.requests.cancel_confirm'))) cancelMut.mutate(r._id);
                        }}
                        title={t('admin.requests.cancel')}
                      >
                        <XCircle className="h-4 w-4" />
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

      <Modal open={!!detail} onClose={() => setDetail(null)} title={detail?.title ?? ''}>
        {detail && (
          <div className="space-y-3 text-sm">
            <Row label={t('admin.requests.request')} value={detail.serviceType} />
            <Row label={t('admin.users.status')} value={<ServiceStatusBadge status={detail.status} />} />
            <Row label={t('admin.requests.client')} value={`${detail.userName} · ${detail.userPhone}`} />
            <Row label={t('admin.requests.worker')} value={detail.workerName ?? '—'} />
            <Row label={t('admin.requests.price')} value={formatPrice(detail.finalPrice ?? detail.agreedPrice)} />
            <Row label={t('admin.requests.bids')} value={String(detail.bidCount)} />
            <Row label="Adresse" value={detail.userAddress} />
            <div>
              <div className="mb-1 text-xs font-semibold text-content-secondary">Description</div>
              <p className="rounded-lg bg-surface-variant p-3 text-content-secondary">{detail.description}</p>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}

function Row({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-4 border-b border-border pb-2">
      <span className="text-xs font-semibold text-content-secondary">{label}</span>
      <span className="text-end font-medium text-content">{value}</span>
    </div>
  );
}
