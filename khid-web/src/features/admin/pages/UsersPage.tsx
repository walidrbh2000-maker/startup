import { useState, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Search, Ban, ShieldCheck, Trash2, MoreVertical } from 'lucide-react';
import { adminApi, type ListParams } from '../api';
import { useDebounced } from '../../../hooks/useDebounced';
import { Input, Select, Badge, Button } from '../../../components/ui';
import { Pagination } from '../../../components/ui/Pagination';
import { useToast } from '../../../components/ui/toast';
import {
  PageHeader,
  TableCard,
  Th,
  Td,
  LoadingRows,
  EmptyState,
  RoleBadge,
} from '../components/shared';
import { formatDate, initials } from '../../../lib/format';
import { useTheme } from '../../../lib/theme';
import type { AdminUser } from '../../../lib/types';
import type { ApiError } from '../../../lib/api';

export function UsersPage() {
  const { t } = useTranslation();
  const { lang } = useTheme();
  const toast = useToast();
  const qc = useQueryClient();

  const [page, setPage] = useState(1);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const debounced = useDebounced(search);

  const params: ListParams = { page, limit: 15, search: debounced || undefined, role: role || undefined };
  const { data, isLoading } = useQuery({
    queryKey: ['admin-users', params],
    queryFn: () => adminApi.users(params),
  });

  const invalidate = () => {
    void qc.invalidateQueries({ queryKey: ['admin-users'] });
    void qc.invalidateQueries({ queryKey: ['admin-stats'] });
  };
  const onErr = (e: unknown) => toast((e as ApiError)?.message ?? t('common.error'), 'error');

  const banMut = useMutation({
    mutationFn: ({ id, isBanned }: { id: string; isBanned: boolean }) => adminApi.setBan(id, isBanned),
    onSuccess: invalidate,
    onError: onErr,
  });
  const roleMut = useMutation({
    mutationFn: (id: string) => adminApi.setRole(id, 'admin'),
    onSuccess: invalidate,
    onError: onErr,
  });
  const delMut = useMutation({
    mutationFn: (id: string) => adminApi.deleteUser(id),
    onSuccess: invalidate,
    onError: onErr,
  });

  return (
    <div>
      <PageHeader title={t('admin.users.title')} />

      <div className="mb-4 flex flex-wrap items-center gap-3">
        <div className="relative min-w-[220px] flex-1">
          <Search className="pointer-events-none absolute inset-y-0 start-3 my-auto h-4 w-4 text-content-tertiary" />
          <Input
            className="ps-9"
            placeholder={t('admin.users.search')}
            value={search}
            onChange={(e) => {
              setSearch(e.target.value);
              setPage(1);
            }}
          />
        </div>
        <Select
          value={role}
          onChange={(e) => {
            setRole(e.target.value);
            setPage(1);
          }}
          className="w-40"
        >
          <option value="">{t('admin.users.all_roles')}</option>
          <option value="client">client</option>
          <option value="worker">worker</option>
          <option value="admin">admin</option>
        </Select>
      </div>

      {isLoading ? (
        <LoadingRows />
      ) : !data || data.items.length === 0 ? (
        <TableCard>
          <tbody>
            <tr>
              <td>
                <EmptyState />
              </td>
            </tr>
          </tbody>
        </TableCard>
      ) : (
        <>
          <TableCard>
            <thead>
              <tr>
                <Th>{t('admin.users.name')}</Th>
                <Th>{t('admin.users.role')}</Th>
                <Th>{t('admin.users.contact')}</Th>
                <Th>{t('admin.users.status')}</Th>
                <Th>{t('admin.users.joined')}</Th>
                <Th className="text-end">{t('admin.users.actions')}</Th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((u: AdminUser) => (
                <tr key={u._id} className="transition hover:bg-surface-variant/50">
                  <Td>
                    <div className="flex items-center gap-3">
                      <div className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-primary/12 text-xs font-bold text-primary">
                        {initials(u.name) || '?'}
                      </div>
                      <div className="min-w-0">
                        <div className="truncate font-semibold text-content">{u.name}</div>
                        <div className="truncate text-xs text-content-tertiary">{u._id.slice(0, 12)}…</div>
                      </div>
                    </div>
                  </Td>
                  <Td>
                    <RoleBadge role={u.role} />
                  </Td>
                  <Td>
                    <div className="text-xs text-content-secondary">
                      <div>{u.phoneNumber || '—'}</div>
                      <div className="text-content-tertiary">{u.email || '—'}</div>
                    </div>
                  </Td>
                  <Td>
                    {u.isBanned ? (
                      <Badge tone="danger">{t('admin.users.banned')}</Badge>
                    ) : (
                      <Badge tone="success">{t('admin.users.active')}</Badge>
                    )}
                  </Td>
                  <Td>
                    <span className="whitespace-nowrap text-xs text-content-secondary">
                      {formatDate(u.lastUpdated, lang)}
                    </span>
                  </Td>
                  <Td className="text-end">
                    <RowMenu
                      user={u}
                      onBan={() => banMut.mutate({ id: u._id, isBanned: !u.isBanned })}
                      onMakeAdmin={() => roleMut.mutate(u._id)}
                      onDelete={() => {
                        if (confirm(t('admin.users.delete_confirm'))) delMut.mutate(u._id);
                      }}
                    />
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

function RowMenu({
  user,
  onBan,
  onMakeAdmin,
  onDelete,
}: {
  user: AdminUser;
  onBan: () => void;
  onMakeAdmin: () => void;
  onDelete: () => void;
}) {
  const { t } = useTranslation();
  const [open, setOpen] = useState(false);
  return (
    <div className="relative inline-block text-start">
      <Button variant="ghost" size="sm" onClick={() => setOpen((o) => !o)} aria-label="actions">
        <MoreVertical className="h-4 w-4" />
      </Button>
      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute end-0 z-20 mt-1 w-44 overflow-hidden rounded-xl border border-border bg-surface py-1 shadow-card">
            <MenuItem onClick={() => { onBan(); setOpen(false); }}>
              <Ban className="h-4 w-4" />
              {user.isBanned ? t('admin.users.unban') : t('admin.users.ban')}
            </MenuItem>
            {user.role !== 'admin' && (
              <MenuItem onClick={() => { onMakeAdmin(); setOpen(false); }}>
                <ShieldCheck className="h-4 w-4" />
                {t('admin.users.make_admin')}
              </MenuItem>
            )}
            <MenuItem danger onClick={() => { onDelete(); setOpen(false); }}>
              <Trash2 className="h-4 w-4" />
              {t('admin.users.delete')}
            </MenuItem>
          </div>
        </>
      )}
    </div>
  );
}

function MenuItem({
  children,
  onClick,
  danger,
}: {
  children: ReactNode;
  onClick: () => void;
  danger?: boolean;
}) {
  return (
    <button
      onClick={onClick}
      className={`flex w-full items-center gap-2.5 px-3.5 py-2 text-sm font-medium transition hover:bg-surface-variant ${
        danger ? 'text-danger' : 'text-content'
      }`}
    >
      {children}
    </button>
  );
}
