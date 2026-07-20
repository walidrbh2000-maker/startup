import { useEffect, useRef, useState, type PointerEvent, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import {
  AnimatePresence,
  animate,
  motion,
  useInView,
  useMotionValue,
  useReducedMotion,
  useSpring,
  useTransform,
} from 'framer-motion';
import { ArrowLeft, ArrowRight, Star, MapPin, CheckCircle2, BellRing } from 'lucide-react';
import { useQuery } from '@tanstack/react-query';
import { http } from '../../../lib/api';
import type { ProfessionDto } from '../../../lib/types';
import { Button } from '../../../components/ui';
import { useTheme } from '../../../lib/theme';
import { IS_SERVER } from '../../../lib/env';

/** On the server, render motion elements in their final (visible) state. */
const mi = <T,>(v: T): T | false => (IS_SERVER ? false : v);

/** Animated count-up that starts when scrolled into view. */
function CountUp({ to, suffix = '' }: { to: number; suffix?: string }) {
  const ref = useRef<HTMLSpanElement>(null);
  const inView = useInView(ref, { once: true, margin: '-40px' });
  const reduced = useReducedMotion();
  const [display, setDisplay] = useState(IS_SERVER || reduced ? to : 0);

  useEffect(() => {
    if (!inView) return;
    if (reduced) {
      setDisplay(to);
      return;
    }
    const controls = animate(0, to, {
      duration: 1.4,
      ease: [0.22, 1, 0.36, 1],
      onUpdate: (v) => setDisplay(Math.round(v)),
    });
    return () => controls.stop();
  }, [inView, to, reduced]);

  return (
    <span ref={ref}>
      {display.toLocaleString()}
      {suffix}
    </span>
  );
}

function Stat({ children, label }: { children: ReactNode; label: string }) {
  return (
    <div>
      <div className="font-display text-2xl font-extrabold text-content sm:text-3xl">{children}</div>
      <div className="text-xs font-medium text-content-secondary sm:text-sm">{label}</div>
    </div>
  );
}

export function Hero() {
  const { t } = useTranslation();
  const { lang } = useTheme();
  const Arrow = lang === 'ar' ? ArrowLeft : ArrowRight;

  // Same queryKey as the Services grid → deduped into a single request.
  const { data: professions } = useQuery({
    queryKey: ['professions', lang],
    queryFn: () => http.get<ProfessionDto[]>('/professions', { lang }),
    staleTime: 1000 * 60 * 30,
  });

  return (
    <section id="top" className="relative overflow-hidden pt-32 pb-10 sm:pt-40 sm:pb-14">
      {/* ambient glows */}
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute -top-24 start-1/4 h-96 w-96 rounded-full bg-primary/25 blur-[120px]" />
        <div className="absolute top-40 end-0 h-80 w-80 rounded-full bg-violet/20 blur-[120px]" />
      </div>

      <div className="container-x grid items-center gap-14 lg:grid-cols-2">
        {/* ── Copy ── */}
        <div className="text-center lg:text-start">
          <motion.span
            initial={mi({ opacity: 0, y: 12 })}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="inline-flex items-center gap-2 rounded-full border border-border bg-surface/70 px-4 py-1.5 text-xs font-semibold text-content-secondary backdrop-blur"
          >
            <span className="relative flex h-2 w-2">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-success opacity-75" />
              <span className="relative inline-flex h-2 w-2 rounded-full bg-success" />
            </span>
            {t('hero.badge')}
          </motion.span>

          <motion.h1
            initial={mi({ opacity: 0, y: 16 })}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.05 }}
            className="mt-6 font-display text-4xl font-extrabold leading-[1.1] tracking-tight text-content sm:text-6xl"
          >
            {t('hero.title_1')} <span className="text-gradient">{t('hero.title_hl')}</span>{' '}
            {t('hero.title_2')}
          </motion.h1>

          <motion.p
            initial={mi({ opacity: 0, y: 16 })}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.12 }}
            className="mx-auto mt-6 max-w-xl text-lg text-content-secondary lg:mx-0"
          >
            {t('hero.subtitle')}
          </motion.p>

          <motion.div
            initial={mi({ opacity: 0, y: 16 })}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6, delay: 0.18 }}
            className="mt-8 flex flex-col items-center gap-3 sm:flex-row lg:justify-start"
          >
            <a href="#download">
              <Button size="lg">
                {t('hero.cta_primary')}
                <Arrow className="h-4 w-4" />
              </Button>
            </a>
            <a href="#services">
              <Button size="lg" variant="outline">
                {t('hero.cta_secondary')}
              </Button>
            </a>
          </motion.div>

          {/* Honest, verifiable product facts (professions count is live data) */}
          <motion.div
            initial={mi({ opacity: 0 })}
            animate={{ opacity: 1 }}
            transition={{ duration: 0.6, delay: 0.3 }}
            className="mt-12 flex items-center justify-center gap-8 lg:justify-start"
          >
            <Stat label={t('hero.stat_professions')}>
              <CountUp to={professions?.length ?? 20} suffix="+" />
            </Stat>
            <div className="h-10 w-px bg-border" />
            <Stat label={t('hero.stat_languages')}>
              <CountUp to={3} />
            </Stat>
            <div className="h-10 w-px bg-border" />
            <Stat label={t('hero.stat_free')}>
              <CountUp to={100} suffix="%" />
            </Stat>
          </motion.div>
        </div>

        {/* ── Phone mockup ── */}
        <div className="relative mx-auto w-full max-w-sm">
          <PhoneMockup />
        </div>
      </div>

      {/* ── Professions marquee ── */}
      <ProfessionMarquee items={professions ?? []} />
    </section>
  );
}

