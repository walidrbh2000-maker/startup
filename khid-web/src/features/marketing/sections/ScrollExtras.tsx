import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { AnimatePresence, motion, useReducedMotion, useScroll, useSpring } from 'framer-motion';
import { ArrowUp } from 'lucide-react';

/** Top-of-page reading progress bar tied to scroll position. */
export function ScrollProgress() {
  const { scrollYProgress } = useScroll();
  const scaleX = useSpring(scrollYProgress, { stiffness: 140, damping: 28, restDelta: 0.001 });
  return (
    <motion.div
      aria-hidden="true"
      style={{ scaleX }}
      className="fixed inset-x-0 top-0 z-50 h-0.5 origin-left bg-gradient-to-r from-primary via-violet to-pink rtl:origin-right"
    />
  );
}

/** Floating back-to-top button, appears after ~1.5 screens of scroll. */
export function BackToTop() {
  const { t } = useTranslation();
  const reduced = useReducedMotion();
  const [show, setShow] = useState(false);

  useEffect(() => {
    const onScroll = () => setShow(window.scrollY > window.innerHeight * 1.5);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  return (
    <AnimatePresence>
      {show && (
        <motion.button
          initial={reduced ? false : { opacity: 0, scale: 0.8, y: 8 }}
          animate={{ opacity: 1, scale: 1, y: 0 }}
          exit={reduced ? undefined : { opacity: 0, scale: 0.8, y: 8 }}
          transition={{ duration: 0.2, ease: 'easeOut' }}
          onClick={() => window.scrollTo({ top: 0, behavior: reduced ? 'auto' : 'smooth' })}
          aria-label={t('common.back_to_top')}
          className="fixed bottom-6 end-6 z-40 grid h-11 w-11 place-items-center rounded-full border border-border bg-surface/80 text-content shadow-card backdrop-blur transition hover:border-primary/40 hover:text-primary"
        >
          <ArrowUp className="h-5 w-5" />
        </motion.button>
      )}
    </AnimatePresence>
  );
}
