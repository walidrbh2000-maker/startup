import { useEffect } from 'react';
import { Link, useParams, Navigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, ArrowRight } from 'lucide-react';
import { PublicNav } from './sections/PublicNav';
import { Footer } from './sections/Footer';
import { useTheme } from '../../lib/theme';

const DOCS = ['privacy', 'terms'] as const;
type Doc = (typeof DOCS)[number];

/**
 * Privacy policy / terms of service. Content lives in i18n as an array of
 * { h, p } sections so all three languages stay in sync.
 */
export function LegalPage() {
  const { doc } = useParams<{ doc: string }>();
  const { t } = useTranslation();
  const { lang } = useTheme();
  const Arrow = lang === 'ar' ? ArrowRight : ArrowLeft;

  useEffect(() => {
    window.scrollTo(0, 0);
  }, [doc]);

  if (!DOCS.includes(doc as Doc)) return <Navigate to="/" replace />;
  const key = doc as Doc;

  const sections = t(`legal.${key}.sections`, { returnObjects: true }) as {
    h: string;
    p: string;
  }[];

  return (
    <div className="min-h-screen bg-bg">
      <PublicNav />
      <main id="main" className="container-x pb-24 pt-32 sm:pt-40">
        <div className="mx-auto max-w-3xl">
          <Link
            to="/"
            className="inline-flex items-center gap-2 text-sm font-semibold text-content-secondary transition hover:text-primary"
          >
            <Arrow className="h-4 w-4" />
            {t('legal.back')}
          </Link>
          <h1 className="mt-6 font-display text-3xl font-extrabold text-content sm:text-4xl">
            {t(`legal.${key}.title`)}
          </h1>
          <p className="mt-2 text-sm text-content-secondary">{t('legal.updated')}</p>

          <div className="mt-10 space-y-8">
            {sections.map((s, i) => (
              <section key={i}>
                <h2 className="font-display text-xl font-bold text-content">{s.h}</h2>
                <p className="mt-2 leading-relaxed text-content-secondary">{s.p}</p>
              </section>
            ))}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
