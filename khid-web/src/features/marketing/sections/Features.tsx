import { useTranslation } from 'react-i18next';
import { ShieldCheck, Sparkles, MapPin, Radio, BadgeDollarSign, Languages } from 'lucide-react';
import { Section, SectionHeading, Reveal } from './_shared';

export function Features() {
  const { t } = useTranslation();
  const features = [
    { Icon: ShieldCheck, title: t('features.f1_title'), desc: t('features.f1_desc'), tone: 'text-emerald', bg: 'bg-emerald/12' },
    { Icon: Sparkles, title: t('features.f2_title'), desc: t('features.f2_desc'), tone: 'text-violet', bg: 'bg-violet/12' },
    { Icon: MapPin, title: t('features.f3_title'), desc: t('features.f3_desc'), tone: 'text-indigo', bg: 'bg-indigo/12' },
    { Icon: Radio, title: t('features.f4_title'), desc: t('features.f4_desc'), tone: 'text-pink', bg: 'bg-pink/12' },
    { Icon: BadgeDollarSign, title: t('features.f5_title'), desc: t('features.f5_desc'), tone: 'text-warning', bg: 'bg-warning/12' },
    { Icon: Languages, title: t('features.f6_title'), desc: t('features.f6_desc'), tone: 'text-primary', bg: 'bg-primary/12' },
  ];

  return (
    <Section className="bg-bg-deep/40">
      <SectionHeading kicker={t('features.kicker')} title={t('features.title')} />

      <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
        {features.map((f, i) => (
          <Reveal key={f.title} delay={(i % 3) * 0.06}>
            <div className="card h-full p-6 transition-all duration-300 hover:-translate-y-1 hover:shadow-glow">
              <div className={`grid h-12 w-12 place-items-center rounded-xl ${f.bg}`}>
                <f.Icon className={`h-6 w-6 ${f.tone}`} />
              </div>
              <h3 className="mt-4 font-display text-lg font-bold text-content">{f.title}</h3>
              <p className="mt-1.5 text-sm text-content-secondary">{f.desc}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
