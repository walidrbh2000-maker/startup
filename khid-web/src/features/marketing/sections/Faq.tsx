import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Plus } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';
import { Section, SectionHeading, Reveal } from './_shared';
import { cn } from '../../../lib/cn';

export function Faq() {
  const { t } = useTranslation();
  const [open, setOpen] = useState<number | null>(0);
  const items = [
    { q: t('faq.q1'), a: t('faq.a1') },
    { q: t('faq.q2'), a: t('faq.a2') },
    { q: t('faq.q3'), a: t('faq.a3') },
    { q: t('faq.q4'), a: t('faq.a4') },
  ];

  return (
    <Section id="faq">
      <SectionHeading kicker={t('faq.kicker')} title={t('faq.title')} />

      <div className="mx-auto mt-12 max-w-3xl space-y-3">
        {items.map((it, i) => {
          const isOpen = open === i;
          return (
            <Reveal key={i} delay={i * 0.05}>
              <div className={cn('card overflow-hidden transition-colors', isOpen && 'border-primary/40')}>
                <button
                  className="flex w-full items-center justify-between gap-4 p-5 text-start"
                  onClick={() => setOpen(isOpen ? null : i)}
                  aria-expanded={isOpen}
                  aria-controls={`faq-panel-${i}`}
                >
                  <span className="font-bold text-content">{it.q}</span>
                  <Plus
                    aria-hidden="true"
                    className={cn(
                      'h-5 w-5 shrink-0 text-primary transition-transform duration-300',
                      isOpen && 'rotate-45',
                    )}
                  />
                </button>
                <AnimatePresence initial={false}>
                  {isOpen && (
                    <motion.div
                      id={`faq-panel-${i}`}
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.25 }}
                    >
                      <p className="px-5 pb-5 text-sm leading-relaxed text-content-secondary">{it.a}</p>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </Reveal>
          );
        })}
      </div>
    </Section>
  );
}
