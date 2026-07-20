import { useTranslation } from 'react-i18next';
import { motion } from 'framer-motion';
import { Radar, Wallet, TrendingUp, BellRing, Check } from 'lucide-react';
import { Section, Reveal } from './_shared';
import { IS_SERVER } from '../../../lib/env';
import { Button } from '../../../components/ui';

export function ForWorkers() {
  const { t } = useTranslation();
  const benefits = [
    { Icon: Radar, text: t('workers.benefit1') },
    { Icon: Wallet, text: t('workers.benefit2') },
    { Icon: TrendingUp, text: t('workers.benefit3') },
    { Icon: BellRing, text: t('workers.benefit4') },
  ];

  return (
    <Section id="workers">
      <div className="grid items-center gap-12 lg:grid-cols-2">
        {/* visual */}
        <Reveal className="order-2 lg:order-1">
          <div className="relative overflow-hidden rounded-3xl border border-border bg-gradient-to-br from-worker/15 via-primary/10 to-transparent p-8">
            <div className="pointer-events-none absolute -end-10 -top-10 h-48 w-48 rounded-full bg-worker/20 blur-3xl" />
            <div className="space-y-3">
              {benefits.map((b, i) => (
                <motion.div
                  key={i}
                  initial={IS_SERVER ? false : { opacity: 0, x: 20 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.08 }}
                  className="glass flex items-center gap-3 rounded-2xl border border-border p-4"
                >
                  <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-worker/15 text-worker">
                    <b.Icon className="h-5 w-5" />
                  </div>
                  <span className="text-sm font-semibold text-content">{b.text}</span>
                  <Check className="ms-auto h-5 w-5 text-success" />
                </motion.div>
              ))}
            </div>
          </div>
        </Reveal>

        {/* copy */}
        <div className="order-1 lg:order-2">
          <Reveal>
            <span className="inline-flex items-center rounded-full bg-worker/12 px-3 py-1 text-xs font-bold uppercase tracking-wide text-worker">
              {t('workers.kicker')}
            </span>
          </Reveal>
          <Reveal delay={0.05}>
            <h2 className="mt-4 font-display text-3xl font-extrabold leading-tight text-content sm:text-4xl">
              {t('workers.title')}
            </h2>
          </Reveal>
          <Reveal delay={0.1}>
            <p className="mt-3 text-lg text-content-secondary">{t('workers.subtitle')}</p>
          </Reveal>
          <Reveal delay={0.15}>
            <a href="#download" className="mt-8 inline-block">
              <Button size="lg" className="!bg-worker">
                {t('workers.cta')}
              </Button>
            </a>
          </Reveal>
        </div>
      </div>
    </Section>
  );
}
