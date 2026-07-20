import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { Menu, X } from 'lucide-react';
import { Controls } from '../../../components/layout/Controls';
import { Button } from '../../../components/ui';
import { Logo } from '../../../components/layout/Logo';
import { cn } from '../../../lib/cn';

const links = [
  { href: '#services', key: 'nav.services' },
  { href: '#how', key: 'nav.how' },
  { href: '#workers', key: 'nav.workers' },
  { href: '#faq', key: 'nav.faq' },
];

export function PublicNav() {
  const { t } = useTranslation();
  const reduced = useReducedMotion();
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 12);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  // Close the mobile menu with Escape (focus stays on the toggle).
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setOpen(false);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open]);

  return (
    <header
      className={cn(
        'fixed inset-x-0 top-0 z-40 transition-all duration-300',
        scrolled ? 'glass border-b border-border py-2.5' : 'py-4',
      )}
    >
      <nav className="container-x flex items-center justify-between gap-4" aria-label="Main">
        <a href="#top" className="shrink-0">
          <Logo />
        </a>

        <div className="hidden items-center gap-8 lg:flex">
          {links.map((l) => (
            <a
              key={l.href}
              href={l.href}
              className="text-sm font-semibold text-content-secondary transition hover:text-content"
            >
              {t(l.key)}
            </a>
          ))}
        </div>

        <div className="flex items-center gap-2">
          <Controls className="hidden sm:flex" />
          <a href="#download" className="hidden sm:block">
            <Button size="sm">{t('nav.download')}</Button>
          </a>
          <button
            className="inline-flex h-11 w-11 items-center justify-center rounded-lg border border-border bg-surface text-content lg:hidden"
            onClick={() => setOpen((o) => !o)}
            aria-label={t('nav.menu')}
            aria-expanded={open}
            aria-controls="mobile-menu"
          >
            {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
          </button>
        </div>
      </nav>

      <AnimatePresence>
        {open && (
          <motion.div
            id="mobile-menu"
            initial={reduced ? false : { opacity: 0, y: -8 }}
            animate={{ opacity: 1, y: 0 }}
            exit={reduced ? undefined : { opacity: 0, y: -8, transition: { duration: 0.15 } }}
            transition={{ duration: 0.2, ease: 'easeOut' }}
            className="container-x mt-2 lg:hidden"
          >
            <div className="card flex flex-col gap-1 p-3 shadow-card">
              {links.map((l) => (
                <a
                  key={l.href}
                  href={l.href}
                  onClick={() => setOpen(false)}
                  className="rounded-lg px-3 py-2.5 text-sm font-semibold text-content-secondary hover:bg-surface-variant hover:text-content"
                >
                  {t(l.key)}
                </a>
              ))}
              <div className="flex items-center justify-between gap-2 px-1 pt-2">
                <Controls />
                <a href="#download" onClick={() => setOpen(false)}>
                  <Button size="sm">{t('nav.download')}</Button>
                </a>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </header>
  );
}
