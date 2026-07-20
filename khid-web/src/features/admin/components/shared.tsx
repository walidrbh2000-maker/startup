import { type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { Inbox } from 'lucide-react';
import { Badge, Skeleton } from '../../../components/ui';
import type { BidStatus, Role, ServiceStatus } from '../../../lib/types';

export function PageHeader({
  title,
  subtitle,
  action,
}: {
  title: string;
  subtitle?: string;
  action?: ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-wrap items-end justify-between gap-3">
      <div>
        <h1 className="font-display text-2xl font-extrabold text-content">{title}</h1>
        {subtitle && <p className="mt-1 text-sm text-content-secondary">{subtitle}</p>}
      </div>
      {action}
    </div>
  );
}

/** Card-wrapped, horizontally scrollable table shell. */
export function TableCard({ children }: { children: ReactNode }) {
  return (
    <div className="card overflow-hidden p-0">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[640px] text-start text-sm">{children}</table>
      </div>
    </div>
  );
}

export function Th({ children, className }: { children?: ReactNode; className?: string }) {
  return (
    <th
      className={`whitespace-nowrap border-b border-border px-4 py-3 text-start text-xs font-bold uppercase tracking-wide text-content-secondary ${className ?? ''}`}
    >
      {children}
    </th>
  );
}

export function Td({ children, className }: { children?: ReactNode; className?: string }) {
  return <td className={`border-b border-border px-4 py-3 align-middle ${className ?? ''}`}>{children}</td>;
}

export function LoadingRows({ rows = 6 }: { rows?: number }) {
  return (
    <div className="space-y-3 p-4">
      {Array.from({ length: rows }, (_, i) => (
        <div key={i} className="flex items-center gap-4">
          <Skeleton className="h-9 w-9 shrink-0 rounded-full" />
          <Skeleton className="h-4 flex-1" />
          <Skeleton className="h-4 w-20" />
          <Skeleton className="hidden h-4 w-24 sm:block" />
        </div>
      ))}
    </div>
  );
}

export function EmptyState() {
  const { t } = useTranslation();
  return (
    <div className="flex flex-col items-center gap-3 py-16 text-content-secondary">
      <Inbox className="h-8 w-8 opacity-60" />
      <p className="text-sm">{t('common.empty')}</p>
    </div>
  );
}

// ── Status badges ─────────────────────────────────────────────────────────────
const serviceTone: Record<string, Parameters<typeof Badge>[0]['tone']> = {
  open: 'primary',
  awaitingSelection: 'warning',
  bidSelected: 'warning',
  inProgress: 'violet',
  completed: 'success',
  cancelled: 'danger',
  expired: 'neutral',
  pending: 'warning',
  accepted: 'success',
  declined: 'danger',
};

export function ServiceStatusBadge({ status }: { status: ServiceStatus }) {
  return <Badge tone={serviceTone[status] ?? 'neutral'}>{status}</Badge>;
}

const bidTone: Record<string, Parameters<typeof Badge>[0]['tone']> = {
  pending: 'warning',
  accepted: 'success',
  declined: 'danger',
  withdrawn: 'neutral',
  expired: 'neutral',
};

export function BidStatusBadge({ status }: { status: BidStatus }) {
  return <Badge tone={bidTone[status] ?? 'neutral'}>{status}</Badge>;
}

const roleTone: Record<Role, Parameters<typeof Badge>[0]['tone']> = {
  admin: 'violet',
  worker: 'primary',
  client: 'neutral',
};

export function RoleBadge({ role }: { role: Role }) {
  return <Badge tone={roleTone[role] ?? 'neutral'}>{role}</Badge>;
}
