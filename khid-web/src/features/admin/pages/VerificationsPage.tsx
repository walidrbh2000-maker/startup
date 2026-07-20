import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { ShieldCheck, XCircle, FileText } from 'lucide-react';
import { adminApi, type ListParams } from '../api';
import { Button } from '../../../components/ui';
import { Modal } from '../../../components/ui/Modal';
import { Pagination } from '../../../components/ui/Pagination';
import { useToast } from '../../../components/ui/toast';
import { PageHeader, TableCard, Th, Td, LoadingRows, EmptyState, RoleBadge } from '../components/shared';
import { initials } from '../../../lib/format';
import { cn } from '../../../lib/cn';
import type { AdminUser } from '../../../lib/types';
import type { ApiError } from '../../../lib/api';

type Tab = 'pending' | 'rejected';

export function VerificationsPage() {
  const { t } = useTranslation();
  const toast = useToast();
  const qc = useQueryClient();

  const [tab, setTab] = useState<Tab>('pending');
  const [page, setPage] = useState(1);
  const [rejecting, setRejecting] = useState<AdminUser | null>(null);
  const [note, setNote] = useState('');

  const params: ListParams = { page, limit: 15, verificationStatus: tab };
  const { data, isLoading } = useQuery({
    queryKey: ['admin-verifications', params],
    queryFn: () => adminApi.users(params),
  });

  const invalidate = () => void qc.invalidateQueries({ queryKey: ['admin-verifications'] });
  const onErr = (e: unknown) => toast((e as ApiError)?.message ?? t('common.error'), 'error');

  const approveMut = useMutation({
    mutationFn: (id: string) => adminApi.setVerification(id, 'approved'),
    onSuccess: () => {
      invalidate();
      toast(t('admin.verif.approved_toast'), 'success');
    },
    onError: onErr,
  });
  const rejectMut = useMutation({
    mutationFn: ({ id, n }: { id: string; n?: string }) => adminApi.setVerification(id, 'rejected', n),
    onSuccess: () => {
      invalidate();
      toast(t('admin.verif.rejected_toast'), 'success');
      setRejecting(null);
      setNote('');
    },
    onError: onErr,
  });

  const tabs: { key: Tab; label: string }[] = [
    { key: 'pending', label: t('admin.verif.tab_pending') },
    { key: 'rejected', label: t('admin.verif.tab_rejected') },
  ];

  return (
    <div>
      <PageHeader title={t('admin.verif.title')} />

      <div className="mb-4 inline-flex gap-1 rounded-xl border border-border bg-surface p-1">
        {tabs.map((tb) => (
          <button
            key={tb.key}
            type="button"
            onClick={() => {
              setTab(tb.key);
              setPage(1);
            }}
            className={cn(
              'rounded-lg px-4 py-2 text-sm font-semibold transition',
              tab === tb.key
                ? 'bg-primary/12 text-primary'
                : 'text-content-secondary hover:bg-surface-variant hover:text-content',
            )}
          >
            {tb.label}
          </button>
        ))}
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
                <Th>{t('admin.users.name')}</Th>
                <Th>{t('admin.users.role')}</Th>
                <Th>{t('admin.verif.docs')}</Th>
                {tab === 'rejected' && <Th>{t('admin.verif.note_label')}</Th>}
                <Th className="text-end">{t('admin.users.actions')}</Th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((u: AdminUser) => (
                <tr key={u._id} className="transition hover:bg-surface-variant/50">
                  <Td>
                    <div className="flex items-center gap-3">
                      <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-violet/12 text-xs font-bold text-violet">
                        {initials(u.name) || '?'}
                      </div>
                      <div className="min-w-0">
                        <div className="truncate font-semibold text-content">{u.name}</div>
                        <div className="truncate text-xs text-content-tertiary">{u.phoneNumber || u.email || '—'}</div>
                      </div>
                    </div>
                  </Td>
                  <Td>
                    <RoleBadge role={u.role} />
                  </Td>
                  <Td>
                    <div className="flex flex-wrap gap-1.5">
                      {(u.verificationDocs ?? []).map((url, i) => (
                        <a
                          key={url}
                          href={url}
                          target="_blank"
                          rel="noreferrer"
                          className="inline-flex items-center gap-1 rounded-lg border border-border px-2 py-1 text-xs font-semibold text-content-secondary transition hover:bg-surface-variant hover:text-content"
                        >
                          <FileText className="h-3.5 w-3.5" />
                          {t('admin.verif.doc_n', { n: i + 1 })}
                        </a>
                      ))}
                      {(u.verificationDocs ?? []).length === 0 && (
                        <span className="text-xs text-content-tertiary">—</span>
                      )}
                    </div>
                  </Td>
                  {tab === 'rejected' && (
                    <Td>
                      <span className="block max-w-[16rem] truncate text-xs text-content-secondary" title={u.verificationNote}>
                        {u.verificationNote || '—'}
                      </span>
                    </Td>
                  )}
                  <Td className="text-end">
                    <div className="flex justify-end gap-2">
                      <Button
                        size="sm"
                        variant="soft"
                        className="!bg-success/10 !text-success hover:!bg-success/20"
                        loading={approveMut.isPending && approveMut.variables === u._id}
                        onClick={() => approveMut.mutate(u._id)}
                        title={t('admin.verif.approve')}
                      >
                        <ShieldCheck className="h-4 w-4" />
                        {t('admin.verif.approve')}
                      </Button>
                      {tab === 'pending' && (
                        <Button
                          size="sm"
                          variant="danger"
                          onClick={() => {
                            setNote('');
                            setRejecting(u);
                          }}
                          title={t('admin.verif.reject')}
                        >
                          <XCircle className="h-4 w-4" />
                          {t('admin.verif.reject')}
                        </Button>
                      )}
                    </div>
                  </Td>
                </tr>
              ))}
            </tbody>
          </TableCard>
          <Pagination page={data.page} pages={data.pages} total={data.total} onPage={setPage} />
        </>
      )}

      <Modal
        open={!!rejecting}
        onClose={() => setRejecting(null)}
        title={t('admin.verif.reject_title')}
        footer={
          <>
            <Button variant="outline" onClick={() => setRejecting(null)}>
              {t('common.cancel')}
            </Button>
            <Button
              variant="danger"
              loading={rejectMut.isPending}
              onClick={() => rejecting && rejectMut.mutate({ id: rejecting._id, n: note.trim() || undefined })}
            >
              {t('admin.verif.confirm_reject')}
            </Button>
          </>
        }
      >
        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold text-content-secondary">{t('admin.verif.note_label')}</span>
          <textarea
            value={note}
            onChange={(e) => setNote(e.target.value)}
            maxLength={500}
            rows={4}
            placeholder={t('admin.verif.note_placeholder')}
            className="w-full rounded-xl border border-border bg-surface px-4 py-3 text-sm text-content placeholder:text-content-tertiary focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/50"
          />
        </label>
      </Modal>
    </div>
  );
}