/* ── Live offers demo: bids "arrive" in a loop like the real app ─────────── */
const OFFERS = [
  { n: 'Karim B.', r: 4.9, p: '1 800 DA', tone: 'text-emerald' },
  { n: 'Sofiane M.', r: 4.7, p: '2 100 DA', tone: 'text-indigo' },
  { n: 'Yacine T.', r: 4.8, p: '1 950 DA', tone: 'text-violet' },
];

function useOfferCycle(reduced: boolean) {
  // Grow 1 → 3 visible offers, hold, then restart — reads as live bids arriving.
  const [count, setCount] = useState(IS_SERVER || reduced ? OFFERS.length : 1);
  useEffect(() => {
    if (reduced) return;
    const id = setInterval(() => {
      setCount((c) => (c >= OFFERS.length ? 1 : c + 1));
    }, 2600);
    return () => clearInterval(id);
  }, [reduced]);
  return count;
}

function PhoneMockup() {
  const { t } = useTranslation();
  const reduced = useReducedMotion() ?? false;
  const visible = useOfferCycle(reduced);

  // Pointer-follow tilt (springed, disabled for reduced motion)
  const mx = useMotionValue(0);
  const my = useMotionValue(0);
  const rotateY = useSpring(useTransform(mx, [-0.5, 0.5], [-7, 7]), { stiffness: 120, damping: 14 });
  const rotateX = useSpring(useTransform(my, [-0.5, 0.5], [6, -6]), { stiffness: 120, damping: 14 });

  const onPointerMove = (e: PointerEvent<HTMLDivElement>) => {
    if (reduced) return;
    const r = e.currentTarget.getBoundingClientRect();
    mx.set((e.clientX - r.left) / r.width - 0.5);
    my.set((e.clientY - r.top) / r.height - 0.5);
  };
  const onPointerLeave = () => {
    mx.set(0);
    my.set(0);
  };

  return (
    <motion.div
      initial={mi({ opacity: 0, scale: 0.92, y: 20 })}
      animate={{ opacity: 1, scale: 1, y: 0 }}
      transition={{ duration: 0.7, delay: 0.2, ease: [0.22, 1, 0.36, 1] }}
      className="relative"
      style={{ perspective: 1000 }}
      onPointerMove={onPointerMove}
      onPointerLeave={onPointerLeave}
    >
      <motion.div
        style={{ rotateX, rotateY, transformStyle: 'preserve-3d' }}
        className="relative mx-auto aspect-[9/19] w-72 rounded-[2.5rem] border border-border bg-bg-deep p-3 shadow-glow"
      >
        <div className="flex h-full flex-col overflow-hidden rounded-[2rem] bg-surface">
          {/* app bar */}
          <div className="flex items-center justify-between bg-gradient-to-br from-primary to-violet px-5 pb-6 pt-8 text-white">
            <div>
              <div className="text-xs opacity-80">Khidmeti</div>
              <div className="font-display text-base font-bold">{t('hero.title_hl')}</div>
            </div>
            <div className="grid h-9 w-9 place-items-center rounded-full bg-white/20 text-sm font-bold">
              خ
            </div>
          </div>
          {/* request card */}
          <div className="-mt-4 space-y-3 px-4">
            <div className="rounded-2xl border border-border bg-bg p-3 shadow-card">
              <div className="flex items-center gap-2 text-xs font-semibold text-content">
                <MapPin className="h-3.5 w-3.5 text-primary" /> Oran, Es Senia
              </div>
              <div className="mt-1.5 text-sm font-bold text-content">Fuite d'eau · Plomberie</div>
            </div>

            {/* live incoming offers */}
            <div className="flex items-center gap-1.5 px-1 text-[11px] font-bold text-content-secondary">
              <BellRing className="h-3 w-3 text-primary" />
              {t('hero.phone_offers')}
              <span className="ms-auto inline-flex h-4 min-w-4 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-black text-white">
                {visible}
              </span>
            </div>
            <AnimatePresence initial={false}>
              {OFFERS.slice(0, visible).map((o) => (
                <motion.div
                  key={o.n}
                  layout
                  initial={mi({ opacity: 0, y: 14, scale: 0.96 })}
                  animate={{ opacity: 1, y: 0, scale: 1 }}
                  exit={{ opacity: 0, scale: 0.96, transition: { duration: 0.15 } }}
                  transition={{ duration: 0.35, ease: [0.22, 1, 0.36, 1] }}
                  className="flex items-center gap-3 rounded-2xl border border-border bg-bg p-3"
                >
                  <div className="grid h-9 w-9 place-items-center rounded-full bg-primary/15 text-xs font-bold text-primary">
                    {o.n[0]}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="truncate text-xs font-bold text-content">{o.n}</div>
                    <div className="flex items-center gap-1 text-[11px] text-content-secondary">
                      <Star className="h-3 w-3 fill-warning text-warning" /> {o.r}
                    </div>
                  </div>
                  <div className={`text-sm font-extrabold ${o.tone}`}>{o.p}</div>
                </motion.div>
              ))}
            </AnimatePresence>
          </div>
        </div>
      </motion.div>

      {/* floating badge */}
      <motion.div
        animate={reduced ? undefined : { y: [0, -10, 0] }}
        transition={{ duration: 4, repeat: Infinity, ease: 'easeInOut' }}
        className="glass absolute -start-6 top-1/3 flex items-center gap-2 rounded-2xl border border-border p-3 shadow-card"
      >
        <CheckCircle2 className="h-5 w-5 text-success" />
        <div className="text-xs">
          <div className="font-bold text-content">Vérifié</div>
          <div className="text-content-secondary">Profils vérifiés</div>
        </div>
      </motion.div>
    </motion.div>
  );
}

/* ── Seamless professions marquee (CSS-driven, dir-aware, pauses on hover) ── */
function ProfessionMarquee({ items }: { items: ProfessionDto[] }) {
  if (items.length < 4) return null;
  const labels = items.map((p) => p.label);
  return (
    <div className="marquee relative mt-16 overflow-hidden" aria-hidden="true">
      <div className="pointer-events-none absolute inset-y-0 start-0 z-10 w-24 bg-gradient-to-r from-bg to-transparent rtl:bg-gradient-to-l" />
      <div className="pointer-events-none absolute inset-y-0 end-0 z-10 w-24 bg-gradient-to-l from-bg to-transparent rtl:bg-gradient-to-r" />
      <div className="marquee-track gap-3 pe-3">
        {[...labels, ...labels].map((label, i) => (
          <span
            key={`${label}-${i}`}
            className="whitespace-nowrap rounded-full border border-border bg-surface/70 px-4 py-2 text-sm font-semibold text-content-secondary"
          >
            {label}
          </span>
        ))}
      </div>
    </div>
  );
}
