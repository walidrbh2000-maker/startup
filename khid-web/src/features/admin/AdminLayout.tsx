import { useState } from 'react';
import { NavLink, Outlet, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
  LayoutDashboard,
  Users,
  HardHat,
  FileCheck,
  ClipboardList,
  Gavel,
  Wrench,
  Send,
  LogOut,
  Menu,
  X,
  ExternalLink,
} from 'lucide-react';
import { useAuth } from '../../lib/auth';
import { Controls } from '../../components/layout/Controls';
import { Logo } from '../../components/layout/Logo';
import { cn } from '../../lib/cn';

const nav = [
  { to: '/admin', end: true, icon: LayoutDashboard, key: 'admin.nav.dashboard' },
  { to: '/admin/users', icon: Users, key: 'admin.nav.users' },
  { to: '/admin/workers', icon: HardHat, key: 'admin.nav.workers' },
  { to: '/admin/verifications', icon: FileCheck, key: 'admin.nav.verifications' },
  { to: '/admin/requests', icon: ClipboardList, key: 'admin.nav.requests' },
  { to: '/admin/bids', icon: Gavel, key: 'admin.nav.bids' },
  { to: '/admin/professions', icon: Wrench, key: 'admin.nav.professions' },
  { to: '/admin/broadcast', icon: Send, key: 'admin.nav.broadcast' },
];

export function AdminLayout() {
  const { t } = useTranslation();
  const { user, signOut } = useAuth();
  const [open, setOpen] = useState(false);

  const SidebarContent = (
    <div className="flex h-full flex-col">
      <div className="px-5 py-5">
        <Logo />
      </div>
      <nav className="flex-1 space-y-1 px-3">
        {nav.map((n) => (
          <NavLink
            key={n.to}
            to={n.to}
            end={n.end}
            onClick={() => setOpen(false)}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-semibold transition',
                isActive
                  ? 'bg-primary/12 text-primary'
                  : 'text-content-secondary hover:bg-surface-variant hover:text-content',
              )
            }
          >
            <n.icon className="h-[18px] w-[18px]" />
            {t(n.key)}
          </NavLink>
        ))}
      </nav>
      <div className="space-y-1 border-t border-border p-3">
        <Link
          to="/"
          className="flex items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-semibold text-content-secondary transition hover:bg-surface-variant hover:text-content"
        >
          <ExternalLink className="h-[18px] w-[18px]" />
          {t('admin.nav.site')}
        </Link>
        <button
          onClick={() => void signOut()}
          className="flex w-full items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-semibold text-danger transition hover:bg-danger/10"
        >
          <LogOut className="h-[18px] w-[18px]" />
          {t('admin.nav.logout')}
        </button>
      </div>
    </div>
  );

  return (
    <div className="min-h-screen bg-bg">
      {/* desktop sidebar */}
      <aside className="fixed inset-y-0 start-0 z-30 hidden w-64 border-e border-border bg-surface lg:block">
        {SidebarContent}
      </aside>

      {/* mobile drawer */}
      {open && (
        <div className="fixed inset-0 z-40 lg:hidden">
          <div className="absolute inset-0 bg-black/50" onClick={() => setOpen(false)} />
          <aside className="absolute inset-y-0 start-0 w-64 border-e border-border bg-surface">
            {SidebarContent}
          </aside>
        </div>
      )}

      {/* main column */}
      <div className="lg:ps-64">
        <header className="glass sticky top-0 z-20 flex h-16 items-center justify-between gap-3 border-b border-border px-4 sm:px-6">
          <button
            className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-surface text-content lg:hidden"
            onClick={() => setOpen((o) => !o)}
            aria-label="menu"
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
          <div className="hidden lg:block" />
          <div className="flex items-center gap-3">
            <Controls />
            <div className="flex items-center gap-2.5">
              <div className="grid h-9 w-9 place-items-center rounded-full bg-primary/15 text-sm font-bold text-primary">
                {(user?.email ?? 'A')[0].toUpperCase()}
              </div>
              <span className="hidden text-sm font-semibold text-content sm:block">{user?.email}</span>
            </div>
          </div>
        </header>

        <main className="p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
