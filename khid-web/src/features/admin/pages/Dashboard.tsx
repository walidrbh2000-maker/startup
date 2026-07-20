import { useQuery } from '@tanstack/react-query';
import { useTranslation } from 'react-i18next';
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  Cell,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { Users, HardHat, ClipboardList, Gavel, Wifi, ShieldCheck, Ban, UserRound } from 'lucide-react';
import { adminApi } from '../api';
import { Card, Centered, Spinner } from '../../../components/ui';
import { PageHeader } from '../components/shared';
import type { AdminStats } from '../../../lib/types';

// Fixed brand palette (identical in light/dark) — mirrors app_theme icon accents.
const PALETTE = ['#4F46E5', '#8B5CF6', '#10B981', '#EC4899', '#FBBF24', '#6366F1', '#F87171', '#34D399'];

function StatCard({
  icon: Icon,
  label,
  value,
  tone,
}: {
  icon: typeof Users;
  label: string;
  value: number | string;
  tone: string;
}) {
  return (
    <Card className="flex items-center gap-4">
      <div className={`grid h-12 w-12 shrink-0 place-items-center rounded-xl ${tone}`}>
        <Icon className="h-6 w-6" />
      </div>
      <div className="min-w-0">
        <div className="font-display text-2xl font-extrabold text-content">{value}</div>
        <div className="truncate text-xs font-medium text-content-secondary">{label}</div>
      </div>
    </Card>
  );
}

const tooltipStyle = {
  background: 'rgb(var(--surface))',
  border: '1px solid rgb(var(--border))',
  borderRadius: 12,
  color: 'rgb(var(--text))',
  fontSize: 12,
};

export function Dashboard() {
  const { t } = useTranslation();
  const { data, isLoading } = useQuery({ queryKey: ['admin-stats'], queryFn: adminApi.stats });

  if (isLoading || !data) {
    return (
      <Centered>
        <Spinner />
      </Centered>
    );
  }

  const s: AdminStats = data;
  const statusData = Object.entries(s.requests.byStatus).map(([status, count]) => ({ status, count }));
  const proData = s.charts.topProfessions.map((p) => ({ name: p.profession, count: p.count }));

  return (
    <div>
      <PageHeader title={t('admin.dashboard.title')} subtitle={t('admin.dashboard.subtitle')} />

      {/* KPI grid */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard icon={Users} label={t('admin.dashboard.total_users')} value={s.users.total} tone="bg-primary/12 text-primary" />
        <StatCard icon={UserRound} label={t('admin.dashboard.clients')} value={s.users.clients} tone="bg-indigo/12 text-indigo" />
        <StatCard icon={HardHat} label={t('admin.dashboard.workers')} value={s.workers.total} tone="bg-violet/12 text-violet" />
        <StatCard icon={Wifi} label={t('admin.dashboard.online_workers')} value={s.workers.online} tone="bg-emerald/12 text-emerald" />
        <StatCard icon={ClipboardList} label={t('admin.dashboard.total_requests')} value={s.requests.total} tone="bg-pink/12 text-pink" />
        <StatCard icon={Gavel} label={t('admin.dashboard.total_bids')} value={s.bids.total} tone="bg-warning/12 text-warning" />
        <StatCard icon={ShieldCheck} label={t('admin.dashboard.verified')} value={s.workers.verified} tone="bg-success/12 text-success" />
        <StatCard icon={Ban} label={t('admin.dashboard.banned')} value={s.users.banned} tone="bg-danger/12 text-danger" />
      </div>

      {/* charts */}
      <div className="mt-6 grid gap-5 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <h3 className="mb-4 font-bold text-content">{t('admin.dashboard.requests_per_day')}</h3>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={s.charts.requestsPerDay} margin={{ top: 4, right: 8, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="reqFill" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#4F46E5" stopOpacity={0.4} />
                  <stop offset="100%" stopColor="#4F46E5" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="date" tick={{ fontSize: 10, fill: 'rgb(var(--text-secondary))' }} tickLine={false} axisLine={false} minTickGap={24} />
              <YAxis tick={{ fontSize: 10, fill: 'rgb(var(--text-secondary))' }} tickLine={false} axisLine={false} allowDecimals={false} width={30} />
              <Tooltip contentStyle={tooltipStyle} cursor={{ stroke: 'rgb(var(--border))' }} />
              <Area type="monotone" dataKey="count" stroke="#4F46E5" strokeWidth={2.5} fill="url(#reqFill)" />
            </AreaChart>
          </ResponsiveContainer>
        </Card>

        <Card>
          <h3 className="mb-4 font-bold text-content">{t('admin.dashboard.by_status')}</h3>
          {statusData.length === 0 ? (
            <p className="py-10 text-center text-sm text-content-secondary">{t('common.empty')}</p>
          ) : (
            <div className="space-y-3">
              {statusData.map((row, i) => {
                const max = Math.max(...statusData.map((r) => r.count));
                return (
                  <div key={row.status}>
                    <div className="mb-1 flex justify-between text-xs">
                      <span className="font-semibold text-content">{row.status}</span>
                      <span className="text-content-secondary">{row.count}</span>
                    </div>
                    <div className="h-2 overflow-hidden rounded-full bg-surface-variant">
                      <div
                        className="h-full rounded-full"
                        style={{ width: `${(row.count / max) * 100}%`, background: PALETTE[i % PALETTE.length] }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </Card>
      </div>

      {/* top professions */}
      <Card className="mt-5">
        <h3 className="mb-4 font-bold text-content">{t('admin.dashboard.top_professions')}</h3>
        {proData.length === 0 ? (
          <p className="py-10 text-center text-sm text-content-secondary">{t('common.empty')}</p>
        ) : (
          <ResponsiveContainer width="100%" height={260}>
            <BarChart data={proData} margin={{ top: 4, right: 8, left: -20, bottom: 0 }}>
              <XAxis dataKey="name" tick={{ fontSize: 10, fill: 'rgb(var(--text-secondary))' }} tickLine={false} axisLine={false} interval={0} angle={-15} textAnchor="end" height={50} />
              <YAxis tick={{ fontSize: 10, fill: 'rgb(var(--text-secondary))' }} tickLine={false} axisLine={false} allowDecimals={false} width={30} />
              <Tooltip contentStyle={tooltipStyle} cursor={{ fill: 'rgb(var(--surface-variant))' }} />
              <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                {proData.map((_, i) => (
                  <Cell key={i} fill={PALETTE[i % PALETTE.length]} />
                ))}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
        )}
      </Card>
    </div>
  );
}
