import { useTranslation } from 'react-i18next';
import { PublicNav } from './sections/PublicNav';
import { Hero } from './sections/Hero';
import { Services } from './sections/Services';
import { HowItWorks } from './sections/HowItWorks';
import { ForWorkers } from './sections/ForWorkers';
import { Features } from './sections/Features';
import { Faq } from './sections/Faq';
import { DownloadCta } from './sections/DownloadCta';
import { Footer } from './sections/Footer';
import { BackToTop, ScrollProgress } from './sections/ScrollExtras';

export function Landing() {
  const { t } = useTranslation();
  return (
    <div className="min-h-screen bg-bg">
      <a href="#main" className="skip-link">
        {t('common.skip_to_content')}
      </a>
      <ScrollProgress />
      <PublicNav />
      <main id="main">
        <Hero />
        <Services />
        <HowItWorks />
        <ForWorkers />
        <Features />
        <Faq />
        <DownloadCta />
      </main>
      <Footer />
      <BackToTop />
    </div>
  );
}
