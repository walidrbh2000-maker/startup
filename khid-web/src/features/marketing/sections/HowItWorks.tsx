import { useTranslation } from 'react-i18next';
import { FileText, Users, CheckCheck } from 'lucide-react';
import { Section, SectionHeading, Reveal } from './_shared';

export function HowItWorks() {
  const { t } = useTranslation();
  const steps = [
    { Icon: FileText, title: t('how.step1_title'), desc: t('how.step1_desc'), tone: 'text-indigo', bg: 'bg-indigo/12' },
    { Icon: Users, title: t('how.step2_title'), desc: t('how.step2_desc'), tone: 'text-violet', bg: 'bg-violet/12' },
    { Icon: CheckCheck, title: t('how.step3_title'), desc: t('how.step3_desc'), tone: 'text-emerald', bg: 'bg-emerald/12' },
  ];

  return (
    <Section id="how" className="bg-bg-deep/40">
      <SectionHeading kicker={t('how.kicker')} title={t('how.title')} subtitle={t('how.subtitle')} />

      <div className="mt-16 grid gap-8 md:grid-cols-3">
        {steps.map((s, i) => (
          <Reveal key={s.title} delay={i * 0.1}>
            <div className="relative flex flex-col items-center text-center">
              <div className={`relative grid h-16 w-16 place-items-center rounded-2xl ${s.bg}`}>
                <s.Icon className={`h-7 w-7 ${s.tone}`} />
                <span className="absolute -end-2 -top-2 grid h-7 w-7 place-items-center rounded-full bg-primary text-xs font-black text-white shadow-glow">
                  {i + 1}
                </span>
              </div>
              <h3 className="mt-5 font-display text-xl font-bold text-content">{s.title}</h3>
              <p className="mt-2 max-w-xs text-sm text-content-secondary">{s.desc}</p>
            </div>
          </Reveal>
        ))}
      </div>
    </Section>
  );
}
