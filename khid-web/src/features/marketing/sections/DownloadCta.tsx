import { useTranslation } from 'react-i18next';
import { motion } from 'framer-motion';
import { Smartphone, Apple } from 'lucide-react';
import { Reveal } from './_shared';

export function DownloadCta() {
  const { t } = useTranslation();
  const android = import.meta.env.VITE_APP_ANDROID_URL || '#';
  const ios = import.meta.env.VITE_APP_IOS_URL || '#';

  return (
    <section id="download" className="py-20 sm:py-28">
      <div className="container-x">
        <Reveal>
          <div
            className="animated-gradient relative overflow-hidden rounded-[2rem] px-8 py-16 text-center shadow-glow sm:px-16"
            style={{
              backgroundImage:
                'linear-gradient(120deg, rgb(var(--primary)), rgb(var(--accent-violet)), rgb(var(--accent-pink)), rgb(var(--primary)))',
            }}
          >
            <div className="pointer-events-none absolute -end-16 -top-16 h-64 w-64 rounded-full bg-white/10 blur-2xl" />
            <div className="pointer-events-none absolute -bottom-20 -start-10 h-64 w-64 rounded-full bg-black/10 blur-2xl" />
            <h2 className="relative font-display text-3xl font-extrabold text-white sm:text-4xl">
              {t('download.title')}
            </h2>
            <p className="relative mx-auto mt-3 max-w-xl text-base text-white/85 sm:text-lg">
              {t('download.subtitle')}
            </p>
            <div className="relative mt-8 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <motion.a
                whileHover={{ scale: 1.04 }}
                whileTap={{ scale: 0.97 }}
                href={android}
                className="inline-flex h-12 items-center gap-2.5 rounded-xl bg-white px-6 font-semibold text-primary shadow-lg"
              >
                <Smartphone className="h-5 w-5" />
                {t('download.android')}
              </motion.a>
              <motion.a
                whileHover={{ scale: 1.04 }}
                whileTap={{ scale: 0.97 }}
                href={ios}
                className="inline-flex h-12 items-center gap-2.5 rounded-xl border border-white/40 bg-white/10 px-6 font-semibold text-white backdrop-blur"
              >
                <Apple className="h-5 w-5" />
                {t('download.ios')}
              </motion.a>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
